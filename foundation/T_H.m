%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GTML-E -- T_H
%
% Copyright (c) 2014-2021 The GTML-E Contributors
% See LICENSE for details.
%
% Version: 1.2
%
% Describe:
% 	Give entHalpy 'H(J/kg)',
%       fuel air ratio 'FAR(-)',
%       temperature guess value 'T(K)',
%       flag 'Oil/Gas'. 
%   Return real temperature 'T(K)'.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ T_real, iter_flag ] = T_H( H, FAR, T_guess, flag  )

if nargin == 1
    FAR = 0;
end
if nargin <= 2
    T_real = 288.15;
else
    T_real = T_guess;
end
if nargin <= 3
    flag = 'Oil';
end

minH = H_T( 200, FAR, flag );
maxH = H_T( 3000, FAR, flag );

if H < minH
    H = minH;
elseif H > maxH
    H = maxH;
end

% Define the error function for the solver
error_fun = @(T) H_T(T, FAR, flag) - H;

% Set options for lsqnonlin, requires Optimization Toolbox
options = optimoptions('lsqnonlin', 'Display', 'off');

% Set bounds
T_min = 200;
T_max = 3000;

% Call the solver
[T_real, ~, ~, exitflag] = lsqnonlin(error_fun, T_guess, T_min, T_max, options);

% Basic check for solver success
if exitflag <= 0
    % Handle solver failure if necessary, for now, it will just return the last value
    iter_flag = -1;
else
    iter_flag = 1; % Placeholder for success
end

end