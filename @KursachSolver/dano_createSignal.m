function [time, dt, u, jumps, umax] = dano_createSignal(obj)
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
    for k = 1:3
        if U1 > 0
            obj.jumps{k}.time = [obj.jumps{k}.time 0]; %#ok<*AGROW>
            obj.jumps{k}.amplitude = [obj.jumps{k}.amplitude U1];
        end
        if U2 ~= U3
            obj.jumps{k}.time = [obj.jumps{k}.time T(k)];
            obj.jumps{k}.amplitude = [obj.jumps{k}.amplitude U3-U2];
        end
        if U4 > 0
            obj.jumps{k}.time = [obj.jumps{k}.time T2];
            obj.jumps{k}.amplitude = [obj.jumps{k}.amplitude -U4];
        end
    end



    % % Запоминаем где первая производная это константа (в сигнале наклон)
    for k = 1:3
        i=1;
        if U2~=U1 && T(k)~=0  
            obj.slopes(k,i).t1 = 0;
            obj.slopes(k,i).t2 = T(k);
            obj.slopes(k,i).diff = (U2-U1)/(T(k)-0);
            i = i+1;
        end
        if U4~=U3 && T2~=T(k)
            obj.slopes(k,i).t1 = T(k);
            obj.slopes(k,i).t2 = T2;
            obj.slopes(k,i).diff = (U4-U3)/(T2-T(k));
        end
    end

end