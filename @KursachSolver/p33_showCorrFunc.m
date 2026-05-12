function p33_showCorrFunc(obj)
% P33_SHOWCORRFUNC — строит графики КФ B(τ) и выходного сигнала СФ.
%
% Каждая ветка рисуется своим цветом, границы веток отмечены вертикальными
% пунктирами, горизонтальный пунктир показывает B(0) = E (энергия сигнала).
% Оси координат проведены через начало, B(τ) продолжена симметрично на
% отрицательные τ (КФ чётная).

    k  = obj.selectedSignal;
    T1 = obj.T(k);
    T2 = obj.T2;
    E  = obj.corrEnergy;
    A  = obj.A;
    tm = obj.time_mult;
    t_unit = timeUnit(tm);
    E_disp = E / tm;
    u_max = A * E;

    figure(name=sprintf("КФ сигнала, T1 = %.3g %s, B(0) = E = %.4g В²·%s", ...
           T1/tm, t_unit, E_disp, t_unit), NumberTitle="off", Color='w');
    ax = gca;
    ax.Color = 'w';
    hold(ax, "on");

    % Цвета для трёх веток (сколько есть — столько и используем)
    branchColors = [0.00 0.45 0.74;    % синий
                    0.85 0.33 0.10;    % оранжевый
                    0.47 0.67 0.19];   % зелёный

    % --- Рисуем каждую ветку (и её зеркало) своим цветом ---
    for j = 1:length(obj.corrCoeffs)
        r = obj.corrCoeffs(j).tauRange;
        if r(2) <= r(1)
            continue;   % пустая ветка — пропускаем
        end
        tauJ  = linspace(r(1), r(2), 800);
        Bj    = polyval(obj.corrCoeffs(j).poly, tauJ);
        color = branchColors(j, :);

        % Положительная часть — с подписью для легенды
        plot(ax, tauJ/tm, Bj/tm, "LineWidth", 2.5, "Color", color, ...
            "DisplayName", sprintf("Ветка %d: |τ| ∈ [%.3g, %.3g] %s", ...
            j, r(1)/tm, r(2)/tm, t_unit));

        % Зеркальная часть — без отдельной подписи
        plot(ax, -tauJ/tm, Bj/tm, "LineWidth", 2.5, "Color", color, ...
            "HandleVisibility", "off");
    end

    % --- Границы веток (пунктирные вертикали на ±r) ---
    for j = 1:length(obj.corrCoeffs)
        r2 = obj.corrCoeffs(j).tauRange(2);
        if r2 <= 0
            continue;
        end
        xline(ax,  r2/tm, "--", "HandleVisibility", "off", "Color", [0.4 0.4 0.4]);
        xline(ax, -r2/tm, "--", "HandleVisibility", "off", "Color", [0.4 0.4 0.4]);
    end

    % --- Горизонтальный пунктир B(0) с подписью энергии ---
    yline(ax, E_disp, "--k", sprintf("B(0) = E = %.4g В²·%s", E_disp, t_unit), ...
        "LabelHorizontalAlignment", "left", ...
        "LabelVerticalAlignment",   "bottom", ...
        "HandleVisibility", "off");

    % --- Оси через начало координат ---
    ax.XAxisLocation = "origin";
    ax.YAxisLocation = "origin";

    xlabel(ax, "τ, " + t_unit);
    ylabel(ax, "B(τ), В²·" + t_unit);
    title(ax, sprintf("КФ сигнала, T_1 = %.3g %s, B(0) = E = %.4g В²·%s", ...
        T1/tm, t_unit, E_disp, t_unit));
    grid(ax, "on");
    xlim(ax, [-1.1*T2/tm, 1.1*T2/tm]);
    legend(ax, "Location", "best");
    hold(ax, "off");

    % =====================================================================
    % ВЫХОДНОЙ СИГНАЛ СОГЛАСОВАННОГО ФИЛЬТРА
    % =====================================================================
    figure(name=sprintf("Выходной сигнал СФ, uвых max = %.4g В", u_max), ...
           NumberTitle="off", Color='w');
    ax = gca;
    ax.Color = 'w';
    hold(ax, "on");

    for j = 1:length(obj.corrCoeffs)
        r = obj.corrCoeffs(j).tauRange;
        if r(2) <= r(1)
            continue;
        end

        tauJ = linspace(r(1), r(2), 800);
        Bj = polyval(obj.corrCoeffs(j).poly, tauJ);
        yOut = A .* Bj;
        color = branchColors(j, :);

        plot(ax, (T2 + tauJ)/tm, yOut, "LineWidth", 2.5, "Color", color, ...
            "DisplayName", sprintf("Ветка %d: |t-T_2| ∈ [%.3g, %.3g] %s", ...
            j, r(1)/tm, r(2)/tm, t_unit));
        plot(ax, (T2 - tauJ)/tm, yOut, "LineWidth", 2.5, "Color", color, ...
            "HandleVisibility", "off");
    end

    for j = 1:length(obj.corrCoeffs)
        r2 = obj.corrCoeffs(j).tauRange(2);
        if r2 <= 0
            continue;
        end
        xline(ax, (T2 + r2)/tm, "--", "HandleVisibility", "off", "Color", [0.4 0.4 0.4]);
        xline(ax, (T2 - r2)/tm, "--", "HandleVisibility", "off", "Color", [0.4 0.4 0.4]);
    end

    xline(ax, T2/tm, "--k", "t = T_2", ...
        "LabelVerticalAlignment", "bottom", ...
        "HandleVisibility", "off");
    yline(ax, u_max, "--k", sprintf("u_{вых max} = %.4g В", u_max), ...
        "LabelHorizontalAlignment", "left", ...
        "LabelVerticalAlignment", "bottom", ...
        "HandleVisibility", "off");

    xlabel(ax, "t, " + t_unit);
    ylabel(ax, "u_{вых}(t), В");
    title(ax, sprintf("Выходной сигнал СФ: u_{вых}(t)=A B(t-T_2), A = %.4g Гц/В", A));
    grid(ax, "on");
    xlim(ax, [-0.05*T2/tm, 2.05*T2/tm]);
    legend(ax, "Location", "best");
    hold(ax, "off");
end

function unit = timeUnit(tm)
    if tm == 1e-6
        unit = "мкс";
    elseif tm == 1e-3
        unit = "мс";
    elseif tm == 1e-9
        unit = "нс";
    elseif tm == 1
        unit = "с";
    else
        unit = sprintf("%.0e с", tm);
    end
end
