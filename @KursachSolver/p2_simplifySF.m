function p2_simplifySF(obj)
% P2_SIMPLIFYSF — упрощает ПФ СФ и строит структурные схемы.
%
% Расчетная модель остается универсальной: каждое звено СФ хранится как
% coeff * exp(-j*w*delay) / (j*w)^order. По этим звеньям строятся:
%   1) неупрощенная схема — каждое слагаемое отдельной ветвью;
%   2) упрощенная схема — общий первый интегратор, общий второй интегратор
%      для звеньев второго порядка и компактные ветви задержек.

    slopes = obj.slopes;
    jumps  = obj.jumps;
    A  = obj.A;
    T2 = obj.T2;

    terms = struct('coeff', {}, 'delay', {}, 'order', {}, 'type', {}, ...
        'coeff_label', {}, 'delay_label', {});

    % === Звенья от наклонов (порядок 2) ===
    if ~isempty(slopes.diff)
        imp_times = [slopes.time1(:)', slopes.time2(:)'];
        imp_amps  = [slopes.diff(:)', -slopes.diff(:)'];
        [unique_times, ~, idx] = unique(imp_times);
        combined_amps = accumarray(idx, imp_amps);

        for k = 1:length(combined_amps)
            if abs(combined_amps(k)) < 1e-12, continue; end
            terms(end+1).coeff = A * combined_amps(k); %#ok<AGROW>
            terms(end).delay   = T2 - unique_times(k);
            terms(end).order   = 2;
            terms(end).type    = "slope";
            terms(end).coeff_label = makeSlopeCoeffLabel(unique_times(k), slopes, obj);
            terms(end).delay_label = makeDelayLabel(unique_times(k), obj);
        end
    end

    % === Звенья от скачков (порядок 1) ===
    if ~isempty(jumps.amplitude)
        for k = 1:length(jumps.amplitude)
            if abs(jumps.amplitude(k)) < 1e-12, continue; end
            terms(end+1).coeff = -A * jumps.amplitude(k); %#ok<AGROW>
            terms(end).delay   = T2 - jumps.time(k);
            terms(end).order   = 1;
            terms(end).type    = "jump";
            terms(end).coeff_label = makeJumpCoeffLabel(jumps.time(k), obj);
            terms(end).delay_label = makeDelayLabel(jumps.time(k), obj);
        end
    end

    % === Формирование LaTeX-строки ===
    latex_str = "";
    for k = 1:length(terms)
        part = formatTerm(terms(k));
        if k == 1
            latex_str = part;
        elseif terms(k).coeff >= 0
            latex_str = latex_str + " + " + part;
        else
            latex_str = latex_str + " " + part;
        end
    end

    obj.K_SF_simplified_terms = terms;
    obj.K_SF_simplified_text  = latex_str;

    % === Вывод в консоль ===
    disp(newline);
    disp("== УПРОЩЁННАЯ ФОРМА ПФ СФ ==");
    disp("Количество звеньев: " + length(terms));
    for k = 1:length(terms)
        disp(sprintf("  Звено %d: коэфф = %.4e, задержка = %.4e с, порядок = %d (%s)", ...
            k, terms(k).coeff, terms(k).delay, terms(k).order, terms(k).type));
    end
    disp("Формула (LaTeX):");
    disp(latex_str);

    % === Структурные схемы ===
    drawUnoptimizedDiagram(terms, obj.time_mult);
    drawSimplifiedDiagram(terms, obj.time_mult);
end


%% ========================================================================
%  ФОРМАТИРОВАНИЕ
%  ========================================================================

function str = formatTerm(term)
    c = term.coeff;
    tau = term.delay;

    coeff_str = formatCoeff(c);
    if term.order == 2
        denom = "(j\omega)^2";
    else
        denom = "j\omega";
    end

    if abs(tau) < 1e-15
        str = coeff_str + "\frac{1}{" + denom + "}";
    else
        str = coeff_str + "\frac{e^{-j\omega " + sprintf("%.4g", tau) + "}}{" + denom + "}";
    end
end

function str = formatCoeff(c)
    if c >= 0
        str = sprintf("%.4g", c);
    else
        str = sprintf("- %.4g", abs(c));
    end
end

function str = formatGainLabel(coeff)
    if abs(coeff) < 1e-15
        str = '0';
        return;
    end

    sign_str = '';
    if coeff < 0
        sign_str = '-';
    end
    coeff = abs(coeff);

    if coeff >= 1e4 || coeff < 1e-2
        exp_val = floor(log10(coeff));
        mantissa = coeff / 10^exp_val;
        str = sprintf('%s%.3g\\cdot10^{%d}', sign_str, mantissa, exp_val);
    else
        str = sprintf('%s%.4g', sign_str, coeff);
    end
