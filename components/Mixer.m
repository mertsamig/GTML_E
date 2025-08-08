%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GTML-E -- Mixer
%
% Copyright (c) 2014-2021 The GTML-E Contributors
% See LICENSE for details.
%
% Version: 1.1
%
% Msg:  0 or -ABC, 0 means ok, -ABC means warnning
%       A: flow of primary input, 1 : too small, 2 : too large 
%       B: flow of secondary input, 1 : too small, 2 : too large
%       C: pressure of primary input, 1 : too small, 2 : too large
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ GasPthCharOut, NErrorOut, OthrData, Msg ] = Mixer( GasPthCharIn1, GasPthCharIn2, Adesign1, Adesign2 )

% -- Load data --

WIn1 = 0;
TtIn1 = 0;
PtIn1 = 0;
FARcIn1 = 0;
WIn2 = 0;
TtIn2 = 0;
PtIn2 = 0;
FARcIn2 = 0;

if length( GasPthCharIn1 ) == 5
WIn1 = GasPthCharIn1( 1 );
TtIn1 = GasPthCharIn1( 3 );
PtIn1 = GasPthCharIn1( 4 );
FARcIn1 = GasPthCharIn1( 5 );
end

if length( GasPthCharIn2 ) == 5
WIn2 = GasPthCharIn2( 1 );
TtIn2 = GasPthCharIn2( 3 );
PtIn2 = GasPthCharIn2( 4 );
FARcIn2 = GasPthCharIn2( 5 );
end

% -- Calculate Flow out of mixer --

WOut = WIn1 + WIn2;

% -- Calculate output fuel to air ratio --

Wftot = FARcIn1 * WIn1 / ( 1 + FARcIn1 ) + FARcIn2 * WIn2 / ( 1 + FARcIn2 );
FARcOut = Wftot / ( WOut - Wftot );

% --  Calculate total output temperature --
 
htin1 = H_T( TtIn1, FARcIn1 );
htin2 = H_T( TtIn2, FARcIn2 );
htOut = ( WIn1 * htin1 + WIn2 * htin2 ) / WOut;
TtOut = T_H( htOut, FARcOut );

% --  Calculate lambda1 --

RIn1 = gas_constant( FARcIn1 );
CpIn1 = Cp_T( TtIn1, FARcIn1 );
gammaIn1 = CpIn1 / (CpIn1 - RIn1);
Kqlambda1 = sqrt( gammaIn1/RIn1*( (2/(gammaIn1+1))^((gammaIn1+1)/(gammaIn1-1)) ) );
qlambdaIn1 = ( WIn1 * sqrt( TtIn1 ) ) / ( Kqlambda1 * Adesign1 * PtIn1 * 1e3 );
[ lamada1, ~, message ] = lambda_root( qlambdaIn1, gammaIn1 );
Msg = message;

% --  Calculate lambda2 --

RIn2 = gas_constant( FARcIn2 );
CpIn2 = Cp_T( TtIn2, FARcIn2 );
gammaIn2 = CpIn2 / (CpIn2 - RIn2);
Kqlambda2 = sqrt( gammaIn2/RIn2*( (2/(gammaIn2+1))^((gammaIn2+1)/(gammaIn2-1)) ) );
qlambdaIn2 = ( WIn2 * sqrt( TtIn2 ) ) / ( Kqlambda2 * Adesign2 * PtIn2 * 1e3 );
[ lamada2, ~, message ] = lambda_root( qlambdaIn2, gammaIn2 );
Msg = Msg * 10 + message;

% --  Calculate output Area --

AOut = Adesign1 + Adesign2;

% --  Calculate output Impulse --

flamada1 = (lamada1^2+1) * (1-(gammaIn1-1)/(gammaIn1+1)*lamada1^2)^(1/(gammaIn1-1));
flamada2 = (lamada2^2+1) * (1-(gammaIn2-1)/(gammaIn2+1)*lamada2^2)^(1/(gammaIn2-1));
ImpulseIn = PtIn1*Adesign1*flamada1 + PtIn2*Adesign2*flamada2;

% --  Iterate to find output pressure, calculated from errors in Impulse --

