classdef KursachSolver < handle
    %KURSACHSOLVER Решает курсовик по РТЦиСу

    properties
        prec;  % Точность вычислений

        % Далее идут параметры из дано
        U1;
        U2;
        U3;
        U4;
        T;
        n;
        m;
        f_gr;
        T2;
        
        time;   % Ось времени
        cyclic_freq;    % Ось частоты

        % Параметры, связанные с сигналом
        u;  % Матрица из сигналов
        umax;   % Максимум сигнала
        jumps;  % Трёхмерный массив скачков

        % Параметры, связанные с СПМ шума
        noise_SPM;  % СПМ шума
        W0; % Амплитуда СПМ
        omega_gr_n; % Граничная частота


    end

    methods
        function obj = KursachSolver(U1, U2, U3, U4, T, n, m, f_gr, T2, prec)
            %KURSACHSOLVER Конструктор
            % T - в виде вектора
            % f_gr - "min", "max"
            
            obj.U1 = U1;
            obj.U2 = U2;
            obj.U3 = U3;
            obj.U4 = U4;
            obj.T = T;
            obj.n = n;
            obj.m = m;
            obj.f_gr = f_gr;
            obj.T2 = T2;
            obj.prec = prec;
            
            % Генерируем сигнал по дано
            [obj.time, obj.u, obj.jumps, obj.umax] = createSignal(obj);
            
            % Генерируем СПМ шума по дано
            [obj.cyclic_freq, obj.noise_SPM, obj.W0, obj.omega_gr_n] = createNoiseSPM(obj);


        end
    end

    methods (Access=protected)
        [time, u, jumps, umax] = createSignal(obj)    % Создавалка сигнала по дано
        [cyclic_freq, noise_SPM, W0, omega_gr_n] = createNoiseSPM(obj)     % Создавалка СПМ шума по дано

        % Добавить сюда функции спектров
    end

    methods
        showSignal(obj)     % Вывод сигнала из дано
        showNoiseSPM(obj)   % Вывод СПМ шума из дано
    end
end