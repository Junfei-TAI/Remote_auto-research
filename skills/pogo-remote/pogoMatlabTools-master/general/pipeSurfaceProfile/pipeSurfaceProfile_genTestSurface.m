%% Generate example surfaces for pipeSurfaceProfile.m
%
%   Sam Horne (2019)
%   sjh415@ic.ac.uk

Rin = 2.5;      % Inside radius of pipe
nr = 10;        % Number of nodes in radial direction
nc = 100;       % Number of nodes in circumferential direction
nz = 10;        % Number of nodes in z direction
dr = 0.1;       % spacing of nodes in radial direction
dz = 0.1;       % spacing of nodes in z direction

Rin = 2.5;                      % Internal radius
Rout = 3.5;                     % External radius

offset = [0.25,0];      % Offset of inner surface for eccentricity in x and y dimensions
amplitude = 0.1;        % amplitude of surface roughness;

% File names
folder = '';
FO_eccentricity = 'outerSurface_eccentricity';
FI_eccentricity = 'innerSurface_eccentricity';

FO_rough = 'outerSurface_rough';
FI_rough = 'innerSurface_rough';

%% Example of pipe eccentricity
% Calculate with shift to x posion of the axis of the inner radii
% Save as radius to each point
dTh = 2*pi/nc;                  % Angular spacing between nodes
th = 0:dTh:dTh*(nc-1);          % angle to each radial row of nodes

% convert to (x,y) positions and shift by offset
a = Rin*[cos(th);sin(th)];
a(1,:) = a(1,:) + offset(1);
a(2,:) = a(2,:) + offset(2);

% convert back to radius
innerR = sqrt(a(1,:).^2 + a(2,:).^2);

figure;
title('Eccentricity')
polarplot(th,repmat(Rin,size(th,1),size(th,2)),'r')
hold on
polarplot(th,innerR,'r--')
polarplot(th,repmat(Rout,size(th,1),size(th,2)),'k')
legend('Original inner surface','Modified inner surface','Original Outer surface')

innerSurface_eccentricity = repmat(innerR,nz,1)';
outerSurface_eccentricity = repmat(Rout,nz,nc)';

csvwrite([folder,FI_eccentricity,'.csv'],innerSurface_eccentricity)
csvwrite([folder,FO_eccentricity,'.csv'],outerSurface_eccentricity)

%% Example of surface roughness
% simple sinusoidal roughness profile
% Save as deviation from surface
% innerSurface = zeros(nz,nc)';
% outerSurface = zeros(nz,nc)';
innerR = amplitude*cos(th*5);
outerR = amplitude*sin(th*7);

for n=1:nz
    innerSurface_rough(:,n) = innerR.*cos(2*pi*(n/nz)*3);
    outerSurface_rough(:,n) = outerR.*cos(2*pi*(n/nz)*4);
end

csvwrite([folder,FI_rough,'.csv'],innerSurface_rough)
csvwrite([folder,FO_rough,'.csv'],outerSurface_rough)

return