ROut = gas_constant( FARcOut );
CpOut = Cp_T( TtOut, FARcOut );
gammaOut = CpOut / (CpOut - ROut);
KqlambdaOut = sqrt( gammaOut/ROut*( (2/(gammaOut+1))^((gammaOut+1)/(gammaOut-1)) ) );

% Define the error function for the impulse balance
    function impulse_error = calc_impulse_error(p_out)
        qlambda_out = WOut * sqrt(TtOut) / AOut / p_out / 1e3 / KqlambdaOut;
        [lambda_out, ~, ~] = lambda_root(qlambda_out, gammaOut);
        flambda_out = (lambda_out^2+1) * (1-(gammaOut-1)/(gammaOut+1)*lambda_out^2)^(1/(gammaOut-1));
        impulse_out = flambda_out * p_out * AOut;
        impulse_error = (ImpulseIn - impulse_out) / ImpulseIn;
    end

% Set initial guess for output pressure
PtOut_guess = ( PtIn1 * WIn1 + PtIn2 * WIn2 ) / WOut;

if ( Msg == 0 )
    % Set options for lsqnonlin, requires Optimization Toolbox
    options = optimoptions('lsqnonlin', 'Display', 'off', 'TolFun', 1e-7);
    
    % Set bounds (pressure must be positive)
    pt_min = 0.01;
    pt_max = inf;

    % Call the solver
    PtOut = lsqnonlin(@calc_impulse_error, PtOut_guess, pt_min, pt_max, options);
else
    PtOut = PtOut_guess;
end

%-- Calculate secondary flow --
pilambda1 = (1-(gammaIn1-1)/(gammaIn1+1)*lamada1^2)^(gammaIn1/(gammaIn1-1));
PsIn = PtIn1 * pilambda1;
pilambda2 = PsIn / PtIn2;
%-- Limit pilambda range --
if ( pilambda2 < 0.01 )
    pilambda2 = 0.01;
    message = -1;
elseif ( pilambda2 > 1 )
    pilambda2 = 1;
    message = -2;
else
    message = 0;
end
Msg = Msg * 10 + message;
lambda2c = sqrt( (gammaIn2+1)/(gammaIn2-1) * (1 - pilambda2^((gammaIn2-1)/gammaIn2)) );
qlambdaIn2c = ((gammaIn2+1)/2)^(1/(gammaIn2-1)) * (1-((gammaIn2-1)/(gammaIn2+1)*lambda2c^2))^(1/(gammaIn2-1)) * lambda2c;
WIn2c = Kqlambda2 * PtIn2*1e3 * Adesign2 * qlambdaIn2c / sqrt(TtIn2);

%-- Compute normalized error --
if ( WIn2 == 0 )
	NErrorOut = 100;
else
    NErrorOut = ( WIn2 - WIn2c ) / WIn2;
end

%-- Assign output values --
GasPthCharOut = zeros( 1, 5 );
GasPthCharOut( 1 ) = WOut;
GasPthCharOut( 2 ) = htOut;
GasPthCharOut( 3 ) = TtOut;
GasPthCharOut( 4 ) = PtOut;
GasPthCharOut( 5 ) = FARcOut;
OthrData = WIn2c;

end

function [ lambda, i_sum, message ] = lambda_root( q_lambda0, k )
	
    %-- Limit qlambda range --
    if ( q_lambda0 < 0.01 )
        q_lambda0 = 0.01;
        message = -1;
    elseif ( q_lambda0 > 1 )
        q_lambda0 = 1;
        message = -2;
    else
        message = 0;
    end
    
    % Define the error function for the solver
    error_fun = @(l) (((k+1)/2)^(1/(k-1)) * l .* (1-(k-1)/(k+1)*l.^2).^(1/(k-1))) - q_lambda0;

    % Set options for lsqnonlin, requires Optimization Toolbox
    options = optimoptions('lsqnonlin', 'Display', 'off', 'TolFun', 1e-7);

    % Set initial guess and bounds
    lambda_guess = q_lambda0;
    lambda_min = 0;
    lambda_max = 1.5; % Lambda can be > 1

    % Call the solver
    [lambda, ~, ~, exitflag, output] = lsqnonlin(error_fun, lambda_guess, lambda_min, lambda_max, options);

    if exitflag <= 0
        i_sum = -1;
    else
        i_sum = output.iterations;
    end
	
end