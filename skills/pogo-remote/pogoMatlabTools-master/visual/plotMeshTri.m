function [ ] = plotMeshTri( m, LineSpec )
%Plot a triangular Pogo mesh
%Just a wrapper for Matlab's triplot(), so fairly fast and better for big models than plotMesh()

if nargin < 2
    triplot(m.elNodes.',m.nodePos(1,:),m.nodePos(2,:))
else
    triplot(m.elNodes.',m.nodePos(1,:),m.nodePos(2,:),LineSpec)
end


end
