function obj = p1_createSpectrAnalytical(obj)
%SPECTRANALYTICAL_1 Создание спектра аналитическим методом

jumps = obj.jumps;
slopes = obj.slopes;
omega = obj.cyclic_freq;

sp = [];

% Импульсы от наклонов
imp_times = [slopes.time1(:)', slopes.time2(:)'];
imp_amps  = [slopes.diff(:)', -slopes.diff(:)'];

[unique_times, ~, idx] = unique(imp_times);
combined_amps = accumarray(idx, imp_amps);


% Обрабатываем дельта-функции
for k = 1:length(combined_amps)
    if isempty(sp)
        sp = combined_amps(k).*exp(-1i.*omega.*unique_times(k))./(1i.*omega).^2;
    else
        sp = [sp; combined_amps(k).*exp(-1i.*omega.*unique_times(k))./(1i.*omega).^2];     
    end
end

% Обрабатываем производные дельта-функций
for k = 1:length(jumps.amplitude)
    if isempty(sp)
        sp = jumps.amplitude(k).*exp(-1i.*omega.*jumps.time(k))./(1i.*omega);
    else
        sp = [sp; jumps.amplitude(k).*exp(-1i.*omega.*jumps.time(k))./(1i.*omega)];     
    end
end

obj.spectrAnalytical_zveno = sp;
obj.spectrAnalytical = sum(sp,1);

