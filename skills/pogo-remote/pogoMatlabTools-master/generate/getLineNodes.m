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

%get vectors parallel and perpendicular to the line
v1 = [px(n2)-px(n1) py(n2)-py(n1) 0];
len = norm(v1);
v1 = v1 / len; %normalise it to a unit vector
v2 = cross(v1, [0 0 1]); %get perpendicular vector
v1 = v1/len; %include factor to ensure transform is on 0-1
v2 = v2/dx;
%coordinate transform:
ps = [px(:)-px(n1) py(:)-py(n1)] * v1(1:2).';
pt = [px(:)-px(n1) py(:)-py(n1)] * v2(1:2).';

% figure
% plot(px, py,'b.')



%pick out nodes to go into transducer
srcNodes = find(ps >= -1e-3 & ps <= 1.001 & abs(pt) < 0.02);


% figure
% plot(ps, pt,'k.')
% hold on
% plot(ps([srcNodes]), pt([srcNodes]),'g.')
% plot(ps([n1,n2]), pt([n1,n2]),'r.')
% grid on

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
