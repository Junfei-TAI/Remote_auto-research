function [  ] = plotMesh( m, linecol )
%plotMesh - general routine for plotting the mesh from a 2D model
%
%	plotMesh( m, linecol )
%
% m - Pogo model struct
% linecol - line colour (and style) in the standard Matlab form (i.e. as in plot())
%Note that this is not fast for big models and plotMeshTri() is faster for 3-noded elements
%Written by PH 2017

    if nargin == 1
        linecol = 'k-';
    end
    if m.nDims ~= 2
        error('Only 2 dimensions supported here')
    end

    px = m.nodePos(1,:);
    py = m.nodePos(2,:);
    ord = m.elNodes;
    for eCnt = 1:size(m.elNodes,2)
        ord(ord(:,eCnt) == 0,eCnt) = ord(1,eCnt);
    end
    ord = [ord.' ord(1,:).'].';


    plot(px(ord),py(ord),linecol)
end
