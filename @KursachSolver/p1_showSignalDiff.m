function p1_showSignalDiff(obj)
% P1_SHOWSIGNALDIFF — строит графики первой и второй производных сигнала.
%
% ЗАЧЕМ ЭТО НУЖНО:
%   Производные сигнала — промежуточный этап метода дифференцирования
%   для аналитического расчёта спектра (см. p1_createSpectrAnalytical).
%   Графики производных нужны для пояснительной записки и для понимания
%   того, откуда берутся слагаемые в формуле спектра.
%
% ПЕРВАЯ ПРОИЗВОДНАЯ u'(t):
%   - На линейных участках: горизонтальные линии (константы = наклон).
%   - В точках скачков: дельта-функции δ(t-t0) с амплитудой = величина скачка.
%   Дельта-функции рисуются как вертикальные "палки" (stem) с треугольниками.
%
% ВТОРАЯ ПРОИЗВОДНАЯ u''(t):
%   - Дельта-функции δ(t-t0) от "включения/выключения" наклонов
%     (от наклонов — синие, отмечены как δ').
%   - Дельта-функции δ(t-t0) от скачков первой производной
%     (от скачков — оранжевые, отмечены как δ).
%
% ОБОЗНАЧЕНИЯ НА ГРАФИКАХ:
%   - Треугольник вверх (^) — положительный импульс
%   - Треугольник вниз (v) — отрицательный импульс
%   - Рядом с каждым импульсом подписана формула: Aδ(t) или Aδ(t-τ)

jumps = obj.jumps;          % Скачки выбранного сигнала
slopes = obj.slopes;        % Наклоны выбранного сигнала
T2 = obj.T2;
time_mult = obj.time_mult;  % Множитель времени (например, 1e-6 для мкс)
time = obj.time;

% Пересчитываем амплитуды скачков с учётом множителя времени.
% Это нужно для корректных единиц измерения на графике:
% если время в мкс, то δ-функция имеет амплитуду в В/мкс, а не В/с.
jumps.amplitude = jumps.amplitude ./ time_mult;

% -- Цвета для различения типов --
color_slopes = [0 0.4470 0.7410];    % Синий — вклады от наклонов
color_jumps  = [0.8500 0.3250 0.0980]; % Оранжевый — вклады от скачков

figure(name="Производные сигнала");
tiledlayout(1,2);  % Два графика рядом: u'(t) слева, u''(t) справа

% =====================================================================
% ПЕРВАЯ ПРОИЗВОДНАЯ u'(t)
% =====================================================================
nexttile;
hold on;    % Позволяет рисовать несколько графиков на одних осях

% --- Наклоны (горизонтальные линии) ---
% На каждом линейном участке [t1, t2] первая производная = константа.
% Рисуем эти константы как горизонтальные линии.
res = zeros(1, length(time));   % Массив значений u'(t)
for k = 1:length(slopes.diff)
    t1 = slopes.time1(k); t2 = slopes.time2(k);

    % Маска: выделяем точки, принадлежащие данному участку
    id_line = time > t1 & time < t2;
    res(id_line) = slopes.diff(k);  % Присваиваем значение наклона
end
h_slopes = plot(time, res, Color=color_slopes, LineWidth=3);

% --- Скачки (дельта-функции, рисуются как вертикальные "палки") ---
% stem() рисует вертикальные линии от оси X до заданной высоты.
% Это общепринятый способ изображения дельта-функций на графиках.
h_jumps = [];
if ~isempty(jumps.time)
    pos = jumps.amplitude > 0;  % Положительные скачки
    neg = jumps.amplitude < 0;  % Отрицательные скачки

    % Положительные: треугольник вверх (^)
    if any(pos)
        h_jumps = stem(jumps.time(pos), jumps.amplitude(pos), '^', 'filled', ...
             Color=color_jumps, LineWidth=2, MarkerSize=10, MarkerFaceColor=color_jumps);
    end
    % Отрицательные: треугольник вниз (v)
    if any(neg)
        h_neg = stem(jumps.time(neg), jumps.amplitude(neg), 'v', 'filled', ...
             Color=color_jumps, LineWidth=2, MarkerSize=10, MarkerFaceColor=color_jumps);
        if isempty(h_jumps), h_jumps = h_neg; end
    end

    % Подписи δ-функций рядом с каждым скачком (например, "6δ(t)" или "-2δ(t-T1)")
    for i = 1:length(jumps.time)
        label = formatDelta(obj.jumps.amplitude(i), jumps.time(i), "\delta");
        t = text(jumps.time(i), jumps.amplitude(i), "  " + label, ...
            FontSize=9, Color=color_jumps, FontWeight='bold', AffectAutoLimits='on');
        uistack(t, 'top');  % Поднимаем текст поверх графика
    end
end

% Легенда
if ~isempty(h_jumps)
    legend([h_slopes, h_jumps], "От наклона", "От скачка (\delta-функция)", ...
        Location="best");
else
    legend(h_slopes, "От наклона", Location="best");
end

grid on;
xlim([-0.1*T2 1.2*T2]);
ylim([1.2*min([slopes.diff jumps.amplitude]) 1.2*max([slopes.diff jumps.amplitude])]);
ax = gca;
ax.XAxisLocation = 'origin';   % Ось X через y=0
ax.YAxisLocation = 'origin';   % Ось Y через x=0
title("Первая производная сигнала");
xlabel("t, с");
ylabel("u'(t)");

% =====================================================================
% ВТОРАЯ ПРОИЗВОДНАЯ u''(t)
% =====================================================================
% Состоит ТОЛЬКО из дельта-функций (обычных и производных):
%   1. От наклонов: на границах каждого линейного участка возникает
%      дельта-функция (ступенька в u'(t) → δ в u''(t)).
%      Амплитуда: +наклон на начале, -наклон на конце участка.
%   2. От скачков: скачки в u(t) дают δ в u'(t), а значит δ' в u''(t).
%      Но здесь они рисуются как обычные δ-функции для наглядности.
nexttile;
hold on;

% --- Импульсы от наклонов (δ-функции от "включения/выключения" наклонов) ---
% Собираем моменты и амплитуды: начало наклона → +diff, конец → -diff
imp_times = [slopes.time1(:)', slopes.time2(:)'];
imp_amps  = [slopes.diff(:)', -slopes.diff(:)'];

% Объединяем импульсы в совпадающих точках времени
[unique_times, ~, idx] = unique(imp_times);
combined_amps = accumarray(idx, imp_amps);

pos = combined_amps > 0;
neg = combined_amps < 0;

% Рисуем δ-функции от наклонов (синие)
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

% --- Импульсы от скачков (δ-функции, оранжевые) ---
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
    legend(handles, labels, Location="best");
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
    % FORMATDELTA — формирует строку-подпись для дельта-функции на графике.
    %
    % Примеры результата:
    %   formatDelta(6, 0, "δ")     → "6δ(t)"
    %   formatDelta(-2, 1e-6, "δ") → "-2δ(t - 1e-06)"
    %   formatDelta(1, 0, "δ'")    → "δ'(t)"

    % Аргумент δ-функции: "t" или "t - τ"
    if t == 0
        arg = "t";
    else
        arg = sprintf("t - %g", t);
    end

    % Амплитудный коэффициент: опускаем "1", пишем "-" вместо "-1"
    if amplitude == 1
        coeff = "";
    elseif amplitude == -1
        coeff = "-";
    else
        coeff = sprintf("%.2g", amplitude);
    end

    str = coeff + delta_symbol + "(" + arg + ")";
end
