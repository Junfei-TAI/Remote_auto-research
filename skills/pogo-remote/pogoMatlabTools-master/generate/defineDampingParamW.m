function [dampingParam,l] = defineDampingParamW(m, W, w0, Wlim, w0lim)
%defineDampingParamW - define the damping parameter based on weighting
%vectors. See cartesian version for an overview of what we're doing.
%
%   [dampingParam, l] = defineDampingParamW(m, W, w0, Wlim, w0lim)
%
%The weighting vectors which are combined to form W (each is a row) each
%give a direction. w0 gives an offset.
%
%Taking each element centre as x, we can calculate g(x) = w*x + w0. g will
%give the damping parameter, limited to between 0 and 1. w should be scaled
% such that a suitable width will be generated.
%
% For the limit values Wlim, w0lim (both optional), g(x) is again
% calculated. Where g(x) < 0, absorbing boundaries are not applied. Where
% multiple Wlim values are provided, g(x) must be positive for all. This
% defines a concave region where the absorbing boundaries are applied.
%
%Written by P. Huthwaite, 18th November 2023

if nargin < 4
    Wlim = [];
    w0lim = [];
end

[nRows, nParams] = size(W);
if nParams ~= m.nDims
    error("Number of parameters indicated by w, %d, does not match the dimensions in the model, %d", nParams, m.nDims)
end

[nRowsW0, nColsW0] = size(w0);
if nColsW0 ~= 1
    error("Incorrect shape of w0")
end
if nRowsW0 ~= nRows
    error("Incorrect shape of w0")
end


%get element centroids
[xm, ym, zm] = getElCents(m);

X = [xm(:), ym(:), zm(:)].';

g = W*X + w0;

g(g < 0) = 0;
g(g > 1) = 1;


dampingParam = max(g, [], 1);

if ~isempty(Wlim)
    g2 = Wlim*X + w0lim;
    appBound = min(g2, [], 1);

    dampingParam(appBound < 0) = 0;
end

lVals = 1./sqrt(sum(W.^2,2));
l = min(lVals);

end
