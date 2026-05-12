function p1_showSignalDiffSchematic(obj)
% P1_SHOWSIGNALDIFFSCHEMATIC — схематические графики u'(t) и u''(t)
% в стиле "Рис.3 / Рис.4" из учебной курсовой: вертикальная компоновка,
% символьные подписи (U1, U3, t1, t2), без числовых значений.

T1 = obj.T(obj.selectedSignal);
T2 = obj.T2;

% Безразмерные координаты (рисуем "схему", оси без чисел)
t1 = 1;          % условная позиция T1 на оси
t2 = T2/T1;      % условная позиция T2 (сохраняем пропорцию)
A_jump  = 1.0;   % условная высота для (U1-U3)δ(t-t1)
A_delta = 0.7;   % условная высота для U1δ(t)
A_slope = 0.55;  % условная "высота" константы U3/(t2-t1)

color_slope = [0 0.4470 0.7410];
color_jump  = [0    0    0   ];

figure(Name="Производные сигнала (схема)", NumberTitle="off", ...
       Position=[100 100 700 800]);
tiledlayout(2,1, TileSpacing="compact", Padding="compact");

% =====================================================================
% Рис.3 — Первая производная u'(t)
% =====================================================================
nexttile; hold on;

% Горизонтальная "полка" наклона −U3/(t2−t1) на участке [t1, t2]
plot([t1 t2], [-A_slope -A_slope], Color=color_slope, LineWidth=2.5);
plot([t1 t1], [0 -A_slope], '--', Color=color_slope, LineWidth=1);
plot([t2 t2], [0 -A_slope], '--', Color=color_slope, LineWidth=1);

% δ-функция U1·δ(t) в нуле (стрелка вверх)
drawArrow(0, 0, 0, A_delta, color_jump);
text(0.05, A_delta, " U_1\delta(t)", FontSize=14, ...
     VerticalAlignment="top", FontWeight="bold");

% δ-функция -(U1-U3)·δ(t-t1) (стрелка вниз)
drawArrow(t1, 0, t1, -A_jump, color_jump);
text(t1+0.05, -A_jump, "  -(U_1-U_3)\delta(t-t_1)", FontSize=14, ...
     VerticalAlignment="bottom", FontWeight="bold");

% Подпись уровня константы наклона
text(t1+0.05, -A_slope, "  -\dfrac{U_3}{t_2-t_1}", FontSize=14, ...
     Interpreter="tex", VerticalAlignment="bottom", Color=color_slope);

% Оси и подписи
ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';
ax.XTick = [t1 t2];
ax.XTickLabel = {'t_1', 't_2'};
ax.YTick = [];
xlim([-0.3 t2+0.5]);
ylim([-1.4 1.2]);
xlabel("t");
ylabel("u'(t)", Rotation=0, HorizontalAlignment="right");
title("Рис.3 — Первая производная исходного сигнала");
box off;

% =====================================================================
% Рис.4 — Вторая производная u''(t)
% =====================================================================
nexttile; hold on;

% δ'(t) от U1·δ(t) в u'(t)  → U1·δ'(t)  (стрелка вверх в нуле)
drawArrow(0, 0, 0, A_delta, color_jump);
text(0.05, A_delta, " U_1\delta'(t)", FontSize=14, ...
     VerticalAlignment="top", FontWeight="bold");

% -(U1-U3)·δ'(t-t1) (стрелка вниз в t1)
drawArrow(t1, 0, t1, -A_jump, color_jump);
text(t1+0.05, -A_jump, "  -(U_1-U_3)\delta'(t-t_1)", FontSize=14, ...
     VerticalAlignment="bottom", FontWeight="bold");

% -U3/(t2-t1) · δ(t-t1) (стрелка вниз в t1, синяя — от наклона)
drawArrow(t1-0.03, 0, t1-0.03, -A_slope, color_slope);
text(t1-0.05, -A_slope, "-\dfrac{U_3}{t_2-t_1}\delta(t-t_1) ", ...
     FontSize=13, Interpreter="tex", Color=color_slope, ...
     VerticalAlignment="bottom", HorizontalAlignment="right", FontWeight="bold");

% +U3/(t2-t1) · δ(t-t2) (стрелка вверх в t2, синяя)
drawArrow(t2, 0, t2, A_slope, color_slope);
text(t2-0.05, A_slope, "\dfrac{U_3}{t_2-t_1}\delta(t-t_2) ", ...
     FontSize=13, Interpreter="tex", Color=color_slope, ...
     VerticalAlignment="top", HorizontalAlignment="right", FontWeight="bold");

ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';
ax.XTick = [t1 t2];
ax.XTickLabel = {'t_1', 't_2'};
ax.YTick = [];
xlim([-0.3 t2+0.5]);
ylim([-1.4 1.2]);
xlabel("t");
ylabel("u''(t)", Rotation=0, HorizontalAlignment="right");
title("Рис.4 — Вторая производная исходного сигнала");
box off;

end

% Нарисовать "стрелку" (δ-функцию) от (x1,y1) к (x2,y2)
function drawArrow(x1, y1, x2, y2, color)
    plot([x1 x2], [y1 y2], Color=color, LineWidth=2.5);
    if y2 > y1
        marker = '^';
    else
        marker = 'v';
    end
    plot(x2, y2, marker, MarkerSize=12, MarkerFaceColor=color, ...
         MarkerEdgeColor=color);
end
