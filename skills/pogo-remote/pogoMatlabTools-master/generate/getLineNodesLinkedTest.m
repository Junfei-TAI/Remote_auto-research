function [srcNodes, nodeWeight, nodePos, len, v1, v2] = getLineNodes(m, n1, n2, dx)
% Routine for finding source nodes on line and weighting
% [srcNodes, nodeWeight, nodePos, len, v1, v2] = getLineNodes(m, n1, n2, dx)
%
%m - model
%n1 - first node on line
%n2 - last node on line
%dx - spacing
%
%srcNodes - what are the nodes on the line
%nodeWeight - what weight do they have
%nodePos - what are their normalised positions
%len - what is the length of the line
%v1 - what is the vector along the line
%v2 what is a vector perpendiculat to the line
%
%Written by P. Huthwaite
%Updated with documentation Aug 2020

px = m.nodePos(1,:);
py = m.nodePos(2,:);
%------------------

%get vector parallel to line
v1 = [px(n2)-px(n1) py(n2)-py(n1) 0];
len = norm(v1);
v1 = v1 / len; %normalise it to a unit vector

currNode = n1;

srcNodesLenEst = 2 * ceil(len/dx); %be conservative by doubling it
srcNodes = zeros(srcNodesLenEst,1);
currNodeIndex = 1;
srcNodes(currNodeIndex) = currNode;
currNodeIndex = currNodeIndex + 1;
while 1
	%find linked nodes
	linkedEls = find(sum(int32(m.elNodes == currNode),1)>0);
    linkedNodes = unique(m.elNodes(:,linkedEls));
    linkedNodes = linkedNodes(:);

    relVect = [px(linkedNodes).'-px(currNode) py(linkedNodes).'-py(currNode) zeros(length(linkedNodes),1)];
    relVect = relVect ./ vecnorm(relVect,2,2);
    dotProd = relVect*v1.';

    [res,whichOne] = min(abs(1-dotProd));

    nextNode = linkedNodes(whichOne);


    if res > 0.01
        warning("Closest node found %d is not well aligned with line",nextNode)
    end

    currNode = nextNode

    srcNodes(currNodeIndex) = currNode;
    currNodeIndex = currNodeIndex + 1;

    if nextNode == n2
        break
    end
    if currNodeIndex == srcNodesLenEst
        error("Too many nodes found - suggests poorly defined mesh")
    end


end

return

%get vectors parallel and perpendicular to the line
v2 = cross(v1, [0 0 1]); %get perpendicular vector
v1 = v1/len; %include factor to ensure transform is on 0-1
v2 = v2/dx;
%coordinate transform:
ps = [px(:)-px(n1) py(:)-py(n1)] * v1(1:2).';
pt = [px(:)-px(n1) py(:)-py(n1)] * v2(1:2).';

%pick out nodes to go into transducer
srcNodes = find(ps >= -1e-3 & ps <= 1.001 & abs(pt) < 0.01);
nodePos = ps(srcNodes);

%need to sort into order:
[nodePos, ind] = sort(nodePos);
srcNodes = srcNodes(ind);

%nSrcNodes = length(srcNodes);

gaps = (nodePos(2:end)-nodePos(1:end-1))*len;
nodeWeight = ([gaps(:).' dx] + [dx gaps(:).'])/2;

%correct to given a certain amount per unit length
nodeWeight = nodeWeight(:)/sum(nodeWeight)*len;
nodePos = nodePos(:);
srcNodes = srcNodes(:);

end
