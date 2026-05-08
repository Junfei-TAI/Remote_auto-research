function [ m ] = addAbsBound( m, xLims, yLims, zLims, nAbsVals, K, c, f0, doSrm )
%addAbsBound - add an absorbing boundary to a Pogo input file
%   [ mAbs ] = addAbsBound( m, xLims, yLims, zLims, nAbsVals, K, c, f0, doSrm )
%
%m - model to add absorbing boundary to
%mAbs - model with absorbing boundary added
%xLims, yLims, zLims - limit definitions in each dimension (zLims ignored
%in 2D). Set each to [] if unused (or omit).
%nAbsVals - number of 'layers' or material values to use. Defaults to 60.
%K - Maximum damping factor. A good parameter will be estimated if
%undefined.
%c - Material velocity used in calculating K. Omit and it will be
%calculated from the first material found in the absorbing region.
%f0 - Frequency used in calculating K. Will be estimated if not provided.
%doSrm - 1 use the stiffness reduction method (more efficient) [default], 0
%           don't use SRM
%
%NB - generally if performance is poor this is because boundary is not big
%enough
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
%xLims(1) corresponds to A, xLims(2) to B and so on. If just two are given,
%these are xLims(1) corresponds to C, xLims(2) corresponds to D (i.e. just
%a ramp upwards). The same holds for other dimensions.
%
%Generally, need around 1.5 lambda layer width for SRM, 3 lambda for ALID.
%
%Written by P. Huthwaite, 2017
%Updated with SRM, Feb 2018, PH
%Updated with support for acoustic materials 23rd April 2019, PH

if nargin < 9 || isempty(doSrm)
    doSrm = 1;
end

if nargin < 8 || isempty(f0)
    %take the first signal and get the dominant frequency
    df = 1/(m.shots{1}.ntSig*m.shots{1}.dtSig);
    spect = abs(fft(m.shots{1}.sigs{1}.sig));
    spect(round(m.shots{1}.ntSig/2):end) = 0;

    %take CoG of the spectrum
    fVect = (0:m.shots{1}.ntSig-1)*df;
    f0 = sum(fVect(:).*spect(:))/sum(spect(:));

    %old method - just get peak - issue with Gaussian type excitations
    %going to f0 = 0
    %[~, ind] = max(spect);
    %f0 = (ind-1)*df;
    fprintf('Centre frequency estimated as %6.4g Hz\n',f0)
end
if nargin < 7 || isempty(c)
    c = 0; %predict later from materials
end

if nargin < 6 || isempty(K)
    K = 0; %predict later from other params
end
if nargin < 5 || isempty(nAbsVals)
    nAbsVals = 60;
end

if nargin < 4
    zLims = [];
end
if nargin < 3
    yLims = [];
end


m.matTypeRefs = m.matTypeRefs(:);

[dampParam,l] = defineDampingParamCartesian(m,xLims,yLims,zLims);

m = addGeneralAbsBound(m,dampParam,l, nAbsVals, K, c, f0, doSrm);

end
