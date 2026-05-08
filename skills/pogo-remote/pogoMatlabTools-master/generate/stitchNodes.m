function [elNodesJoin] = stitchNodes(nodePos1, nodePos2, nodeNums1, nodeNums2)
%stitchNodes - stitch two lines of nodes together with elements
%
%   [elNodesJoin] = stitchNodes(nodePos1, nodePos2, nodeNums1, nodeNums2)
%
% nodePos1, nodePos2 - nodal positions, as defined in the model struct
% (size nDims x nNodes). These do not need to be the same size.
% nodeNums1, nodeNums2 - vectors containing the corresponding node numbers.
% These do not need to be in order.
% elNodesJoin - the elements joining the two rows of nodes. These are
% triangular elements. The matrix is 3 x nTris, so each column corresponds
% to a triangle.
%
% The two rows of nodes should be 1 element size apart for best results.
% This could be useful for joining two 2D meshes together
% It is used in the wrapMesh routine.
% Written by P Huthwaite, April 2020


%transpose nodePos
nodePos1 = nodePos1.';
nodePos2 = nodePos2.';

n1 = size(nodePos1,1);
n2 = size(nodePos2,1);
n = n1+n2;

%get the direction
dir = nodePos1(end,:)-nodePos1(1,:);
mag = norm(dir);
dir = dir / mag;


%get normalised values
posDir = [nodePos1*dir.'-mag*1e-5;nodePos2*dir.'];
whichSet = [zeros(n1,1)+1;zeros(n2,1)+2];
nodeNumsAll = [nodeNums1(:); nodeNums2(:)];

[posDirSort,ind] = sort(posDir);

whichSetSort = whichSet(ind);

nodeNumsSort = nodeNumsAll(ind);


%set counter
p = 1;

triList = [];
while 1

    %loop through the crossings
    %want a list of nodes from one crossing to the next (except first and
    %last cases

    %get a list of these nodes first


    consNodes = [];

    while 1
        consNodes = [consNodes; p];
        p = p+1;
        if p > n
            break;
        end
        if length(consNodes) ~= 1 && whichSetSort(p) ~= whichSetSort(p-1) %if we have a switch after the first one
            consNodes = [consNodes; p];
            break;
        end
    end

    %put back by 1 for next time
    p = p - 1;

    %disp(nodeNumsSort(consNodes))

    nTris = length(consNodes)-2;

    if nTris == 0
        break;
    end

    if nTris == 1
        %decide whether to flip based on middle node
        triList = [triList; reshape(consNodes,[1,3])];

    else




        if whichSetSort(consNodes(2)) == whichSetSort(consNodes(1))

            %one flip at end

            for tCnt = 1:nTris
                triList = [triList; reshape(consNodes([end, tCnt, tCnt+1]),[1,3])];
            end

        elseif whichSetSort(consNodes(end-1)) == whichSetSort(consNodes(end))

            %one flip at start

            for tCnt = 1:nTris
                triList = [triList; reshape(consNodes([1, tCnt+1, tCnt+2]),[1,3])];
            end

        else

            %this all assumes two flips

            %get the midpoint node which will make the triangle with the
            %opposite side
            %get distance from midpoint for each node
            %take the smallest distance

            %get middle distance first
            midDist = 0.5*(posDirSort(consNodes(1))+posDirSort(consNodes(end)));

            %get the distance from that
            distFromMid = posDirSort(consNodes)-midDist;

            %take the point with the smallest (abs) distance
            [~, whichMid] = min(abs(distFromMid));


            nTrisA = whichMid - 2;
            nTrisB = nTris - 1 - nTrisA;
            for tCnt = 1:nTrisA
                triList = [triList; reshape(consNodes([1, tCnt+1, tCnt+2]),[1,3])];
            end
            triList = [triList; reshape(consNodes([end, whichMid, 1]),[1,3])]; %#ok<*AGROW>
            for tCnt = 1:nTrisB
                triList = [triList; reshape(consNodes([end, tCnt-1+whichMid, tCnt-1+whichMid+1]),[1,3])];
            end
        end
    end




    if p == n
        break
    end

end

nodePosAll = [nodePos1; nodePos2];
nodePosSort = nodePosAll(ind,:);

%correct ordering of triangles (anticlockwise) if necessary
nTris = size(triList,1);
for tCnt = 1:nTris
    ax = nodePosSort(triList(tCnt,2),1)-...
        nodePosSort(triList(tCnt,1),1);
    ay = nodePosSort(triList(tCnt,2),2)-...
        nodePosSort(triList(tCnt,1),2);
    bx = nodePosSort(triList(tCnt,3),1)-...
        nodePosSort(triList(tCnt,2),1);
    by = nodePosSort(triList(tCnt,3),2)-...
        nodePosSort(triList(tCnt,2),2);
    cp = ax*by - ay*bx; %cross product

    if cp < 0
        %wrong way round - need to flip
        tempNode = triList(tCnt,3);
        triList(tCnt,3) = triList(tCnt,2);
        triList(tCnt,2) = tempNode;
    end

end

%rearrange all nodes to true original node numbers
elNodesJoin = nodeNumsSort(triList).';

end
