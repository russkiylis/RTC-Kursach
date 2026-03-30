function p1_showSpectrAnalytical(obj)
%P1_SHOWSPECTRANALYTICAL Вывод аналитического спектра

sp = obj.spectrAnalytical;
f = obj.cyclic_freq ./(2.*pi);

sp_max = max(abs(sp));
f_sr = -f(find(abs(sp) >= 0.1.*(sp_max),1));


figure(name="Аналитический спектр, fгр = " + sprintf("%.2e",f_sr) + " Гц");
plot(f, abs(sp), LineWidth=2);
xline([-f_sr f_sr], "--");
yline(0.1.*(sp_max), "--");
xlabel("f, Гц");
ylabel("S(f), В/Гц");
grid on;
title("Аналитический спектр, fгр = " + sprintf("%.2e",f_sr) + " Гц");

xlim([-f_sr.*1.1 f_sr.*1.1]);
end