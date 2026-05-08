function [ m3d ] = extrudePogo( m, nz, dz )
%extrudePogo - extrude a 2D Pogo mesh into a 3D model
%   [ m3d ] = extrudePogo( m, nz, dz )
%
%m - 2d input model
%nz - number of desired points in the z (out of plane) direction
%dz - spacing in the z direction
%m3d - 3d output model
%
%z positions run from zero up to (nz-1)*dz
%
%Written by P Huthwaite Dec 2017

if nz == 1
    error('Cannot have 3D model 1 node thick. Change nz parameter.')
end

m3d = m; %copy everything, then we'll just change what we need to

m3d.nDims = 3;
if m.nDofPerNode == 2
    m3d.nDofPerNode = 3;
else
    m3d.nDofPerNode = 1;
end

%sort out nodes
nNodes2D = size(m.nodePos,2);

px = m.nodePos(1,:).'; %column vectors
py = m.nodePos(2,:).';

pz = (0:(nz-1))*dz; %row vector

PX = px*ones(1,nz);
PY = py*ones(1,nz);
PZ = ones(nNodes2D,1)*pz;

%nNodes3D = nNodes2D*nz;

m3d = rmfield(m3d,'nodePos');
m3d.nodePos(1,:) = PX(:);
m3d.nodePos(2,:) = PY(:);
m3d.nodePos(3,:) = PZ(:);

%sort out elements
nEls2D = size(m.elNodes,2);
nNodesPerEl2D = size(m.elNodes,1);
nNodesPerEl3D = nNodesPerEl2D*2;
nElsz = nz - 1;

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

%do a single layer of elements to start with
%deal with the 'full' element definitions first
elNodesSingle3D(1:nNodesPerEl2D,fullEls) = m.elNodes(:,fullEls);
elNodesSingle3D((1:nNodesPerEl2D)+nNodesPerEl2D,fullEls) = m.elNodes(:,fullEls)+nNodes2D;

%deal with the case where number of nodes per element is less than the
%maximum
elNodesSingle3D(1:nNodesPerEl2D-1,shortEls) = m.elNodes(1:nNodesPerEl2D-1,shortEls);
elNodesSingle3D((1:nNodesPerEl2D-1)+nNodesPerEl2D-1,shortEls) ...
    = m.elNodes(1:nNodesPerEl2D-1,shortEls)+nNodes2D;

%then replicate this layer up, incrementing each time
elNodes3D = elNodesSingle3D(:)*ones(1,nElsz)...
    +ones(nEls2D*nNodesPerEl3D,1)*(0:nElsz-1)*nNodes2D;

elNodes3D(elNodesSingle3D(:) == 0, :) = 0;

%elNodes3D = reshape(elNodes3D, [nNodesPerEl3D,nEls2D,nElsz]);

%loop around - actually don't do this because not rotating
% elNodes3D((1:nNodesPerEl2D)+nNodesPerEl2D,:,nCirc) = elNodes3D((1:nNodesPerEl2D),:,1);
% if nNodesPerEl2D == 4
%     elNodes3D(7:8,shortEls,:) = 0;
%     elNodes3D((1:nNodesPerEl2D-1)+nNodesPerEl2D-1,shortEls,nCirc) = elNodes3D((1:nNodesPerEl2D-1),shortEls,1);
% end

elNodes3D = reshape(elNodes3D, [nNodesPerEl3D,nEls2D*nElsz]);
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
    elseif (strcmp(m.elTypes{eCnt}.name, 'AC2D4'))
        newName = 'AC3D8';
	elseif (strcmp(m.elTypes{eCnt}.name, 'AC2D3'))
        newName = 'AC3D6';
    else
        error("2D element type %s not supported", m.elTypes{eCnt}.name)
    end
    m3d.elTypes{eCnt}.name = newName;
end

%replicate the references
m3d.elTypeRefs = reshape(m.elTypeRefs(:)*ones(1,nElsz),[],1);

if isfield(m,'matTypeRefs')
    m3d.matTypeRefs = reshape(m.matTypeRefs(:)*ones(1,nElsz),[],1);
end

end
