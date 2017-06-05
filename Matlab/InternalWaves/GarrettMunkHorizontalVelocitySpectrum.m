function [ S ] = GarrettMunkHorizontalVelocitySpectrum( omega, latitude, rho, zIn, zOut )
%GarrettMunkHorizontalVelocitySpectrum 
%
% Returns S where size(S) = [m n] with length(zOut)=m, length(omega) = n;
%
% Rather than simply evaluate the function at the request frequencies, we
% actually integrate the function, and then divide by delta-frequency. This
% is because the function is infinite at f, but is integrable.

if length(omega)>1 && ~isrow(omega)
   omega = reshape(omega,1,[]);
end

if length(zOut)>1 && ~iscolumn(zOut)
   zOut = reshape(zOut,[],1);
end

im = InternalModes(rho,zIn,zOut,latitude, 'nEVP', 128);
im.normalization = 'const_F_norm';
N2 = im.N2;
f0 = im.f0;

% GM Parameters
j_star = 3;
L_gm = 1.3e3; % thermocline exponential scale, meters
invT_gm = 5.2e-3; % reference buoyancy frequency, radians/seconds
E_gm = 6.3e-5; % non-dimensional energy parameter
E = L_gm*L_gm*L_gm*invT_gm*invT_gm*E_gm;

H = (j_star+(1:3000)).^(-5/2);
H_norm = 1/sum(H);

% This function tells you how much energy you need between two frequencies
B_norm = 1./acos(f0./sqrt(N2)); % B_norm *at each depth*.
B_int = @(omega0,omega1) B_norm.*(atan(f0/sqrt(omega0*omega0-f0*f0)) - atan(f0./sqrt(omega1.*omega1-f0*f0)));

% Assume omega0 & omega1 >=0 and that omega1>omega0;
% Create a function that integrates from f0 to N(z) at each depth, and is
% zero outside those bounds.
B = @(omega0,omega1) (omega1<f0 | omega1 > sqrt(N2)).*zeros(size(zOut)) + (omega0<f0 & omega1>f0)*B_int(f0,omega1) + (omega0>=f0*ones(size(zOut)) & omega1 <= sqrt(N2)).*B_int(omega0,omega1) + (omega0<sqrt(N2) & omega1 > sqrt(N2)).*B_int(omega0,sqrt(N2));

C = @(omega) (abs(omega)<f0 | abs(omega) > sqrt(N2)).*zeros(size(zOut)) + (abs(omega) >= f0 & abs(omega) <= sqrt(N2)).*( (1+f0/omega)*(1+f0/omega)*(N2 - omega*omega)./(N2-f0*f0) );
dOmegaVector = diff(omega);
if any(dOmegaVector<0)
    error('omega must be strictly monotonically increasing.')
end

dOmega = unique(dOmegaVector);

if max(abs(diff(dOmega))) > 1e-7
    error('omega must be an evenly spaced grid');
end

dOmega = min( [f0/2,dOmega]);

S = zeros(length(zOut),length(omega));
for i=1:length(omega)
    Bomega = B( abs( omega(i) ) - dOmega/2, abs( omega(i) ) + dOmega/2 )/dOmega;
        
    S(:,i) = E* ( Bomega .* C(omega(i)) );
    
%     if (abs(omega(i)) > f0)
%         [F, ~, h] = im.ModesAtFrequency(omega(i));
%         j_max = find(h>0,1,'last');
%         
%         if ~isempty(j_max)
%             j_max = j_max-5; % Last mode may be bad.
%             H = H_norm*(j_star + (1:j_max)').^(-5/2);
%             Phi = sum( (F(:,1:j_max).^2) * H, 2);
%             
%             S(:,i) = S(:,i).*Phi;
%         end
%     end
    
    
end

nEVP = 128;
min_j = 64; % minimum number of good modes we require
[sortedOmegas, indices] = sort(abs(omega));
for i = 1:length(sortedOmegas)
    if (sortedOmegas(i) > f0)
        
        [F, ~, h] = im.ModesAtFrequency(sortedOmegas(i));
        j_max = ceil(find(h>0,1,'last')/2);
        
        while( isempty(j_max) || j_max < min_j )          
            nEVP = nEVP + 128;
            im = InternalModes(rho,zIn,zOut,latitude, 'nEVP', nEVP);
            im.normalization = 'const_F_norm';
            [F, ~, h] = im.ModesAtFrequency(sortedOmegas(i));
            j_max = ceil(find(h>0,1,'last')/2);
        end
        
        H = H_norm*(j_star + (1:j_max)').^(-5/2);
        Phi = sum( (F(:,1:j_max).^2) * H, 2);
        S(:,i) = S(:,i).*Phi;
    end
end

% for the vertical structure function I think we should sort the
% frequencies, and try to solve with a small nEVP. If the number of valid
% modes starts to look small, then we up the resolution. We keep the
% resolution for higher frequencies, and repeat the check. This is good
% because high resolution is always needed as the frequencies get higher.


end
