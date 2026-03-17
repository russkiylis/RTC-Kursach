function [time, dt, u, jumps, slopes, umax] = dano_createSignal(obj)
%CREATESIGNAL Создавалка сигнала по дано
    
    U1 = obj.U1;
    U2 = obj.U2;
    U3 = obj.U3;
    U4 = obj.U4;
    T = obj.T;
    T2 = obj.T2;
    N = obj.N;

    % Создание функций
    time = linspace(-0.01.*T2, 1.01.*T2, N);
    dt = time(2)-time(1);
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
    jumps = cell(3,1);
    for k = 1:3
        jumps{k}.time = [];
        jumps{k}.amplitude = [];

        if U1 > 0
            jumps{k}.time = [jumps{k}.time 0]; %#ok<*AGROW>
            jumps{k}.amplitude = [jumps{k}.amplitude U1];
        end
        if U2 ~= U3
            jumps{k}.time = [jumps{k}.time T(k)];
            jumps{k}.amplitude = [jumps{k}.amplitude U3-U2];
        end
        if U4 > 0
            jumps{k}.time = [jumps{k}.time T2];
            jumps{k}.amplitude = [jumps{k}.amplitude -U4];
        end
    end

    % Запоминаем где первая производная это константа (в сигнале наклон)
    slopes = cell(3,1);
    for k = 1:3
        slopes{k}.time = [];
        slopes{k}.diff = [];

        if U2~=U1 && T(k)~=0
            slopes{k}.time = [slopes{k}.time; 0 T(k)];
            slopes{k}.diff = [slopes{k}.diff (U2-U1)/(T(k)-0)];
        end
        if U4~=U3 && T2~=T(k)
            slopes{k}.time = [slopes{k}.time; T(k) T2];
            slopes{k}.diff = [slopes{k}.diff (U4-U3)/(T2-T(k))];
        end
    end

end