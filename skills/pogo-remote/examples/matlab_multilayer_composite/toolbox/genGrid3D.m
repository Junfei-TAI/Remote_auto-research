function [ m ] = genGrid3D( nx, ny, nz, dx, dy, dz, cx, cy, cz )
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

%make nodes
px = repmat( dx*( (1:nx)-(nx+1)/2 ).', [1,ny,nz])+cx;
py = repmat(dy*( (1:ny).'-(ny+1)/2).', [nx,1,nz] )+cy;
pz = repmat(dz*permute( (1:nz).'-(nz+1)/2,[2,3,1]), [nx,ny,1] )+cz;

px = reshape(px,[],1);
py = reshape(py,[],1);
pz = reshape(pz,[],1);

m.nodePos = [px(:), py(:), pz(:)].';

nEls = (nx-1)*(ny-1)*(nz-1);

nNodesPerEl = 8;

elNodes = zeros(nNodesPerEl,nEls);

cubeNodes = zeros(8,1);
elCnt = 0;
for elCntZ = 1:(nz-1)
    for elCntY = 1:(ny-1)
        for elCntX = 1:(nx-1)
                        
            cubeNodes(1) = elCntX-1+(elCntY-1)*nx + (elCntZ-1)*nx*ny;
            cubeNodes(2) = elCntX-1+1+(elCntY-1)*nx + (elCntZ-1)*nx*ny;
            cubeNodes(3) = elCntX-1+1+(elCntY-1+1)*nx + (elCntZ-1)*nx*ny;
            cubeNodes(4) = elCntX-1+(elCntY-1+1)*nx + (elCntZ-1)*nx*ny;
            
            cubeNodes(5) = elCntX-1+(elCntY-1)*nx + (elCntZ-1+1)*nx*ny;
            cubeNodes(6) = elCntX-1+1+(elCntY-1)*nx + (elCntZ-1+1)*nx*ny;
            cubeNodes(7) = elCntX-1+1+(elCntY-1+1)*nx + (elCntZ-1+1)*nx*ny;
            cubeNodes(8) = elCntX-1+(elCntY-1+1)*nx + (elCntZ-1+1)*nx*ny;

            %hex:
            elCnt = elCnt+1;
            elNodes(1:8,elCnt) = cubeNodes(:);
        end
    end
end

m.elNodes = elNodes+1;

m.elTypes = cell(1,1);
m.elTypes{1}.name = 'C3D8R';
m.elTypes{1}.paramsType = 0;

m.elTypeRefs = ones(nEls,1);


end

