function p46_showRCOptimalComparison(obj)
% P46_SHOWRCOPTIMALCOMPARISON — сравнение оптимального RC-фильтра с СФ.
%
% Используется настоящее оптимальное значение tau, найденное по максимуму
% отношения сигнал/шум в p45_calcRCSNR().

    if isempty(obj.K_SF)
        error('Сначала вызовите p2_createSF()');
    end

    if isempty(obj.rcSNRMaxTau)
        obj.p45_calcRCSNR();
    end

    if isempty(obj.rcTime) || isempty(obj.rcInputSignal)
        obj.p41_calcRCResponses();
    end

    tauOpt = obj.rcSNRMaxTau;
    tm = obj.time_mult;
    tUnit = timeUnit(tm);
    T2 = obj.T2;

    obj.rcOptTime = obj.rcTime;
    obj.rcOptOutputSignal = rcResponseFirstOrderHold(obj.rcInputSignal, obj.dt, tauOpt);
    [obj.rcOptOutputMax, idxMax] = max(obj.rcOptOutputSignal);
    obj.rcOptOutputMaxTime = obj.rcOptTime(idxMax);

    sfTime = T2 + obj.corrTau;
    sfOutput = obj.A .* obj.corrFunc;
    [sfMax, idxSFMax] = max(sfOutput);
    sfMaxTime = sfTime(idxSFMax);

    fprintf('\n== RC-ФИЛЬТР: ОПТИМАЛЬНОЕ tau И СРАВНЕНИЕ С СФ ==\n');
    fprintf('tau_RC,opt = %.6g с = %.6g %s = %.6g tau0\n', ...
            tauOpt, tauOpt / tm, tUnit, tauOpt / obj.rcTauOpt);
    fprintf('max u_RC,opt(t) = %.6g В при t = %.6g %s\n', ...
            obj.rcOptOutputMax, obj.rcOptOutputMaxTime / tm, tUnit);
    fprintf('max u_СФ(t) = %.6g В при t = %.6g %s\n', ...
            sfMax, sfMaxTime / tm, tUnit);

    figure(name="Выходной сигнал оптимального RC-фильтра и СФ", ...
           NumberTitle="off", Color='w');
    ax = gca;
    ax.Color = 'w';
    hold(ax, "on");

    plot(ax, sfTime / tm, sfOutput, ...
        "LineWidth", 2.5, ...
        "Color", [0.20 0.45 0.75], ...
        "DisplayName", "u_{СФ вых}(t)");
    plot(ax, obj.rcOptTime / tm, obj.rcOptOutputSignal, ...
        "LineStyle", "--", ...
        "LineWidth", 2.5, ...
        "Color", [0.85 0.12 0.10], ...
        "DisplayName", sprintf("u_{RC вых}(t), \\tau_{RC,opt}=%.4g %s", ...
                               tauOpt / tm, tUnit));
    plot(ax, sfMaxTime / tm, sfMax, "o", ...
        "MarkerSize", 8, "LineWidth", 2.0, ...
        "MarkerFaceColor", [0.20 0.45 0.75], ...
        "MarkerEdgeColor", [0.20 0.45 0.75], ...
        "HandleVisibility", "off");
    plot(ax, obj.rcOptOutputMaxTime / tm, obj.rcOptOutputMax, "o", ...
        "MarkerSize", 8, "LineWidth", 2.0, ...
        "MarkerFaceColor", [0.85 0.12 0.10], ...
        "MarkerEdgeColor", [0.85 0.12 0.10], ...
        "HandleVisibility", "off");
    xline(ax, T2 / tm, "--k", "t = T_2", ...
        "HandleVisibility", "off", ...
        "LabelVerticalAlignment", "bottom");
    xlabel(ax, "t, " + tUnit);
    ylabel(ax, "u_{вых}(t), В");
    title(ax, "Сравнение выходного сигнала СФ и оптимального RC-фильтра");
    grid(ax, "on");
    legend(ax, "Location", "best");
    xlim(ax, [0, min(15e-6, max([sfTime(:); obj.rcOptTime(:)])) / tm]);
    hold(ax, "off");

    omega = obj.cyclic_freq;
    f = omega ./ (2*pi);
    fMHz = f .* 1e-6;
    K_SF = obj.K_SF;
    K_RC = 1 ./ (1 + 1i .* omega .* tauOpt);
    obj.rcOptK = K_RC;

    pos = f >= 0;
    spMax = max(abs(obj.spectrAnalytical));
    f01 = max(f(pos & abs(obj.spectrAnalytical) >= 0.1 * spMax));
    if isempty(f01) || f01 <= 0
        f01 = abs(obj.f_gr01_FFT(obj.selectedSignal));
    end
    f01MHz = f01 * 1e-6;

    figure(name="АЧХ и ФЧХ согласованного фильтра и оптимального RC-фильтра", ...
           NumberTitle="off", Color='w');
    tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    ax = nexttile;
    ax.Color = 'w';
    hold(ax, "on");
    plot(ax, fMHz(pos), abs(K_SF(pos)), ...
        "LineWidth", 2.2, ...
        "Color", [0.20 0.45 0.75], ...
        "DisplayName", "|K_{СФ}(f)|");
    plot(ax, fMHz(pos), abs(K_RC(pos)), ...
        "LineStyle", "--", ...
        "LineWidth", 2.2, ...
        "Color", [0.85 0.12 0.10], ...
        "DisplayName", sprintf("|K_{RC}(f)|, \\tau_{RC,opt}=%.4g %s", ...
                               tauOpt / tm, tUnit));
    xline(ax, f01MHz, "--k", "f_{0.1}", ...
        "HandleVisibility", "off", ...
        "LabelVerticalAlignment", "bottom");
    xlabel(ax, "f, МГц");
    ylabel(ax, "|K(f)|");
    title(ax, "АЧХ согласованного фильтра и оптимального RC-фильтра");
    grid(ax, "on");
    legend(ax, "Location", "best");
    xlim(ax, [0, 1.5 * f01MHz]);
    hold(ax, "off");

    ax = nexttile;
    ax.Color = 'w';
    hold(ax, "on");
    plot(ax, fMHz(pos), unwrap(angle(K_SF(pos))), ...
        "LineWidth", 2.0, ...
        "Color", [0.20 0.45 0.75], ...
        "DisplayName", "\phi_{СФ}(f)");
    plot(ax, fMHz(pos), unwrap(angle(K_RC(pos))), ...
        "LineStyle", "--", ...
        "LineWidth", 2.0, ...
        "Color", [0.85 0.12 0.10], ...
        "DisplayName", "\phi_{RC}(f)");
    xline(ax, f01MHz, "--k", "f_{0.1}", ...
        "HandleVisibility", "off", ...
        "LabelVerticalAlignment", "bottom");
    xlabel(ax, "f, МГц");
    ylabel(ax, "\phi_K(f), рад");
    title(ax, "ФЧХ согласованного фильтра и оптимального RC-фильтра");
    grid(ax, "on");
    legend(ax, "Location", "best");
    xlim(ax, [0, 1.5 * f01MHz]);
    hold(ax, "off");

    phaseXMaxMHz = 0.45 * f01MHz;

    figure(name="АЧХ и ФЧХ согласованного фильтра и оптимального RC-фильтра (укороченная ФЧХ)", ...
           NumberTitle="off", Color='w');
    tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    ax = nexttile;
    ax.Color = 'w';
    hold(ax, "on");
    plot(ax, fMHz(pos), abs(K_SF(pos)), ...
        "LineWidth", 2.2, ...
        "Color", [0.20 0.45 0.75], ...
        "DisplayName", "|K_{СФ}(f)|");
    plot(ax, fMHz(pos), abs(K_RC(pos)), ...
        "LineStyle", "--", ...
        "LineWidth", 2.2, ...
        "Color", [0.85 0.12 0.10], ...
        "DisplayName", sprintf("|K_{RC}(f)|, \\tau_{RC,opt}=%.4g %s", ...
                               tauOpt / tm, tUnit));
    xline(ax, f01MHz, "--k", "f_{0.1}", ...
        "HandleVisibility", "off", ...
        "LabelVerticalAlignment", "bottom");
    xlabel(ax, "f, МГц");
    ylabel(ax, "|K(f)|");
    title(ax, "АЧХ согласованного фильтра и оптимального RC-фильтра");
    grid(ax, "on");
    legend(ax, "Location", "best");
    xlim(ax, [0, 1.5 * f01MHz]);
    hold(ax, "off");

    ax = nexttile;
    ax.Color = 'w';
    hold(ax, "on");
    plot(ax, fMHz(pos), unwrap(angle(K_SF(pos))), ...
        "LineWidth", 2.0, ...
        "Color", [0.20 0.45 0.75], ...
        "DisplayName", "\phi_{СФ}(f)");
    plot(ax, fMHz(pos), unwrap(angle(K_RC(pos))), ...
        "LineStyle", "--", ...
        "LineWidth", 2.0, ...
        "Color", [0.85 0.12 0.10], ...
        "DisplayName", "\phi_{RC}(f)");
    xlabel(ax, "f, МГц");
    ylabel(ax, "\phi_K(f), рад");
    title(ax, "ФЧХ согласованного фильтра и оптимального RC-фильтра");
    grid(ax, "on");
    legend(ax, "Location", "best");
    xlim(ax, [0, phaseXMaxMHz]);
    hold(ax, "off");
end

function y = rcResponseFirstOrderHold(u, dt, tau)
% Расчёт отклика RC-цепи y'=(u-y)/tau.
% На каждом шаге считаем вход линейным между соседними отсчётами.
    y = zeros(size(u));
    alpha = exp(-dt / tau);
    slopeCoeff = (dt - tau + tau * alpha) / dt;

    for n = 2:numel(u)
        du = u(n) - u(n - 1);
        y(n) = alpha * y(n - 1) + ...
               (1 - alpha) * u(n - 1) + ...
               slopeCoeff * du;
    end
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
