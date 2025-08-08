%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GTML-E -- Turbine
%
% Copyright (c) 2014-2021 The GTML-E Contributors
% See LICENSE for details.
%
% Version: 1.03
%
% MaxNum of bleeds : 10
% to be continued : map scale & error count
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ GasPthCharOut, PwrOut, NErrorOut, OthrData, Msg ] = Turbine( CoolingFlwCharIn, GasPthCharIn, Nmech, PRMap, CoolingPlan, Nc_tab, Eff_tab, PR_tab, Wc_tab, SF, CNST, FuelType )

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
SF_Wc = SF( 1 );
SF_PR = SF( 2 );
SF_Eff = SF( 3 );
SF_Nc = SF( 4 );
PSTD = CNST( 1 );
TSTD = CNST( 2 );

if FuelType == 1
    MARK = 'Oil';
else
    MARK = 'Gas';
end

% -- Vectorized Cooling Flow Calculations --
[ ~, num ] = size(CoolingPlan);
Wcool = zeros(1, num);
htcool = zeros(1, num);

[port_num,~] = size(CoolingFlwCharIn);
if (port_num == 5)
    % Use logical indexing to find active cooling flows
    active_cool_flows = CoolingPlan(1, :) > 0;

    % Vectorize the loading of cooling flow properties
    Wcool(active_cool_flows) = CoolingFlwCharIn(1, active_cool_flows) .* CoolingPlan(1, active_cool_flows);
    Ttcool_active = CoolingFlwCharIn(3, active_cool_flows);
    FARcool_active = CoolingFlwCharIn(5, active_cool_flows);

    % H_T must be called in a loop as it is not vectorized
    active_indices = find(active_cool_flows);
    for i = 1:length(active_indices)
        idx = active_indices(i);
        htcool(idx) = H_T(Ttcool_active(i), FARcool_active(i), MARK);
    end
end

% Vectorize the calculation of summed cooling flow properties
Wcools1 = sum(Wcool .* (1 - CoolingPlan(2, :)));
Wcoolout = sum(Wcool);

% To avoid division by zero, replace FAR values of -1 (or any invalid) with 0 for calculation
FARcool_safe = FARcool;
FARcool_safe(FARcool < 0) = 0;
Wfcools1 = sum(FARcool_safe .* Wcool .* (1 - CoolingPlan(2, :)) ./ (1 + FARcool_safe));
Wfcoolout = sum(FARcool_safe .* Wcool ./ (1 + FARcool_safe));

% Vectorize the calculation of enthalpy sums
dHcools1 = sum(htcool .* Wcool .* (1 - CoolingPlan(2, :)));
dHcoolout = sum(htcool .* Wcool .* CoolingPlan(2, :));

% -- Compute Total Flow --
Ws1in = WIn + Wcools1;
WOut = WIn + Wcoolout;

% -- Compute Fuel to Air Ratios --
FARs1in = (FARcIn * WIn / (1 + FARcIn) + Wfcools1) / (WIn / (1 + FARcIn) + Wcools1 - Wfcools1);
FARcOut = (FARcIn * WIn / (1 + FARcIn) + Wfcoolout) / (WIn / (1 + FARcIn) + Wcoolout - Wfcoolout);

% -- Compute avg enthalpy at stage 1 --

htIn = H_T( TtIn, FARcIn, MARK );
hts1In = ( htIn * WIn + dHcools1 ) / Ws1in;

% -- Compute stage 1 total temp --

Tts1In = T_H( hts1In, FARs1in, TtIn, MARK );

% -- Compute stage 1 psi, assuming PtIn = Pts1In --

psiIn = psi_T( Tts1In, FARs1in, MARK );

% -- Calculate fluid condition related variables --
persistent STD_CONSTS;
if isempty(STD_CONSTS)
    STD_CONSTS = struct();
