% This script benchmarks the performance of the T_H function.
% To compare the performance before and after the optimization,
% run this script on the original version of the code and then again
% on the modified version. The 'elapsed time' will show the improvement.

fprintf('Starting T_H performance verification...\n');

% Setup test parameters
n_points = 1000;
H_values = linspace(H_T(250), H_T(2500), n_points); % Test a range of enthalpies
T_guess = 1000; % Initial temperature guess
FAR = 0.01; % Typical fuel-air ratio
flag = 'Oil';

% --- Benchmarking T_H ---
fprintf('Benchmarking T_H function over %d points...\n', n_points);
tic; % Start timer
for i = 1:n_points
    T_H(H_values(i), FAR, T_guess, flag);
end
elapsed_time = toc; % Stop timer

fprintf('Elapsed time for %d calls to T_H: %.4f seconds\n', n_points, elapsed_time);
fprintf('The optimized version should be significantly faster.\n');
