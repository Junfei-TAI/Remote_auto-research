function [ m ] = genTetGrid3D( nx, ny, nz, dx, dy, dz, cx, cy, cz )
%genTetGrid3D - generate a Pogo mesh in 3D using tetrahedral elements
%   [ m ] = genTetGrid3D( nx, ny, nz, dx, dy, dz, cx, cy, cz )
%
%m - generated model struct in Pogo format
%nx, ny, nz - number of nodes in x, y and z directions
%dx, dy, dz - spacing in each direction
%cx, cy, cz - mesh centre in each direction (defaults to 0)
%
%4 noded tet elements are generated
%note that this mesh is non-conforming and should only be used for
%demonstration/testing purposes
%
%Written by Peter Huthwaite, Aug 2017

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

nEls = (nx-1)*(ny-1)*(nz-1)*5;

nNodesPerEl = 4;

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

            elCnt = elCnt+1;
            elNodes(1,elCnt) = cubeNodes(1);
            elNodes(2,elCnt) = cubeNodes(2);
            elNodes(3,elCnt) = cubeNodes(4);
            elNodes(4,elCnt) = cubeNodes(5);

            elCnt = elCnt+1;
            elNodes(1,elCnt) = cubeNodes(3);
            elNodes(2,elCnt) = cubeNodes(4);
            elNodes(3,elCnt) = cubeNodes(2);
            elNodes(4,elCnt) = cubeNodes(7);

            elCnt = elCnt+1;
            elNodes(1,elCnt) = cubeNodes(6);
            elNodes(2,elCnt) = cubeNodes(5);
            elNodes(3,elCnt) = cubeNodes(7);
            elNodes(4,elCnt) = cubeNodes(2);

            elCnt = elCnt+1;
            elNodes(1,elCnt) = cubeNodes(8);
            elNodes(2,elCnt) = cubeNodes(7);
            elNodes(3,elCnt) = cubeNodes(5);
            elNodes(4,elCnt) = cubeNodes(4);

            elCnt = elCnt+1;
            elNodes(1,elCnt) = cubeNodes(2);
            elNodes(2,elCnt) = cubeNodes(5);
            elNodes(3,elCnt) = cubeNodes(7);
            elNodes(4,elCnt) = cubeNodes(4);
        end
    end
end

m.elNodes = elNodes+1;

m.elTypes = cell(1,1);
m.elTypes{1}.name = 'C3D4';
m.elTypes{1}.paramsType = 0;

m.elTypeRefs = ones(nEls,1);


end
