classdef KursachSolver < handle
    %KURSACHSOLVER Решает курсовик по РТЦиС

    properties
        prec;  % Точность вычислений

        U1;
        U2;
        U3;
        U4;
        T;
        n;
        m;
        f_gr;
        T2;

        time;
        u;
        jumps;
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
            [obj.time, obj.u, obj.jumps] = createSignal(obj);


        end
    end

    methods (Access=protected)
        [time, u, jumps] = createSignal(obj)    % Создавалка сигнала по дано
        
    end
end