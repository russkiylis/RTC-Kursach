function p2_showSF(obj)
% P2_SHOWSF — графики АЧХ/ФЧХ и временные диаграммы узлов СФ.
%
% Временные диаграммы строятся по той же упрощенной структурной схеме,
% которую рисует p2_simplifySF(): общий первый интегратор, ветви первого
% порядка и общая ветвь второго порядка для наклонов.

    terms = obj.K_SF_simplified_terms;
    if isempty(terms)
        error('Сначала вызовите p2_simplifySF()');
    end

    % =====================================================================
    % ФИГУРА 1: АЧХ и ФЧХ согласованного фильтра
    % =====================================================================
    f = obj.cyclic_freq ./ (2*pi);
    f_mhz = f .* 1e-6;
    K = obj.K_SF;
    pos = f >= 0;

    sp_max = max(abs(obj.spectrAnalytical));
    f_gr = -f(find(abs(obj.spectrAnalytical) >= 0.1*sp_max, 1));
    f_gr_mhz = f_gr .* 1e-6;

    figure(name="АЧХ и ФЧХ согласованного фильтра", NumberTitle="off", Color='w');
    tiledlayout(2, 1);

    nexttile;
    plot(f_mhz(pos), abs(K(pos)), 'LineWidth', 2);
    xlabel('f, МГц');
    ylabel('|K_{СФ}(f)|');
    title('АЧХ согласованного фильтра');
    grid on;
    xlim([0 f_gr_mhz*1.5]);

    nexttile;
    plot(f_mhz(pos), unwrap(angle(K(pos))), 'LineWidth', 2);
    xlabel('f, МГц');
    ylabel('\phi_{K}(f), рад');
    title('ФЧХ согласованного фильтра');
    grid on;
    xlim([0 f_gr_mhz*1.5]);

    % =====================================================================
    % ФИГУРА 2: Временные диаграммы по упрощенной схеме
    % =====================================================================
    T2 = obj.T2;
    tm = obj.time_mult;
    t_unit = timeUnit(tm);

    N_ir = 10000;
    t_ir = linspace(-0.05*T2, 1.3*T2, N_ir);
    heav = @(t) double(t >= 0);

    [nodes, terminal_idx] = buildSimplifiedImpulseNodes(terms, t_ir, heav, tm);

    % Ожидаемый результат: h_СФ(t) = A*u(T2-t)
    sel = obj.selectedSignal;
    t_sig = obj.time;
    u_sig = obj.u(sel, :);
    v_expected = obj.A .* interp1(t_sig, u_sig, T2 - t_ir, 'linear', 0);

    if ~isempty(nodes)
        nodes(end).compare = v_expected;
        nodes(end).legend1 = 'Сумма ветвей';
        nodes(end).legend2 = 'A \cdot u(T_2 - t)';
    end

    t_disp = t_ir / tm;
    xl = [-0.05*T2/tm, 1.3*T2/tm];

    input_idx = 1;
    output_idx = length(nodes);
    internal_idx = 2:(output_idx-1);

    figure(name="Вход СФ (дельта-функция)", NumberTitle="off", Color='w');
    plotImpulseNode(nodes(input_idx), t_disp, xl, t_unit);

    if ~isempty(internal_idx)
        figure(name="Импульсная характеристика СФ (внутренние узлы схемы)", NumberTitle="off", Color='w');

        n_plots = length(internal_idx);
        n_cols = 2;
        n_rows = ceil(n_plots / n_cols);
        tiledlayout(n_rows, n_cols, 'TileSpacing', 'compact', 'Padding', 'compact');

        for k = internal_idx
            nexttile;
            plotImpulseNode(nodes(k), t_disp, xl, t_unit);
        end
    end

    figure(name="Выход СФ (импульсная характеристика)", NumberTitle="off", Color='w');
    plotImpulseNode(nodes(output_idx), t_disp, xl, t_unit);

    if ~isempty(terminal_idx)
        disp("Выход СФ формируется как сумма узлов:");
        names = strings(1, length(terminal_idx));
        for k = 1:length(terminal_idx)
            names(k) = string(nodes(terminal_idx(k)).name);
        end
        disp(strjoin(names, " + "));
    end
