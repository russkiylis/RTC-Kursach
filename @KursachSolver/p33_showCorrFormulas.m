function p33_showCorrFormulas(obj)
% P33_SHOWCORRFORMULAS — выводит аналитическую формулу КФ в LaTeX-формате.
%
% Формула нормализуется: τ отображается в единицах obj.time_mult
% (например, в микросекундах), а значения B — соответственно в В²·мкс.
% Преобразование коэффициентов: a_k_disp = a_k_real * tm^(k-1).
%
% Коэффициенты показаны как простые дроби через rats() (например, "172/3",
% а не "57.3333"). Нечётные степени τ записываются через |τ| (КФ чётная).

    k  = obj.selectedSignal;
    T1 = obj.T(k);
    T2 = obj.T2;
    tm = obj.time_mult;

    unitStr = formatTimeUnit(tm);

    fprintf("\n=== КФ выбранного сигнала (T_1 = %.4g с, τ в %s) ===\n\n", T1, unitStr);

    % =====================================================================
    % LATEX-ФОРМУЛА B(τ)
    % =====================================================================
    fprintf("B(\\tau) = \\begin{cases}\n");
    for j = 1:length(obj.corrCoeffs)
        r = obj.corrCoeffs(j).tauRange;
        if r(2) <= r(1)
            continue;    % пустая ветка (например, T1 = T2-T1)
        end

        % Нормализованные коэффициенты: a_k_disp = a_k_real * tm^(k-1)
        pDisp = normalizePoly(obj.corrCoeffs(j).poly, tm);

        exprStr = polyToLatex(pDisp);
        lBnd    = formatBound(r(1), T1, T2);
        rBnd    = formatBound(r(2), T1, T2);

        fprintf("  %s, & |\\tau| \\in [%s,\\, %s] \\\\\n", exprStr, lBnd, rBnd);
    end
    fprintf("  0, & |\\tau| > T_2\n");
    fprintf("\\end{cases}\n\n");

    % =====================================================================
    % ЧИСЛОВЫЕ КОЭФФИЦИЕНТЫ ПОЛИНОМОВ (в нормализованных единицах)
    % =====================================================================
    fprintf("Коэффициенты (нормализованные, τ в %s):\n", unitStr);
    for j = 1:length(obj.corrCoeffs)
        r = obj.corrCoeffs(j).tauRange;
        if r(2) <= r(1)
            continue;
        end
        pDisp = normalizePoly(obj.corrCoeffs(j).poly, tm);
        fprintf("  Ветка %d: a0 = %s, a1 = %s, a2 = %s, a3 = %s\n", j, ...
                fractionStr(pDisp(4)), fractionStr(pDisp(3)), ...
                fractionStr(pDisp(2)), fractionStr(pDisp(1)));
    end
    fprintf("\n");
end


% =========================================================================
% ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
% =========================================================================

function pNorm = normalizePoly(p, tm)
% Преобразует коэффициенты [a3 a2 a1 a0] (τ в секундах) к виду для τ в tm.
% Формула: a_k_disp = a_k_real * tm^(k-1).
    pNorm = zeros(1, 4);
    for deg = 0:3
        idx = 4 - deg;   % индекс коэффициента при τ^deg в [a3 a2 a1 a0]
        pNorm(idx) = p(idx) * tm^(deg - 1);
    end
end

function s = polyToLatex(p)
% Формирует LaTeX-строку для полинома p = [a3 a2 a1 a0].
% Нечётные степени пишутся через |τ|, чётные — через τ.
% Нулевые члены пропускаются, знаки расставляются корректно.
    parts = "";
    firstTerm = true;
    for deg = 0:3
        a = p(4 - deg);
        if abs(a) < 1e-12
            continue;   % пропускаем нулевой член
        end

        % Знак и разделитель
        if firstTerm
            if a < 0
                signStr = "-";
            else
                signStr = "";
            end
            firstTerm = false;
        else
            if a < 0
                signStr = " - ";
            else
                signStr = " + ";
            end
        end

        % Переменная
        switch deg
            case 0
                varStr = "";
            case 1
                varStr = "|\tau|";
            case 2
                varStr = "\tau^2";
            case 3
                varStr = "|\tau|^3";
        end

        % Коэффициент (абсолютное значение), опускаем "1" для deg > 0
        absA = abs(a);
        if deg > 0 && abs(absA - 1) < 1e-12
            coeffStr = "";
        else
            coeffStr = fractionLatex(absA);
        end

        parts = parts + signStr + coeffStr + varStr;
    end
    if firstTerm
        s = "0";
    else
        s = parts;
    end
end

function s = fractionLatex(v)
% Форматирует положительное число как LaTeX-дробь \frac{p}{q} или целое.
    r = strtrim(string(rats(v)));
    if contains(r, "/")
        q = split(r, "/");
        s = sprintf("\\frac{%s}{%s}", strtrim(q(1)), strtrim(q(2)));
    else
        s = r;
    end
end

function s = fractionStr(v)
% Обычная строка для коэффициента (для раздела "Коэффициенты").
    if abs(v) < 1e-12
        s = "0";
    else
        s = strtrim(string(rats(v)));
    end
end

function s = formatBound(val, T1, T2)
% Распознаёт значение границы ветки и возвращает символьную LaTeX-метку
% ("0", "T_1", "T_2-T_1", "T_2"); иначе — численное значение.
    tol = 1e-9 * max([abs(T1), abs(T2), 1]);
    if abs(val) < tol
        s = "0";
    elseif abs(val - T1) < tol
        s = "T_1";
    elseif abs(val - (T2 - T1)) < tol
        s = "T_2-T_1";
    elseif abs(val - T2) < tol
        s = "T_2";
    else
        s = sprintf("%.4g", val);
    end
end

function u = formatTimeUnit(tm)
    if     tm == 1,    u = "с";
    elseif tm == 1e-3, u = "мс";
    elseif tm == 1e-6, u = "мкс";
    elseif tm == 1e-9, u = "нс";
    else,              u = sprintf("единицах %.0e с", tm);
    end
end
