function p1_showSpectrAnalytical(obj)
% P1_SHOWSPECTRANALYTICAL — строит график аналитического амплитудного спектра.
%
% Этот спектр получен методом дифференцирования (см. p1_createSpectrAnalytical).
% Он должен совпадать со спектром, посчитанным через БПФ (p1_showSpectrFFT),
% что служит проверкой правильности аналитических формул.
%
% Ось X: обычная частота f (МГц), пересчитанная из круговой: f = ω / (2π).
% Ось Y: амплитудный спектр |S(f)| (В/МГц).
%
% На графике отмечена граничная частота f_гр по уровню 0.1 от максимума.

sp = obj.spectrAnalytical;          % Суммарный аналитический спектр S(ω)
f = obj.cyclic_freq ./(2.*pi);      % Пересчёт оси из ω (рад/с) в f (Гц)
f_mhz = f .* 1e-6;                  % Частота f (МГц)
abs_sp_mhz = abs(sp) .* 1e6;        % Амплитудный спектр в В/МГц

sp_max = max(abs(sp));              % Максимум амплитудного спектра
sp_max_mhz = sp_max .* 1e6;         % Максимум амплитудного спектра в В/МГц

% Определяем граничную частоту f_гр по уровню 0.1 от максимума.
% find(..., 1) находит первую точку, где |S| ≥ 0.1*max — это левая граница.
% Берём её с минусом (т.к. спектр симметричен, левая граница отрицательная),
% чтобы получить положительное значение f_гр.
f_sr = -f(find(abs(sp) >= 0.1.*(sp_max),1));
f_sr_mhz = f_sr .* 1e-6;
xlim_max_mhz = 1.5 .* f_sr_mhz;
pos = f >= 0;


figure(name="Аналитический спектр, fгр = " + sprintf("%.2f",f_sr_mhz) + " МГц", ...
    NumberTitle="off", Color='w');
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- Амплитудный спектр ---
nexttile;
plot(f_mhz(pos), abs_sp_mhz(pos), LineWidth=2);
xline(f_sr_mhz, "--");
yline(0.1.*sp_max_mhz, "--");
xlabel("f, МГц");
ylabel("|S(f)|, В/МГц");
grid on;
title("Амплитудный спектр");
xlim([0 xlim_max_mhz]);

% --- Фазовый спектр ---
nexttile;
plot(f_mhz(pos), angle(sp(pos)), LineWidth=2);
xline(f_sr_mhz, "--");
xlabel("f, МГц");
ylabel("\phi_S(f), рад");
grid on;
title("Фазовый спектр");
xlim([0 xlim_max_mhz]);
end
