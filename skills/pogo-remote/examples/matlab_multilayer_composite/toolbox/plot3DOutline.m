function plot3DOutline(X, Y, Z, dx, varargin)
% plot3DOutline - Plot only the outer contour/edges of a 3D point cloud.
%   plot3DOutline(X, Y, Z, dx) plots the outline using default marker size and color.
%   plot3DOutline(X, Y, Z, dx, markerSize, markerColor) allows customization.
%
%   X, Y, Z: vectors of coordinates (same size)
%   dx: mesh size (tolerance for edge detection)
%   markerSize: (optional) marker size for scatter3
%   markerColor: (optional) marker color for scatter3

    if nargin < 5
        markerSize = 8;
    else
        markerSize = varargin{1};
    end
    if nargin < 6
        markerColor = 'filled';
    else
        markerColor = varargin{2};
    end

    tol = dx / 2;

    xMin = min(X); xMax = max(X);
    yMin = min(Y); yMax = max(Y);
    zMin = min(Z); zMax = max(Z);

    isEdge_XY_zMin = abs(Z - zMin) < tol & ...
        (abs(X - xMin) < tol | abs(X - xMax) < tol | ...
         abs(Y - yMin) < tol | abs(Y - yMax) < tol);

    isEdge_XY_zMax = abs(Z - zMax) < tol & ...
        (abs(X - xMin) < tol | abs(X - xMax) < tol | ...
         abs(Y - yMin) < tol | abs(Y - yMax) < tol);

    isEdge_XZ_yMin = abs(Y - yMin) < tol & ...
        (abs(X - xMin) < tol | abs(X - xMax) < tol | ...
         abs(Z - zMin) < tol | abs(Z - zMax) < tol);

    isEdge_XZ_yMax = abs(Y - yMax) < tol & ...
        (abs(X - xMin) < tol | abs(X - xMax) < tol | ...
         abs(Z - zMin) < tol | abs(Z - zMax) < tol);

    isEdge_YZ_xMin = abs(X - xMin) < tol & ...
        (abs(Y - yMin) < tol | abs(Y - yMax) < tol | ...
         abs(Z - zMin) < tol | abs(Z - zMax) < tol);

    isEdge_YZ_xMax = abs(X - xMax) < tol & ...
        (abs(Y - yMin) < tol | abs(Y - yMax) < tol | ...
         abs(Z - zMin) < tol | abs(Z - zMax) < tol);

    isOutline = isEdge_XY_zMin | isEdge_XY_zMax | ...
                isEdge_XZ_yMin | isEdge_XZ_yMax | ...
                isEdge_YZ_xMin | isEdge_YZ_xMax;

    scatter3(X(isOutline)*1e3, Y(isOutline)*1e3, Z(isOutline)*1e3, markerSize, markerColor);
end