function [W, w0] = calcWAll(points, segs, l)
%[W, w0] = calcWAll(points, segs, l)
%
%points - points defining the corners
%segs - segments defining how the points are joined together
%  Note that the final ordering of the points around the boundary
%  should be anti-clockwise to ensure that the boundary is
%  properly defined.
%
%P Huthwaite Feb 2024

nPoints = size(points,2);
nSegs = size(segs,2);

if size(points,1) ~= 2
    error('points is wrong size: dim 1 should have size 2')
end

if size(segs,1) ~= 2
    error('segs is wrong size: dim 1 should have size 2')
end

nDims = 2;

W = zeros(nSegs,nDims);
w0 = zeros(nSegs,1);

%loop through the segments and calculate W values
for sCnt = 1:nSegs
    p1 = points(:,segs(1,sCnt));
    p2 = points(:,segs(2,sCnt));
    [wInd, w0Ind] = calcW(p1,p2,l);
    W(sCnt,:) = wInd;
    w0(sCnt) = w0Ind;
end

end
