function [ m3, delta ] = combinePogoMesh( m1, m2, n1, n2, shiftModel )
%combinePogoMesh - combine two Pogo meshes together
%   [ m3 ] = combinePogoMesh( m1, m2, n1, n2 );
%
%m1, m2 - input models to be combined
%         m1 is the 'master' - keeps any sources etc., these will be
%         dropped from 2
%m3 - output model
%n1 - stitching nodes in 1
%n2 - corresponding nodes in 2 in same position
%shiftModel - if nonzero then m2 is shifted so that the mean position of
%the two node sets are the same
%
%Written by P. Huthwaite, Aug 2017
%Updated June 2018, PH, include shiftModel

if nargin < 5
    shiftModel = 0;
end

if shiftModel
    m1Pos = mean(m1.nodePos(:,n1),2);
    m2Pos = mean(m2.nodePos(:,n2),2);
    nodeShift = m1Pos - m2Pos;
    m2.nodePos = m2.nodePos+nodeShift;
end
delta = m1.nodePos(:,n1) - m2.nodePos(:,n2);

if m1.nDims ~= m2.nDims
    error('Dimensions of the two models do not match')
end

ln1 = length(n1);
ln2 = length(n2);
if ln1 ~= ln2
    error('length(n1) ~= length(n2) - the node arrays should be equal in size')
end

nNodesM1 = size(m1.nodePos,2);
nNodesM2 = size(m2.nodePos,2);

%derive a node mapping for m2
nodeMap2r = 1:nNodesM2;
nodeMap2r(n2) = [];
%^ this then contains just the maintained nodes
nodeMap2 = zeros(nNodesM2,1);
nodeMap2(nodeMap2r) = (1:(nNodesM2-ln2))+nNodesM1; %what is the numbering of these nodes in the new model

%nodeMap2(nodeMap2 == 0) = n1; %out of order code

nodeMap2(n2) = n1; %the deleted nodes from m2 need to point to equiv in m1


%nodeMap2

m3 = m1;
elNodesTemp = m2.elNodes;
elNodesTemp(elNodesTemp == 0) = 1; %just to avoid indexing issues
elNodesTemp = nodeMap2(elNodesTemp);
elNodesTemp(m2.elNodes == 0) = 0;

nPerEl1 = size(m1.elNodes,1);
nPerEl2 = size(m2.elNodes,1);

if nPerEl2 > nPerEl1
    %need to expand
    nExtra = nPerEl2 - nPerEl1;
    nEls1 = size(m1.elNodes,2);
    m3.elNodes = [m3.elNodes; zeros(nExtra,nEls1)];
end
m3.elNodes = [m3.elNodes elNodesTemp];

nEt1 = length(m1.elTypes);
nEt2 = length(m2.elTypes);

for etCnt = 1:nEt2
    m3.elTypes{nEt1+etCnt} = m2.elTypes{etCnt};
end
elTypesTemp = m2.elTypeRefs+nEt1;
m3.elTypeRefs = [m1.elTypeRefs; elTypesTemp];

nodePosTemp = m2.nodePos;
nodePosTemp(:,n2) = [];
m3.nodePos = [m3.nodePos nodePosTemp];

if isfield(m2,'shots') || isfield(m2,'measSets') || isfield(m2,'nodeFix')
    warning('Non geometry related features found in m2. Ignoring.')
end

end
