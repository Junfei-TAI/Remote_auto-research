function [ m3d ] = revolvePogo( m, nCirc, whichAxis )
%revolvePogo - take a 2D mesh and revolve it to make a 3D model
%   [ m3d ] = revolvePogo( m, nCirc, whichAxis )
%m - 2d input model
%nCirc - number of nodes around circumference
%whichAxis - which axis to do rotation around (defaults to x)
%m3d - 3d output model
%
%Written by P Huthwaite Aug 2017


if nargin < 3
    whichAxis = 1;
end

m3d = m; %copy everything, then we'll just change what we need to

m3d.nDims = 3;
m3d.nDofPerNode = 3;

%sort out nodes
nNodes2D = size(m.nodePos,2);

if whichAxis == 1
    pz = m.nodePos(1,:);
    pr = m.nodePos(2,:);
else
    pz = m.nodePos(2,:);
    pr = m.nodePos(1,:);
end

PZ = pz(:)*ones(1,nCirc);
PR = pr(:)*ones(1,nCirc);

pc = (0:nCirc-1)/nCirc*2*pi;

PC = ones(nNodes2D,1)*pc(:).';

PX = PR.*cos(PC);
PY = PR.*sin(PC);

m3d = rmfield(m3d,'nodePos');
m3d.nodePos(1,:) = PX(:);
m3d.nodePos(2,:) = PY(:);
m3d.nodePos(3,:) = PZ(:);

%sort out elements
nEls2D = size(m.elNodes,2);
nNodesPerEl2D = size(m.elNodes,1);
nNodesPerEl3D = nNodesPerEl2D*2;

if nNodesPerEl2D == 4
    %could have some triangular elements in there
    shortEls = (m.elNodes(4,:) == 0);
    fullEls = (m.elNodes(4,:) ~= 0);
else
    shortEls = [];
    fullEls = 1:nEls2D;
end

elNodesSingle3D = zeros(nNodesPerEl3D, nEls2D);

% elNodesSingle3D(1:nNodesPerEl2D,:) = m.elNodes(:,:);
% elNodesSingle3D((1:nNodesPerEl2D)+nNodesPerEl2D,:) = m.elNodes(:,:)+nNodes2D;

elNodesSingle3D(1:nNodesPerEl2D,fullEls) = m.elNodes(:,fullEls);
elNodesSingle3D((1:nNodesPerEl2D)+nNodesPerEl2D,fullEls) = m.elNodes(:,fullEls)+nNodes2D;

elNodesSingle3D(1:nNodesPerEl2D-1,shortEls) = m.elNodes(1:nNodesPerEl2D-1,shortEls);
elNodesSingle3D((1:nNodesPerEl2D-1)+nNodesPerEl2D-1,shortEls) ...
    = m.elNodes(1:nNodesPerEl2D-1,shortEls)+nNodes2D;

elNodes3D = elNodesSingle3D(:)*ones(1,nCirc)+ones(nEls2D*nNodesPerEl3D,1)*(0:nCirc-1)*nNodes2D;

elNodes3D = reshape(elNodes3D, [nNodesPerEl3D,nEls2D,nCirc]);
%loop around
elNodes3D((1:nNodesPerEl2D)+nNodesPerEl2D,:,nCirc) = elNodes3D((1:nNodesPerEl2D),:,1);
if nNodesPerEl2D == 4
    elNodes3D(7:8,shortEls,:) = 0;
    elNodes3D((1:nNodesPerEl2D-1)+nNodesPerEl2D-1,shortEls,nCirc) = elNodes3D((1:nNodesPerEl2D-1),shortEls,1);
end

elNodes3D = reshape(elNodes3D, [nNodesPerEl3D,nEls2D*nCirc]);
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
m3d.elTypeRefs = reshape(m.elTypeRefs(:)*ones(1,nCirc),[],1);

if isfield(m,'matTypeRefs')
    m3d.matTypeRefs = reshape(m.matTypeRefs(:)*ones(1,nCirc),[],1);
end

end
