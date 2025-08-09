%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GTML-E -- Compressor
%
% Copyright (c) 2014-2021 The GTML-E Contributors
% See LICENSE for details.
%
% Version: 1.02
%
% MaxNum of bleeds : 10
% to be continued : map scale & error count & stall margin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ GasPthCharOut, PwrOut, NErrorOut, OthrData, CustBldsCharOut, FBldsCharOut, Msg ] = Compressor( GasPthCharIn, Nmech, beta, VSV, CustBldsPlan, FBldsPlan, Nc_tab, Beta_tab, Eff_tab, PR_tab, Wc_tab, SF, CNST, WcSurgeVec, PRSurgeVec )

WIn = 0;
TtIn = 0;
PtIn = 0;

if length(GasPthCharIn) == 5
WIn = GasPthCharIn( 1 );
TtIn = GasPthCharIn( 3 );
PtIn = GasPthCharIn( 4 );
end
SF_Wc = SF( 1 );
SF_PR = SF( 2 );
SF_Eff = SF( 3 );
SF_Nc = SF( 4 );
PSTD = CNST( 1 );
TSTD = CNST( 2 );

% -- Compute output Fuel to Air Ratio --

FAROut = 0;

% -- Compute Input enthalpy --

htIn = H_T( TtIn );

% -- Compute Input psi --
psiIn = psi_T( TtIn );

% -- Calculate fluid condition related variables and corected Flow --
persistent RSTD CpSTD gammaSTD;
if isempty(RSTD)
    % Calculate standard day constants once and store them
    RSTD = gas_constant(0);
    CpSTD = Cp_T(TSTD);
    gammaSTD = CpSTD / (CpSTD - RSTD);
end

RIn = gas_constant(0);
CpIn = Cp_T(TtIn);
gammaIn = CpIn / (CpIn - RIn);

delta = PtIn / PSTD;
theta = TtIn / TSTD;
fai = gammaIn / gammaSTD;

Wcin = WIn * sqrt( theta / fai ) / delta;

% -- Calculate corrected speed --

NcMap = Nmech / sqrt( theta * fai );
NcMap_ = NcMap / SF_Nc;

% --- Map Interpolation ---
% Clamp inputs to map boundaries to avoid extrapolation.
NcMap_clamped = max(min(NcMap_, Nc_tab(end)), Nc_tab(1));
beta_clamped = max(min(beta, Beta_tab(end)), Beta_tab(1));

% -- Define constants for clarity --
PERCENT_TO_FRACTION = 0.01;
VSV_EFF_PENALTY_FACTOR = 1e-4;

% -- Compute Total Flow input --
WcMap = interp2(Nc_tab, Beta_tab, Wc_tab, NcMap_clamped, beta_clamped, 'makima');
WcMap = WcMap + VSV * WcMap * PERCENT_TO_FRACTION;
WcMap = WcMap * SF_Wc;

% -- Compute Pressure Ratio --
PRMap = interp2(Nc_tab, Beta_tab, PR_tab, NcMap_clamped, beta_clamped, 'makima');
PRMap = (PRMap - 1) * SF_PR + 1;

% -- Compute Efficiency --
EffMap = interp2(Nc_tab, Beta_tab, Eff_tab, NcMap_clamped, beta_clamped, 'makima');
EffMap = EffMap - VSV * VSV * VSV_EFF_PENALTY_FACTOR * EffMap;
EffMap = EffMap * SF_Eff;

% -- Compute pressure output --

PtOut = PtIn * PRMap;

% -- Enthalpy calculations --

R = gas_constant( FAROut );
psiOut = psiIn + ( R * log( PRMap ) );
htOut = htIn + ( H_T( T_psi( psiOut ) ) - htIn ) / EffMap;
TtOut = T_H( htOut );

% --- Vectorized Bleed Calculations ---

% -- Customer Bleed components --
[ ~, uWidth1 ] = size(CustBldsPlan);
WcustOut = zeros(1, uWidth1);
htcustOut = zeros(1, uWidth1);
TtcustOut = zeros(1, uWidth1);
PtcustOut = zeros(1, uWidth1);
FARcustOut = zeros(1, uWidth1);

% Use logical indexing for vectorization
active_cust_bleeds = CustBldsPlan(1, :) > 0;
if any(active_cust_bleeds)
    WcustOut(active_cust_bleeds) = CustBldsPlan(1, active_cust_bleeds);
    FARcustOut(active_cust_bleeds) = FAROut;
    htcustOut(active_cust_bleeds) = htIn + CustBldsPlan(2, active_cust_bleeds) .* (htOut - htIn);
    PtcustOut(active_cust_bleeds) = PtIn + CustBldsPlan(3, active_cust_bleeds) .* (PtOut - PtIn);

    % With the vectorized T_H solver, we can calculate all bleed temperatures in a single call.
    TtcustOut(active_cust_bleeds) = T_H(htcustOut(active_cust_bleeds), FAROut, TtOut);

    Pwr_cust_bleeds = sum(WcustOut(active_cust_bleeds) .* (htcustOut(active_cust_bleeds) - htOut));
