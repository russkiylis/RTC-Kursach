function p1_showSignalDiff(obj)
%P1_SHOWSIGNALDIFF Выводит производные сигнала

jumps = obj.jumps;
slopes = obj.slopes;
T2 = obj.T2;
time_mult = obj.time_mult;
time = obj.time;

jumps.amplitude = jumps.amplitude ./ time_mult;

% -- Цвета --
color_slopes = [0 0.4470 0.7410];
color_jumps  = [0.8500 0.3250 0.0980];

figure(name="Производные сигнала");
tiledlayout(1,2);

% ===== Первая производная =====
nexttile;
hold on;

% Наклоны (горизонтальные линии)
res = zeros(1, length(time));
for k = 1:length(slopes.diff)
    t1 = slopes.time1(k); t2 = slopes.time2(k);

    id_line = time > t1 & time < t2;
    res(id_line) = slopes.diff(k);
end
h_slopes = plot(time, res, Color=color_slopes, LineWidth=3);

% Скачки (stem с треугольниками)
h_jumps = [];
if ~isempty(jumps.time)
    pos = jumps.amplitude > 0;
    neg = jumps.amplitude < 0;
    if any(pos)
        h_jumps = stem(jumps.time(pos), jumps.amplitude(pos), '^', 'filled', ...
             Color=color_jumps, LineWidth=2, MarkerSize=10, MarkerFaceColor=color_jumps);
    end
    if any(neg)
        h_neg = stem(jumps.time(neg), jumps.amplitude(neg), 'v', 'filled', ...
             Color=color_jumps, LineWidth=2, MarkerSize=10, MarkerFaceColor=color_jumps);
        if isempty(h_jumps), h_jumps = h_neg; end
    end

    % Подписи δ-функций рядом со скачками
    for i = 1:length(jumps.time)
        label = formatDelta(obj.jumps.amplitude(i), jumps.time(i), "\delta");
        t = text(jumps.time(i), jumps.amplitude(i), "  " + label, ...
            FontSize=9, Color=color_jumps, FontWeight='bold', AffectAutoLimits='on');
        uistack(t, 'top');
    end
end

% Легенда
if ~isempty(h_jumps)
    legend([h_slopes, h_jumps], "От наклона", "От скачка (\delta-функция)", ...
        Location="northeast");
else
    legend(h_slopes, "От наклона", Location="best");
end

grid on;
xlim([-0.1*T2 1.2*T2]);
ylim([1.2*min([slopes.diff jumps.amplitude]) 1.2*max([slopes.diff jumps.amplitude])]);
ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';
title("Первая производная сигнала");
xlabel("t, с");
ylabel("u'(t)");

% ===== Вторая производная =====
nexttile;
hold on;

% Импульсы от наклонов
imp_times = [slopes.time1(:)', slopes.time2(:)'];
imp_amps  = [slopes.diff(:)', -slopes.diff(:)'];

[unique_times, ~, idx] = unique(imp_times);
combined_amps = accumarray(idx, imp_amps);

pos = combined_amps > 0;
neg = combined_amps < 0;

h_slopes2 = [];
if any(pos)
    h_slopes2 = stem(unique_times(pos), combined_amps(pos), '^', 'filled', ...
         Color=color_slopes, LineWidth=2, MarkerSize=10, MarkerFaceColor=color_slopes);
end
if any(neg)
    h_neg2 = stem(unique_times(neg), combined_amps(neg), 'v', 'filled', ...
         Color=color_slopes, LineWidth=2, MarkerSize=10, MarkerFaceColor=color_slopes);
    if isempty(h_slopes2), h_slopes2 = h_neg2; end
end

% Подписи δ'-функций от наклонов
nonzero = combined_amps ~= 0;
for i = find(nonzero)'
    label = formatDelta(combined_amps(i), unique_times(i), "\delta'");
    t = text(unique_times(i), combined_amps(i), "  " + label, ...
        FontSize=9, Color=color_slopes, FontWeight='bold', AffectAutoLimits='on');
    uistack(t, 'top');
end

% Импульсы от скачков
h_jumps2 = [];
if ~isempty(jumps.time)
    pos_j = jumps.amplitude > 0;
    neg_j = jumps.amplitude < 0;

    if any(pos_j)
        h_jumps2 = stem(jumps.time(pos_j), jumps.amplitude(pos_j), '^', 'filled', ...
             Color=color_jumps, LineWidth=2, MarkerSize=10, MarkerFaceColor=color_jumps);
    end
    if any(neg_j)
        h_neg_j2 = stem(jumps.time(neg_j), jumps.amplitude(neg_j), 'v', 'filled', ...
             Color=color_jumps, LineWidth=2, MarkerSize=10, MarkerFaceColor=color_jumps);
        if isempty(h_jumps2), h_jumps2 = h_neg_j2; end
    end

    % Подписи δ-функций от скачков
    for i = 1:length(jumps.time)
        label = formatDelta(obj.jumps.amplitude(i), jumps.time(i), "\delta");
        t = text(jumps.time(i), jumps.amplitude(i), "  " + label, ...
            FontSize=9, Color=color_jumps, FontWeight='bold',AffectAutoLimits='on');
        uistack(t, 'top');
    end
end

% Легенда
handles = []; labels = {};
if ~isempty(h_slopes2)
    handles = [handles, h_slopes2];
    labels{end+1} = "\delta'(t) (от наклона)";
end
if ~isempty(h_jumps2)
    handles = [handles, h_jumps2];
    labels{end+1} = "\delta(t) (от скачка)";
end
if ~isempty(handles)
    legend(handles, labels, Location="northeast");
end

grid on;
xlim([-0.1*T2 1.2*T2]);
ylim([1.2*min([slopes.diff jumps.amplitude]) 1.2*max([slopes.diff jumps.amplitude])]);
ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';
title("Вторая производная сигнала");
xlabel("t, с");
ylabel("u''(t)");

end

%% Вспомогательная функция форматирования δ-подписи
function str = formatDelta(amplitude, t, delta_symbol)
    % Формирует строку вида "Aδ(t)" или "Aδ(t - τ)"

    % Аргумент δ-функции
    if t == 0
        arg = "t";
    else
        arg = sprintf("t - %g", t);
    end

    % Амплитудный коэффициент
    if amplitude == 1
        coeff = "";
    elseif amplitude == -1
        coeff = "-";
    else
        coeff = sprintf("%.2g", amplitude);
    end

    str = coeff + delta_symbol + "(" + arg + ")";
end
