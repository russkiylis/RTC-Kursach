function p36_showRectSNR(obj)
% P36_SHOWRECTSNR — ОСШ на входе/выходе СФ для прямоугольного импульса.

    if isempty(obj.K_SF)
        error('Сначала вызовите p2_createSF()');
    end

    if isempty(obj.noiseStdIn) || isempty(obj.noiseStdOut)
        obj.p33_showNoiseStats();
    end

    if isempty(obj.rectAmp) || isempty(obj.rectOutSignal)
        obj.p35_showRectResponse();
    end

    Uv = obj.rectAmp;
    uOutMax = max(abs(obj.rectOutSignal));

    obj.rectSnrIn = Uv / obj.noiseStdIn;
    obj.rectSnrOut = uOutMax / obj.noiseStdOut;
    obj.rectSnrGain = obj.rectSnrOut / obj.rectSnrIn;

    fprintf('\n== ОТНОШЕНИЕ СИГНАЛ/ШУМ ДЛЯ ПРЯМОУГОЛЬНОГО ИМПУЛЬСА ==\n');
    fprintf('Отношение сигнал/шум на входе фильтра:\n');
    fprintf('(С/Ш)_вх.пр = Uv / sigma_ш.вх = %.6g / %.6g = %.6g\n', ...
            Uv, obj.noiseStdIn, obj.rectSnrIn);

    fprintf('Отношение сигнал/шум на выходе фильтра:\n');
    fprintf('(С/Ш)_вых.пр = u_вых,max / sigma_ш.вых = %.6g / %.6g = %.6g\n', ...
            uOutMax, obj.noiseStdOut, obj.rectSnrOut);

    fprintf('Отношение (С/Ш)_вых.пр к (С/Ш)_вх.пр:\n');
    fprintf('(С/Ш)_вых.пр / (С/Ш)_вх.пр = %.6g / %.6g = %.6g\n', ...
            obj.rectSnrOut, obj.rectSnrIn, obj.rectSnrGain);
end
