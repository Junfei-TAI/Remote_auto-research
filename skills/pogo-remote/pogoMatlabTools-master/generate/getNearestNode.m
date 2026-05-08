function [node] = getNearestNode(m, pos)
%Get the nearest node in a Pogo mesh to a particular position
%[node] = getNearestNode(m, pos)
%
%m - Pogo model
%pos - positon vector, should be same number of dimensions as m
%node - output node
%
%Note probably not hugely efficient for cases where large numbers of nodes
%have to be extracted, particularly from large meshes. If you're trying to
%do this you probably have other issues to sort out anyway.
%
%Note that we do the L1 distance rather than L2 (Euclidian) to minimise calculations - this should not be
%too different
%
%Written P. Huthwaite Aug 2020

[~,node] = min(sum(abs(m.nodePos(:,:)-pos(:))));
end
