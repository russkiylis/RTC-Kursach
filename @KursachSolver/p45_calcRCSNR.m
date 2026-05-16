function p45_calcRCSNR(obj)
% P45_CALCRCSNR — зависимость отношения сигнал/шум RC-фильтра от tau.
%
% Для каждого tau:
%   (C/Ш)_RC = u_RCmax / sigma_RCвых.

    if isempty(obj.rcOutputMax)
        obj.p41_calcRCResponses();
    end

    if isempty(obj.rcNoiseStdOut)
        obj.p44_calcRCNoiseStats(false);
    end

    tm = obj.time_mult;
    tUnit = timeUnit(tm);

    obj.rcSNR = obj.rcOutputMax ./ obj.rcNoiseStdOut;
    [~, idxBaseMax] = max(obj.rcSNR);
    [~, idxTau0] = min(abs(obj.rcTauFactors - 1));

    % Базовая таблица строится по методичке: 0.1*tau0 ... 2.4*tau0.
    % Если максимум оказывается около правой границы, для графика добавляем
    % дополнительные точки правее и более мелкую сетку вокруг максимума.
    plotFactors = unique([obj.rcTauFactors, 2.0:0.1:3.0, 1.70:0.01:2.05]);
    obj.rcSNRPlotFactors = plotFactors(:).';
    obj.rcSNRPlotTauValues = obj.rcTauOpt .* obj.rcSNRPlotFactors;

    obj.rcSNRPlotValues = zeros(size(obj.rcSNRPlotTauValues));
    for i = 1:numel(obj.rcSNRPlotTauValues)
        tau = obj.rcSNRPlotTauValues(i);
        y = rcResponseFirstOrderHold(obj.rcInputSignal, obj.dt, tau);
        uMax = max(y);
        sigma = sqrt(obj.W0 ./ (pi .* tau) .* atan(obj.omega_gr_n .* tau));
        obj.rcSNRPlotValues(i) = uMax ./ sigma;
    end

    % Важно: кривая ОСШ не строго одномодальная, поэтому fminbnd на всей
    % области может попасть в локальный максимум. Сначала находим лучший
    % участок по сетке графика, затем уточняем максимум только внутри него.
    [~, idxPlotBest] = max(obj.rcSNRPlotValues);
    if idxPlotBest > 1 && idxPlotBest < numel(obj.rcSNRPlotTauValues)
        tauSearchMin = obj.rcSNRPlotTauValues(idxPlotBest - 1);
        tauSearchMax = obj.rcSNRPlotTauValues(idxPlotBest + 1);
        obj.rcSNRMaxTau = fminbnd( ...
            @(tau) -calcRCSNRAtTau(obj, tau), ...
            tauSearchMin, tauSearchMax);
        obj.rcSNRMax = calcRCSNRAtTau(obj, obj.rcSNRMaxTau);
    else
        obj.rcSNRMaxTau = obj.rcSNRPlotTauValues(idxPlotBest);
        obj.rcSNRMax = obj.rcSNRPlotValues(idxPlotBest);
    end
    rcSNRBaseMaxTau = obj.rcTauValues(idxBaseMax);

    fprintf('\n== RC-ФИЛЬТР: ЗАВИСИМОСТЬ ОТНОШЕНИЯ СИГНАЛ/ШУМ ОТ tau ==\n');
    fprintf('%12s %14s %16s %16s %16s\n', ...
            'tau/tau0', "tau, " + tUnit, 'u_RCmax, В', 'sigma_RCвых, В', '(C/Ш)_RC');
    for i = 1:numel(obj.rcTauValues)
        fprintf('%12.6g %14.6g %16.6g %16.6g %16.6g\n', ...
                obj.rcTauFactors(i), ...
                obj.rcTauValues(i) / tm, ...
                obj.rcOutputMax(i), ...
                obj.rcNoiseStdOut(i), ...
                obj.rcSNR(i));
    end
    fprintf('Максимум на базовой сетке: (C/Ш)_RC = %.6g при tau = %.6g %s = %.6g tau0\n', ...
            obj.rcSNR(idxBaseMax), rcSNRBaseMaxTau / tm, tUnit, obj.rcTauFactors(idxBaseMax));
    fprintf('Уточнённый максимум: (C/Ш)_RC = %.6g при tau = %.6g %s = %.6g tau0\n', ...
            obj.rcSNRMax, obj.rcSNRMaxTau / tm, tUnit, obj.rcSNRMaxTau / obj.rcTauOpt);

    figure(name="Зависимость отношения сигнал/шум RC-фильтра от tau", ...
           NumberTitle="off", Color='w');
    ax = gca;
    ax.Color = 'w';
    hold(ax, "on");

    plot(ax, obj.rcSNRPlotTauValues / tm, obj.rcSNRPlotValues, ...
        "-", "LineWidth", 2.0, ...
        "Color", [0.20 0.45 0.75], ...
        "DisplayName", "(C/Ш)_{RC}");
    plot(ax, obj.rcTauValues / tm, obj.rcSNR, ...
        "o", "LineWidth", 1.2, "MarkerSize", 5, ...
        "Color", [0.20 0.45 0.75], ...
        "DisplayName", "точки таблицы");
    plot(ax, obj.rcSNRMaxTau / tm, obj.rcSNRMax, ...
        "o", "MarkerSize", 10, "LineWidth", 2.5, ...
        "MarkerFaceColor", [0.85 0.12 0.10], ...
        "MarkerEdgeColor", [0.85 0.12 0.10], ...
        "DisplayName", sprintf("max при \\tau = %.4g %s", obj.rcSNRMaxTau / tm, tUnit));
    plot(ax, obj.rcTauValues(idxTau0) / tm, obj.rcSNR(idxTau0), ...
        "s", "MarkerSize", 8, "LineWidth", 2.0, ...
        "MarkerFaceColor", [0.10 0.55 0.20], ...
        "MarkerEdgeColor", [0.10 0.55 0.20], ...
        "DisplayName", sprintf("\\tau_0=1/f_{0.1}=%.4g %s", obj.rcTauValues(idxTau0) / tm, tUnit));
    xline(ax, obj.rcSNRMaxTau / tm, "--", "\tau_{max}", ...
        "Color", [0.85 0.12 0.10], ...
        "LineWidth", 1.3, ...
        "HandleVisibility", "off", ...
        "LabelVerticalAlignment", "bottom");
    xline(ax, obj.rcTauValues(idxTau0) / tm, "--", "\tau_0", ...
        "Color", [0.10 0.55 0.20], ...
        "LineWidth", 1.2, ...
        "HandleVisibility", "off", ...
        "LabelVerticalAlignment", "top");

    xlabel(ax, "\tau, " + tUnit);
    ylabel(ax, "(C/Ш)_{RC}");
    title(ax, "Зависимость отношения сигнал/шум на выходе RC-фильтра от \tau");
    grid(ax, "on");
    legend(ax, "Location", "best");
    xlim(ax, [0, max(obj.rcSNRPlotTauValues) / tm]);
    hold(ax, "off");
end

function snr = calcRCSNRAtTau(obj, tau)
    y = rcResponseFirstOrderHold(obj.rcInputSignal, obj.dt, tau);
    uMax = max(y);
    sigma = sqrt(obj.W0 ./ (pi .* tau) .* atan(obj.omega_gr_n .* tau));
    snr = uMax ./ sigma;
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
