clear;
clc;
close all;

% Вайбкоденное кусочное нечто
syms t t1 t2 u1 u2 u3 u4 % Крутая штука, мб чудотворна
u = piecewise( ...
    t < 0, 0, ...                          % от -∞ до 0: значение 0
    t == 0, u1, ...                         % в точке 0: значение u1
    t > 0 & t < t1, u1 + (u2 - u1)*(t/t1), ... % от 0 до t1: линейно от u1 до u2
    t == t1, u3, ...                         % в точке t1: значение u3 (скачок)
    t > t1 & t < t2, u3 + (u4 - u3)*((t - t1)/(t2 - t1)), ... % от t1 до t2: линейно от u3 до u4
    t == t2, u4, ...                          % в точке T2: значение u4
    t > t2, 0 ...                          % от T2 до ∞: значение 0
);

syms f W0 fsh % Кусочнеческий СПМ
spm = piecewise( ...
    abs(f) > fsh, 0, ...   % 0 при модуле частоты больше fsh
    abs(f) <= fsh, W0 ...  % позитивная амплитуда W0 в границах fsh
);

T_antiplot = 1; % Отладочный костыль, позволяет вводить 1е6 для микросекунд

% Старт. Вводные данные.
U1 = 8; U2 = 2; U3 = 4; U4 = 2; uu = [U1, U2, U3, U4];
T11 = 1*T_antiplot; T12 = 2*T_antiplot; T13 = 4*T_antiplot; 
T2 = 5*T_antiplot;
N = 16; M = 10;

% Параметры шумового сигнала, АЛЯРМ здесь есть переход к микросекундам без
% учета отладки 

W0_a = ((max(uu)^2)*T2*1e-6)/N; % Методическая формула  
W0_a_plot = W0_a/(10^floor(log10(abs(W0_a)))); % Костыление для получения чистого графика (без приписки о сложных степенях)

wsh_a = (10*pi*M)/(T2*1e-6); % Методическая формула, частота круговая

fsh_a = wsh_a/(2*pi); % Методическая формула, переход к обычной частоте
fsh_a_plot = fsh_a/(10^floor(log10(abs(fsh_a)))); % Еще одно костыление

% Время, указано с неравномерной дискретизацией
t_bord = T_antiplot*5; % Динамический диапазон пределов определения
t_area = T_antiplot/100; % Диапазон около скачка
t_prec1 = T_antiplot/2; % Низкая точность вне скачков
t_prec2 = T_antiplot/200; % Повышенная точность в пределах скачка
t_chill = [-t_bord:t_prec1:-t_area, t_area:t_prec1:T11-t_area, T11+t_area:t_prec1:T12-t_area, T13+t_area:t_prec1:T13-t_area, T13+t_area:t_prec1:T2-t_area, T2+t_area:t_prec1:T2+T_antiplot];
t_lockin = [-t_area:t_prec2:t_area, T11-t_area:t_prec2:T11+t_area, T12-t_area:t_prec2:T12+t_area, T13-t_area:t_prec2:T13+t_area, T2-t_area:t_prec2:T2+t_area];
T = sort([t_chill, t_lockin]); % Готовый вектор времени

% Подставляем значение в кусочную функцию, получаем три графика
u_var = {t, t1, t2, u1, u2, u3, u4}; % Вектор переменных для сигнала

T1_values = [T11, T12, T13];
titles_str = {'Сигнал при Т1 = 1 мкс', 'Сигнал при Т1 = 2 мкс', 'Сигнал при Т1 = 4 мкс'};

for i = 1:length(T1_values)
    figure;
    u_plot = double(subs(u, {t, t1, t2, u1, u2, u3, u4}, ...
                         {T, T1_values(i), T2, U1, U2, U3, U4}));
    plot(T, u_plot, 'b-', 'LineWidth', 1.5);
    xlabel('Время, мкс');
    xlim([-1*T_antiplot, 5.5*T_antiplot]);
    ylabel('Амплитуда, Вольт');
    ylim([-2, 10]);
    title(titles_str{i});
    grid on;
end

% Вспоминаем про шум
f_bord = fsh_a_plot*3; % Динамический диапазон определения частот для всего графика
f_area = fsh_a_plot/1000; % Не менее динамическая зона около скачка
f_prec1 = fsh_a_plot/10; % Точность вне зоны скачка
f_prec2 = fsh_a_plot/1000; % Повышенная точность в зоне скачка
f_chill = [-f_bord:f_prec1:-fsh_a_plot-f_area, -fsh_a_plot+f_area:f_prec1:fsh_a_plot-f_area, fsh_a_plot+f_area:f_prec1:f_bord];
f_lockin = [-fsh_a_plot-f_area:f_prec2:-fsh_a_plot+f_area, fsh_a_plot-f_area:f_prec2:fsh_a_plot+f_area];
F = sort([f_chill, f_lockin]);

