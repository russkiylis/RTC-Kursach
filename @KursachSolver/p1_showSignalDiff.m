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
    plot(time, res, Color=color_slopes, LineWidth=3);

% Скачки (stem с треугольниками)
if ~isempty(jumps.time)
    pos = jumps.amplitude > 0;
    neg = jumps.amplitude < 0;
    if any(pos)
        stem(jumps.time(pos), jumps.amplitude(pos), '^', 'filled', ...
             Color=color_jumps, LineWidth=2, MarkerSize=10, MarkerFaceColor=color_jumps);
    end
    if any(neg)
        stem(jumps.time(neg), jumps.amplitude(neg), 'v', 'filled', ...
             Color=color_jumps, LineWidth=2, MarkerSize=10, MarkerFaceColor=color_jumps);
    end
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

if any(pos)
    stem(unique_times(pos), combined_amps(pos), '^', 'filled', ...
         Color=color_slopes, LineWidth=2, MarkerSize=10, MarkerFaceColor=color_slopes);
end
if any(neg)
    stem(unique_times(neg), combined_amps(neg), 'v', 'filled', ...
         Color=color_slopes, LineWidth=2, MarkerSize=10, MarkerFaceColor=color_slopes);
end

% Импульсы от скачков
if ~isempty(jumps.time)
    pos_j = jumps.amplitude > 0;
    neg_j = jumps.amplitude < 0;

    if any(pos_j)
        stem(jumps.time(pos_j), jumps.amplitude(pos_j), '^', 'filled', ...
             Color=color_jumps, LineWidth=2, MarkerSize=10, MarkerFaceColor=color_jumps);
    end
    if any(neg_j)
        stem(jumps.time(neg_j), jumps.amplitude(neg_j), 'v', 'filled', ...
             Color=color_jumps, LineWidth=2, MarkerSize=10, MarkerFaceColor=color_jumps);
    end
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
