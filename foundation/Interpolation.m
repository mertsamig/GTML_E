%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GTML-E -- Interpolation
%
% Copyright (c) 2014-2021 The GTML-E Contributors
% See LICENSE for details.
%
% Version: 1.1
%
% Describe:
% 	Give an increasing vector 'x(n)' and vector 'v(n)' and 'xi' 
% return 1-D interp result 'vi'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function vi = Interpolation( x, v, xi )

    il = FindPos( x, xi );
    ih = il + 1;
    
    prm = ( xi - x( il ) ) / ( x( ih ) - x( il ) );
    vi = v( il ) + prm * ( v( ih ) - v( il ) );
end