end

function str = termCoeffLabel(term)
    if isfield(term, 'coeff_label') && ~isempty(term.coeff_label)
        str = term.coeff_label;
    else
        str = formatGainLabel(term.coeff);
    end
end

function str = termDelayLabel(term, time_mult)
    if isfield(term, 'delay_label') && ~isempty(term.delay_label)
        str = term.delay_label;
    else
        str = formatDelayLabel(term.delay, time_mult);
    end
end

function str = formatDelayLabel(tau, time_mult)
    tau_display = tau / time_mult;
    if time_mult == 1e-6
        unit = 'мкс';
    elseif time_mult == 1e-3
        unit = 'мс';
    elseif time_mult == 1e-9
        unit = 'нс';
    else
        unit = 'с';
        tau_display = tau;
    end

    if abs(tau_display - round(tau_display)) < 1e-3
        str = sprintf('%.0f %s', tau_display, unit);
    else
        str = sprintf('%.3g %s', tau_display, unit);
    end
end

function label = makeJumpCoeffLabel(t0, obj)
    T1 = obj.T(obj.selectedSignal);
    T2 = obj.T2;

    if isClose(t0, 0)
        label = '-A U_1';
    elseif isClose(t0, T1)
        label = 'A(U_2-U_3)';
    elseif isClose(t0, T2)
        label = 'A U_4';
    else
        label = '-A \Delta U';
    end
end

function label = makeSlopeCoeffLabel(t0, slopes, obj)
    parts = {};

    for i = 1:length(slopes.diff)
        base = slopeDiffLabel(slopes.time1(i), slopes.time2(i), obj);
        if isClose(t0, slopes.time1(i))
            parts{end+1} = base; %#ok<AGROW>
        end
        if isClose(t0, slopes.time2(i))
            parts{end+1} = negateLabel(base); %#ok<AGROW>
        end
    end

    expr = joinSignedLabels(parts);
    label = prependA(expr);
end

function label = slopeDiffLabel(t_start, t_end, obj)
    T1 = obj.T(obj.selectedSignal);
    T2 = obj.T2;

    if isClose(t_start, 0) && isClose(t_end, T1)
        if obj.U1 == 0
            label = 'U_2/T_1';
        elseif obj.U2 == 0
            label = '-U_1/T_1';
        else
            label = '(U_2-U_1)/T_1';
        end
    elseif isClose(t_start, T1) && isClose(t_end, T2)
        if obj.U4 == 0
            label = '-U_3/(T_2-T_1)';
        elseif obj.U3 == 0
            label = 'U_4/(T_2-T_1)';
        else
            label = '(U_4-U_3)/(T_2-T_1)';
        end
    else
        label = 'd_k';
    end
end

function label = makeDelayLabel(t0, obj)
    T1 = obj.T(obj.selectedSignal);
    T2 = obj.T2;

    if isClose(t0, 0)
        label = 'T_2';
    elseif isClose(t0, T1)
        label = 'T_2-T_1';
    elseif isClose(t0, T2)
        label = '0';
    else
        label = 'T_2-t_k';
    end
end

function out = negateLabel(label)
    if startsWith(label, '-')
        out = extractAfter(label, 1);
        out = char(out);
    else
        out = ['-' label];
    end
end

function expr = joinSignedLabels(parts)
    if isempty(parts)
        expr = '0';
        return;
    end

    expr = '';
    for i = 1:length(parts)
        part = parts{i};
        is_neg = startsWith(part, '-');
        if is_neg
            part = char(extractAfter(part, 1));
        end

        if i == 1
            if is_neg
                expr = ['-' part];
            else
                expr = part;
            end
        elseif is_neg
            expr = [expr ' - ' part]; %#ok<AGROW>
        else
            expr = [expr ' + ' part]; %#ok<AGROW>
        end
    end
end

function label = prependA(expr)
    if strcmp(expr, '0')
        label = '0';
    elseif startsWith(expr, '-')
        label = ['-A ' char(extractAfter(expr, 1))];
    elseif contains(expr, ' + ') || contains(expr, ' - ')
        label = ['A(' expr ')'];
    else
        label = ['A ' expr];
    end
end

function tf = isClose(a, b)
    tf = abs(a - b) < 1e-12;
end


