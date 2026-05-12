function obj = p33_createCorrFunc(obj)
% P33_CREATECORRFUNC — аналитический расчёт корреляционной функции (КФ)
% выбранного кусочно-линейного сигнала.
%
% СУТЬ МЕТОДА:
%   КФ определяется как B(τ) = ∫ s(t)·s(t-τ) dt.
%   Для кусочно-линейного сигнала s(t) это кусочно-полиномиальная функция
%   степени ≤ 3 по τ. B(τ) чётная, поэтому вычисляется для τ ≥ 0 и
%   симметрично продолжается.
%
% СИГНАЛ (два куска):
%   s₁(t) = α₁·t + β₁,  t ∈ [0, T1]
%   s₂(t) = α₂·t + β₂,  t ∈ [T1, T2]
% где:
%   α₁ = (U2-U1)/T1,  β₁ = U1       (так s₁(0)=U1, s₁(T1)=U2)
%   α₂ = (U4-U3)/(T2-T1),  β₂ = U3 - α₂·T1  (так s₂(T1)=U3, s₂(T2)=U4)
%
% РАЗБИЕНИЕ НА ВЕТКИ (в зависимости от T1 vs T2-T1):
%   Случай A (T1 ≤ T2-T1):
%     Ветка 1: τ ∈ [0, T1]        — 3 подынтеграла
%     Ветка 2: τ ∈ [T1, T2-T1]    — 2 подынтеграла
%     Ветка 3: τ ∈ [T2-T1, T2]    — 1 подынтеграл
%   Случай B (T1 > T2-T1):
%     Ветка 1: τ ∈ [0, T2-T1]     — 3 подынтеграла
%     Ветка 2: τ ∈ [T2-T1, T1]    — 2 подынтеграла (s на обоих кусках,
%                                    s(t-τ) весь на s₁)
%     Ветка 3: τ ∈ [T1, T2]       — 1 подынтеграл
%
% РЕЗУЛЬТАТ:
%   obj.corrCoeffs — массив структур с .tauRange = [a,b] и .poly = [a3 a2 a1 a0]
%   obj.corrTau, obj.corrFunc — симметричная сетка B(τ) для графика
%   obj.corrEnergy — энергия сигнала E = B(0)

    % =====================================================================
    % ИСХОДНЫЕ ПАРАМЕТРЫ СИГНАЛА
    % =====================================================================
    k = obj.selectedSignal;       % Индекс выбранного варианта сигнала
    T1 = obj.T(k);                % T1 для выбранного сигнала
    T2 = obj.T2;
    U1 = obj.U1;  U2 = obj.U2;  U3 = obj.U3;  U4 = obj.U4;

    % Линейные коэффициенты кусков сигнала
    alpha1 = (U2 - U1) / T1;
    beta1  = U1;
    alpha2 = (U4 - U3) / (T2 - T1);
    beta2  = U3 - alpha2 * T1;

    % =====================================================================
    % СИМВОЛЬНОЕ ПРЕДСТАВЛЕНИЕ КУСКОВ (только для полиномиальной интеграции)
    % =====================================================================
    syms tau_s t_s
    s1_t     = alpha1 * t_s + beta1;              % s₁(t)
    s2_t     = alpha2 * t_s + beta2;              % s₂(t)
    s1_shift = alpha1 * (t_s - tau_s) + beta1;    % s₁(t-τ)
    s2_shift = alpha2 * (t_s - tau_s) + beta2;    % s₂(t-τ)

    % =====================================================================
    % РАСЧЁТ ПОЛИНОМОВ КАЖДОЙ ВЕТКИ
    % =====================================================================
    if T1 <= T2 - T1
        % --- Случай A: T1 ≤ T2-T1 ---

        % Ветка 1: τ ∈ [0, T1]
        p1 = subInt(s1_t, s1_shift, t_s, tau_s, tau_s,       T1        ) ...
           + subInt(s2_t, s1_shift, t_s, tau_s, T1,          T1 + tau_s) ...
           + subInt(s2_t, s2_shift, t_s, tau_s, T1 + tau_s,  T2        );

        % Ветка 2: τ ∈ [T1, T2-T1]
        p2 = subInt(s2_t, s1_shift, t_s, tau_s, tau_s,       T1 + tau_s) ...
           + subInt(s2_t, s2_shift, t_s, tau_s, T1 + tau_s,  T2        );

        % Ветка 3: τ ∈ [T2-T1, T2]
        p3 = subInt(s2_t, s1_shift, t_s, tau_s, tau_s,       T2        );

        branches(1) = struct('tauRange', [0,       T1      ], 'poly', p1);
        branches(2) = struct('tauRange', [T1,      T2 - T1 ], 'poly', p2);
        branches(3) = struct('tauRange', [T2 - T1, T2      ], 'poly', p3);
    else
        % --- Случай B: T1 > T2-T1 ---

        % Ветка 1: τ ∈ [0, T2-T1]
        p1 = subInt(s1_t, s1_shift, t_s, tau_s, tau_s,       T1        ) ...
           + subInt(s2_t, s1_shift, t_s, tau_s, T1,          T1 + tau_s) ...
           + subInt(s2_t, s2_shift, t_s, tau_s, T1 + tau_s,  T2        );

        % Ветка 2: τ ∈ [T2-T1, T1]
        %   В этой ветке τ+T1 > T2, поэтому второй кусок сдвинутого сигнала
        %   не попадает в область интегрирования — s(t-τ) полностью на s₁.
        %   Сам s(t) при этом переходит с s₁ на s₂ в точке T1.
        p2 = subInt(s1_t, s1_shift, t_s, tau_s, tau_s,       T1        ) ...
           + subInt(s2_t, s1_shift, t_s, tau_s, T1,          T2        );

        % Ветка 3: τ ∈ [T1, T2]
        p3 = subInt(s2_t, s1_shift, t_s, tau_s, tau_s,       T2        );

        branches(1) = struct('tauRange', [0,       T2 - T1 ], 'poly', p1);
        branches(2) = struct('tauRange', [T2 - T1, T1      ], 'poly', p2);
        branches(3) = struct('tauRange', [T1,      T2      ], 'poly', p3);
    end

    obj.corrCoeffs = branches;

    % =====================================================================
    % ПОСТРОЕНИЕ B(τ) НА МЕЛКОЙ СЕТКЕ (СИММЕТРИЧНО)
    % =====================================================================
    % Для τ ≥ 0: идём по веткам и конкатенируем значения полинома на их
    % диапазонах. Для τ < 0: зеркально отражаем (B(τ) чётная).
    nPerBranch = 4000;
    tauPos  = [];
    funcPos = [];
    for j = 1:length(branches)
        r = branches(j).tauRange;
        if r(2) <= r(1)
            continue;    % пропускаем пустую ветку (T1 = T2-T1)
        end
        tauJ = linspace(r(1), r(2), nPerBranch);
        if ~isempty(tauPos)
            tauJ = tauJ(2:end);    % избегаем дублирования точки на стыке
        end
        tauPos  = [tauPos,  tauJ];                                %#ok<AGROW>
        funcPos = [funcPos, polyval(branches(j).poly, tauJ)];     %#ok<AGROW>
    end

    % Симметричное продолжение (без дублирования нулевой точки)
    tauNeg  = -fliplr(tauPos(2:end));
    funcNeg =  fliplr(funcPos(2:end));
    obj.corrTau  = [tauNeg,  tauPos ];
    obj.corrFunc = [funcNeg, funcPos];

    % Энергия сигнала = B(0), вычисленная по полиному первой ветки
    obj.corrEnergy = polyval(branches(1).poly, 0);
