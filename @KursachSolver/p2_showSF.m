function p2_showSF(obj)
% P2_SHOWSF — Графики АЧХ/ФЧХ и импульсная характеристика СФ.
%
% 1) АЧХ |K_СФ(f)| и ФЧХ φ_K(f) согласованного фильтра.
% 2) Временные зависимости напряжений в различных точках структурной
%    схемы СФ при подаче на вход δ(t) — иллюстрация формирования
%    импульсной характеристики (рис. 3.4 методички).
%
% Имена узлов (u_1, u_2, ...) соответствуют меткам на структурной схеме,
% нарисованной в p2_simplifySF.

    terms = obj.K_SF_simplified_terms;
    if isempty(terms)
        error('Сначала вызовите p2_simplifySF()');
    end

    % =====================================================================
    % ФИГУРА 1: АЧХ и ФЧХ согласованного фильтра
    % =====================================================================
    f = obj.cyclic_freq ./ (2*pi);       % ω → f (Гц)
    K = obj.K_SF;

    % Определяем граничную частоту для ограничения оси X
    sp_max = max(abs(obj.spectrAnalytical));
    f_gr = -f(find(abs(obj.spectrAnalytical) >= 0.1*sp_max, 1));

    figure('Name', 'АЧХ и ФЧХ согласованного фильтра', ...
           'NumberTitle', 'off', 'Color', 'w');
    tiledlayout(2, 1);

    % --- АЧХ ---
    nexttile;
    plot(f, abs(K), 'LineWidth', 2);
    xlabel('f, Гц');
    ylabel('|K_{СФ}(f)|');
    title('АЧХ согласованного фильтра');
    grid on;
    xlim([0 f_gr*1.5]);

    % --- ФЧХ ---
    nexttile;
    plot(f, angle(K), 'LineWidth', 2);
    xlabel('f, Гц');
    ylabel('\phi_{K}(f), рад');
    title('ФЧХ согласованного фильтра');
    grid on;
    xlim([0 f_gr*1.5]);

    % =====================================================================
    % ФИГУРА 2: Импульсная характеристика на узлах структурной схемы
    % =====================================================================

    T2 = obj.T2;
    tm = obj.time_mult;

    % Единица измерения времени для подписей
    if tm == 1e-6
        t_unit = 'мкс';
    elseif tm == 1e-3
        t_unit = 'мс';
    elseif tm == 1e-9
        t_unit = 'нс';
    else
        t_unit = 'с';
    end

    % Ось времени для импульсной характеристики
    N_ir = 10000;
    t_ir = linspace(-0.05*T2, 1.3*T2, N_ir);
    heav = @(t) double(t >= 0);

    % Разделяем звенья по типам
    slope_terms = terms([terms.order] == 2);
    jump_terms  = terms([terms.order] == 1);
    n_slope = length(slope_terms);
    n_jump  = length(jump_terms);

    % --- Имена узлов (та же логика, что в drawStructuralDiagram) ---
    ni = 1;
    name_input = sprintf('u_{%d}', ni); ni = ni + 1;
    name_int1  = sprintf('u_{%d}', ni); ni = ni + 1;
    if n_slope > 0
        name_int2 = sprintf('u_{%d}', ni); ni = ni + 1;
    end
    name_slopes = cell(1, n_slope);
    for k = 1:n_slope
        name_slopes{k} = sprintf('u_{%d}', ni); ni = ni + 1;
    end
    name_jumps = cell(1, n_jump);
    for k = 1:n_jump
        name_jumps{k} = sprintf('u_{%d}', ni); ni = ni + 1;
    end
    name_output = sprintf('u_{%d}', ni);

    % --- Считаем сигналы на каждом узле ---

    % После 1-го интегратора → 1(t)
    v_int1 = heav(t_ir);

    % После 2-го интегратора → t·1(t)
    v_int2 = t_ir .* heav(t_ir);

    % Выходы звеньев наклонов
    v_slope = zeros(n_slope, N_ir);
    for k = 1:n_slope
        tau = slope_terms(k).delay;
        c   = slope_terms(k).coeff;
        v_slope(k,:) = c .* (t_ir - tau) .* heav(t_ir - tau);
    end

    % Выходы звеньев скачков
    v_jump = zeros(n_jump, N_ir);
    for k = 1:n_jump
        tau = jump_terms(k).delay;
        c   = jump_terms(k).coeff;
        v_jump(k,:) = c .* heav(t_ir - tau);
    end

    % Суммарный выход
    v_output = sum(v_slope, 1) + sum(v_jump, 1);

    % Ожидаемый результат: h_S(t) = A·u(T2 - t)
    sel = obj.selectedSignal;
    t_sig = obj.time;
    u_sig = obj.u(sel, :);
    v_expected = obj.A .* interp1(t_sig, u_sig, T2 - t_ir, 'linear', 0);

    % --- Определяем количество subplots ---
    n_plots = 2 + (n_slope > 0) + n_slope + n_jump + 1;
    n_cols = 2;
    n_rows = ceil(n_plots / n_cols);

    figure('Name', 'Импульсная характеристика СФ (\delta на входе)', ...
           'NumberTitle', 'off', 'Color', 'w', ...
           'Position', [50 50 900 max(400, 200*n_rows)]);

    t_disp = t_ir / tm;   % ось времени в отображаемых единицах
    xl = [-0.05*T2/tm, 1.3*T2/tm];

    plot_idx = 0;

    % --- u_1: δ(t) на входе ---
    plot_idx = plot_idx + 1;
    subplot(n_rows, n_cols, plot_idx);
    hold on;
    defcolor = [0 0.4470 0.7410];
    stem(0/tm, 1, '^', 'filled', 'Color', defcolor, 'LineWidth', 2, ...
        'MarkerSize', 10, 'MarkerFaceColor', defcolor);
    text(0/tm, 1, '  \delta(t)', 'FontSize', 9, 'FontWeight', 'bold', ...
        'Color', defcolor);
    xlim(xl); ylim([-0.1 1.1]);
    xlabel(['t, ' t_unit]); ylabel('В')
    title([name_input ': \delta(t)  (вход)'], 'Interpreter', 'tex');
    grid on;

    % --- u_2: после 1-го интегратора → 1(t) ---
    plot_idx = plot_idx + 1;
    subplot(n_rows, n_cols, plot_idx);
    plot(t_disp, v_int1, 'LineWidth', 2);
    xlim(xl); addYPadding();
    xlabel(['t, ' t_unit]); ylabel('В');
    title([name_int1 ': 1(t)  (после 1-го интегратора)'], 'Interpreter', 'tex');
    grid on;

    % --- u_3: после 2-го интегратора → t·1(t) ---
    if n_slope > 0
        plot_idx = plot_idx + 1;
        subplot(n_rows, n_cols, plot_idx);
        plot(t_disp, v_int2/tm, 'LineWidth', 2);
        xlim(xl); addYPadding();
        xlabel(['t, ' t_unit]);
        title([name_int2 ': t \cdot 1(t)  (после 2-го интегратора)'], 'Interpreter', 'tex');
        grid on;
    end

    % --- Звенья наклонов ---
    for k = 1:n_slope
        plot_idx = plot_idx + 1;
        subplot(n_rows, n_cols, plot_idx);
        plot(t_disp, v_slope(k,:), 'LineWidth', 2);
        xlim(xl); addYPadding();
        xlabel(['t, ' t_unit]); ylabel('В');

        tau_disp = slope_terms(k).delay / tm;
        if abs(slope_terms(k).delay) < 1e-15
            ttl = sprintf('%s: наклон (\\tau=0)', name_slopes{k});
        else
            ttl = sprintf('%s: наклон (\\tau=%.3g %s)', name_slopes{k}, tau_disp, t_unit);
        end
        title(ttl, 'Interpreter', 'tex');
        grid on;
    end

    % --- Звенья скачков ---
    for k = 1:n_jump
        plot_idx = plot_idx + 1;
        subplot(n_rows, n_cols, plot_idx);
        plot(t_disp, v_jump(k,:), 'LineWidth', 2);
        xlim(xl); addYPadding();
        xlabel(['t, ' t_unit]); ylabel('В');

        tau_disp = jump_terms(k).delay / tm;
        if abs(jump_terms(k).delay) < 1e-15
            ttl = sprintf('%s: скачок (\\tau=0)', name_jumps{k});
        else
            ttl = sprintf('%s: скачок (\\tau=%.3g %s)', name_jumps{k}, tau_disp, t_unit);
        end
        title(ttl, 'Interpreter', 'tex');
        grid on;
    end

    % --- Суммарный выход + сравнение ---
    plot_idx = plot_idx + 1;
    subplot(n_rows, n_cols, plot_idx);
    plot(t_disp, v_output, 'LineWidth', 2);
    hold on;
    plot(t_disp, v_expected, 'r--', 'LineWidth', 1.5);
    xlim(xl); addYPadding();
    xlabel(['t, ' t_unit]); ylabel('В');
    title([name_output ': h_{СФ}(t) = A \cdot u(T_2 - t)  (выход)'], 'Interpreter', 'tex');
    legend('Сумма звеньев', 'A \cdot u(T_2 - t)', 'Location', 'best');
    grid on;
end

function addYPadding()
% Расширяет ylim на ×1.1 от текущего диапазона данных
    yl = ylim;
    dy = (yl(2) - yl(1)) * 0.1;
    if dy == 0, dy = 0.1; end
    ylim([yl(1) - dy, yl(2) + dy]);
end
