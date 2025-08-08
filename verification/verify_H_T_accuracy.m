% This script checks the result of the H_T function.
% The bug was that for the 'Oil' case, the result was 1000x too large.
% Run this script before and after the fix to see the difference.

fprintf('Starting H_T accuracy verification...\n');

% Setup test parameters
T = 1000; % Test temperature in Kelvin
FAR = 0.02; % Test fuel-air ratio
flag = 'Oil';

% --- Verifying H_T ---
H_val = H_T(T, FAR, flag);

fprintf('Calculated enthalpy H at %.1f K with FAR=%.2f is: %.4e J/kg\n', T, FAR, H_val);

% For reference, the enthalpy of air at 1000K is around 7.5e5 J/kg.
% The original buggy code would return a value around 7.5e8 J/kg.
% The fixed code should return a value in the correct order of magnitude.
fprintf('Expected value should be on the order of 1e5 to 1e6 J/kg.\n');
