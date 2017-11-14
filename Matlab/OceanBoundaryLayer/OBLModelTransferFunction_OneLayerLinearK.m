% This implements model 3b from S. Elipot and S. T. Gille: Ekman layers in the Southern Ocean.
% www.ocean-sci.net/5/115/2009
%
% Winds are assumed to be given in meters per second. Time is in days. Depth in meters.
% slab_damp is the slab e-fold damping scale in days. K0 has units of m^2/s
function [H] = OBLModelTransferFunction_OneLayerLinearK( time, z, latitude, h, K0, K1 );

f = (2 * 7.2921e-5)*sind(latitude);
rho_water = 1025; % units of kg/m^3

% Lets go to the frequency domain
% nu has units of 1/s
nu = FFTFrequenciesFromTimeSeries( time*86400 );

% Make a an appropriate coordinate grid.
% The resulting matrices are length(z) x length(nu).
[NU, Z] = meshgrid( nu, z);

% Scale depth for each frequency
delta_1 = sqrt(2*K0./(2*pi*NU+f)); % units of m
delta_2 = K1./(2*pi*NU+f);
z_0 = K0/K1;
zeta_z = 2*sqrt( sqrt(-1)*(z_0 + Z)./delta_2 );
zeta_h = 2*sqrt( sqrt(-1)*(z_0 + h)./delta_2 );
zeta_0 = 2*sqrt( sqrt(-1)*(z_0 + 0)./delta_2 );

% Transfer function, units of m^2 s / kg
H = 1 ./ ( rho_water * sqrt( sqrt(-1)*(2*pi*NU + f)*K0 ) );
H = H .* ( besseli(0,zeta_h) .* besselk(0,zeta_z) - besselk(0,zeta_h) .* besseli(0,zeta_z) ) ;
H = H ./ ( besseli(1,zeta_0) .* besselk(0,zeta_h) + besselk(1,zeta_0) .* besseli(0,zeta_h) ) ;

