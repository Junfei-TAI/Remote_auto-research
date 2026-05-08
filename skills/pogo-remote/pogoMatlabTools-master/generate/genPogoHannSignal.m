function [ mOut ] = genPogoHannSignal( m, nCyc, freq, whichSig, whichShot, useCos, timeDelay, distCorr )
%genPogoHannSignal - add a Hann windowed signal to a model
%
%[ mOut ] = genPogoHannSignal( m, nCyc, freq[, whichSig[, whichShot[, useCos[, timeDelay[, distCorr]]]]] )
%
% m - input model
% mOut - output model
% nCyc, freq - number of cycles and frequency for signal
% whichSig - which signal number to apply it to (default 1)
% whichShot - which shot it should be put in (default 1)
% timeDelay - how much of a delay this signal should have (default 0)
% distCorr - apply distortion correction or not - remove inherent weighting
% which appears when exciting source in free space
%
% m.dt and m.nt must be defined prior to running this.
%
%Written by P. Huthwaite, 2017
%Added option to use cosine - PH June 2018
%Added time delay option - PH May 2020
%Added distortion correction - PH Sept 2020

if nargin < 8 || isempty(distCorr)
    distCorr = 0;
end
if nargin < 7 || isempty(timeDelay)
    timeDelay = 0;
end
if nargin < 6 || isempty(useCos)
    useCos = 0;
end
if nargin < 5 || isempty(whichShot)
    whichShot = 1;
end
if nargin < 4 || isempty(whichSig)
    whichSig = 1;
end




tSig = (0:m.nt-1)*m.dt;
sigLength = nCyc/freq;

wind = 0.5.*(1-cos(2*pi.*(tSig-timeDelay)./sigLength));
wind((tSig-timeDelay) < 0) = 0;
wind((tSig-timeDelay) > sigLength) = 0;


if isfield(m,'sigs')
    error('Old version defining model.sigs is not permitted with this function. Use shots.')
end

if useCos == 0
    sig = sin(2*pi*(tSig-timeDelay)*freq).*wind;
else
    sig = cos(2*pi*(tSig-timeDelay)*freq).*wind;
end
if distCorr
    %Apply correction in Fourier space
    sf = conj(fft(sig));

    df = 1/(m.dt*m.nt);
    f = (0:m.nt-1)*df;
    sf(m.nt/2:end) = 0;



    if ~isfield(m,'nDims')
        error('m.nDims field must be set to use distCorr')
    end
    if m.nDims == 2
        %correction because of 1/sqrt(kr)
        sf2 = sf.*sqrt(f);
    elseif m.nDims == 3
        %correction because of 1/kr
        sf2 = sf.*f;
    end

    sig2 = (2*ifft(conj(sf2)));
    sig = real(sig2)/max(abs(sig2));
end

% figure
% plot(tSig,sig)

m.shots{whichShot}.sigs{whichSig}.sig = sig;

m.shots{whichShot}.ntSig = m.nt;
m.shots{whichShot}.dtSig = m.dt;

m.metadata.centFreq = freq;
m.metadata.sigNumCycles = nCyc;

mOut = m;

end
