%%%%%%%%%%%%%%%%%%%%%%%%%
% Informal version
%%%%%%%%%%%%%%%%%%%%%%%%%

function [beta,i_sum, maxnum, minnum] = MapBetaSolution( n_cor,pi,n_tab,beta_tab,pi_tab,beta_guess )

    % Define a nested function to perform the interpolation and error calculation.
    % This is necessary because the logic is too complex for a single-line
    % anonymous function. The nested function has access to the parent's
    % variables (n_cor, pi, etc.).
    function err = interp_and_calc_error(b)
        % Clamp inputs to map boundaries to avoid extrapolation.
        n_cor_clamped = max(min(n_cor, n_tab(end)), n_tab(1));
        b_clamped = max(min(b, beta_tab(end)), beta_tab(1));

        % Interpolate using the 'makima' method.
        pi_interp = interp2(n_tab, beta_tab, pi_tab, n_cor_clamped, b_clamped, 'makima');

        % Calculate the error for the solver.
        err = pi_interp - pi;
    end

% Define the error function handle for the solver
error_fun = @interp_and_calc_error;

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

