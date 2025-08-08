%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GTML-E -- gas_constant
%
% Copyright (c) 2014-2021 The GTML-E Contributors
% See LICENSE for details.
%
% Version: 1.1
%
% Describe:
% 	Give fuel air ratio 'FAR(-)' and flag 'Oil/Gas'. 
%   Return corresponding 'Rg(J/(kg*K))'.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
function Rg = gas_constant( FAR, flag )

%FAR:-
%Rg:J/(kg*K)

if nargin == 1

    flag = 'Oil';
end

if strcmp(flag, 'Gas')
    % To avoid code duplication, calculate the average molar mass of the
    % mixture using the results from Fuel_Composition, then find Rg.

    R_universal = 8.31446; % J/(mol*K)

    % Get mass fractions of the gas mixture components
    % The first argument to Fuel_Composition seems to be total gas flow,
    % which for a mixture of air + fuel is (1 + FAR).
    % We are interested in the composition, so the absolute value doesn't
    % matter, only the ratio. We can use Wg=1+FAR and Wf=FAR.
    mass_fractions = Fuel_Composition(1 + FAR, FAR);

    % Molar masses of the components [N2, O2, CO2, H2O]
    molar_masses = [28.0134, 31.9988, 44.01, 18.01528];

    % Calculate average molar mass of the mixture
    % M_avg = 1 / sum(mass_fraction_i / Molar_mass_i)
    avg_molar_mass = 1 / sum(mass_fractions ./ molar_masses);

    Rg = R_universal / avg_molar_mass;
    
else

    Rg = 287.05-0.00990*FAR+1e-7*FAR^2;
end

end