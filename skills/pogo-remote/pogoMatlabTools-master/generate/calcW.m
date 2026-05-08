function [w, w0] = calcW(p1, p2, l)
%[w, w0] = calcW(p1, p2, l)
%
%p1 is the first point on the outer boundary
%p2 is the second
%l is the thickness of the absorbing boundary
%w is the resulting weighting vector
%w0 is the offset term

if nargin < 3
    l = [];
end
if isnan(l)
    l = [];
end

p1 = [p1(:); 0];
p2 = [p2(:); 0];
dif = p2 - p1;
oop = [0; 0; 1];
n = cross(dif, oop); %going from p1 to p2, n points right, outwards

%make it a unit vector:
n = n/sqrt(sum(n.^2));

if ~isempty(l)
    %define w - scale it such that it will go from 0-1 in a distance l
    w3 = n./l;
end

%w0 should be defined that w*p1 + w0 = 1
%so w0 = 1-w*p1
w0 = 1-sum(w3.*p1);

%check:
%w0test = 1-sum(w3.*p2); %should give same w0

w = w3(1:2);
end
