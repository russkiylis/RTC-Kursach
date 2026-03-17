classdef KursachSolver < handle
    %KURSACHSOLVER Решает курсовик по РТЦиСу

    properties

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
        
        %--Оси--%
        N = 10000;  % Количество точек
        time;   % Ось времени
        cyclic_freq;    % Ось частоты
        freqFFT; % Ось частоты для FFT
        dt; % Деление по времени

        %--Параметры, связанные с сигналом--%
        u;  % Матрица из сигналов
        umax;   % Максимум сигнала
        jumps;  % Трёхмерный массив скачков
        slopes;

        %--Параметры, связанные с СПМ шума--%
        noise_SPM;  % СПМ шума
        W0; % Амплитуда СПМ
        omega_gr_n; % Граничная частота

        %--Параметры, связанные со спектром--%
        spectrFFT; % Посчитанные через FFT спектры
        zpad;
        f_gr01_FFT; % Частоты среза для FFT-спектров по уровню 0.1
        selectedSignal; % Выбранный сигнал

    end

    methods
        function obj = KursachSolver(U1, U2, U3, U4, T, n, m, f_gr, T2)
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

            % Генерируем сигнал по дано
            [obj.time, obj.dt, obj.u, obj.jumps, obj.slopes, obj.umax] = dano_createSignal(obj);
            
            % Генерируем СПМ шума по дано
            [obj.cyclic_freq, obj.noise_SPM, obj.W0, obj.omega_gr_n] = dano_createNoiseSPM(obj);

            % Генерируем FFT спектры сигналов
            obj = p1_createSpectrFFT(obj);

        end
    end

    methods (Access=protected)
        %--ДАНО--%
        [time, dt, u, jumps, slopes, umax] = dano_createSignal(obj)    % Создавалка сигнала по дано
        [cyclic_freq, noise_SPM, W0, omega_gr_n] = dano_createNoiseSPM(obj)     % Создавалка СПМ шума по дано
        
        %--ПУНКТ 1--%
        obj = p1_createSpectrFFT(obj);
        obj = p1_createSpectrAnalytical(obj);
    end

    methods
        %--ДАНО--%
        dano_showSignal(obj)     % Вывод сигнала из дано
        dano_showNoiseSPM(obj)   % Вывод СПМ шума из дано

        %--ПУНКТ 1--%
        p1_showSpectrFFT(obj)  % Вывод FFT-расчёта спектров
    end
end