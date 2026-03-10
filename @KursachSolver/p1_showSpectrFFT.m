function p1_showSpectrFFT(obj)
%UNTITLED 1 пункт -Вывод спектров FFT
fs = 1/obj.dt;


% Сколько надо вывести точек чтобы было видно примерно 1/3T_2
N = length(obj.freqFFT);
points_number = (5/obj.T2)/(fs/(obj.N*obj.zpad));
% points_number = 500;

figure(name="Амплитудные сигналов через БПФ");
tiledlayout(3,1);
for k = 1:3
    ASp = abs(obj.spectrFFT(k,round(N/2-points_number):round(N/2+points_number)));  % Амплитудный спектр
    freq = obj.freqFFT(round(N/2-points_number):round(N/2+points_number));    % Частота
    ymax = max(ASp);

    nexttile;
    if k == obj.selectedSignal
        plot(freq,ASp, LineWidth=2,Color="r");
    else
        plot(freq,ASp, LineWidth=2);
    end
    xlim([freq(1) freq(end)]);
    ylim([0 1.1.*ymax]);
    
    yline(0.1.*ymax, '--');
    xline(-obj.f_gr01_FFT(k,1),'--');
    xline(obj.f_gr01_FFT(k,1),'--');

    grid on;
    if k == obj.selectedSignal
        title("АС сигнала через БПФ. T = "+num2str(obj.T(k))+" с. fср = "+sprintf("%.2e",obj.f_gr01_FFT(k,1))+" Гц. Выбран этот сигнал.")
    else
        title("АС сигнала через БПФ. T = "+num2str(obj.T(k))+" с. fср = "+sprintf("%.2e",obj.f_gr01_FFT(k,1))+" Гц")
    end
    xlabel("f, Гц");
    ylabel("S(f), В/Гц");
end


end