end

function plotImpulseNode(node, t_disp, xl, t_unit)
    hold on;

    if strcmp(node.kind, 'delta')
        stem(0, 1, '^', 'filled', 'LineWidth', 2, 'MarkerSize', 9);
        text(0, 1, '  \delta(t)', 'FontSize', 9, 'FontWeight', 'bold');
        ylim([-0.1 1.15]);
    else
        y = node.value .* node.scale;
        plot(t_disp, y, 'LineWidth', 2);

        if ~isempty(node.compare)
            plot(t_disp, node.compare .* node.scale, 'r--', 'LineWidth', 1.5);
            legend(node.legend1, node.legend2, 'Location', 'best');
        end
        addYPadding(y);
    end

    xlim(xl);
    xlabel(['t, ' t_unit]);
    ylabel(node.ylabel);
    title([node.name ': ' node.title], 'Interpreter', 'tex');
    grid on;
end


%% ========================================================================
%  ПОСТРОЕНИЕ СИГНАЛОВ ПО УЗЛАМ УПРОЩЕННОЙ СХЕМЫ
%  ========================================================================

function [nodes, terminal_idx] = buildSimplifiedImpulseNodes(terms, t, heav, tm)
    nodes = emptyNodeStruct();
    terminal_idx = [];

    slope_terms = terms([terms.order] == 2);
    jump_terms  = terms([terms.order] == 1);
    [slope_pair, direct_slope, delayed_slope] = findOppositeDelayPair(slope_terms);

    [nodes, ~] = addNode(nodes, 'delta', [], 1, '\delta(t)  (вход)', 'В');

    v_int1 = heav(t);
    [nodes, ~] = addNode(nodes, 'line', v_int1, 1, '1(t)  (после 1-го интегратора)', 'В');

    % Ветви первого порядка: в упрощённой схеме сначала используется общая
    % линия задержки с отводами, а затем масштабные преобразователи.
    % Поэтому на диаграммах узлы этих ветвей уже должны быть задержанными.
    for k = 1:length(jump_terms)
        term = jump_terms(k);
        c = term.coeff;
        tau = term.delay;

        if abs(tau) > 1e-15
            v_branch = c .* heav(t - tau);
            [nodes, idx_branch] = addNode(nodes, 'line', v_branch, 1, ...
                [coeffText(term) ' \cdot 1(t-' delayText(term) ')'], 'В');
        else
            v_branch = c .* v_int1;
            [nodes, idx_branch] = addNode(nodes, 'line', v_branch, 1, ...
                [coeffText(term) ' \cdot 1(t)'], 'В');
        end
        terminal_idx(end+1) = idx_branch; %#ok<AGROW>
    end

    % Ветви второго порядка: общий второй интегратор.
    if ~isempty(slope_terms)
        v_int2 = t .* heav(t);
        [nodes, ~] = addNode(nodes, 'line', v_int2, 1/tm, ...
            't \cdot 1(t)  (после 2-го интегратора)', 'В');

        if slope_pair
            c = direct_slope.coeff;
            tau = delayed_slope.delay;

            v_gain = c .* v_int2;
            [nodes, idx_direct] = addNode(nodes, 'line', v_gain, 1, ...
                [coeffText(direct_slope) ' \cdot t1(t)'], 'В');
            terminal_idx(end+1) = idx_direct; %#ok<AGROW>

            v_delay = c .* (t - tau) .* heav(t - tau);
            [nodes, ~] = addNode(nodes, 'line', v_delay, 1, ...
                [coeffText(direct_slope) ' \cdot (t-' delayText(delayed_slope) ')1(t-' delayText(delayed_slope) ')'], 'В');

            v_inv = -v_delay;
            [nodes, idx_inv] = addNode(nodes, 'line', v_inv, 1, ...
                'инверсия задержанной ветви', 'В');
            terminal_idx(end+1) = idx_inv; %#ok<AGROW>
        else
            for k = 1:length(slope_terms)
                term = slope_terms(k);
                c = term.coeff;
                tau = term.delay;

                if abs(tau) > 1e-15
                    % В универсальной упрощённой схеме ветви второго
                    % порядка также могут использовать общую линию задержки
                    % с отводами, а масштабный блок стоит после отвода.
                    v_branch = c .* (t - tau) .* heav(t - tau);
                    [nodes, idx_branch] = addNode(nodes, 'line', v_branch, 1, ...
                        [coeffText(term) ' \cdot (t-' delayText(term) ')1(t-' delayText(term) ')'], 'В');
                    terminal_idx(end+1) = idx_branch; %#ok<AGROW>
                else
                    v_branch = c .* v_int2;
                    [nodes, idx_branch] = addNode(nodes, 'line', v_branch, 1, ...
                        [coeffText(term) ' \cdot t1(t)'], 'В');
                    terminal_idx(end+1) = idx_branch; %#ok<AGROW>
                end
            end
        end
    end

    v_output = zeros(size(t));
    for k = 1:length(terminal_idx)
        v_output = v_output + nodes(terminal_idx(k)).value;
    end

    [nodes, ~] = addNode(nodes, 'line', v_output, 1, ...
        'h_{СФ}(t)=A \cdot u(T_2-t)  (выход)', 'В');
