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

omegaScale = 1e8;          % Чтобы ось omega была читаемой: 10^8 рад/с.
spmScale = 1e6;            % Перевод В^2/Гц -> В^2/МГц.
f_noise_gr_mhz = omega_gr_n / (2*pi) * 1e-6;

omega_scaled = cyclic_freq ./ omegaScale;
omega_gr_scaled = omega_gr_n ./ omegaScale;
noiseSPM_mhz = noiseSPM .* spmScale;
W0_mhz = W0 .* spmScale;

figure(name="СПМ шума", NumberTitle="off", Color='w');

% Рисуем СПМ. Добавляем нулевые точки за пределами оси частот,
% чтобы график корректно уходил в ноль на краях.
plot([-2.*omega_gr_scaled omega_scaled 2.*omega_gr_scaled], ...
     [0 noiseSPM_mhz 0], LineWidth=3);
grid on;

% Ограничиваем оси с запасом
xlim([-1.5.*omega_gr_scaled 1.5.*omega_gr_scaled]);
ylim([0 1.3.*W0_mhz]);

% Оси через начало координат
ax = gca;
ax.Color = 'w';
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';

% Пунктирные линии-маркеры для наглядности
xline(-omega_gr_scaled, '--', "-\omega_{ш.гр}");   % Левая граничная частота
xline(omega_gr_scaled, '--', "\omega_{ш.гр}");      % Правая граничная частота
yline(W0_mhz, '--', "W_0");                         % Уровень СПМ

title({ ...
    sprintf("СПМ исходного шума: W_0 = %.4g В^2/МГц", W0_mhz), ...
    sprintf("|\\omega_{ш.гр}| = %.4g\\cdot10^8 рад/с, f_{ш.гр} = %.4g МГц", ...
            omega_gr_scaled, f_noise_gr_mhz)});
xlabel("\omega, 10^8 рад/с");
ylabel("W(\omega), В^2/МГц");


end
