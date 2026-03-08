U1 = 6;
U2 = 6;
U3 = 4;
U4 = 0;
T = [1 3 4].*1e-6;
n = 14;
m = 40;
f_gr = "max";
T2 = 5e-6;

% Объект, который всё посчитает
solver = KursachSolver(U1, U2, U3, U4, T, n, m, f_gr, T2);
