%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Adjustable parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wavelength = 1000; % wavelength in meters
j = 1; % vertical model number
epsilon = 0.1; % nonlinearity parameter
maxOscillations = 100; % Total number of oscillations, in periods

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fixed parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
D = 500;
N2 = (5.3e-3)^2;
rho0 = 1025;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Derived parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
k = 2*pi/wavelength;
m = j*pi/D;
h = N2/(k*k + m*m)/9.81;
omega = sqrt(9.81*h*k*k);
U = epsilon*(omega/k);
drhodz = -(rho0/9.81)*N2;

period = abs(2*pi/omega);
t = (0:(1/40):maxOscillations)'*period;
fprintf('The wave period is set to %.1f hours.\n', period/3600)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Velocity field
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
u = @(t,x) U*[cos(k*x(1)+omega*t)*cos(m*x(2));  (k/m)*sin(k*x(1)+omega*t)*sin(m*x(2))];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% density
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rho = @(t,x) -(rho0*N2/g)*(x(2)-D + (epsilon/m)*cos(k*x(1)+omega*t)*sin(m*x(2)) );

depths = linspace(0+50,D-50,5)';
figure
for i=1:length(depths)
% Using ode113 for extremely high error tolerances
options = odeset('RelTol',1e-12,'AbsTol',1e-12); % overkill
[T, X] = ode113(u,t,[0 depths(i)],options);

x = X(:,1);
z = X(:,2);

plot(x,z), hold on
end

U_stokes = @(z) -(U*U*k/(2*omega))*(cos(m*z).*cos(m*z) - 1/(h*m*m*9.81)*(N2-omega*omega)*sin(m*z).*sin(m*z) );

z_stokes = linspace(0,D,500);
plot(U_stokes(z_stokes)*max(t),z_stokes)

