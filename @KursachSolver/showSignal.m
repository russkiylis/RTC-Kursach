function showSignal(obj)
%SHOWSIGNAL Вывод трёх типов сигналов из дано

time = obj.time;
u = obj.u;
T = obj.T;
T2 = obj.T2;
umax = obj.umax;
prec = obj.prec;

for k = 1:3
    figure(name="Сигнал, T1 = "+num2str(T(k))+" с");
    plot([-T2 time(1:prec:end) 3.*T2], [0 u(k, 1:prec:end) 0], LineWidth=3);
    grid on;
    xlim([-0.1.*T2 1.2.*T2]);
    ylim([-0.5 1.2.*umax]);

    ax = gca;
    ax.XAxisLocation = 'origin';
    ax.YAxisLocation = 'origin';

    title("Сигнал, T1 = "+num2str(T(k))+" с");
    xlabel("t, с");
    ylabel("u(t), В");
end


end