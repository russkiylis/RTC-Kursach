function p41_calcRCResponses(obj, tauValues)
% P41_CALCRCRESPONSES — выходные сигналы RC-фильтра для набора tau.
%
% Если tauValues не передан, берётся стандартный набор:
% 0.1*tau0, 0.2*tau0, ..., 2.4*tau0,
% где tau0 = 1/f_0.1 выбранного сигнала.
% Все значения tau внутри объекта хранятся в секундах.

    k = obj.selectedSignal;
    T1 = obj.T(k);
    T2 = obj.T2;
    tm = obj.time_mult;
    tUnit = timeUnit(tm);

    f01 = abs(obj.f_gr01_FFT(k));
    if isempty(f01) || f01 <= 0
        error('Граничная частота f_0.1 не рассчитана');
    end

    obj.rcTauOpt = 1 / f01;

    if nargin < 2 || isempty(tauValues)
        obj.rcTauFactors = 0.1:0.1:2.4;
        tauValues = obj.rcTauOpt .* obj.rcTauFactors;
    else
        tauValues = tauValues(:).';
        obj.rcTauFactors = tauValues ./ obj.rcTauOpt;
    end

    if any(tauValues <= 0)
        error('Все значения tau должны быть положительными');
    end

    obj.rcTauValues = tauValues;

    dt = obj.dt;
    tEnd = T2 + max(T2, 8 * max(tauValues));
    obj.rcTime = 0:dt:tEnd;
    obj.rcInputSignal = selectedSignalValue(obj, obj.rcTime, T1);

    nTau = numel(tauValues);
    nTime = numel(obj.rcTime);
    obj.rcOutputSignals = zeros(nTau, nTime);
    obj.rcOutputMax = zeros(nTau, 1);
    obj.rcOutputMaxTime = zeros(nTau, 1);

    for i = 1:nTau
        tau = tauValues(i);
        y = rcResponseFirstOrderHold(obj.rcInputSignal, dt, tau);
        obj.rcOutputSignals(i, :) = y;

        [obj.rcOutputMax(i), idxMax] = max(y);
        obj.rcOutputMaxTime(i) = obj.rcTime(idxMax);
    end

    fprintf('\n== RC-ФИЛЬТР: ВЫХОДНОЙ СИГНАЛ ДЛЯ РАЗНЫХ tau ==\n');
    fprintf('f_0.1 = %.6g Гц = %.6g МГц\n', f01, f01 * 1e-6);
    fprintf('tau0 = 1/f_0.1 = %.6g с = %.6g %s\n', ...
            obj.rcTauOpt, obj.rcTauOpt / tm, tUnit);
    fprintf('Таблица зависимости максимального значения выходного сигнала от постоянной времени:\n');
    fprintf('%12s %14s %16s %14s\n', 'tau/tau0', "tau, " + tUnit, 'u_RCmax, В', "t_max, " + tUnit);
    for i = 1:nTau
        fprintf('%12.6g %14.6g %16.6g %14.6g\n', ...
                obj.rcTauFactors(i), ...
                obj.rcTauValues(i) / tm, ...
                obj.rcOutputMax(i), ...
                obj.rcOutputMaxTime(i) / tm);
    end

    figure(name="Выходные сигналы RC-фильтра для разных tau", ...
           NumberTitle="off", Color='w');
    ax = gca;
    ax.Color = 'w';
    hold(ax, "on");

    colors = lines(nTau);
    [~, idxTau0] = min(abs(obj.rcTauFactors - 1));
    for i = 1:nTau
        if i == idxTau0
            lineStyle = "-";
            lineWidth = 3.2;
            lineColor = [0.85 0.12 0.10];
            displayName = sprintf("\\tau_0 = %.4g %s", obj.rcTauValues(i) / tm, tUnit);
        else
            lineStyle = "--";
            lineWidth = 0.9;
            lineColor = 0.65 .* colors(i, :) + 0.35 .* [1 1 1];
            displayName = sprintf("\\tau = %.4g %s", obj.rcTauValues(i) / tm, tUnit);
        end

        plot(ax, obj.rcTime / tm, obj.rcOutputSignals(i, :), ...
            "LineStyle", lineStyle, ...
            "LineWidth", lineWidth, ...
            "Color", lineColor, ...
            "DisplayName", displayName);
    end

    plot(ax, obj.rcTime / tm, obj.rcInputSignal, ...
        "k--", "LineWidth", 1.4, "DisplayName", "u_{вх}(t)");

    xlabel(ax, "t, " + tUnit);
    ylabel(ax, "u_{RC}(t), В");
    title(ax, "Выходной сигнал RC-фильтра при различных постоянных времени");
    grid(ax, "on");
    legend(ax, "Location", "eastoutside");
    xlim(ax, [0, min(15e-6, obj.rcTime(end)) / tm]);
    hold(ax, "off");

    figure(name="Зависимость u_RCmax от постоянной времени", ...
           NumberTitle="off", Color='w');
    ax = gca;
    ax.Color = 'w';
    hold(ax, "on");
    plot(ax, obj.rcTauValues / tm, obj.rcOutputMax, ...
        "-o", "LineWidth", 1.8, "MarkerSize", 5, ...
        "Color", [0.20 0.45 0.75], ...
        "DisplayName", "u_{RCmax}(\tau)");
    plot(ax, obj.rcTauValues(idxTau0) / tm, obj.rcOutputMax(idxTau0), ...
        "o", "MarkerSize", 10, "LineWidth", 2.5, ...
        "MarkerFaceColor", [0.85 0.12 0.10], ...
        "MarkerEdgeColor", [0.85 0.12 0.10], ...
        "DisplayName", sprintf("\\tau_0 = %.4g %s", obj.rcTauValues(idxTau0) / tm, tUnit));
    xline(ax, obj.rcTauValues(idxTau0) / tm, "--", "\tau_0", ...
        "Color", [0.85 0.12 0.10], ...
        "LineWidth", 1.4, ...
        "HandleVisibility", "off", ...
        "LabelVerticalAlignment", "bottom");
    xlabel(ax, "\tau, " + tUnit);
    ylabel(ax, "u_{RCmax}, В");
    title(ax, "Зависимость максимального выходного сигнала RC-фильтра от \tau");
    grid(ax, "on");
    legend(ax, "Location", "best");
    xlim(ax, [0, max(obj.rcTauValues) / tm]);
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

function y = selectedSignalValue(obj, t, T1)
% Значение выбранного кусочно-линейного сигнала в моменты t.
    y = zeros(size(t));

    idx1 = (t >= 0) & (t <= T1);
    if any(idx1)
        y(idx1) = obj.U1 + (obj.U2 - obj.U1) .* t(idx1) ./ T1;
    end

    idx2 = (t > T1) & (t <= obj.T2);
    if any(idx2)
        y(idx2) = obj.U3 + (obj.U4 - obj.U3) .* (t(idx2) - T1) ./ (obj.T2 - T1);
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
