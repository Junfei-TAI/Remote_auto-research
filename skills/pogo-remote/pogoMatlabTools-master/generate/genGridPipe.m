function [ m, pr, pTh, pz ] = genGridPipe( ri, nr, nc, nz, dr, dz )
%genGridPipe - generate a Pogo mesh for a pipe
%   [ m ] = genGridPipe( ri, nr, nc, nz, dr, dTh, dz )
%
%m - generated model struct in Pogo format
%ri - inner radius
%nr, nc, nz - number of nodes in radial, circumferential and axial directions
%dr, dz - spacing in each direction (circ calculated automatically)
%pr, pTh, pz - output node coordinates in r, theta and z directions
%
%8 noded brick elements are generated
%order of nodes and elements is radially, circumferentially, then axially
%radially, inside to out
%
%Written by Peter Huthwaite, Dec 2016
m.nDims = 3;
m.nDofPerNode = 3;

%r fastest
%theta
%z slowest

%make nodes
dTh = 2*pi/nc;

pr = repmat( dr*( (0:nr-1) ).', [1,nc,nz])+ri;
pTh = repmat(dTh*( (1:nc).'-(nc+1)/2).', [nr,1,nz] );
pz = repmat(dz*permute( (1:nz).'-(nz+1)/2,[2,3,1]), [nr,nc,1] );

pr = reshape(pr,[],1);
pTh = reshape(pTh,[],1);
pz = reshape(pz,[],1);

px = pr.*cos(pTh);
py = pr.*sin(pTh);

m.nodePos = [px(:), py(:), pz(:)].';

nEls = (nr-1)*(nc)*(nz-1);

% Element vector for first layer in z direction
Evec = (1:((nr-1)*(nc)));
EvecL = length(Evec);

% Node id for first node in each element of Evec (skip nodes at outer radius)
v = 1:((nr)*(nc));
vm = (1:(nc))*nr;
v(vm) = [];

m.elNodes(1,Evec) = v;
m.elNodes(2,Evec) = v + 1;
m.elNodes(3,Evec) = v + 1 + nr;
m.elNodes(4,Evec) = v + nr;

% Set last radial line of nodes around the circumference to be equal to
% first set to stitch pipe together
Nrc = nr*nc;
m.elNodes(m.elNodes>Nrc) = m.elNodes(m.elNodes>Nrc) - Nrc;

% Replicate pattern for z = dz layer to complete first layer of elements.
m.elNodes(5,Evec) = m.elNodes(1,:) + Nrc;
m.elNodes(6,Evec) = m.elNodes(2,:) + Nrc;
m.elNodes(7,Evec) = m.elNodes(3,:) + Nrc;
m.elNodes(8,Evec) = m.elNodes(4,:) + Nrc;

% Add a shift to each additional layer of elements so they address the
% correct z layer of nodes.
shift = repelem((0:(nz-2))*Nrc,8,EvecL);
m.elNodes = repmat(m.elNodes,1,nz-1) + shift;

m.elTypes = cell(1,1);
m.elTypes{1}.name = 'C3D8R';
m.elTypes{1}.paramsType = 0;

m.elTypeRefs = ones(nEls,1);

end
