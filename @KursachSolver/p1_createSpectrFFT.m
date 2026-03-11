function obj = p1_createSpectrFFT(obj)
%SPECTRCOUNT_1 1 пункт - расчет спектров численно


    fs = 1/obj.dt;
    % Zero padding — увеличиваем N
    obj.zpad = 100;
    N_pad = obj.N * obj.zpad;
    
    % Ось циклической частоты
    obj.freqFFT = (-N_pad/2 : N_pad/2-1) * (fs / N_pad);
    % obj.cyclic_freqFFT = 2 * pi * f_axis;
    

    obj.spectrFFT = zeros(3,length(obj.u(1,:))*obj.zpad);
    obj.f_gr01_FFT = zeros(3,1);
    for k = 1:3
        obj.spectrFFT(k,:) = fftshift(fft(obj.u(k,:),N_pad)) .* obj.dt;
        obj.f_gr01_FFT(k,1) = obj.freqFFT(find(abs(obj.spectrFFT(k,:))>=max(abs(obj.spectrFFT(k,:))*0.1),1,"last"));
    end

    f = obj.f_gr01_FFT(:,1);          % вектор граничных частот [3x1]
    
    [~, idx_max] = max(f);
    [~, idx_min] = min(f);
    
    if obj.f_gr == "max"
        obj.selectedSignal = idx_max;
    
    elseif obj.f_gr == "min"
        obj.selectedSignal = idx_min;
    
    else
        all_idx = 1:length(f);
        mid_idx = all_idx(all_idx ~= idx_max & all_idx ~= idx_min);
        obj.selectedSignal = mid_idx(1);
    end
    
    obj.slopes = obj.slopes(obj.selectedSignal,:);

end