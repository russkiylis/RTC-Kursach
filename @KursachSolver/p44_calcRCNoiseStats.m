function p44_calcRCNoiseStats(obj, plotMode)
% P44_CALCRCNOISESTATS — СПМ, дисперсия и СКО шума на выходе RC-фильтра.
%
% Для каждого tau из obj.rcTauValues:
%   K_RC(jw) = 1 / (1 + j*w*tau),
%   W_out(f) = W_in(f) * |K_RC(jw)|^2,
%   D_out = integral W_out(f) df,
%   sigma_out = sqrt(D_out).

    if nargin < 2 || isempty(plotMode)
        plotMode = "all";
    elseif islogical(plotMode)
        if plotMode
            plotMode = "all";
        else
            plotMode = "none";
        end
    else
        plotMode = string(plotMode);
    end

    if isempty(obj.rcTauValues)
        obj.p41_calcRCResponses();
    end

    if isempty(obj.K_SF)
        error('Сначала вызовите p2_createSF()');
    end

    tm = obj.time_mult;
    tUnit = timeUnit(tm);

    omega = obj.cyclic_freq;            % рад/с
    f = omega ./ (2*pi);                % Гц
    f_mhz = f .* 1e-6;                  % МГц
    W_in = obj.noise_SPM;               % В²/Гц
    W_in_mhz = W_in .* 1e6;             % В²/МГц
    W_sf_out = W_in .* abs(obj.K_SF).^2;
    W_sf_out_mhz = W_sf_out .* 1e6;
    obj.noise_SPM_out = W_sf_out;
    f_noise_gr = obj.omega_gr_n ./ (2*pi);
    f_noise_gr_mhz = f_noise_gr .* 1e-6;
    f_sig_gr = abs(obj.f_gr01_FFT(obj.selectedSignal));
    f_sig_gr_mhz = f_sig_gr .* 1e-6;

    nTau = numel(obj.rcTauValues);
    nFreq = numel(omega);
    obj.rcKValues = zeros(nTau, nFreq);
    obj.rcNoiseSPMOut = zeros(nTau, nFreq);
    obj.rcNoiseVarOut = zeros(nTau, 1);
    obj.rcNoiseStdOut = zeros(nTau, 1);

    for i = 1:nTau
        tau = obj.rcTauValues(i);
        K_RC = 1 ./ (1 + 1i .* omega .* tau);
        W_out = W_in .* abs(K_RC).^2;

        obj.rcKValues(i, :) = K_RC;
        obj.rcNoiseSPMOut(i, :) = W_out;
        obj.rcNoiseVarOut(i) = max(trapz(f, W_out), 0);
        obj.rcNoiseStdOut(i) = sqrt(obj.rcNoiseVarOut(i));
    end

    if plotMode == "none"
        return;
    end

    plotStats = any(plotMode == ["all", "stats"]);
    plotSpm = any(plotMode == ["all", "spm"]);
    [~, idxTau0] = min(abs(obj.rcTauFactors - 1));

    tau0 = obj.rcTauValues(idxTau0);
    tau0Label = "\tau_0";
    D_tau0 = obj.rcNoiseVarOut(idxTau0);
    sigma_tau0 = obj.rcNoiseStdOut(idxTau0);

    if plotSpm
        if isempty(obj.rcSNRMaxTau)
            tauSpm = tau0;
            tauSpmLabel = tau0Label;
        else
            tauSpm = obj.rcSNRMaxTau;
            tauSpmLabel = "\tau_{RC,opt}";
        end

        K_RC_opt = 1 ./ (1 + 1i .* omega .* tauSpm);
        W_RC_opt = W_in .* abs(K_RC_opt).^2;
        obj.rcOptK = K_RC_opt;
        obj.rcOptNoiseSPMOut = W_RC_opt;
        obj.rcOptNoiseVarOut = max(trapz(f, W_RC_opt), 0);
        obj.rcOptNoiseStdOut = sqrt(obj.rcOptNoiseVarOut);
        W_opt_mhz = W_RC_opt .* 1e6;
    end

    fprintf('\n== RC-ФИЛЬТР: СПМ, ДИСПЕРСИЯ И СКО ШУМА ДЛЯ РАЗНЫХ tau ==\n');
    fprintf('W0 = %.6g В^2/Гц\n', obj.W0);
    fprintf('f_ш.гр = %.6g Гц = %.6g МГц\n', f_noise_gr, f_noise_gr_mhz);
    if plotSpm
        fprintf('Для графика СПМ используется %s = %.6g с = %.6g %s\n', ...
                tauSpmLabel, tauSpm, tauSpm / tm, tUnit);
        fprintf('D_RCвых(%s) = %.6g В^2, sigma_RCвых(%s) = %.6g В\n', ...
                tauSpmLabel, obj.rcOptNoiseVarOut, tauSpmLabel, obj.rcOptNoiseStdOut);
    end
    if plotStats
        fprintf('%12s %14s %16s %16s\n', ...
                'tau/tau0', "tau, " + tUnit, 'D_RCвых, В^2', 'sigma_RCвых, В');
        for i = 1:nTau
            fprintf('%12.6g %14.6g %16.6g %16.6g\n', ...
                    obj.rcTauFactors(i), ...
                    obj.rcTauValues(i) / tm, ...
                    obj.rcNoiseVarOut(i), ...
                    obj.rcNoiseStdOut(i));
        end
    end

    if plotSpm
        figure(name="СПМ шума на выходе RC-фильтра и СФ", ...
               NumberTitle="off", Color='w');
        ax = gca;
        ax.Color = 'w';
        hold(ax, "on");

        plot(ax, f_mhz, W_in_mhz, "--", ...
            "LineWidth", 1.4, ...
            "Color", [0.50 0.50 0.50], ...
            "DisplayName", "W_{вх}(f)");
        plot(ax, f_mhz, W_sf_out_mhz, ...
            "LineWidth", 2.2, ...
            "Color", [0.20 0.45 0.75], ...
            "DisplayName", "W_{СФ вых}(f)");
        plot(ax, f_mhz, W_opt_mhz, ...
            "LineStyle", "--", ...
            "LineWidth", 2.4, ...
            "Color", [0.85 0.12 0.10], ...
            "DisplayName", sprintf("W_{RCвых}(f), %s=%.4g %s", ...
                                   tauSpmLabel, tauSpm / tm, tUnit));
        xline(ax, -f_sig_gr_mhz, "--", "-f_{0.1}", "HandleVisibility", "off");
        xline(ax,  f_sig_gr_mhz, "--",  "f_{0.1}", "HandleVisibility", "off");
        xlabel(ax, "f, МГц");
        ylabel(ax, "W(f), В^2/МГц");
        title(ax, "СПМ шума на выходе RC-фильтра и согласованного фильтра");
        grid(ax, "on");
        legend(ax, "Location", "best");
        zoom_lim = max(1.2 * f_sig_gr_mhz, eps);
        xlim(ax, [-zoom_lim, zoom_lim]);
        ylim(ax, [0, 1.15 * max([W_opt_mhz(:); W_sf_out_mhz(:); W_in_mhz(:)])]);
        hold(ax, "off");
    end

    if ~plotStats
        return;
    end

    figure(name="Дисперсия и СКО шума на выходе RC-фильтра", ...
           NumberTitle="off", Color='w');
    tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    ax = nexttile;
    ax.Color = 'w';
    hold(ax, "on");
    plot(ax, obj.rcTauValues / tm, obj.rcNoiseVarOut, ...
        "-o", "LineWidth", 1.8, "MarkerSize", 5, ...
        "Color", [0.20 0.45 0.75]);
    plot(ax, tau0 / tm, D_tau0, ...
        "o", "MarkerSize", 9, "LineWidth", 2.3, ...
        "MarkerFaceColor", [0.85 0.12 0.10], ...
        "MarkerEdgeColor", [0.85 0.12 0.10]);
    xline(ax, tau0 / tm, "--", tau0Label, ...
        "Color", [0.85 0.12 0.10], "LineWidth", 1.2, ...
        "HandleVisibility", "off", "LabelVerticalAlignment", "bottom");
    xlabel(ax, "\tau, " + tUnit);
    ylabel(ax, "D_{RCвых}, В^2");
    title(ax, "Дисперсия шума на выходе RC-фильтра");
    grid(ax, "on");
    xlim(ax, [0, max(obj.rcTauValues) / tm]);
    hold(ax, "off");

    ax = nexttile;
    ax.Color = 'w';
    hold(ax, "on");
    plot(ax, obj.rcTauValues / tm, obj.rcNoiseStdOut, ...
        "-o", "LineWidth", 1.8, "MarkerSize", 5, ...
        "Color", [0.20 0.45 0.75]);
    plot(ax, tau0 / tm, sigma_tau0, ...
        "o", "MarkerSize", 9, "LineWidth", 2.3, ...
        "MarkerFaceColor", [0.85 0.12 0.10], ...
        "MarkerEdgeColor", [0.85 0.12 0.10]);
    xline(ax, tau0 / tm, "--", tau0Label, ...
        "Color", [0.85 0.12 0.10], "LineWidth", 1.2, ...
        "HandleVisibility", "off", "LabelVerticalAlignment", "bottom");
    xlabel(ax, "\tau, " + tUnit);
    ylabel(ax, "\sigma_{RCвых}, В");
    title(ax, "СКО шума на выходе RC-фильтра");
    grid(ax, "on");
    xlim(ax, [0, max(obj.rcTauValues) / tm]);
    hold(ax, "off");
end

function unit = timeUnit(tm)
    if tm == 1e-6
        unit = "мкс";
    elseif tm == 1e-3
        unit = "мс";
    elseif tm == 1e-9
        unit = "нс";
    elseif tm == 1
        unit = "с";
    else
        unit = sprintf("%.0e с", tm);
    end
end
