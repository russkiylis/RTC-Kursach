function p33_showNoiseStats(obj)
% P33_SHOWNOISESTATS — рассчитывает дисперсию и СКО шума на входе/выходе СФ.
%
% СПМ в проекте задана в В²/Гц, поэтому дисперсия равна площади под СПМ
% по обычной частоте f:
%   D = integral W(f) df.

    if isempty(obj.K_SF)
        error('Сначала вызовите p2_createSF()');
    end

    f = obj.cyclic_freq ./ (2*pi);     % Гц
    W_in = obj.noise_SPM;              % В²/Гц

    if isempty(obj.noise_SPM_out)
        W_out = W_in .* abs(obj.K_SF).^2;
        obj.noise_SPM_out = W_out;
    else
        W_out = obj.noise_SPM_out;
    end

    D_in_numeric = trapz(f, W_in);
    obj.noiseVarInFormula = 2 * (obj.omega_gr_n / (2*pi)) * obj.W0;
    D_out_numeric = trapz(f, W_out);
    obj.noiseVarOutParseval = obj.W0 * obj.A^2 * obj.corrEnergy;

    obj.noiseVarIn = max(D_in_numeric, 0);
    obj.noiseStdIn = sqrt(obj.noiseVarIn);
    obj.noiseVarOut = max(D_out_numeric, 0);
    obj.noiseStdOut = sqrt(obj.noiseVarOut);

    fprintf('\n== ДИСПЕРСИЯ И СКО ШУМА ==\n');
    fprintf('D_вх = %.6g В^2, sigma_вх = %.6g В\n', obj.noiseVarIn, obj.noiseStdIn);
    fprintf('D_вх по формуле 2*f_ш.гр*W0 = %.6g В^2\n', obj.noiseVarInFormula);
    fprintf('D_вых = %.6g В^2, sigma_вых = %.6g В\n', obj.noiseVarOut, obj.noiseStdOut);
    fprintf('D_вых по оценке W0*A^2*E = %.6g В^2\n', obj.noiseVarOutParseval);

    figure(name="Дисперсия и СКО шума на входе и выходе СФ", ...
           NumberTitle="off", Color='w');
    tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    nexttile;
    bar([obj.noiseVarIn, obj.noiseVarOut], 0.55);
    set(gca, 'XTickLabel', {'Вход СФ', 'Выход СФ'}, 'Color', 'w');
    ylabel('D, В^2');
    title('Дисперсия шума');
    grid on;

    nexttile;
    bar([obj.noiseStdIn, obj.noiseStdOut], 0.55);
    set(gca, 'XTickLabel', {'Вход СФ', 'Выход СФ'}, 'Color', 'w');
    ylabel('\sigma, В');
    title('Среднеквадратическое отклонение шума');
    grid on;
end