%% ========================================================================
%  НЕУПРОЩЕННАЯ СХЕМА
%  ========================================================================

function drawUnoptimizedDiagram(terms, time_mult)
    if isempty(terms), return; end

    jump_terms = terms([terms.order] == 1);
    slope_terms = terms([terms.order] == 2);
    terms = [jump_terms, slope_terms];

    n = length(terms);
    y_step = 1.6;
    y_vals = ((n-1)/2:-1:-(n-1)/2) * y_step;

    fig = figure(name="Неупрощённая структурная схема СФ", NumberTitle="off", color='w');
    ax = axes('Parent', fig, 'Position', [0.02 0.05 0.96 0.9]);
    hold(ax, 'on');
    axis(ax, 'off');
    axis(ax, 'equal');

    x_in = 0;
    x_bus = 1.0;
    x_amp = 2.0;
    x_int1 = 3.35;
    x_int2 = 4.6;
    x_delay = 6.15;
    x_join = 8.2;
    x_sum = 9.15;
    y_mid = 0;

    drawArrowLine(ax, x_in, y_mid, x_bus, y_mid);
    text(ax, x_in - 0.15, y_mid, 'Вход', 'FontSize', 12, ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
    drawNode(ax, x_bus, y_mid);
    line(ax, [x_bus x_bus], [min(y_vals) max(y_vals)], 'Color', 'k', 'LineWidth', 1.5);

    for i = 1:n
        y = y_vals(i);
        x = x_bus;

        drawArrowLine(ax, x, y, x_amp - 0.55, y);
        drawAmplifier(ax, x_amp, y, termCoeffLabel(terms(i)));
        x = x_amp + 0.65;

        drawArrowLine(ax, x, y, x_int1 - 0.35, y);
        drawIntegrator(ax, x_int1, y);
        x = x_int1 + 0.35;

        if terms(i).order == 2
            drawArrowLine(ax, x, y, x_int2 - 0.35, y);
            drawIntegrator(ax, x_int2, y);
            x = x_int2 + 0.35;
        end

        if abs(terms(i).delay) > 1e-15
            drawArrowLine(ax, x, y, x_delay - 0.45, y);
            drawDelay(ax, x_delay, y, termDelayLabel(terms(i), time_mult));
            x = x_delay + 0.45;
        end

        drawArrowLine(ax, x, y, x_join, y);
        line(ax, [x_join x_sum-0.35], [y y_mid], 'Color', 'k', 'LineWidth', 1.5);
    end

    drawSummator(ax, x_sum, y_mid);
    drawArrowLine(ax, x_sum + 0.45, y_mid, x_sum + 1.25, y_mid);
    text(ax, x_sum + 1.4, y_mid, 'Выход', 'FontSize', 12, ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');

    axis(ax, 'tight');
    padAxes(ax, 0.7);
end


%% ========================================================================
%  УПРОЩЕННАЯ СХЕМА
%  ========================================================================

function drawSimplifiedDiagram(terms, time_mult)
    if isempty(terms), return; end

    slope_terms = terms([terms.order] == 2);
    jump_terms  = terms([terms.order] == 1);

    [slope_pair, direct_slope, delayed_slope] = findOppositeDelayPair(slope_terms);

    n_jump = length(jump_terms);
    n_slope_lines = max(1, length(slope_terms));
    if slope_pair
        n_slope_lines = 2; % прямой и задержанный выход после общего усилителя
    end

    y_jump = [];
    if n_jump > 0
        y_jump = linspace(2.3, 0.9, n_jump);
    end
    y_slope_center = -1.6;
    y_slope_top = y_slope_center + 0.7;
    y_slope_bottom = y_slope_center - 0.7;

    fig = figure(name="Упрощённая структурная схема СФ", NumberTitle="off", color='w');
    ax = axes('Parent', fig, 'Position', [0.02 0.05 0.96 0.9]);
    hold(ax, 'on');
    axis(ax, 'off');
    axis(ax, 'equal');

    x_in = 0;
    x_int1 = 1.5;
    x_split = 2.5;
    x_jump_amp = 3.6;
    x_jump_delay = 5.0;
    x_int2 = 3.5;
    x_slope_amp = 4.8;
    x_slope_delay = 6.3;
    x_slope_inv = 7.45;
    x_join = 8.5;
    x_sum = 9.35;
    y_main = 0;

    node_id = 1;
    drawArrowLine(ax, x_in, y_main, x_int1 - 0.35, y_main);
    text(ax, x_in - 0.15, y_main, 'Вход', 'FontSize', 12, ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
    drawNodeLabel(ax, (x_in + x_int1 - 0.35)/2, y_main, node_id); node_id = node_id + 1;

    drawIntegrator(ax, x_int1, y_main);
    drawArrowLine(ax, x_int1 + 0.35, y_main, x_split, y_main);
    drawNode(ax, x_split, y_main);
    drawNodeLabel(ax, (x_int1 + 0.35 + x_split)/2, y_main, node_id); node_id = node_id + 1;

    if isempty(slope_terms)
        y_all = y_jump;
    else
        y_all = [y_jump, y_slope_center];
    end
    line(ax, [x_split x_split], [min(y_all)-0.2 max(y_all)+0.2], 'Color', 'k', 'LineWidth', 1.5);

    % Ветви первого порядка (скачки)
    for i = 1:n_jump
        y = y_jump(i);
        drawArrowLine(ax, x_split, y, x_jump_amp - 0.55, y);
        drawAmplifier(ax, x_jump_amp, y, termCoeffLabel(jump_terms(i)));
        drawNodeLabel(ax, x_jump_amp + 0.72, y, node_id); node_id = node_id + 1;

        if abs(jump_terms(i).delay) > 1e-15
            drawArrowLine(ax, x_jump_amp + 0.65, y, x_jump_delay - 0.45, y);
            drawDelay(ax, x_jump_delay, y, termDelayLabel(jump_terms(i), time_mult));
            drawArrowLine(ax, x_jump_delay + 0.45, y, x_join, y);
            drawNodeLabel(ax, x_jump_delay + 0.65, y, node_id); node_id = node_id + 1;
        else
            drawArrowLine(ax, x_jump_amp + 0.65, y, x_join, y);
        end
        line(ax, [x_join x_sum-0.35], [y 0], 'Color', 'k', 'LineWidth', 1.5);
    end

    % Ветви второго порядка (наклоны)
    if ~isempty(slope_terms)
        drawArrowLine(ax, x_split, y_slope_center, x_int2 - 0.35, y_slope_center);
        drawIntegrator(ax, x_int2, y_slope_center);
        drawNodeLabel(ax, x_int2 + 0.55, y_slope_center, node_id); node_id = node_id + 1;

        if slope_pair
            drawArrowLine(ax, x_int2 + 0.35, y_slope_center, x_slope_amp - 0.55, y_slope_center);
            drawAmplifier(ax, x_slope_amp, y_slope_center, termCoeffLabel(direct_slope));
            drawNodeLabel(ax, x_slope_amp + 0.72, y_slope_center, node_id); node_id = node_id + 1;

            x_after_amp = x_slope_amp + 0.65;
            line(ax, [x_after_amp x_after_amp], [y_slope_top y_slope_bottom], 'Color', 'k', 'LineWidth', 1.5);

            % Прямая ветвь
            drawArrowLine(ax, x_after_amp, y_slope_bottom, x_join, y_slope_bottom);
            line(ax, [x_join x_sum-0.35], [y_slope_bottom 0], 'Color', 'k', 'LineWidth', 1.5);

            % Задержанная ветвь с инверсией
            drawArrowLine(ax, x_after_amp, y_slope_top, x_slope_delay - 0.45, y_slope_top);
            drawDelay(ax, x_slope_delay, y_slope_top, termDelayLabel(delayed_slope, time_mult));
            drawNodeLabel(ax, x_slope_delay + 0.62, y_slope_top, node_id); node_id = node_id + 1;
            drawArrowLine(ax, x_slope_delay + 0.45, y_slope_top, x_slope_inv - 0.55, y_slope_top);
            drawAmplifier(ax, x_slope_inv, y_slope_top, '-1');
            drawArrowLine(ax, x_slope_inv + 0.65, y_slope_top, x_join, y_slope_top);
            drawNodeLabel(ax, x_slope_inv + 0.82, y_slope_top, node_id); node_id = node_id + 1;
            line(ax, [x_join x_sum-0.35], [y_slope_top 0], 'Color', 'k', 'LineWidth', 1.5);
        else
            y_branch = linspace(y_slope_center + (n_slope_lines-1)*0.65, ...
                                y_slope_center - (n_slope_lines-1)*0.65, n_slope_lines);
            line(ax, [x_int2+0.35 x_int2+0.35], [min(y_branch) max(y_branch)], 'Color', 'k', 'LineWidth', 1.5);

            for i = 1:length(slope_terms)
                y = y_branch(i);
                drawArrowLine(ax, x_int2 + 0.35, y, x_slope_amp - 0.55, y);
                drawAmplifier(ax, x_slope_amp, y, termCoeffLabel(slope_terms(i)));
                drawNodeLabel(ax, x_slope_amp + 0.72, y, node_id); node_id = node_id + 1;

                if abs(slope_terms(i).delay) > 1e-15
                    drawArrowLine(ax, x_slope_amp + 0.65, y, x_slope_delay - 0.45, y);
                    drawDelay(ax, x_slope_delay, y, termDelayLabel(slope_terms(i), time_mult));
                    drawArrowLine(ax, x_slope_delay + 0.45, y, x_join, y);
                    drawNodeLabel(ax, x_slope_delay + 0.65, y, node_id); node_id = node_id + 1;
                else
                    drawArrowLine(ax, x_slope_amp + 0.65, y, x_join, y);
                end
                line(ax, [x_join x_sum-0.35], [y 0], 'Color', 'k', 'LineWidth', 1.5);
            end
        end
    end

    drawSummator(ax, x_sum, 0);
    drawArrowLine(ax, x_sum + 0.45, 0, x_sum + 1.25, 0);
    drawNodeLabel(ax, x_sum + 0.85, 0, node_id);
    text(ax, x_sum + 1.4, 0, 'Выход', 'FontSize', 12, ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');

    axis(ax, 'tight');
    padAxes(ax, 0.8);
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


%% ========================================================================
%  ПРИМИТИВЫ РИСОВАНИЯ
%  ========================================================================

function drawIntegrator(ax, x, y)
    rectangle(ax, 'Position', [x-0.35, y-0.35, 0.7, 0.7], ...
        'LineWidth', 1.5, 'FaceColor', 'w', 'EdgeColor', 'k');
    text(ax, x, y, '\int', 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', 'FontSize', 18, 'Interpreter', 'tex');
end

function drawDelay(ax, x, y, label)
    rectangle(ax, 'Position', [x-0.45, y-0.35, 0.9, 0.7], ...
        'LineWidth', 1.5, 'FaceColor', 'w', 'EdgeColor', 'k');
    text(ax, x, y, label, 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', 'FontSize', 10, 'Interpreter', 'tex');
end

function drawAmplifier(ax, x, y, label)
    px = [x-0.55, x-0.55, x+0.65];
    py = [y-0.45, y+0.45, y];
    patch(ax, px, py, 'w', 'EdgeColor', 'k', 'LineWidth', 1.5);
    text(ax, x, y+0.6, label, 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', 'FontSize', 10, 'Interpreter', 'tex');
end

function drawSummator(ax, x, y)
    r = 0.42;
    theta = linspace(0, 2*pi, 80);
    patch(ax, x + r*cos(theta), y + r*sin(theta), 'w', ...
        'EdgeColor', 'k', 'LineWidth', 1.5);
    text(ax, x, y, '\Sigma', 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', 'FontSize', 16, 'FontWeight', 'bold');
end

function drawNode(ax, x, y)
    plot(ax, x, y, 'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'k');
end

function drawNodeLabel(ax, x, y, idx)
    plot(ax, x, y, 'ko', 'MarkerSize', 4.5, 'MarkerFaceColor', 'k');
    text(ax, x, y - 0.32, sprintf('u_{%d}', idx), ...
        'FontSize', 10, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'Interpreter', 'tex', 'Color', [0.1 0.1 0.8]);
end

function drawArrowLine(ax, x1, y1, x2, y2)
    line(ax, [x1 x2], [y1 y2], 'Color', 'k', 'LineWidth', 1.5);
    dx = x2 - x1;
    dy = y2 - y1;
    len = sqrt(dx^2 + dy^2);
    if len < 1e-12
        return;
    end
    ux = dx / len;
    uy = dy / len;
    arrow_sz = 0.12;
    px = x2 - arrow_sz*ux + arrow_sz*0.45*uy;
    py = y2 - arrow_sz*uy - arrow_sz*0.45*ux;
    qx = x2 - arrow_sz*ux - arrow_sz*0.45*uy;
    qy = y2 - arrow_sz*uy + arrow_sz*0.45*ux;
    patch(ax, [x2 px qx], [y2 py qy], 'k', 'EdgeColor', 'k');
end

function padAxes(ax, pad)
    xl = xlim(ax);
    yl = ylim(ax);
    xlim(ax, [xl(1)-pad, xl(2)+pad]);
    ylim(ax, [yl(1)-pad, yl(2)+pad]);
end
