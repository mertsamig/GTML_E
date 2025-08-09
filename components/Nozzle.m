%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GTML-E -- Nozzle
%
% Copyright (c) 2014-2021 The GTML-E Contributors
% See LICENSE for details.
%
% Version: 1.1
%
% to be continued : CD nozzle & calculate gamma by Ts
%
% Msg:  0 or -A, 0 means ok, -A means warnning
%       A: pressure of input, 1 : too small, 2 : too large
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ WOut, FgOut, NErrorOut, OthrData, Msg ] = Nozzle( GasPthCharIn, PambIn, AthroatIn, Cdth, CV, CX )

Msg = 0;

% -- Load data --

WIn = 0;
TtIn = 0;
PtIn = 0;
FARcIn = 0;

if length(GasPthCharIn) == 5
WIn = GasPthCharIn( 1 );
TtIn = GasPthCharIn( 3 );
PtIn = GasPthCharIn( 4 );
FARcIn = GasPthCharIn( 5 );
end

% -- Calculate PsMN1 --
  
Rth = gas_constant( FARcIn ); 
Cpth = Cp_T( TtIn, FARcIn );
gammath = Cpth / ( Cpth - Rth );
PRMN1 = (( gammath + 1 ) / 2 ) ^ ( gammath / ( gammath - 1 ) );
PsMN1 = PtIn / PRMN1;

% -- Determine if Nozzle is choked --

if ( PsMN1 < PambIn )
	choked = 0;
else
	choked = 1;
end
  
% -- Assumed not choked,  set Ps to ambient pressure and calculate parameters --
if ( choked == 0 )
	Psth = PambIn;
	PRlambdath = Psth / PtIn;
    
    %-- Limit pilambda range --
    if ( PRlambdath > 1 )
        PRlambdath = 1;
        Msg = -1;
    elseif ( PRlambdath < 0.01 )
        PRlambdath = 0.01;
        Msg = -2;
    end
else
% -- Assuming choked, determine static pressure and tempurature --
	Psth = PsMN1;
end

% -- Calculate velocity & gross thrust --
% Using the standard isentropic flow equation for exit velocity.
V = CV * sqrt(max(0, 2 * Cpth * TtIn * (1 - (Psth / PtIn)^((gammath-1)/gammath))));
FgOut = ( WOut * V + ( Psth - PambIn ) * AthroatIn * 1e+3 ) * CX;

% -- Calculate Flow out of nozzle for error checking --
% This section calculates the theoretical mass flow ('Woutcalc') that the
% nozzle can pass for the given conditions. This is compared against the
% incoming flow 'WIn' to generate a normalized error for the solver.

WOut = WIn;

% Calculate throat Mach number from the pressure ratio PtIn/Psth
M_th_sq = (2 / (gammath - 1)) * ((PtIn / Psth)^((gammath - 1) / gammath) - 1);
M_th = sqrt(max(0, M_th_sq));

% Calculate the non-dimensional flow function q(M)
% q(M) = M * (1 + (gamma-1)/2 * M^2)^(-(gamma+1)/(2*(gamma-1)))
% We apply the discharge coefficient Cdth to the final mass flow calculation.
q_M = M_th * (1 + (gammath - 1) / 2 * M_th_sq)^(-(gammath + 1) / (2 * (gammath - 1)));

% Calculate the theoretical mass flow rate using the gas dynamics flow function.
% The 1e3 factor is for unit consistency, originally present in the code.
Woutcalc = (AthroatIn * PtIn / sqrt(TtIn)) * sqrt(gammath/Rth) * q_M * Cdth * 1e3;
 
% -- Compute Normalized Flow Error --
if ( WIn == 0 )
	NErrorOut = 100;
else 
	NErrorOut = ( WIn - Woutcalc ) / WIn ;
end

% -- Assign output values --
OthrData = [Woutcalc];
    
end