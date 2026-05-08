%% Example use of pipeSurfaceProfile.m to modify surface profiles
%
%   Sam Horne (2019)
%   sjh415@ic.ac.uk

folder = '';    % folder where surface files are located

% Rough Surface properties
rough.outer.type = 'deviation';        % Is surface given as 'radius' to points or 'deviation' from Rout
rough.outer.fN = [folder,'outerSurface_rough.csv'];
rough.inner.type = 'deviation';        % Is surface given as 'radius' to points or 'deviation' from Rin
rough.inner.fN = [folder,'innerSurface_rough.csv'];
rough.deformationLimit = 0.25;         % What is the maximum amount that elements can deform as a fraction of the original size

% Eccentric Surface properties
eccentric.outer.type = 'radius';        % Is surface given as 'radius' to points or 'deviation' from Rout
eccentric.outer.fN = [folder,'outerSurface_eccentricity.csv'];
eccentric.inner.type = 'radius';        % Is surface given as 'radius' to points or 'deviation' from Rin
eccentric.inner.fN = [folder,'innerSurface_eccentricity.csv'];
eccentric.deformationLimit = 0.25;         % What is the maximum amount that elements can deform as a fraction of the original size


%% Generate pipe
Rin = 2.5;      % Inside radius of pipe
nr = 10;        % Number of nodes in radial direction
nc = 100;        % Number of nodes in circumferential direction
nz = 10;        % Number of nodes in z direction
dr = 0.1;       % spacing of nodes in radial direction
dz = 0.1;       % spacing of nodes in z direction
Rout = Rin+nr*dr; % Outer radius of pipe
dTh = 2*pi/nc;

[ model ] = genGridPipe( Rin, nr, nc, nz, dr, dz );         % Pogo libray function to generate pipe mesh

%% Rough surface
[nodePos_rough] = pipeSurfaceProfile(model,rough, Rin, Rout, dTh, dr);

figure
scatter3(model.nodePos(1,:),model.nodePos(2,:),model.nodePos(3,:),'k.');
hold on
axis equal
scatter3(nodePos_rough(1,:),nodePos_rough(2,:),nodePos_rough(3,:),'ro');
legend('Original position','Modified position')
zlim([max(model.nodePos(3,:)),inf]) % just show one z slice for clarity
view(0,90) % rotate view
title('Rough surface')

%% Eccentric surface
[nodePos_eccentric] = pipeSurfaceProfile(model,eccentric, Rin, Rout, dTh, dr);

figure
scatter3(model.nodePos(1,:),model.nodePos(2,:),model.nodePos(3,:),'k.');
hold on
axis equal
scatter3(nodePos_eccentric(1,:),nodePos_eccentric(2,:),nodePos_eccentric(3,:),'ro');
zlim([max(model.nodePos(3,:)),inf]) % just show one z slice for clarity
view(0,90) % rotate view
title('Eccentric surface')
