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

% This function is vectorized to handle scalar or vector inputs for H and T_guess.
% It uses a vectorized Newton-Raphson method for high performance, which is
% crucial for calculations like compressor bleed flows. This avoids slow loops
% and dependencies on the Optimization Toolbox.

iter_flag = 1;
max_iter = 10; % Max iterations for the solver
tol = 1e-6;    % Tolerance for convergence

for i = 1:max_iter
    % Function value (error), calculated element-wise for the vector
    f_val = H_T(T_real, FAR, flag) - H;

    % Check for convergence (all elements must be within tolerance)
    if all(abs(f_val) < tol)
        break;
    end

    % Derivative of the function, calculated element-wise
    df_dT = Cp_T(T_real, FAR, flag);

    % Newton-Raphson step, element-wise
    T_new = T_real - f_val ./ df_dT;

    % Enforce bounds on all elements
    T_new(T_new < 200) = 200;
    T_new(T_new > 3000) = 3000;

    % Check for convergence on step size (all elements)
    if all(abs(T_new - T_real) < tol)
        T_real = T_new;
        break;
    end

    T_real = T_new;
end

if i == max_iter
    iter_flag = -1; % Indicates solver did not converge for at least one element
end

end