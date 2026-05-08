function [w, w0] = calcW3d(p1, p2, p3, l)
%[w, w0] = calcW(p1, p2, p3, l)
%
%p1 is the first point on the outer boundary
%p2 is the second
%p3 is the third
%l is the thickness of the absorbing boundary
% if l is [] or nan then g(x) is defined such that g(x) is zero at the three
% points, rather than one (needed for abs boundaries)
%w is the resulting weighting vector
%w0 is the offset term

if nargin < 4
    l = [];
end
if isnan(l)
    l = [];
end

p1 = p1(:);
p2 = p2(:);
p3 = p3(:);

dif1 = p2 - p1;
dif2 = p3 - p1;
n = cross(dif1, dif2);

%make it a unit vector:
n = n/sqrt(sum(n.^2));

if ~isempty(l)
    %define w - scale it such that it will go from 0-1 in a distance l
    w3 = -n./l;
end

%w0 should be defined that w*p1 + w0 = 1
%so w0 = 1-w*p1
w0 = 1-sum(w3.*p1);

%check:
%w0test = 1-sum(w3.*p2); %should give same w0

w = w3;
end