end


% =========================================================================
% ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ: ОДИН ПОДЫНТЕГРАЛ
% =========================================================================
function p = subInt(sa, sb, t_s, tau_s, t_lo, t_hi)
% SUBINT — вычисляет ∫[t_lo, t_hi] sa(t_s)·sb(t_s) dt_s и возвращает
% коэффициенты полинома по tau_s в формате [a3 a2 a1 a0].
%
% Пределы t_lo и t_hi могут быть числами или символьными выражениями,
% содержащими tau_s. Подстановка каждого предела выполняется ОТДЕЛЬНО —
% нельзя подставлять разность (b-a)^n, т.к. это неверно при наличии tau_s.

    integrand = sa * sb;                            % квадратичный по t_s
    F = int(integrand, t_s);                        % антипроизводная (кубическая по t_s)
    result = subs(F, t_s, t_hi) - subs(F, t_s, t_lo);
    result = expand(result);

    % Получаем коэффициенты полинома по tau_s
    if isequal(result, sym(0))
        p = zeros(1, 4);
        return;
    end
    c_sym = coeffs(result, tau_s, 'All');     % от старшей степени к константе
    c = double(c_sym);

    % Дополняем до длины 4 (полином степени ≤ 3)
    if length(c) < 4
        p = [zeros(1, 4 - length(c)), c];
    else
        p = c;
    end
end
