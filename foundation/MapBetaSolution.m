%%%%%%%%%%%%%%%%%%%%%%%%%
% Informal version
%%%%%%%%%%%%%%%%%%%%%%%%%

function [beta,i_sum, maxnum, minnum] = MapBetaSolution( n_cor,pi,n_tab,beta_tab,pi_tab,beta_guess )

% Define the error function for the solver
error_fun = @(b) interpolation_map(n_cor, b, n_tab, beta_tab, pi_tab) - pi;

% Set options for lsqnonlin, requires Optimization Toolbox
options = optimoptions('lsqnonlin', 'Display', 'off', 'TolFun', 1e-7);

% Set bounds
beta_min = 0;
beta_max = 1;

% Call the solver
[beta, resnorm, residual, exitflag, output] = lsqnonlin(error_fun, beta_guess, beta_min, beta_max, options);
i_sum = output.iterations;

% The maxnum and minnum outputs are not straightforward to get from lsqnonlin
% without evaluating the function at each step. Returning NaN as a placeholder.
maxnum = NaN;
minnum = NaN;

end

