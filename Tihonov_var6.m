clear;
clc;
close all;

U1 = 9;
U2 = 9;
U3 = 9;
U4 = 0;
T = [1 2 4].*1e-6;
n = 16;
m = 10;
f_gr = "mid"; % min/max/mid
T2 = 5e-6;

% Объект, который всё посчитает
solver = KursachSolver(U1, U2, U3, U4, T, n, m, f_gr, T2, 1e-6);

% Вывод сигнала и СПМ шума из дано
solver.dano_showSignal();
solver.dano_showNoiseSPM();
solver.p1_showSpectrFFT();
solver.p1_showSignalDiff();