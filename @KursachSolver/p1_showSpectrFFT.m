function p1_showSpectrFFT(obj)
%UNTITLED 1 пункт -Вывод спектров FFT

figure(name="Амплитудные сигналов через БПФ");
tiledlayout(1,3);
for k = 1:3
    ASp = abs(obj.spectrFFT(k,:));  % Амплитудный спектр
    freq = obj.freqFFT;    % Частота
    ymax = max(ASp);

    nexttile;
    if k == obj.selectedSignal
        plot(freq,ASp, LineWidth=2,Color="r");
    else
        plot(freq,ASp, LineWidth=2);
    end
    xlim([-max(obj.f_gr01_FFT')*1.2 max(obj.f_gr01_FFT')*1.2]);
    ylim([0 1.1.*ymax]);
    
    yline(0.1.*ymax, '--');
    xline(-obj.f_gr01_FFT(k,1),'--');
    xline(obj.f_gr01_FFT(k,1),'--');

    grid on;
    title("T = "+num2str(obj.T(k))+" с. fср = "+sprintf("%.2e",obj.f_gr01_FFT(k,1))+" Гц")
    xlabel("f, Гц");
    ylabel("S(f), В/Гц");
end


end