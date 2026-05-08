function [m] = pogoRampFilterSource(m, p, whichSig, whichShot)
%Add a ramp filter to a Pogo source (indicated by whichSig and whichShot)
%
% [m] = pogoRampFilterSource(m, p, whichSig, whichShot)
%
%m - model to operate on
%p - power - what power to raise the frequency to
%whichSig - which signal to filter
%whichShot - which shot to filter
%
%Written by P. Huthwaite, Nov 2020


    if nargin < 4 || isempty(whichShot)
        whichShot = 1;
    end
    if nargin < 3 || isempty(whichSig)
        whichSig = 1;
    end

    sig = m.shots{whichShot}.sigs{whichSig}.sig;

    sf = conj(fft(sig));

    df = 1/(m.dt*m.nt);
    f = (0:m.nt-1)*df;
    sf(m.nt/2:end) = 0;

    sf2 = sf.*power(f,p);

    sig2 = (2*ifft(conj(sf2)));
    sig = real(sig2)/max(abs(sig2));

    m.shots{whichShot}.sigs{whichSig}.sig = sig;
end
