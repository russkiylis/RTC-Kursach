function p2_simplifySF(obj)
% P2_SIMPLIFYSF — Упрощает формулу ПФ СФ и рисует структурную схему.
%
% Каждое звено ПФ СФ имеет вид:
%   A * coeff * e^{jωt_k} / (-jω)^n * e^{-jωT2}
%
% После упрощения:
%   Для наклонов (n=2): A*c_k * e^{-jω(T2-t_k)} / (jω)²
%   Для скачков  (n=1): -A*b_k * e^{-jω(T2-t_k)} / (jω)

    slopes = obj.slopes;
    jumps  = obj.jumps;
    A  = obj.A;
    T2 = obj.T2;

    terms = struct('coeff', {}, 'delay', {}, 'order', {}, 'type', {});

    % === Звенья от наклонов (порядок 2) ===
    if ~isempty(slopes.diff)
        imp_times = [slopes.time1(:)', slopes.time2(:)'];
        imp_amps  = [slopes.diff(:)', -slopes.diff(:)'];
        [unique_times, ~, idx] = unique(imp_times);
        combined_amps = accumarray(idx, imp_amps);

        for k = 1:length(combined_amps)
            if abs(combined_amps(k)) < 1e-12, continue; end
            terms(end+1).coeff = A * combined_amps(k);  %#ok<AGROW>
            terms(end).delay   = T2 - unique_times(k);
            terms(end).order   = 2;
            terms(end).type    = "slope";
        end
    end

    % === Звенья от скачков (порядок 1) ===
    if ~isempty(jumps.amplitude)
        for k = 1:length(jumps.amplitude)
            if abs(jumps.amplitude(k)) < 1e-12, continue; end
            terms(end+1).coeff = -A * jumps.amplitude(k);  %#ok<AGROW>
            terms(end).delay   = T2 - jumps.time(k);
            terms(end).order   = 1;
            terms(end).type    = "jump";
        end
    end

    % === Формирование LaTeX-строки ===
    latex_str = "";
    for k = 1:length(terms)
        part = formatTerm(terms(k), obj.time_mult);
        if k == 1
            latex_str = part;
        else
            if terms(k).coeff >= 0
                latex_str = latex_str + " + " + part;
            else
                latex_str = latex_str + " " + part;
            end
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

    % === Структурная схема ===
    drawStructuralDiagram(terms, obj.time_mult);
end


%% ========================================================================
%  ЛОКАЛЬНЫЕ ФУНКЦИИ
%  ========================================================================

function str = formatTerm(term, time_mult)
% Формирует LaTeX-строку для одного упрощённого звена.
    c = term.coeff;
    tau = term.delay;
    ord = term.order;

    % Коэффициент — используем красивую запись
    coeff_str = formatCoeff(c);

    % Знаменатель
    if ord == 2
        denom = "(j\omega)^2";
    else
        denom = "j\omega";
    end

    % Числитель (экспонента задержки)
    if abs(tau) < 1e-15
        % Задержка = 0 → e^0 = 1, не пишем экспоненту
        str = coeff_str + "\frac{1}{" + denom + "}";
    else
        tau_str = formatDelay(tau, time_mult);
        str = coeff_str + "\frac{e^{-j\omega " + tau_str + "}}{" + denom + "}";
    end
end

function str = formatCoeff(c)
% Красивая запись коэффициента (например, -10^6 A вместо -71429.2652*1000000)
    if c >= 0
        str = sprintf("%.4g", c);
    else
        str = sprintf("- %.4g", abs(c));
    end
end

function str = formatDelay(tau, time_mult)
% Красивая запись задержки в секундах
    str = sprintf("%.4g", tau);
end


%% ========================================================================
%  РИСОВАНИЕ СТРУКТУРНОЙ СХЕМЫ
%  ========================================================================

