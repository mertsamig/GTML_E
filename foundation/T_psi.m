%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GTML-E -- T_psi
%
% Copyright (c) 2014-2021 The GTML-E Contributors
% See LICENSE for details.
%
% Version: 1.1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [t_guess, i] = T_psi(psi, f, t_guess, flag)
%t:K
%psi:J/kg/K
%f:-


if nargin <= 3
    flag = 'Oil';
end
if nargin <= 2
  t_guess = 288.15;
end
if nargin == 1
  f = 0;
end

minpsi = psi_T( 200, f, flag );
maxpsi = psi_T( 2200, f, flag );

if psi < minpsi
    psi = minpsi;
elseif psi > maxpsi
    psi = maxpsi;
end


% Define the error function for the solver
error_fun = @(t) psi_T(t, f, flag) - psi;

% Set options for lsqnonlin, requires Optimization Toolbox
options = optimoptions('lsqnonlin', 'Display', 'off');

% Set bounds
T_min = 200;
T_max = 2200;

% Call the solver
[t_guess, ~, ~, exitflag] = lsqnonlin(error_fun, t_guess, T_min, T_max, options);

% Basic check for solver success
if exitflag <= 0
    % Handle solver failure if necessary
    i = -1;
else
    i = 1; % Placeholder for success
end

end
