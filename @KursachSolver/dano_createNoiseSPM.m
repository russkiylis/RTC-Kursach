function [cyclic_freq, noise_SPM, W0, omega_gr_n] = dano_createNoiseSPM(obj)
%CREATENOISESPM Создавалка СПМ шума по дано

    n = obj.n;
    m = obj.m;
    umax = obj.umax;
    T2 = obj.T2;
    N = obj.N;
    
    % Расчёт W0 и omega_gr_n
    W0 = (umax.^2.*T2)./n;
    omega_gr_n = (10.*pi.*m)./T2;

    cyclic_freq = linspace(-1.5*omega_gr_n, 1.5*omega_gr_n, N);    % Ось циклической частоты
    
    % Маска частот где СПМ не равна 0
    kusok = (cyclic_freq > -omega_gr_n) & (cyclic_freq < omega_gr_n);
    
    noise_SPM = zeros(1,length(cyclic_freq));
    noise_SPM(kusok) = W0;
    
end