function drawStructuralDiagram(terms, time_mult)

    slope_idx = find([terms.order] == 2);
    jump_idx  = find([terms.order] == 1);
    n_slope = length(slope_idx);
    n_jump  = length(jump_idx);
    n_total = n_slope + n_jump;

    if n_total == 0, return; end

    % --- Имена узлов (соответствуют графикам импульсной характеристики) ---
    ni = 1;
    name_input = sprintf('u_{%d}', ni); ni = ni + 1;
    name_int1  = sprintf('u_{%d}', ni); ni = ni + 1;
    if n_slope > 0
        name_int2 = sprintf('u_{%d}', ni); ni = ni + 1;
    end
    name_slopes = cell(1, n_slope);
    for i = 1:n_slope
        name_slopes{i} = sprintf('u_{%d}', ni); ni = ni + 1;
    end
    name_jumps = cell(1, n_jump);
    for i = 1:n_jump
        name_jumps{i} = sprintf('u_{%d}', ni); ni = ni + 1;
    end
    name_output = sprintf('u_{%d}', ni);

    % --- Размеры блоков и отступы ---
    bw = 1.6;   % ширина блока
    bh = 0.7;   % высота блока
    gap_x = 0.6; % горизонтальный зазор между блоками
    gap_y = 1.2; % вертикальный зазор между ветвями
    arrow_sz = 0.12; % размер стрелки

    % --- Определяем X-координаты колонок ---
    x_input = 0;
    x_int1  = x_input + bw/2 + gap_x + bw/2;  % 1-й интегратор
    x_nodeA = x_int1 + bw/2 + gap_x;           % точка разветвления A

    % Для наклонов: 2-й интегратор
    x_int2  = x_nodeA + gap_x + bw/2 + 0.5;

    % Усилители и задержки — общие колонки для всех ветвей
    if n_slope > 0
        x_amp = x_int2 + bw/2 + gap_x + bw/2;
    else
        x_amp = x_nodeA + gap_x + bw/2 + 0.5;
    end
    x_delay = x_amp + bw/2 + gap_x + bw/2;
    x_sum   = x_delay + bw/2 + gap_x + 0.4;
    x_out   = x_sum + 0.4 + gap_x + 0.5;

    % --- Определяем Y-координаты ветвей ---
    % Наклоны — сверху, скачки — снизу
    y_mid = 0;
    all_y = [];
    slope_y = [];
    jump_y  = [];
    for i = 1:n_slope
        slope_y(i) = y_mid + (n_slope - i) * gap_y + (n_jump > 0) * gap_y/2;
    end
    for i = 1:n_jump
        jump_y(i) = y_mid - (i) * gap_y + (n_slope == 0) * gap_y * (n_jump - i);
        if n_slope == 0
            jump_y(i) = y_mid + (n_jump - i) * gap_y;
        end
    end

    % Центрируем по вертикали
    all_y_vals = [slope_y, jump_y];
    y_center = mean(all_y_vals);
    slope_y = slope_y - y_center;
    jump_y  = jump_y - y_center;
    y_mid   = y_mid - y_center;

    % Позиция основной шины (вход - инт1 - nodeA)
    if n_slope > 0 && n_jump > 0
        y_spine = (min(slope_y) + max(jump_y)) / 2;
    elseif n_slope > 0
        y_spine = mean(slope_y);
    else
        y_spine = mean(jump_y);
    end

    % --- Создаём фигуру ---
    fig = figure('Name', 'Структурная схема СФ', 'NumberTitle', 'off', ...
                 'Color', 'w', 'Position', [100 200 1200 max(300, 150*n_total)]);
    ax = axes(fig, 'Position', [0.02 0.05 0.96 0.9]);
    hold(ax, 'on');
    axis(ax, 'off');
    axis(ax, 'equal');

    % --- Рисуем основной путь: Вход → 1/jω → nodeA ---
    drawArrowLine(ax, x_input, y_spine, x_int1 - bw/2, y_spine, arrow_sz);
    drawBlock(ax, x_int1, y_spine, bw, bh, '1/j\omega');
    drawArrowLine(ax, x_int1 + bw/2, y_spine, x_nodeA, y_spine, arrow_sz);
    drawNode(ax, x_nodeA, y_spine);
    text(ax, x_input - 0.3, y_spine, 'Вход', 'FontSize', 11, ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');

    % Точки-метки узлов u_1 (вход) и u_2 (после 1-го интегратора)
    x_u1 = (x_input + x_int1 - bw/2) / 2;
    drawNodeLabel(ax, x_u1, y_spine, name_input);
    x_u2 = (x_int1 + bw/2 + x_nodeA) / 2;
    drawNodeLabel(ax, x_u2, y_spine, name_int1);

    % --- Ветвь наклонов: nodeA → 2-й интегратор → nodeB → ветви ---
    if n_slope > 0
        y_slope_spine = mean(slope_y);

        % Вертикальная линия от nodeA к slope_spine
        if abs(y_spine - y_slope_spine) > 0.01
            line(ax, [x_nodeA x_nodeA], sort([y_spine, y_slope_spine]), ...
                'Color', 'k', 'LineWidth', 1.5);
        end

        % Горизонт к 2-му интегратору
        drawArrowLine(ax, x_nodeA, y_slope_spine, x_int2 - bw/2, y_slope_spine, arrow_sz);
        drawBlock(ax, x_int2, y_slope_spine, bw, bh, '1/j\omega');

        x_nodeB = x_int2 + bw/2 + gap_x * 0.5;
        drawArrowLine(ax, x_int2 + bw/2, y_slope_spine, x_nodeB, y_slope_spine, 0);
        drawNode(ax, x_nodeB, y_slope_spine);

        % Точка-метка u_3 (после 2-го интегратора)
        drawNodeLabel(ax, x_nodeB, y_slope_spine, name_int2);

        % Вертикальная линия от nodeB к ветвям
        if n_slope > 1
            line(ax, [x_nodeB x_nodeB], [min(slope_y), max(slope_y)], ...
                'Color', 'k', 'LineWidth', 1.5);
        end

        % Ветви наклонов
        for i = 1:n_slope
            k = slope_idx(i);
            y = slope_y(i);

            % Горизонтальная линия от nodeB к усилителю
            drawArrowLine(ax, x_nodeB, y, x_amp - bw/2, y, arrow_sz);

            % Усилитель
            amp_label = formatGainLabel(terms(k).coeff);
            drawBlock(ax, x_amp, y, bw, bh, amp_label);

            if abs(terms(k).delay) > 1e-15
                % Задержка
                delay_label = formatDelayLabel(terms(k).delay, time_mult);
                drawArrowLine(ax, x_amp + bw/2, y, x_delay - bw/2, y, arrow_sz);
                drawBlock(ax, x_delay, y, bw, bh, delay_label);
                drawArrowLine(ax, x_delay + bw/2, y, x_sum, y, arrow_sz);
                % Точка-метка на выходе звена
                drawNodeLabel(ax, x_delay + bw/2 + 0.15, y, name_slopes{i});
            else
                % Без задержки — прямо к сумматору
                drawArrowLine(ax, x_amp + bw/2, y, x_sum, y, arrow_sz);
                drawNodeLabel(ax, x_amp + bw/2 + 0.15, y, name_slopes{i});
            end
        end
    end

    % --- Ветвь скачков: nodeA → ветви (без 2-го интегратора) ---
    if n_jump > 0
        % Если есть наклоны, рисуем вертикальную линию от nodeA вниз к скачкам
        if n_slope > 0
            y_fork_top = min(y_spine, min(jump_y));
            y_fork_bot = max(y_spine, max(jump_y));
            % Линия уже частично проведена к slope_spine, добавим к jump
            line(ax, [x_nodeA x_nodeA], sort([y_spine, min(jump_y)]), ...
                'Color', 'k', 'LineWidth', 1.5);
        end

        if n_jump > 1
            line(ax, [x_nodeA x_nodeA], [min(jump_y), max(jump_y)], ...
                'Color', 'k', 'LineWidth', 1.5);
        end

        % X-координата усилителя для скачков (без 2-го интегратора)
        if n_slope > 0
            x_amp_j = x_amp;   % выравниваем с наклонами
        else
            x_amp_j = x_amp;
        end

        for i = 1:n_jump
            k = jump_idx(i);
            y = jump_y(i);

            drawArrowLine(ax, x_nodeA, y, x_amp_j - bw/2, y, arrow_sz);

            amp_label = formatGainLabel(terms(k).coeff);
            drawBlock(ax, x_amp_j, y, bw, bh, amp_label);

            if abs(terms(k).delay) > 1e-15
                delay_label = formatDelayLabel(terms(k).delay, time_mult);
                drawArrowLine(ax, x_amp_j + bw/2, y, x_delay - bw/2, y, arrow_sz);
                drawBlock(ax, x_delay, y, bw, bh, delay_label);
                drawArrowLine(ax, x_delay + bw/2, y, x_sum, y, arrow_sz);
                drawNodeLabel(ax, x_delay + bw/2 + 0.15, y, name_jumps{i});
            else
                drawArrowLine(ax, x_amp_j + bw/2, y, x_sum, y, arrow_sz);
                drawNodeLabel(ax, x_amp_j + bw/2 + 0.15, y, name_jumps{i});
            end
        end
    end

    % --- Сумматор ---
    sum_y = mean([slope_y, jump_y]);
    drawSummator(ax, x_sum, sum_y, 0.35);

    % Линии от всех ветвей к сумматору (вертикальная сборная шина)
    all_branch_y = [slope_y, jump_y];
    if length(all_branch_y) > 1
        line(ax, [x_sum x_sum], [min(all_branch_y), max(all_branch_y)], ...
            'Color', 'k', 'LineWidth', 1.5);
    end

    % --- Выход ---
    drawArrowLine(ax, x_sum + 0.35, sum_y, x_out, sum_y, arrow_sz);
    text(ax, x_out + 0.15, sum_y, 'Выход', 'FontSize', 11, ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
    drawNodeLabel(ax, (x_sum + 0.35 + x_out) / 2, sum_y, name_output);

    % Подгоняем оси
    axis(ax, 'tight');
    xl = xlim(ax); yl = ylim(ax);
    xlim(ax, [xl(1)-1, xl(2)+1]);
    ylim(ax, [yl(1)-0.8, yl(2)+0.8]);
end


%% --- Вспомогательные функции рисования ---

function drawBlock(ax, x, y, w, h, label)
    rectangle(ax, 'Position', [x-w/2, y-h/2, w, h], ...
        'LineWidth', 1.5, 'FaceColor', [0.95 0.95 1], 'EdgeColor', 'k');
    text(ax, x, y, label, 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', 'FontSize', 9, 'Interpreter', 'tex');
end

function drawArrowLine(ax, x1, y1, x2, y2, arrow_sz)
    line(ax, [x1 x2], [y1 y2], 'Color', 'k', 'LineWidth', 1.5);
    if arrow_sz > 0
        % Рисуем стрелку на конце
        dx = x2 - x1; dy = y2 - y1;
        len = sqrt(dx^2 + dy^2);
        if len < 1e-10, return; end
        ux = dx/len; uy = dy/len;
        % Два крыла стрелки
        px = x2 - arrow_sz*ux + arrow_sz*0.4*uy;
        py = y2 - arrow_sz*uy - arrow_sz*0.4*ux;
        qx = x2 - arrow_sz*ux - arrow_sz*0.4*uy;
        qy = y2 - arrow_sz*uy + arrow_sz*0.4*ux;
        patch(ax, [x2 px qx], [y2 py qy], 'k', 'EdgeColor', 'k');
    end
end

function drawNode(ax, x, y)
    plot(ax, x, y, 'ko', 'MarkerSize', 6, 'MarkerFaceColor', 'k');
end

function drawNodeLabel(ax, x, y, name)
% Рисует точку-метку узла с подписью (соответствует графику импульсной х-ки)
    plot(ax, x, y, 'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'k');
    text(ax, x, y - 0.35, name, 'FontSize', 10, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'Interpreter', 'tex', 'Color', [0.1 0.1 0.8]);
end

function drawSummator(ax, x, y, r)
    theta = linspace(0, 2*pi, 60);
    patch(ax, x + r*cos(theta), y + r*sin(theta), 'w', ...
        'EdgeColor', 'k', 'LineWidth', 1.5);
    text(ax, x, y, '\Sigma', 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', 'FontSize', 14, 'FontWeight', 'bold');
end

function str = formatGainLabel(coeff)
% Формирует надпись для блока усилителя
    if abs(coeff) >= 1e6
        exp_val = floor(log10(abs(coeff)));
        mantissa = coeff / 10^exp_val;
        if abs(mantissa - round(mantissa)) < 0.01
            str = sprintf('\\times %.0f\\cdot10^{%d}', mantissa, exp_val);
        else
            str = sprintf('\\times %.2g\\cdot10^{%d}', mantissa, exp_val);
        end
    elseif abs(coeff) < 0.01
        exp_val = floor(log10(abs(coeff)));
        mantissa = coeff / 10^exp_val;
        str = sprintf('\\times %.2g\\cdot10^{%d}', mantissa, exp_val);
    else
        if abs(coeff - round(coeff)) < 0.01
            str = sprintf('\\times %.0f', coeff);
        else
            str = sprintf('\\times %.4g', coeff);
        end
    end
end

function str = formatDelayLabel(tau, time_mult)
% Формирует надпись для блока задержки
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

    if abs(tau_display - round(tau_display)) < 0.001
        str = sprintf('\\tau = %.0f %s', tau_display, unit);
    else
        str = sprintf('\\tau = %.3g %s', tau_display, unit);
    end
end
