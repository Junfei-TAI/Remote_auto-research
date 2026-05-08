function [ K ] = getDamping( r, P, l, c, freq )
%getDamping - get a suitable damping factor for an absorbing boundary
%   [ K ] = getDamping( r, P, l, c, freq )
%
% r - target reflection coefficient - set this to something like 0.01
% P - power (generally 3) of the damping variation through the layer
% l - length of absorbing boundary
% c - wave speed
% freq - frequency
%
%Written by P. Huthwaite Aug 2017

%initial guess from binomial expansion
qTarg = -log(r);
K = qTarg*2*c/l*(P+1);

nAbsVals = 1000;
X = (1:nAbsVals)/nAbsVals;

for iCnt = 1:100
    kImag = 2*pi*freq/c*imag(sqrt(1+1i*K.*X.^P/(2*pi*freq)));
    qTest = sum(kImag)/nAbsVals*l;

    K = K/qTest*qTarg;%use binomial behaviour to update

    if abs(qTest-qTarg)/qTarg < 0.01
        break
    end
end

end
