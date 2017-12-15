%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% InternalWaveModelPlaneWaveUnitTest
%
% This script uses the InternalWaveModel to create, and validate, a single
% internal wave for all possible wavenumbers.
%
% Jeffrey J. Early
% jeffrey@jeffreyearly.com
%
% November 17th, 2016   Version 1.0


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Specify the problem dimensions
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Lx = 15e3;
Ly = 15e3;
Lz = 5000;

Nx = 4;
Ny = 8;
Nz = 2;

latitude = [0 31];
N0 = 5.2e-3/2; % Choose your stratification 7.6001e-04
U = 0.01; % m/s
phi = 0*0.232; % random, just to see if its doing the right thing
t = 4*86400;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Initialize the wave model
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
totalErrors = 0;
totalTests = 0;

for iLat = 1:length(latitude)
    if 1 == 1
        wavemodel = InternalWaveModelConstantStratification([Lx, Ly, Lz], [Nx, Ny, Nz], latitude(iLat), N0);
        rho0 = wavemodel.rho0;
        g = 9.81;
    else
        rho0 = 1025; g = 9.81;
        rho = @(z) -(N0*N0*rho0/g)*z + rho0;
        z = (Lz/Nz)*(0:Nz-1)' - Lz;
        wavemodel = InternalWaveModelArbitraryStratification([Lx, Ly, Lz], [Nx, Ny, Nz], rho, z, Nz, latitude(iLat), 'method','wkbSpectral','nEVP',128);
    end
    
    % pull out some model constants for easy reference
    f0 = wavemodel.f0;
    k = wavemodel.k;
    l = wavemodel.l;
    h = wavemodel.h;
    x = wavemodel.x;
    y = wavemodel.y;
    X = wavemodel.X;
    Y = wavemodel.Y;
    Z = wavemodel.Z;
    
    for k_loop=(-Nx/2 + 1):1:(Nx/2-1)
        for l_loop=(-Ny/2 + 1):1:(Ny/2-1)
            fprintf('(k0,l0)=(%d,%d) ',k_loop,l_loop);
            for j0=1:Nz/2
                for sign=-1:2:1
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %
                    % Create the analytical solution
                    %
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    if (k_loop < 0)
                        k0 = Nx + k_loop;
                    else
                        k0 = k_loop;
                    end
                    if (l_loop < 0)
                        l0 = Ny + l_loop;
                    else
                        l0 = l_loop;
                    end
                    
                    m = j0*pi/Lz;
                    kk = k(k0+1);
                    ll = l(l0+1);
                    alpha=atan2(ll,kk);
                    K = sqrt( kk^2 + ll^2);
                    omega = sign*sqrt( (K*K*N0*N0 + m*m*f0*f0)/(K*K+m*m) );
                    
                    if latitude(iLat) == 0
                        f0OverOmega = 0;
                        if K == 0
                            kOverOmega = 0;
                        else
                            kOverOmega = K/omega;
                        end
                    else
                        f0OverOmega = f0/omega;
                        kOverOmega = K/omega;
                    end
                    
                    theta = kk*X + ll*Y + omega*t + phi;
                    u_unit = U*(cos(alpha)*cos( theta ) + f0OverOmega*sin(alpha)*sin( theta )).*cos(m*Z);
                    v_unit = U*(sin(alpha)*cos( theta ) - f0OverOmega*cos(alpha)*sin( theta )).*cos(m*Z);
                    w_unit = (U*K/m) * sin( theta ) .* sin(m*Z);
                    zeta_unit = -(U/m) * kOverOmega * cos( theta ) .* sin(m*Z);
                    rho_unit = rho0 -(N0*N0*rho0/g)*reshape(wavemodel.z,1,1,[]) -(rho0/g)*N0*N0*(U*K/m/omega) * cos( theta ) .* sin(m*Z);
                    
                    if any(any(any(isnan(zeta_unit))))
                        error('nan')
                    end
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %
                    % Now test how the different APIs perform at creating the
                    % requested wave.
                    %
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    for API = 1:4
                        wavemodel.RemoveAllExternalWaves();
                        wavemodel.RemoveAllGriddedWaves();
                        
                        if API == 1
                            apiName = 'InitializeWithPlaneWave';
                            wavemodel.InitializeWithPlaneWave(k_loop,l_loop,j0,U,sign);
                        elseif API == 2
                            apiName = 'SetGriddedWavesWithWavemodes';
                            wavemodel.SetGriddedWavesWithWavemodes(k_loop,l_loop,j0,phi,U,sign);
                        elseif API == 3
                            apiName = 'SetExternalWavesWithWavenumbers';
                            wavemodel.SetExternalWavesWithWavenumbers(sign*kk, sign*ll, j0, sign*phi,sign*U,Normalization.uMax);
                        elseif API == 4
                            apiName = 'SetExternalWavesWithFrequencies';
                            wavemodel.SetExternalWavesWithFrequencies(omega, alpha, j0, phi,U,Normalization.uMax);
                        end
                        
                        [u,v,w,zeta] = wavemodel.VariableFieldsAtTime(t,'u','v','w','zeta');
                        rho = wavemodel.DensityFieldAtTime(t);
                        
                        % Compute the relative error
                        max_speed = max(max(max( sqrt(u.*u + v.*v) )));
                        max_u = max( [max(max(max( u ))), 1e-15] );
                        u_error = max(max(max(abs(u-u_unit)/max_speed)));
                        max_v = max( [max(max(max( v ))), 1e-15] );
                        v_error = max(max(max(abs(v-v_unit)/max_speed)));
                        max_w = max( [max(max(max( abs(w) ))), 1e-15] );
                        w_error = max( [max(max(max(abs(w-w_unit)/max_w))), 1e-15] );
                        max_zeta = max( [max(max(max( zeta ))), 1e-15] );
                        zeta_error = max( [max(max(max(abs(zeta-zeta_unit)/max_zeta))), 1e-15] );
                        max_rho = max( [max(max(max( rho ))), 1e-15] );
                        rho_error = max( [max(max(max(abs(rho-rho_unit)/max_rho))), 1e-15] );
                        
                        max_error = max([round((log10(u_error)))  round((log10(v_error))) round((log10(w_error))) round((log10(zeta_error))) round((log10(rho_error)))],[],'includenan');
                        
                        totalTests = totalTests + 1;
                        if isnan(max_error) || max_error > -3
                            totalErrors = totalErrors + 1;
                            if sign > 0
                                fprintf('\nFound at large error at lat=%f with %s at +(k,l,j)=(%d,%d,%d):\n', latitude(iLat),apiName,k_loop,l_loop,j0);
                            else
                                fprintf('\nFound at large error at lat=%f  with %s at -(k,l,j)=(%d,%d,%d):\n', latitude(iLat),apiName,k_loop,l_loop,j0);
                            end
                            fprintf('The model solution for (u,v) matches the analytical solution to 1 part in (10^%d, 10^%d) at time t=%d\n', round((log10(u_error))), round((log10(v_error))),t);
                            fprintf('The model solution for (w,zeta,rho) matches the analytical solution to 1 part in (10^%d, 10^%d, 10^%d) at time t=%d\n', round((log10(w_error))), round((log10(zeta_error))), round((log10(rho_error))),t);
                        end
                    end % API loop
                end % sign loop
            end % j loop
        end % l loop
        fprintf('\n');
    end % k loop
end % latitude loop

fprintf('\n***************************************************\n');
if totalErrors > 0
    fprintf('FAILED %d of %d tests.\n',totalErrors, totalTests);
else
    fprintf('PASSED all %d tests.\n', totalTests);
end
