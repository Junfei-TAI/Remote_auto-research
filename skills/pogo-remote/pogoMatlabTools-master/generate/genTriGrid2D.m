function [ m ] = genTriGrid2D( nx, ny, dx, dy, cx, cy )
%genTriGrid2D - generate a Pogo mesh in 2D with triangle elements
%   [ m ] = genTriGrid2D( nx, ny, dx, dy, cx, cy )
%
%m - generated model struct in Pogo format
%nx, ny - number of nodes in x and y directions
%dx, dy - spacing in each direction
%cx, cy - mesh centre in each direction (defaults to 0)
%
%3 noded tri elements are generated
%
%Written by Peter Huthwaite, Dec 2016

if nargin < 5
    cx = 0;
end
if nargin < 6
    cy = 0;
end

m.nDims = 2;
m.nDofPerNode = 2;

m.metadata.nx = nx;
m.metadata.ny = ny;
m.metadata.dx = dx;
m.metadata.cx = cx;
m.metadata.cy = cy;

px = reshape(repmat( dx*( (1:nx)-(nx+1)/2 ), ny,1).',[],1)+cx;
py = reshape(repmat(dy*( (1:ny).'-(ny+1)/2),1,nx ).',[],1)+cy;

m.nodePos = [px(:), py(:)].';

nEls = (nx-1)*(ny-1)*2;

nNodesPerEl = 3;

elNodes = zeros(nNodesPerEl,nEls)-1;

elCnt = 0;

for elCntY = 1:(ny-1)
    for elCntX = 1:(nx-1)
        elCnt = elCnt+1;
        elNodes(1,elCnt) = elCntX-1+(elCntY-1)*nx;
        elNodes(2,elCnt) = elCntX-1+(elCntY-1)*nx+1;
        elNodes(3,elCnt) = elCntX-1+(elCntY-1+1)*nx+1;

        elCnt = elCnt+1;
        elNodes(1,elCnt) = elCntX-1+(elCntY-1+1)*nx+1;
        elNodes(2,elCnt) = elCntX-1+(elCntY-1+1)*nx;
        elNodes(3,elCnt) = elCntX-1+(elCntY-1)*nx;
    end
end

%model.elNodes - nodes for each element; size nNodesPerElMax x nEls
m.elNodes = elNodes+1;

m.elTypes = cell(1,1);
m.elTypes{1}.name = 'CPE3';
m.elTypes{1}.paramsType = 0;

m.elTypeRefs = ones(nEls,1);

end
