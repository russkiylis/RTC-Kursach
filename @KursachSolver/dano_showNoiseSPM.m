function dano_showNoiseSPM(obj)
% DANO_SHOWNOISESPM — строит график спектральной плотности мощности (СПМ) шума.
%
% СПМ квазибелого шума — это прямоугольник:
%   W(ω) = W0 при |ω| < ω_гр, иначе 0.
%
% На графике отмечены:
%   - Граничные частоты ±ω_гр (вертикальные пунктирные линии)
%   - Уровень W0 (горизонтальная пунктирная линия)

cyclic_freq = obj.cyclic_freq;
noiseSPM = obj.noise_SPM;
W0 = obj.W0;
omega_gr_n = obj.omega_gr_n;

figure(name="СПМ шума");

% Рисуем СПМ. Добавляем нулевые точки за пределами оси частот,
% чтобы график корректно уходил в ноль на краях.
plot([-2.*omega_gr_n cyclic_freq 2.*omega_gr_n], [0 noiseSPM 0], LineWidth=3);
grid on;

% Ограничиваем оси с запасом
xlim([-1.5.*omega_gr_n 1.5.*omega_gr_n]);
ylim([-0.2.*W0 1.3.*W0]);

% Оси через начало координат
ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';

% Пунктирные линии-маркеры для наглядности
xline(-omega_gr_n, '--', "-\omegaгр");   % Левая граничная частота
xline(omega_gr_n, '--', "\omegaгр");      % Правая граничная частота
yline(W0, '--', "W0");                    % Уровень СПМ

title("СПМ шума, W0 = " + sprintf("%.2e", W0) + " В^2/Гц, |\omegaгр| = " + sprintf("%.2e", omega_gr_n) + " рад/с");
xlabel("\omega, рад/с");
ylabel("W(\omega), В^2/Гц");


end