end
if ~isfield(STD_CONSTS, MARK)
    % Calculate standard day constants once per fuel type and store them
    STD_CONSTS.(MARK).RSTD = gas_constant(0, MARK);
    STD_CONSTS.(MARK).CpSTD = Cp_T(TSTD, 0, MARK);
    STD_CONSTS.(MARK).gammaSTD = STD_CONSTS.(MARK).CpSTD / (STD_CONSTS.(MARK).CpSTD - STD_CONSTS.(MARK).RSTD);
end
RSTD = STD_CONSTS.(MARK).RSTD;
CpSTD = STD_CONSTS.(MARK).CpSTD;
gammaSTD = STD_CONSTS.(MARK).gammaSTD;

RIn = gas_constant( FARcIn, MARK );
CpIn = Cp_T( TtIn, FARcIn, MARK );
gammaIn = CpIn / ( CpIn - RIn );

delta = PtIn / PSTD;
theta = TtIn * RIn / TSTD / RSTD;
fai = gammaIn / gammaSTD;

% -- Calculate corrected speed --

NcMap = Nmech / sqrt( theta * fai );
NcMap_ = NcMap / SF_Nc;

% -- Compute Pressure Ratio --

PRMap_ = (PRMap - 1) / SF_PR + 1;

% --- Map Interpolation ---
% Clamp inputs to map boundaries to avoid extrapolation.
NcMap_clamped = max(min(NcMap_, Nc_tab(end)), Nc_tab(1));
PRMap_clamped = max(min(PRMap_, PR_tab(end)), PR_tab(1));

% -- Compute Total Flow input --
WcMap_ = interp2(Nc_tab, PR_tab, Wc_tab, NcMap_clamped, PRMap_clamped, 'makima');
WcMap = WcMap_ * SF_Wc;

% -- Compute Efficiency --
EffMap_ = interp2(Nc_tab, PR_tab, Eff_tab, NcMap_clamped, PRMap_clamped, 'makima');
EffMap = EffMap_ * SF_Eff;

% -- Compute pressure output --

PtOut = PtIn / PRMap;

% -- Enthalpy calculations --

R = gas_constant( FARcOut, MARK );
psiOut = psiIn + ( R * log( 1 / PRMap ) );
htIdealout = H_T( T_psi( psiOut, FARcOut, Tts1In, MARK ), FARcOut, MARK );
htOut = ( ( ( htIdealout - hts1In ) * EffMap + hts1In ) * Ws1in + dHcoolout ) / WOut;

% -- Compute Power output only takes into account cooling flow that enters at front of stage 1 --
WATTS_TO_KW = 1e-3;
PwrOut = ( hts1In - htIdealout ) * EffMap * Ws1in * WATTS_TO_KW;

% -- Compute Temperature output --

TtOut = T_H( htOut, FARcOut, Tts1In, MARK );

% -- Compute Normalized Flow Error --

if Ws1in == 0
    NErrorOut = 100;
else
    NErrorOut = ( Ws1in * sqrt( theta / fai ) / delta - WcMap ) / ( Ws1in * sqrt( theta / fai ) / delta );
end

% -- Assign output values port --

GasPthCharOut = zeros( 5, 1 );
GasPthCharOut( 1 ) = WOut;
GasPthCharOut( 2 ) = htOut;
GasPthCharOut( 3 ) = TtOut;
GasPthCharOut( 4 ) = PtOut;
GasPthCharOut( 5 ) = FARcOut;

OthrData = [ WcMap, PRMap, EffMap, NcMap ];

% -- Generate Warning Messages --
Msg = {}; % Initialize as empty cell array for descriptive warnings
MAP_EDGE_TOLERANCE = 0.01; % 1% margin for warnings

% Check corrected speed bounds
if ( NcMap_ <= Nc_tab(1) * (1 + MAP_EDGE_TOLERANCE) )
    Msg{end+1} = 'Warning: Corrected speed is near or below the map lower bound.';
elseif ( NcMap_ >= Nc_tab(end) * (1 - MAP_EDGE_TOLERANCE) )
    Msg{end+1} = 'Warning: Corrected speed is near or above the map upper bound.';
end

end