else
    Pwr_cust_bleeds = 0;
end

% -- Fractional Bleed components --
[ ~, uWidth2 ] = size(FBldsPlan);
WbldOut = zeros(1, uWidth2);
htbldOut = zeros(1, uWidth2);
TtbldOut = zeros(1, uWidth2);
PtbldOut = zeros(1, uWidth2);
FARbldOut = zeros(1, uWidth2);

% Use logical indexing for vectorization
active_frac_bleeds = FBldsPlan(1, :) > 0;
if any(active_frac_bleeds)
    WbldOut(active_frac_bleeds) = WIn * FBldsPlan(1, active_frac_bleeds);
    FARbldOut(active_frac_bleeds) = FAROut;
    htbldOut(active_frac_bleeds) = htIn + FBldsPlan(2, active_frac_bleeds) .* (htOut - htIn);
    PtbldOut(active_frac_bleeds) = PtIn + FBldsPlan(3, active_frac_bleeds) .* (PtOut - PtIn);

    % With the vectorized T_H solver, we can calculate all bleed temperatures in a single call.
    TtbldOut(active_frac_bleeds) = T_H(htbldOut(active_frac_bleeds), FAROut, TtOut);

    Pwr_frac_bleeds = sum(WbldOut(active_frac_bleeds) .* (htbldOut(active_frac_bleeds) - htOut));
else
    Pwr_frac_bleeds = 0;
end

% -- Sum bleed effects --
Wbleeds = sum(WcustOut) + sum(WbldOut);
PwrBld = Pwr_cust_bleeds + Pwr_frac_bleeds;

% -- Compute Flows --

Wb4bleed = WIn;
WOut = WIn - Wbleeds;

% -- Compute Powers --
WATTS_TO_KW = 1e-3;
Pwrb4bleed = Wb4bleed * ( htIn - htOut );
PwrOut = ( Pwrb4bleed - PwrBld ) * WATTS_TO_KW;

% -- Compute Normalized Flow Error --

if WIn == 0
    NErrorOut = 100;
else
    NErrorOut = ( Wcin - WcMap ) / Wcin;
end

% -- Compute Stall Margin --

% Use MATLAB's built-in interp1 function with the 'makima' method as requested.
SPR = interp1( WcSurgeVec, PRSurgeVec, Wcin, 'makima' );
SM = ( SPR / PRMap - 1 ) * 100;

% -- Assign output values port --

GasPthCharOut = zeros( 5, 1 );
GasPthCharOut( 1 ) = WOut;
GasPthCharOut( 2 ) = htOut;
GasPthCharOut( 3 ) = TtOut;
GasPthCharOut( 4 ) = PtOut;
GasPthCharOut( 5 ) = FAROut;

OthrData = [ SM, WcMap, PRMap, EffMap, NcMap ];

CustBldsCharOut = zeros( 5, uWidth1 );
CustBldsCharOut( 1, : ) = WcustOut;
CustBldsCharOut( 2, : ) = htcustOut;
CustBldsCharOut( 3, : ) = TtcustOut;
CustBldsCharOut( 4, : ) = PtcustOut;
CustBldsCharOut( 5, : ) = FARcustOut;

FBldsCharOut = zeros( 5, uWidth2 );
FBldsCharOut( 1, : ) = WbldOut;
FBldsCharOut( 2, : ) = htbldOut;
FBldsCharOut( 3, : ) = TtbldOut;
FBldsCharOut( 4, : ) = PtbldOut;
FBldsCharOut( 5, : ) = FARbldOut;

% -- Generate Warning Messages --
Msg = {}; % Initialize as empty cell array for descriptive warnings
MAP_EDGE_TOLERANCE = 0.01; % 1% margin

% Check corrected speed bounds
if ( NcMap_ <= Nc_tab(1) * (1 + MAP_EDGE_TOLERANCE) )
    Msg{end+1} = 'Warning: Corrected speed is near or below the map lower bound.';
elseif ( NcMap_ >= Nc_tab(end) * (1 - MAP_EDGE_TOLERANCE) )
    Msg{end+1} = 'Warning: Corrected speed is near or above the map upper bound.';
end

% Check beta bounds
if ( beta <= MAP_EDGE_TOLERANCE )
    Msg{end+1} = 'Warning: Beta is near or below the map lower bound.';
elseif ( beta >= (1 - MAP_EDGE_TOLERANCE) )
    Msg{end+1} = 'Warning: Beta is near or above the map upper bound.';
end

end
