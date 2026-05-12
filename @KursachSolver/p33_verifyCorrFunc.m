function p33_verifyCorrFunc(obj)
% P33_VERIFYCORRFUNC — набор проверок аналитической КФ.
%
% Выполняемые проверки:
%   1. B(0) = E (энергия сигнала): сравнение аналитики с численным
%      расчётом E = ∑ s² · dt.
%   2. Сшивка веток: на каждой внутренней границе значения соседних
%      полиномов должны совпадать (B(τ) непрерывна).
%   3. Сравнение аналитики с xcorr в контрольных точках по τ.
%   4. B(T2) ≈ 0 (КФ обнуляется на границе носителя).
%   5. max(B) = B(0) (максимум КФ — в нуле).

    k  = obj.selectedSignal;
    T1 = obj.T(k);
    T2 = obj.T2;
    s  = obj.u(k, :);

    fprintf("\n=== ПРОВЕРКИ КФ ===\n\n");

    % =====================================================================
    % 1. B(0) vs численная энергия сигнала
    % =====================================================================
    E_num = sum(s.^2) * obj.dt;
    B0    = polyval(obj.corrCoeffs(1).poly, 0);
    if abs(E_num) > 0
        relErr = abs(B0 - E_num) / abs(E_num) * 100;
    else
        relErr = 0;
    end
    fprintf("1. B(0) vs численная энергия:\n");
    fprintf("   B(0) аналит = %.6e В²·с\n", B0);
    fprintf("   E числ      = %.6e В²·с\n", E_num);
    fprintf("   Ошибка      = %.4f %%\n\n", relErr);

    % =====================================================================
    % 2. Сшивка веток на границах
    % =====================================================================
    fprintf("2. Сшивка веток на границах:\n");
    for j = 1:length(obj.corrCoeffs) - 1
        tauBnd = obj.corrCoeffs(j).tauRange(2);
        valL   = polyval(obj.corrCoeffs(j    ).poly, tauBnd);
        valR   = polyval(obj.corrCoeffs(j + 1).poly, tauBnd);
        delta  = abs(valL - valR);
        fprintf("   τ = %.3e с: B_лев = %.6e, B_прав = %.6e, Δ = %.2e\n", ...
                tauBnd, valL, valR, delta);
    end
    fprintf("\n");

    % =====================================================================
    % 3. Сравнение с xcorr в контрольных точках
    % =====================================================================
    [Bxc, lags] = xcorr(s, 'none');
    Bxc    = Bxc * obj.dt;
    tauXC  = lags * obj.dt;

    % Контрольные точки в τ ∈ [0, T2]
    cpRaw = [0, T1/2, T1, (T1 + (T2 - T1))/2, (T2 - T1), ((T2 - T1) + T2)/2, 0.95*T2];
    checkpoints = unique(cpRaw(cpRaw >= 0 & cpRaw <= T2));

    fprintf("3. Сравнение аналитика vs xcorr (В²·с):\n");
    for i = 1:length(checkpoints)
        cp = checkpoints(i);

        % Аналитическое значение: выбираем нужную ветку по диапазону τ
        Banalyt = NaN;
        for j = 1:length(obj.corrCoeffs)
            r = obj.corrCoeffs(j).tauRange;
            if cp >= r(1) - 1e-15 && cp <= r(2) + 1e-15
                Banalyt = polyval(obj.corrCoeffs(j).poly, cp);
                break;
            end
        end

        % Численное значение: ближайший по τ отсчёт xcorr
        [~, idx] = min(abs(tauXC - cp));
        Bxcorr = Bxc(idx);

        if abs(Bxcorr) > 0
            relErr = abs(Banalyt - Bxcorr) / abs(Bxcorr) * 100;
        else
            relErr = 0;
        end
        fprintf("   τ = %.3e: аналит = %.4e, xcorr = %.4e, Δ_отн = %.2f %%\n", ...
                cp, Banalyt, Bxcorr, relErr);
    end
    fprintf("\n");

    % =====================================================================
    % 4. B(T2) ≈ 0 (КФ на границе носителя)
    % =====================================================================
    B_T2 = polyval(obj.corrCoeffs(end).poly, T2);
    fprintf("4. B(T2) = %.6e (ожидается 0)\n\n", B_T2);

    % =====================================================================
    % 5. Максимум B(τ) в нуле
    % =====================================================================
    [Bmax, idxMax] = max(obj.corrFunc);
    tauAtMax = obj.corrTau(idxMax);
    fprintf("5. max(B) = %.6e при τ = %.3e с\n", Bmax, tauAtMax);
    fprintf("   B(0)   = %.6e\n", B0);
    if abs(tauAtMax) < obj.dt
        fprintf("   Максимум находится в нуле (в пределах шага сетки).\n\n");
    else
        fprintf("   ВНИМАНИЕ: максимум смещён от нуля!\n\n");
    end
end
