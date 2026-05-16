function p49_showRectRCResponse(obj)
% P49_SHOWRECTRCRESPONSE — выход RC-фильтра при прямоугольном видеоимпульсе.
%
% Прямоугольный импульс имеет ту же энергию, что и выбранный сигнал:
%   T0 = 1 / f_0.1,
%   Uv = sqrt(E / T0).
% Расчёт выполняется для настоящего оптимального tau_RC,opt из p45.

    if isempty(obj.rcSNRMaxTau)
        obj.p45_calcRCSNR();
    end

    k = obj.selectedSignal;
    tm = obj.time_mult;
    tUnit = timeUnit(tm);

    f01 = abs(obj.f_gr01_FFT(k));
    if isempty(f01) || f01 <= 0
        error('Граничная частота f_0.1 не рассчитана');
    end

    T0 = 1 / f01;
    E = obj.corrEnergy;
    Uv = sqrt(E / T0);
    tau = obj.rcSNRMaxTau;
    sfTime = obj.T2 + obj.corrTau;
    sfOutput = obj.A .* obj.corrFunc;
    [sfOutputMax, idxSFMax] = max(sfOutput);
    sfOutputMaxTime = sfTime(idxSFMax);

    obj.rectT0 = T0;
    obj.rectAmp = Uv;

    tEnd = max(15e-6, T0 + 8 * tau);
    obj.rcRectTime = 0:obj.dt:tEnd;
    obj.rcRectInput = Uv .* double(obj.rcRectTime >= 0 & obj.rcRectTime <= T0);
    obj.rcRectOutput = rectRCResponse(obj.rcRectTime, Uv, T0, tau);
    obj.rcRectOutputMax = Uv * (1 - exp(-T0 / tau));
    obj.rcRectOutputMaxTime = T0;

    fprintf('\n== RC-ФИЛЬТР: ПРЯМОУГОЛЬНЫЙ ВИДЕОИМПУЛЬС НА ВХОДЕ ==\n');
    fprintf('f_0.1 = %.6g Гц = %.6g МГц\n', f01, f01 * 1e-6);
    fprintf('T0 = 1/f_0.1 = %.6g с = %.6g %s\n', T0, T0 / tm, tUnit);
    fprintf('E = %.6g В^2*с = %.6g В^2*%s\n', E, E / tm, tUnit);
    fprintf('Uv = sqrt(E/T0) = %.6g В\n', Uv);
    fprintf('tau_RC,opt = %.6g с = %.6g %s = %.6g tau0\n', ...
            tau, tau / tm, tUnit, tau / obj.rcTauOpt);
    fprintf('max u_RC,v(t) = %.6g В при t = %.6g %s\n', ...
            obj.rcRectOutputMax, obj.rcRectOutputMaxTime / tm, tUnit);
    fprintf('max u_СФ(t) при исходном видеоимпульсе = %.6g В при t = %.6g %s\n', ...
            sfOutputMax, sfOutputMaxTime / tm, tUnit);

    figure(name="Выход RC-фильтра при прямоугольном видеоимпульсе", ...
           NumberTitle="off", Color='w');
    ax = gca;
    ax.Color = 'w';
    hold(ax, "on");

    stairs(ax, obj.rcRectTime / tm, obj.rcRectInput, ...
        "LineStyle", "--", ...
        "LineWidth", 1.8, ...
        "Color", [0.15 0.15 0.15], ...
        "DisplayName", "u_v(t)");
    plot(ax, obj.rcRectTime / tm, obj.rcRectOutput, ...
        "LineWidth", 2.5, ...
        "Color", [0.85 0.12 0.10], ...
        "DisplayName", sprintf("u_{RC,v}(t), \\tau_{RC,opt}=%.4g %s", ...
                               tau / tm, tUnit));
    plot(ax, sfTime / tm, sfOutput, ...
        "LineStyle", "-.", ...
        "LineWidth", 2.3, ...
        "Color", [0.20 0.45 0.75], ...
        "DisplayName", "u_{СФ вых}(t) при u(t)");
    plot(ax, obj.rcRectOutputMaxTime / tm, obj.rcRectOutputMax, "o", ...
        "MarkerSize", 8, ...
        "LineWidth", 2.0, ...
        "MarkerFaceColor", [0.85 0.12 0.10], ...
        "MarkerEdgeColor", [0.85 0.12 0.10], ...
        "HandleVisibility", "off");
    plot(ax, sfOutputMaxTime / tm, sfOutputMax, "s", ...
        "MarkerSize", 8, ...
        "LineWidth", 2.0, ...
        "MarkerFaceColor", [0.20 0.45 0.75], ...
        "MarkerEdgeColor", [0.20 0.45 0.75], ...
        "HandleVisibility", "off");
    xline(ax, T0 / tm, "--k", "T_0", ...
        "HandleVisibility", "off", ...
        "LabelVerticalAlignment", "bottom");
    yline(ax, obj.rcRectOutputMax, ":", ...
        sprintf("u_{RC,v max}=%.4g В", obj.rcRectOutputMax), ...
        "HandleVisibility", "off", ...
        "LabelHorizontalAlignment", "left");

    xlabel(ax, "t, " + tUnit);
    ylabel(ax, "u(t), В");
    title(ax, "Выход RC-фильтра при прямоугольном импульсе и выход СФ при видеоимпульсе");
    grid(ax, "on");
    legend(ax, "Location", "best");
    xlim(ax, [0, min(15e-6, obj.rcRectTime(end)) / tm]);
    hold(ax, "off");
end

function y = rectRCResponse(t, Uv, T0, tau)
    y = zeros(size(t));

    idxRise = (t >= 0) & (t <= T0);
    y(idxRise) = Uv .* (1 - exp(-t(idxRise) ./ tau));

    idxFall = t > T0;
    y(idxFall) = Uv .* (exp(-(t(idxFall) - T0) ./ tau) - ...
                        exp(-t(idxFall) ./ tau));
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
