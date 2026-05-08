function [dampingParam, l] = defineDampingParamCartesian(m, xLims, yLims, zLims)
%defineDampingParamSquare - define the damping parameter in Cartesian
%coordinates
%
%   [dampingParam, l] = defineDampingParamSquare(m, xLims, yLims, zLims)
%
% m - model
% xLims, yLims, zLims - define the boundary positions in each dimension
%
%Limits definitions
%------------------
%If four values contained in each array, defines the start and end points
%for the two 'ramps' in order from smallest dimensional value to largest. i.e.
%
%Damping coeff
%   ^
% K | ------                                              ------
%   |       --                                          --
%   |         ----                                  ----
%   |             -----                        -----
%   |                  ------            ------
% 0 |-----------------------------------------------------------
%   |       A               B            C                D
%
%xLims(1) corresponds to A, xLims(2) to B and so on.
% If we just wist to use A and B, then set xLims(3) and xLims(4) to NaN.
% If we just wist to use C and D, then set xLims(1) and xLims(2) to NaN.
%
%Written by P. Huthwaite, 10th April 2020

%get element centroids
[xm, ym, zm] = getElCents(m);

l = -1;%length
%upper and lower limits
if isempty(xLims)
    dampParamXL = zeros(size(xm));
    dampParamXU = zeros(size(xm));
elseif length(xLims) == 4
    %define up, down, down, up
    xl = xLims(2);
    xu = xLims(1);

    if isnan(xl) || isnan(xu)
        dampParamXL = zeros(size(xm));
    else
        l = abs(xl - xu);
        dampParamXL = (xm-xl)/(xu-xl);
        dampParamXL(dampParamXL < 0) = 0;
        dampParamXL(dampParamXL > 1) = 1;
    end

    xl = xLims(3);
    xu = xLims(4);

    if isnan(xl) || isnan(xu)
        dampParamXU = zeros(size(xm));
    else
        dampParamXU = (xm-xl)/(xu-xl);
        dampParamXU(dampParamXU < 0) = 0;
        dampParamXU(dampParamXU > 1) = 1;
    end
else
    error('xLims poorly defined')
end

if isempty(yLims)
    dampParamYL = zeros(size(ym));
    dampParamYU = zeros(size(ym));
elseif length(yLims) == 4
    %define up, down, down, up
    yl = yLims(2);
    yu = yLims(1);
    if isnan(yl) || isnan(yu)
        dampParamYL = zeros(size(ym));
    else
        if l < 0
            l = abs(yl - yu);
        end
        dampParamYL = (ym-yl)/(yu-yl);
        dampParamYL(dampParamYL < 0) = 0;
        dampParamYL(dampParamYL > 1) = 1;
    end

    yl = yLims(3);
    yu = yLims(4);
    if isnan(yl) || isnan(yu)
        dampParamYU = zeros(size(ym));
    else
        if l < 0
            l = abs(yl - yu);
        end
        dampParamYU = (ym-yl)/(yu-yl);
        dampParamYU(dampParamYU < 0) = 0;
        dampParamYU(dampParamYU > 1) = 1;
    end
else
    error('yLims poorly defined')
end


if m.nDims == 3
    if isempty(zLims)
        dampParamZL = zeros(size(zm));
        dampParamZU = zeros(size(zm));
    elseif length(zLims) == 4
        zl = zLims(2);
        zu = zLims(1);

        if isnan(zl) || isnan(zu)
            dampParamZL = zeros(size(zm));
        else
            if l < 0
                l = abs(zl - zu);
            end
            dampParamZL = (zm-zl)/(zu-zl);
            dampParamZL(dampParamZL < 0) = 0;
            dampParamZL(dampParamZL > 1) = 1;
        end

        zl = zLims(3);
        zu = zLims(4);
        if isnan(zl) || isnan(zu)
            dampParamZU = zeros(size(zm));
        else
            if l < 0
                l = abs(zl - zu);
            end
            dampParamZU = (zm-zl)/(zu-zl);
            dampParamZU(dampParamZU < 0) = 0;
            dampParamZU(dampParamZU > 1) = 1;
        end
    else
        error('zLims poorly defined')
    end
end

if m.nDims == 2
    dampingParam = max([dampParamXL(:) dampParamXU(:) dampParamYL(:) dampParamYU(:)].');
else
    dampingParam = max([dampParamXL(:) dampParamXU(:) dampParamYL(:) dampParamYU(:) dampParamZL(:) dampParamZU(:)].');
end



end
