% This script runs the full test suite for the GTML-E library.

% Get the path to the directory containing this script
[rootDir, ~, ~] = fileparts(mfilename('fullpath'));

% Add the foundation and components directories to the path
addpath(genpath(fullfile(rootDir, 'foundation')));
addpath(genpath(fullfile(rootDir, 'components')));

% Create a test suite from the 'tests' directory
suite = matlab.unittest.TestSuite.fromFolder(fullfile(rootDir, 'tests'));

% Run the tests and display the results
result = run(suite);
disp(result);

% Display a table of the results
disp(table(result));
