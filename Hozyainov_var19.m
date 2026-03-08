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
f_gr = "max";
T2 = 5e-6;
precision = 1000;

% Объект, который всё посчитает
solver = KursachSolver(U1, U2, U3, U4, T, n, m, f_gr, T2);

