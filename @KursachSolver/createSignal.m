function [time, u, jumps, umax] = createSignal(obj)
%CREATESIGNAL Создавалка сигнала по дано
    
    prec = obj.prec;
    U1 = obj.U1;
    U2 = obj.U2;
    U3 = obj.U3;
    U4 = obj.U4;
    T = obj.T;
    T2 = obj.T2;

    % Создание функций
    time = linspace(-0.01.*T2, 1.01.*T2, 10000*prec);
    u = zeros(length(T), length(time));
    
    kusok1 = false(3, length(time));
    skachok = false(3, length(time));
    kusok2 = false(3, length(time));
    
    % Создание временных масок для кусочков
    for k = 1:3
        kusok1(k,:)  = (time >= 0)    & (time <  T(k));
        skachok(k,:) = (time == T(k));
        kusok2(k,:)  = (time >  T(k)) & (time <= T2);
    end
    
    % Создание кусочков
    for k = 1:3
        u(k, kusok1(k,:))  = U1 + (U2-U1) .* time(kusok1(k,:))  / T(k);
        u(k, skachok(k,:)) = U3;
        u(k, kusok2(k,:))  = U3 + (U4-U3) .* (time(kusok2(k,:)) - T(k)) / (T2 - T(k));
    end
    
    umax = max(u(1,:));

    % Запоминаем, где скачки (ыхыхых скАчки)
    % Первое измерение - версия графика (для разных T)
    % Второе измерение - номер скачка
    % Третье измерение - время и амплитуда скачка
    jumps = zeros(3,1,2);
    if U1 > 0
        jumps(:,1,1) = 0;
        jumps(:,1,2) = U1;
    end
    if U2 ~= U3
        for k = 1:3
            jumps(:,2,1) = T';
            jumps(:,2,2) = U3-U2;
        end
    end
    if U4 > 0 && U2 ~=U3
        jumps(:,3,1) = T2;
        jumps(:,3,2) = -U4;
    elseif U4 > 0 && U2 ==U3
        jumps(:,2,1) = T2;
        jumps(:,2,2) = -U4;
    end

end