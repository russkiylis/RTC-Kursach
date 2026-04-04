function p2_createSF(obj)
% P2_CREATESF — Находит функцию согласованного фильтра
    
    % Вычисление масштабного коэффициента
    obj.A = 1 ./ max(abs(obj.spectrAnalytical));
    disp(newline);
    disp("== СОГЛАСОВАННЫЙ ФИЛЬТР == ");
    disp("Масштабный коэффициент А = " + sprintf("%.2e",obj.A) + " Гц/В");


    % Вычисление ПФ СФ
    t0 = obj.T2;
    obj.K_SF = obj.A .* conj(obj.spectrAnalytical) .* exp(-1i.*obj.cyclic_freq.*t0);
    obj.K_SF_zveno = obj.A .* conj(obj.spectrAnalytical_zveno) .* exp(-1i.*obj.cyclic_freq.*t0);

    k_SF_text = [];
    for i = 1:length(obj.K_SF_text_zveno)
        if isempty(k_SF_text)
            k_SF_text = sprintf("%.10g",obj.A) + "*" + obj.K_SF_text_zveno(i) + "*e^{-j\omega" + sprintf("%.10g",t0) + "}";
        else
            k_SF_text = k_SF_text + " + " + sprintf("%.10g",obj.A) + "*" + obj.K_SF_text_zveno(i) + "*e^{-j\omega" + sprintf("%.10g",t0) + "}";
        end
    end
    disp("Передаточная функция согласованного фильтра (латех, можно вставить в ворд):");
    disp(k_SF_text);