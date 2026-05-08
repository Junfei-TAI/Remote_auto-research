function [radius,deviation] = pipeSurfaceProfile_loadSurface(fN,r,type,d)
%% Load surface profile fomr file as both deviation from surface and radius to each point
% The surface should have the same number of points as the pipe mesh
%
%  fN   = filename to load
%  r    = radius to undeformed surface of mesh
%  type = is surface profile 'radius' or 'deviation'
%  d    = element size in radial direction
%
%   Sam Horne (2019)
%   sjh415@ic.ac.uk

disp(['Loading surface profile ',fN])
profile = load(fN)';

% Shift the profile such that (0,0) is at th=0
profile = flip(profile,2);
profile = circshift(profile,size(profile,2)/2,2);

% Calculate profiles
switch type
    case 'deviation'
        deviation = profile;
        radius = deviation + r;
    case 'radius'
        radius = profile;
        deviation = radius - r;

        % Remove small changes compared to the element size in the deviation profile
        % These may occur from deviation = radius - r; step due to
        % numerical effects
        % Setting them to exactly 0 allows these points to be skipped when
        % deforming the mesh saving computation time.
        deviation(abs(deviation) < d*1e-4) = 0;
end

end
