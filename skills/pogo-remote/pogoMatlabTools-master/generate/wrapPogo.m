function [ m3d ] = wrapPogo( m, rInner, nr, dr )
%wrapPogo - extrude a 2D Pogo mesh and wrap it into a 3D pipe model
%   [ m3d ] = wrapPogo( m, rInner, nr, dr )
%
%m - 2d input model
%nr - number of desired points in the r (radial) direction
%rInner - inner radiul
%dr - spacing in the r (radial) direction
%m3d - 3d output model
%
%r positions run from rInner up to (nr-1)*dr+rInner
%note that the 2D x value is mapped into the z direction
% y is mapped into the circumferential direction; note that a gap of size
% dr is added then this is scaled to go from 0 to 2*pi
% Best thing is to make your model y dimension go from 0 to 2*pi*rInner-dr.
%
% Node numbering is as in 2D initially (i.e. first (innermost) layer
% matches node numbering), then each layer has nNodes2d added each time.
%
% depends on stitchNodes() function.
%
%Written by P Huthwaite April 2020

if nr == 1
    error('Cannot have 3D model 1 node thick. Change nr parameter.')
end

m3d = m; %copy everything, then we'll just change what we need to

m3d.nDims = 3;
m3d.nDofPerNode = 3;

%sort out nodes
nNodes2D = size(m.nodePos,2);

pr = rInner + (0:(nr-1))*dr; %row vector
pz = m.nodePos(1,:).'; %column vector
pc = m.nodePos(2,:).'; %column vector

%need to identify top and bottom rows and also scale appropriately
mx = max(pc);
mn = min(pc);

topRow = find(pc>mx-dr*1e-3); %allow a small tolerance
bottomRow = find(pc<mn+dr*1e-3);

pcRange = mx-mn+dr;

pth = (pc-mn)/pcRange*2*pi+pi;


PZ = pz*ones(1,nr);
PTh = pth*ones(1,nr);
PR = ones(nNodes2D,1)*pr;

PX = PR.*cos(PTh);
PY = PR.*sin(PTh);

%nNodes3D = nNodes2D*nr;

m3d = rmfield(m3d,'nodePos');
m3d.nodePos(1,:) = PX(:);
m3d.nodePos(2,:) = PY(:);
m3d.nodePos(3,:) = PZ(:);

%sort out elements

%do stitching together first
addEls = stitchNodes(m.nodePos(:,topRow),m.nodePos(:,bottomRow),topRow,bottomRow);

nNodesPerEl2D = size(m.elNodes,1);
nAddEls = size(addEls,2);

if nNodesPerEl2D == 3
    m.elNodes = [m.elNodes, addEls];
else
    %need to pad the triangle elements with zeros
    m.elNodes = [m.elNodes, [addEls;zeros(1,nAddEls)]];
end

nEls2D = size(m.elNodes,2);
nNodesPerEl3D = nNodesPerEl2D*2;
nElsr = nr - 1;

if nNodesPerEl2D == 4
    %could have some triangular elements in there
    shortEls = (m.elNodes(4,:) == 0);
    fullEls = (m.elNodes(4,:) ~= 0);
else
    shortEls = [];
    fullEls = 1:nEls2D;
end

elNodesSingle3D = zeros(nNodesPerEl3D, nEls2D);

%do a single layer of elements to start with
%deal with the 'full' element definitions first
elNodesSingle3D(1:nNodesPerEl2D,fullEls) = m.elNodes(:,fullEls);
elNodesSingle3D((1:nNodesPerEl2D)+nNodesPerEl2D,fullEls) = m.elNodes(:,fullEls)+nNodes2D;

%now deal with the elements which have gaps (triangles in a square mesh)
elNodesSingle3D(1:nNodesPerEl2D-1,shortEls) = m.elNodes(1:nNodesPerEl2D-1,shortEls);
elNodesSingle3D((1:nNodesPerEl2D-1)+nNodesPerEl2D-1,shortEls) ...
    = m.elNodes(1:nNodesPerEl2D-1,shortEls)+nNodes2D;

%then replicate this layer up, incrementing each time
elNodes3D = elNodesSingle3D(:)*ones(1,nElsr)...
    +ones(nEls2D*nNodesPerEl3D,1)*(0:nElsr-1)*nNodes2D;

elNodes3D(elNodesSingle3D(:) == 0, :) = 0;



elNodes3D = reshape(elNodes3D, [nNodesPerEl3D,nEls2D*nElsr]);
m3d.elNodes = elNodes3D;

%edit the element types
nElTypes = length(m.elTypes);
m3d.elTypes = cell(nElTypes,1);
for eCnt = 1:nElTypes
    m3d.elTypes{eCnt}.paramsType = m.elTypes{eCnt}.paramsType;
    if isfield(m.elTypes{eCnt},'paramValues')
        m3d.elTypes{eCnt}.paramValues = m.elTypes{eCnt}.paramValues;
    end
    if (strcmp(m.elTypes{eCnt}.name, 'CPE4R') || strcmp(m.elTypes{eCnt}.name, 'CPESR'))
        newName = 'C3D8R';
    elseif (strcmp(m.elTypes{eCnt}.name, 'CPE4') || strcmp(m.elTypes{eCnt}.name, 'CPS4'))
        newName = 'C3D8';
    elseif (strcmp(m.elTypes{eCnt}.name, 'CPE3') || strcmp(m.elTypes{eCnt}.name, 'CPS3'))
        newName = 'C3D6R';
    end
    m3d.elTypes{eCnt}.name = newName;
end

%replicate the references
m3d.elTypeRefs = reshape(m.elTypeRefs(:)*ones(1,nElsr),[],1);

if isfield(m,'matTypeRefs')
    m3d.matTypeRefs = reshape(m.matTypeRefs(:)*ones(1,nElsr),[],1);
end

end
