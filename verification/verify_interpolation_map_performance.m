% This script benchmarks the performance of the interpolation_map function.
% To compare the performance before and after the optimization,
% run this script on the original version of the code and then again
% on the modified version. The 'elapsed time' will show the improvement.

fprintf('Starting interpolation_map performance verification...\n');

% --- Setup a large dummy map ---
map_size = 500;
ax = linspace(0.5, 1.5, map_size);
bx = linspace(50, 150, map_size);
% Create some dummy data for the map
[X, Y] = meshgrid(ax, bx);
pcx = X.^2 + sqrt(Y); % Some arbitrary function for map data

% --- Setup test points ---
n_points = 2000;
a_points = linspace(0.6, 1.4, n_points);
b_points = linspace(60, 140, n_points);

% --- Benchmarking interpolation_map ---
fprintf('Benchmarking interpolation_map function over %d points on a %dx%d map...\n', n_points, map_size, map_size);
tic; % Start timer
for i = 1:n_points
    interpolation_map(a_points(i), b_points(i), ax, bx, pcx);
end
elapsed_time = toc; % Stop timer

fprintf('Elapsed time for %d calls to interpolation_map: %.4f seconds\n', n_points, elapsed_time);
fprintf('The optimized version (using binary search) should be much faster than the original (using linear search).\n');