figure
spm_plot = double(subs(spm, {f, W0, fsh}, {F, W0_a_plot, fsh_a_plot}));
plot(F,spm_plot, 'b-', 'LineWidth', 1.5)
xlabel('Частота, Герц*1е7')
xlim([-1.5*fsh_a_plot 1.5*fsh_a_plot]);
ylabel('Спектральная плотность мощности, Вт*1е-5/Гц')
ylim([-0.3*W0_a_plot 1.2*W0_a_plot]);
title('СПМ Исходного шума')
grid on;

%Гадость - представление обоих диффов в виде уравнений, потеря дельтфункций
%
% du = diff(u, t);
%ddu = diff(du, t);
% disp('Производная:');
% disp(df);
% figure
% u_plot11 = double(subs(df, {t, t1, t2, u1, u2, u3, u4}, {T, T11, T2, U1, U2, U3, U4}));
% plot(T,u_plot11, 'b-', 'LineWidth', 1.5)
% xlabel('Время, мкс')
% xlim([-0.5 5.5]);
% ylabel('Амплитуда, Вольт')
% ylim([-2 10]);
% title('Сигнал при Т1 = 1 мкс')
% grid on;
%
% disp('Производная:');
% disp(ddf);
% figure
% u_plot111 = double(subs(ddf, {t, t1, t2, u1, u2, u3, u4}, {T, T11, T2, U1, U2, U3, U4}));
% plot(T,u_plot111, 'b-', 'LineWidth', 1.5)
% xlabel('Время, мкс')
% xlim([-0.5 5.5]);
% ylabel('Амплитуда, Вольт')
% ylim([-2 10]);
% title('Сигнал при Т1 = 1 мкс')
% grid on;

% Еще попытка, двойное дифф от изначальной функции - ошибка преобразования
% ddu = diff(du, t);
% 
% syms omega
% 
% ddu_fourier = fourier(ddu, t, omega);
% 
% % Или найти спектр исходной функции через свойство:
% % FT(d²u/dt²) = (jω)² * FT(u) = -ω² * FT(u)
% 
% % Находим спектр исходной функции
% U_fourier = fourier(u, t, omega);
% 
% % Проверяем связь
% ddu_fourier_check = -omega^2 * U_fourier;
% 
% % Они должны быть равны (упростим для проверки)
% simplify(ddu_fourier - ddu_fourier_check);
% omega_vals = linspace(-50, 50, 2000);
% 
% figure
% u_ddu1 = double(subs(U_fourier, {t1, t2, u1, u2, u3, u4, omega}, {T11, T2, U1, U2, U3, U4, omega_vals}));
% u_amp1 = abs(u_ddu1);
% 
% plot(T,u_amp1, 'b-', 'LineWidth', 1.5)
% xlabel('Время, мкс')
% xlim([-0.5 5.5]);
% ylabel('Амплитуда, Вольт')
% ylim([-2 10]);
% title('Сигнал при Т1 = 1 мкс')
% grid on;

% u_spec = fft(u_plot1); % Ошибка дискретизации результата подстановки u_plot1, графики уходят в говно
% u_amp = abs(u_spec);
% u_phs = angle(u_spec);
% f_u = 0:0.1:1000;
% 
% figure
% %u_amp1 = double(subs(u_amp, {t, t1, t2, u1, u2, u3, u4}, {T, T11, T2, U1, U2, U3, U4}));
% plot(T,u_amp, 'b-', 'LineWidth', 1.5)
% xlabel('Время, мкс')
% xlim([-0.5 5.5]);
% ylabel('Амплитуда, Вольт')
% ylim([-2 10]);
% title('Сигнал при Т1 = 1 мкс')
% grid on;
% 
% figure
% %u_phs1 = double(subs(u_phs, {t, t1, t2, u1, u2, u3, u4}, {T, T12, T2, U1, U2, U3, U4}));
% plot(T,u_phs, 'b-', 'LineWidth', 1.5)
% xlabel('Время, мкс')
% xlim([-0.5 5.5]);
% ylabel('Амплитуда, Вольт')
% ylim([-2 10]);
% title('Сигнал при Т1 = 2 мкс')
% grid on;