end

function nodes = emptyNodeStruct()
    nodes = struct('name', {}, 'kind', {}, 'value', {}, 'scale', {}, ...
        'title', {}, 'ylabel', {}, 'compare', {}, 'legend1', {}, 'legend2', {});
end

function [nodes, idx] = addNode(nodes, kind, value, scale, title_txt, ylabel_txt)
    idx = length(nodes) + 1;
    nodes(idx).name = sprintf('u_{%d}', idx);
    nodes(idx).kind = kind;
    nodes(idx).value = value;
    nodes(idx).scale = scale;
    nodes(idx).title = title_txt;
    nodes(idx).ylabel = ylabel_txt;
    nodes(idx).compare = [];
    nodes(idx).legend1 = '';
    nodes(idx).legend2 = '';
end

function [ok, direct_term, delayed_term] = findOppositeDelayPair(slope_terms)
    ok = false;
    direct_term = struct([]);
    delayed_term = struct([]);

    if length(slope_terms) ~= 2
        return;
    end

    coeffs = [slope_terms.coeff];
    delays = [slope_terms.delay];
    scale = max(1, max(abs(coeffs)));
    is_opposite = abs(coeffs(1) + coeffs(2)) < 1e-9 * scale;
    zero_idx = find(abs(delays) < 1e-15);

    if is_opposite && length(zero_idx) == 1
        other_idx = 3 - zero_idx;
        ok = true;
        direct_term = slope_terms(zero_idx);
        delayed_term = slope_terms(other_idx);
    end
end

function txt = coeffText(term)
    if isfield(term, 'coeff_label') && ~isempty(term.coeff_label)
        txt = term.coeff_label;
    else
        txt = gainText(term.coeff);
    end
end

function txt = delayText(term)
    if isfield(term, 'delay_label') && ~isempty(term.delay_label)
        txt = term.delay_label;
    else
        txt = sprintf('%.3g', term.delay);
    end
end

function txt = gainText(c)
    if abs(c) < 1e-15
        txt = '0';
        return;
    end

    sign_str = '';
    if c < 0
        sign_str = '-';
    end
    c = abs(c);

    if c >= 1e4 || c < 1e-2
        exp_val = floor(log10(c));
        mantissa = c / 10^exp_val;
        txt = sprintf('%s%.3g\\cdot10^{%d}', sign_str, mantissa, exp_val);
    else
        txt = sprintf('%s%.4g', sign_str, c);
    end
end

function unit = timeUnit(tm)
    if tm == 1e-6
        unit = 'мкс';
    elseif tm == 1e-3
        unit = 'мс';
    elseif tm == 1e-9
        unit = 'нс';
    else
        unit = 'с';
    end
end

function addYPadding(y)
    yl = [min(y), max(y)];
    if any(~isfinite(yl))
        ylim([-1 1]);
        return;
    end

    if abs(yl(2) - yl(1)) < 1e-15
        delta = max(0.1, abs(yl(1))*0.1);
        ylim([yl(1)-delta, yl(2)+delta]);
    else
        delta = (yl(2) - yl(1)) * 0.12;
        ylim([yl(1)-delta, yl(2)+delta]);
    end
end
