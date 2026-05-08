function [ m, px, py, pz ] = genGrid3D( nx, ny, nz, dx, dy, dz, cx, cy, cz )
%genGrid3D - generate a Pogo mesh in 3D
%   [ m ] = genGrid3D( nx, ny, nz, dx, dy, dz, cx, cy, cz )
%
%m - generated model struct in Pogo format
%nx, ny, nz - number of nodes in x, y and z directions
%dx, dy, dz - spacing in each direction
%cx, cy, cz - mesh centre in each direction (defaults to 0)
%
%8 noded brick elements are generated
%
%Written by Peter Huthwaite, Dec 2016

if nargin < 7
    cx = 0;
end
if nargin < 8
    cy = 0;
end
if nargin < 9
    cz = 0;
end

m.nDims = 3;
m.nDofPerNode = 3;

m.metadata.nx = nx;
m.metadata.ny = ny;
m.metadata.nz = nz;
m.metadata.dx = dx;
m.metadata.dy = dy;
m.metadata.dz = dz;
m.metadata.cx = cx;
m.metadata.cy = cy;
m.metadata.cz = cz;

%make nodes
px = repmat( dx*( (1:nx)-(nx+1)/2 ).', [1,ny,nz])+cx;
py = repmat(dy*( (1:ny).'-(ny+1)/2).', [nx,1,nz] )+cy;
pz = repmat(dz*permute( (1:nz).'-(nz+1)/2,[2,3,1]), [nx,ny,1] )+cz;

px = reshape(px,[],1);
py = reshape(py,[],1);
pz = reshape(pz,[],1);

m.nodePos = [px(:), py(:), pz(:)].';

nEls = (nx-1)*(ny-1)*(nz-1);

%% Generate element connectivities
nxy = nx*ny;
Evec = (1:((nx-1)*(ny-1)));
EvecL = length(Evec);

v = 1:((nx)*(ny-1));
vm = (1:(ny-1))*nx;
v(vm) = [];

m.elNodes(1,Evec) = v;
m.elNodes(2,Evec) = v + 1;
m.elNodes(3,Evec) = v + 1 + nx;
m.elNodes(4,Evec) = v + nx;

% replicate pattern for second layer of nodes to complete first layer of elements.
m.elNodes(5,Evec) = m.elNodes(1,:) + nxy;
m.elNodes(6,Evec) = m.elNodes(2,:) + nxy;
m.elNodes(7,Evec) = m.elNodes(3,:) + nxy;
m.elNodes(8,Evec) = m.elNodes(4,:) + nxy;

% Add a shift to each additional layer of elements so they address the
% correct z layer of nodes.
shift = repmat(0:(nz-2) , EvecL, 1);
shift = repmat(shift(:)',8,1).*nxy;
m.elNodes = repmat(m.elNodes,1,nz-1) + shift;

%%
m.elTypes = cell(1,1);
m.elTypes{1}.name = 'C3D8R';
m.elTypes{1}.paramsType = 0;

m.elTypeRefs = ones(nEls,1);


end
