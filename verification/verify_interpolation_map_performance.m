% This script benchmarks the performance of the in-place 2D interpolation.
% It measures the speed of using MATLAB's built-in 'interp2' function,
% which is the core of the map-based component models.

fprintf('Starting in-place interpolation performance verification...\n');

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

% --- Benchmarking in-place interpolation ---
fprintf('Benchmarking in-place interp2 function over %d points on a %dx%d map...\n', n_points, map_size, map_size);
tic; % Start timer
for i = 1:n_points
    % In-place interpolation logic, as it would be implemented in components
    a = a_points(i);
    b = b_points(i);
    a = max(min(a, ax(end)), ax(1));
    b = max(min(b, bx(end)), bx(1));
    interp2(ax, bx, pcx, a, b, 'makima');
end
elapsed_time = toc; % Stop timer

fprintf('Elapsed time for %d in-place interpolation calls: %.4f seconds\n', n_points, elapsed_time);
