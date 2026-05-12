function p35_showRectResponse(obj)
% P35_SHOWRECTRESPONSE — прямоугольный импульс той же энергии и выход СФ.
%
% Прямоугольный импульс имеет длительность T0 = 1/f_0.1 и энергию E.
% Выход СФ считается через взаимную корреляцию:
%   B_v(tau) = integral u_v(t) u(t - tau) dt,
%   u_out(t) = A * B_v(t - T2).

    if isempty(obj.A)
        error('Сначала вызовите p2_createSF()');
    end

    k = obj.selectedSignal;
    T1 = obj.T(k);
    T2 = obj.T2;
    tm = obj.time_mult;
    tUnit = timeUnit(tm);

    f01 = abs(obj.f_gr01_FFT(k));
    if isempty(f01) || f01 <= 0
        error('Граничная частота f_0.1 не рассчитана');
    end

    T0 = 1 / f01;
    E = obj.corrEnergy;
    Uv = sqrt(E / T0);

    obj.rectT0 = T0;
    obj.rectAmp = Uv;

    % Ось для отображения входного прямоугольного импульса.
    tShowMin = -0.1 * max(T0, T2);
    tShowMax = 1.1 * max(T0, T2);
    obj.rectTime = linspace(tShowMin, tShowMax, 3000);
    obj.rectPulse = Uv .* double(obj.rectTime >= 0 & obj.rectTime <= T0);

    % Численное вычисление взаимной КФ. Интегрируем только по области,
    % где прямоугольный импульс ненулевой: t in [0, T0].
    tau = linspace(-T2, T0, 6000);
    tInt = linspace(0, T0, 5000);
    Bv = zeros(size(tau));

    for i = 1:numel(tau)
        shiftedSignal = signalValue(obj, tInt - tau(i), T1);
        Bv(i) = Uv * trapz(tInt, shiftedSignal);
    end

    outTime = tau + T2;
    outSignal = obj.A .* Bv;

    obj.rectCorrTau = tau;
    obj.rectCorr = Bv;
    obj.rectOutTime = outTime;
    obj.rectOutSignal = outSignal;

    B0 = interp1(tau, Bv, 0, 'linear', 'extrap');
    uAtT2 = obj.A * B0;
    [uOutMax, idxMax] = max(outSignal);
    tOutMax = outTime(idxMax);

    fprintf('\n== ПРЯМОУГОЛЬНЫЙ ИМПУЛЬС НА ВХОДЕ СФ ==\n');
    fprintf('f_0.1 = %.6g Гц = %.6g МГц\n', f01, f01 * 1e-6);
    fprintf('T0 = 1/f_0.1 = %.6g с = %.6g %s\n', T0, T0 / tm, tUnit);
    fprintf('E = %.6g В^2*с = %.6g В^2*%s\n', E, E / tm, tUnit);
    fprintf('Uv = sqrt(E/T0) = %.6g В\n', Uv);
    fprintf('Bv(0) = %.6g В^2*с = %.6g В^2*%s\n', B0, B0 / tm, tUnit);
    fprintf('u_вых(T2) = A*Bv(0) = %.6g В\n', uAtT2);
    fprintf('max u_вых(t) = %.6g В при t = %.6g %s\n', ...
            uOutMax, tOutMax / tm, tUnit);

    % =====================================================================
    % ГРАФИК ВХОДНОГО ПРЯМОУГОЛЬНОГО ИМПУЛЬСА
    % =====================================================================
    figure(name="Прямоугольный импульс той же энергии", ...
           NumberTitle="off", Color='w');
    ax = gca;
    ax.Color = 'w';
    hold(ax, "on");

    stairs(ax, obj.rectTime / tm, obj.rectPulse, ...
        "LineWidth", 2.5, "DisplayName", "u_v(t)");
    plot(ax, obj.time / tm, obj.u(k, :), "--", ...
        "LineWidth", 1.8, "DisplayName", "u(t)");

    xline(ax, 0, ":", "HandleVisibility", "off");
    xline(ax, T0 / tm, "--", sprintf("T_0 = %.4g %s", T0 / tm, tUnit), ...
        "HandleVisibility", "off", "LabelVerticalAlignment", "bottom");

    xlabel(ax, "t, " + tUnit);
    ylabel(ax, "u(t), В");
    title(ax, sprintf("Прямоугольный импульс той же энергии: U_v = %.4g В", Uv));
    grid(ax, "on");
    legend(ax, "Location", "best");
    xlim(ax, [tShowMin / tm, tShowMax / tm]);
    hold(ax, "off");

    % =====================================================================
    % ГРАФИК ВЗАИМНОЙ КФ И ВЫХОДНОГО СИГНАЛА
    % =====================================================================
    figure(name="Взаимная КФ и выход СФ для прямоугольного импульса", ...
           NumberTitle="off", Color='w');
    tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    ax = nexttile;
    ax.Color = 'w';
    plot(ax, tau / tm, Bv / tm, "LineWidth", 2.5);
    xline(ax, 0, "--k", "\tau = 0", ...
        "HandleVisibility", "off", "LabelVerticalAlignment", "bottom");
    yline(ax, B0 / tm, "--", sprintf("B_v(0) = %.4g В²·%s", B0 / tm, tUnit), ...
        "HandleVisibility", "off", "LabelHorizontalAlignment", "left");
    xlabel(ax, "\tau, " + tUnit);
    ylabel(ax, "B_v(\tau), В²·" + tUnit);
    title(ax, "Взаимная корреляционная функция прямоугольного импульса и сигнала");
    grid(ax, "on");

    ax = nexttile;
    ax.Color = 'w';
    plot(ax, outTime / tm, outSignal, "LineWidth", 2.5);
    xline(ax, T2 / tm, "--k", "t = T_2", ...
        "HandleVisibility", "off", "LabelVerticalAlignment", "bottom");
    yline(ax, uAtT2, "--", sprintf("u_{вых}(T_2) = %.4g В", uAtT2), ...
        "HandleVisibility", "off", "LabelHorizontalAlignment", "left");
    xlabel(ax, "t, " + tUnit);
    ylabel(ax, "u_{вых}(t), В");
    title(ax, "Выходной сигнал СФ при подаче прямоугольного импульса");
    grid(ax, "on");
end

function y = signalValue(obj, t, T1)
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
