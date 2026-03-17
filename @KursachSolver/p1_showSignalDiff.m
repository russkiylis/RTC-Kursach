function p1_showSignalDiff(obj)
%P1_SHOWSIGNALDIFF Выводит производные сигнала

jumps = obj.jumps;
slopes = obj.slopes;
time = obj.time;

tiledlayout(2,1);

% -- Первая производная --
nexttile;
hold on;

for k = 1:length(slopes.diff)
    time_const = time(time > slopes(k).time1 & time < slopes(k).time2);
    plot(time_const, slopes.diff(k).*ones(1,length(time_const)));
end

stem(jumps.time, jumps.amplitude);

xlim([-0.1.*obj.T2 1.2.*obj.T2]);

% -- Вторая производная --
nexttile;
hold on;

stem(slopes.time1, slopes.diff);
stem(slopes.time2, -slopes.diff)

stem(jumps.time, jumps.amplitude, "*");

xlim([-0.1.*obj.T2 1.2.*obj.T2]);

end