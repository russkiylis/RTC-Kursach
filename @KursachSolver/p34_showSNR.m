function p34_showSNR(obj)
% P34_SHOWSNR — рассчитывает отношения сигнал/шум на входе и выходе СФ.
%
% Используем отношение сигнал/шум из методички:
%   q = U_max / sigma_noise,
% где U_max — максимальное значение полезного сигнала, sigma_noise — СКО шума.

    if isempty(obj.K_SF)
        error('Сначала вызовите p2_createSF()');
    end

    if isempty(obj.noiseStdIn) || isempty(obj.noiseStdOut)
        obj.p33_showNoiseStats();
    end

    k = obj.selectedSignal;

    U_in_max = max(abs(obj.u(k, :)));
    U_out_max = obj.A * obj.corrEnergy;

    obj.snrIn = U_in_max / obj.noiseStdIn;
    obj.snrOut = U_out_max / obj.noiseStdOut;
    obj.snrGain = obj.snrOut / obj.snrIn;

    fprintf('\n== ОТНОШЕНИЕ СИГНАЛ/ШУМ ==\n');
    fprintf('Отношение сигнал/шум на входе фильтра:\n');
    fprintf('(С/Ш)_вх = U_вх,max / sigma_ш.вх = %.6g / %.6g = %.6g\n', ...
            U_in_max, obj.noiseStdIn, obj.snrIn);

    fprintf('Отношение сигнал/шум на выходе фильтра:\n');
    fprintf('(С/Ш)_вых = U_вых,max / sigma_ш.вых = %.6g / %.6g = %.6g\n', ...
            U_out_max, obj.noiseStdOut, obj.snrOut);

    fprintf('Отношение (С/Ш)_вых к (С/Ш)_вх:\n');
    fprintf('(С/Ш)_вых / (С/Ш)_вх = %.6g / %.6g = %.6g\n', ...
            obj.snrOut, obj.snrIn, obj.snrGain);
end
