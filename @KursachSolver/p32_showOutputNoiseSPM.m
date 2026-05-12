function p32_showOutputNoiseSPM(obj)
% P32_SHOWOUTPUTNOISESPM — рассчитывает и строит СПМ шума на выходе СФ.
%
% Для линейной цепи спектральная плотность мощности шума на выходе:
%   W_out(f) = W_in(f) * |K_SF(f)|^2.
% Здесь W_in(f) — квазибелый шум, а K_SF(f) — комплексный коэффициент
% передачи согласованного фильтра, уже рассчитанный в p2_createSF().

    if isempty(obj.K_SF)
        error('Сначала вызовите p2_createSF()');
    end

    f = obj.cyclic_freq ./ (2*pi);       % Гц
    f_mhz = f .* 1e-6;                   % МГц
    f_noise_gr = obj.omega_gr_n ./ (2*pi);
    f_noise_gr_mhz = f_noise_gr .* 1e-6;

    W_in = obj.noise_SPM;                % В²/Гц
    W_in_mhz = W_in .* 1e6;              % В²/МГц
    W_out = W_in .* abs(obj.K_SF).^2;    % В²/Гц
    W_out_mhz = W_out .* 1e6;            % В²/МГц
    obj.noise_SPM_out = W_out;

    sp_max = max(abs(obj.spectrAnalytical));
    idx = find(abs(obj.spectrAnalytical) >= 0.1 * sp_max, 1);
    if isempty(idx)
        f_sig_gr = f_noise_gr;
    else
        f_sig_gr = abs(f(idx));
    end
    f_sig_gr_mhz = f_sig_gr .* 1e-6;

    W_out_max_mhz = max(W_out_mhz);
    if W_out_max_mhz <= 0
        W_out_max_mhz = 1;
    end

    fprintf('\n== СПМ шума на выходе СФ ==\n');
    fprintf('W0 = %.4e В^2/Гц\n', obj.W0);
    fprintf('A = %.4e Гц/В\n', obj.A);
    fprintf('f_ш.гр = %.4g МГц\n', f_noise_gr_mhz);
    fprintf('max W_вых = %.4e В^2/Гц = %.4e В^2/МГц\n', ...
        max(W_out), max(W_out_mhz));

    figure(name="СПМ шума на выходе СФ", NumberTitle="off", Color='w');
    tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    % Полный вид в полосе шума.
    nexttile;
    plot(f_mhz, W_in_mhz, '--', 'LineWidth', 2.0, 'Color', [0.25 0.25 0.25], ...
        'DisplayName', 'W_{вх}(f)');
    hold on;
    plot(f_mhz, W_out_mhz, 'LineWidth', 2.2, ...
        'DisplayName', 'W_{вых}(f)=W_{вх}(f)|K_{СФ}(f)|^2');
    xline(-f_noise_gr_mhz, '--', '-f_{ш.гр}', 'HandleVisibility', 'off');
    xline( f_noise_gr_mhz, '--',  'f_{ш.гр}', 'HandleVisibility', 'off');
    yline(max(W_out_mhz), '--', 'max W_{вых}', 'HandleVisibility', 'off');
    grid on;
    xlabel('f, МГц');
    ylabel('W(f), В^2/МГц');
    title(sprintf('СПМ шума на входе и выходе СФ, f_{ш.гр}=%.4g МГц', f_noise_gr_mhz));
    xlim([-1.05*f_noise_gr_mhz, 1.05*f_noise_gr_mhz]);
    ylim([0, 1.15*max(max(W_in_mhz), W_out_max_mhz)]);
    legend('Location', 'best');
    set(gca, 'Color', 'w');
    hold off;

    % Увеличение в области существенного спектра сигнала.
    nexttile;
    plot(f_mhz, W_out_mhz, 'LineWidth', 2.2);
    hold on;
    xline(-f_sig_gr_mhz, '--', '-f_{0.1}', 'HandleVisibility', 'off');
    xline( f_sig_gr_mhz, '--',  'f_{0.1}', 'HandleVisibility', 'off');
    grid on;
    xlabel('f, МГц');
    ylabel('W_{вых}(f), В^2/МГц');
    title(sprintf('Область спектра сигнала, f_{0.1}=%.4g МГц', f_sig_gr_mhz));
    zoom_lim = max(f_sig_gr_mhz * 1.2, eps);
    xlim([-zoom_lim, zoom_lim]);
    ylim([0, 1.15*W_out_max_mhz]);
    set(gca, 'Color', 'w');
    hold off;
end
