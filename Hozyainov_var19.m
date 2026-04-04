clear;
clc;
close all;

U1 = 8;
U2 = 2;
U3 = 4;
U4 = 2;
T = [1 2 4].*1e-6;
n = 16;
m = 10;
f_gr = "max"; % max/min/mid
T2 = 5e-6;


% Объект, который всё посчитает
solver = KursachSolver(U1, U2, U3, U4, T, n, m, f_gr, T2, 1e-6);

% Вывод сигнала и СПМ шума из дано
solver.dano_showSignal();
solver.dano_showNoiseSPM();
solver.p1_showSpectrFFT();
solver.p1_showSignalDiff();
solver.p1_showSpectrAnalytical();

% Пункт 2 - СФ
solver.p2_createSF();
solver.p2_simplifySF();
solver.p2_showSF();
