%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GTML-E -- gas_constant
%
% Copyright (c) 2014-2021 The GTML-E Contributors
% See LICENSE for details.
%
% Version: 1.2
%
% Describe:
% 	Give fuel air ratio 'FAR(-)' and flag 'Oil/Gas'. 
%   Return corresponding 'Rg(J/(kg*K))'.
%   This version includes caching to improve performance on repeated calls.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
function Rg = gas_constant( FAR, flag )

    persistent cache;
    if isempty(cache)
        cache = containers.Map('KeyType', 'char', 'ValueType', 'double');
    end

    if nargin == 1
        flag = 'Oil';
    end

    % Create a unique key for the cache.
    % Round FAR to 6 decimal places to handle floating point variations
    % and increase the likelihood of a cache hit.
    key = sprintf('%s_%.6f', flag, FAR);

    if isKey(cache, key)
        Rg = cache(key);
        return;
    end

    % --- If not in cache, perform calculation ---
    if strcmp(flag, 'Gas')
        % To avoid code duplication, calculate the average molar mass of the
        % mixture using the results from Fuel_Composition, then find Rg.
        R_universal = 8.31446; % J/(mol*K)

        % Get mass fractions of the gas mixture components
        mass_fractions = Fuel_Composition(1 + FAR, FAR);

        % Molar masses of the components [N2, O2, CO2, H2O]
        molar_masses = [28.0134, 31.9988, 44.01, 18.01528];

        % Calculate average molar mass of the mixture
        % M_avg = 1 / sum(mass_fraction_i / Molar_mass_i)
        avg_molar_mass = 1 / sum(mass_fractions ./ molar_masses);

        Rg_calc = R_universal / avg_molar_mass;

    else
        Rg_calc = 287.05-0.00990*FAR+1e-7*FAR^2;
    end

    % Store result in cache and assign to output
    cache(key) = Rg_calc;
    Rg = Rg_calc;
end