function [dampingParam, l] = defineDampingParamRadial(m, radiusLimits, centre)
%defineDampingParamRadial - define the damping parameter in polar
%coordinates relative to a particular centre
%
%   [dampingParam, l] = defineDampingParamRadial(m, radiusLimits, centre)
%
% Define the level of damping in a polar cooordinates.
% m is the model struct
% radiusLimits is a vector containing the two limits (inner and outer) for
% the start and end of the ramp
% centre (optional, defaults to zero) is an N-dimensional vector indicating
% the centre position
%
% Written by P. Huthwaite, 10th April 2020

%get element centroids
[xm, ym, zm] = getElCents(m);

l = radiusLimits(2) - radiusLimits(1);

if nargin < 3
    centre = zeros(1, m.nDims);
end

%calculate the distance of each element from the centre
rm2 = (xm-centre(1)).^2 + (ym-centre(2)).^2;
if m.nDims == 3
    rm2 = rm2 + (zm-centre(3)).^2;
end

rm = sqrt(rm2);

dampingParam = (rm-radiusLimits(1))/l;
dampingParam(dampingParam < 0) = 0;
dampingParam(dampingParam > 1) = 1;

end
