classdef KursachSolver < handle
    %KURSACHSOLVER Решает курсовик по РТЦиС

    properties
        U1;
        U2;
        U3;
        U4;
        T;
        n;
        m;
        f_gr;
        T2;
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
            createSignal(obj);


        end
    end

    methods (Access=protected)
        obj = createSignal(obj)    % Создавалка сигнала по дано
        
    end
end