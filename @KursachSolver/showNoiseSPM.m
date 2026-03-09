function showNoiseSPM(obj)
%SHOWSIGNAL Вывод СПМ шума из дано

cyclic_freq = obj.cyclic_freq;
noiseSPM = obj.noise_SPM;
W0 = obj.W0;
omega_gr_n = obj.omega_gr_n;
prec = obj.prec;

figure(name="СПМ шума");
plot([-2.*omega_gr_n cyclic_freq(1:prec:end) 2.*omega_gr_n], [0 noiseSPM(1:prec:end) 0], LineWidth=3);
grid on;
xlim([-1.5.*omega_gr_n 1.5.*omega_gr_n]);
ylim([-0.2.*W0 1.3.*W0]);

ax = gca;
ax.XAxisLocation = 'origin';
ax.YAxisLocation = 'origin';

xline(-omega_gr_n, '--', "-\omegaгр");
xline(omega_gr_n, '--', "\omegaгр");
yline(W0, '--', "W0");

title("СПМ шума, W0 = "+num2str(W0)+" В^2/Гц, |\omegaгр| = "+num2str(omega_gr_n));
xlabel("\omega, рад/с");
ylabel("W(\omega), В^2/Гц");


end