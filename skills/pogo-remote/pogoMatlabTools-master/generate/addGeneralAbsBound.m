function [m] = addGeneralAbsBound(m, dampingParam, l, nAbsVals, K, c, f0, doSrm, doViscous)
%addGeneralAbsBound - adds an absorbing boundary defined based on an arbitrary damping
%parameter, enabling general absorbing boundaries to be generated
%
% [m] = addGeneralAbsBound(m, dampingParam, l, nAbsVals, K, c, f0, doSrm)
%
% m - model
% dampingParam - parameter varying from 0 to 1 - a vector of values for
% each element
% l - a representative length of the variation from 0 to 1, used to scale
% the damping parameters
% K - the desired damping coefficient (optional - will be estimated if not
% provided)
% c - a representative wave speed (optional, will be estimated if not
% provided)
% f0 - frequency (optional, will be estimated if not provided)
% doSrm - set to 1 if want to use SRM, 0 otherwise. Default is 1.
%
% Written by P. Huthwaite, 10th April 2020
% Updated to add viscous support Nov 2020

if nargin < 9 || isempty(doViscous)
    doViscous = 0;
end

if nargin < 8 || isempty(doSrm)
    doSrm = 1;
end
if doViscous
    doSrm = 0;
end

if nargin < 7 || isempty(f0)
    %take the first signal and get the dominant frequency
    df = 1/(m.shots{1}.ntSig*m.shots{1}.dtSig);
    spect = abs(fft(m.shots{1}.sigs{1}.sig));
    spect(round(m.shots{1}.ntSig/2):end) = 0;
    [~, ind] = max(spect);
    f0 = (ind-1)*df;
end
if nargin < 6 || isempty(c)
    c = 0; %predict later from materials
end

if nargin < 5 || isempty(K)
    K = 0; %predict later from other params
end
if nargin < 4 || isempty(nAbsVals)
    nAbsVals = 60;
end

changeEls = find(dampingParam < 1 & dampingParam > 0);

if isempty(changeEls)
    error('No elements found to change')
end

%check materials present in the area already
changeMats = unique(m.matTypeRefs(changeEls));
if isempty(changeMats)
    error('No materials found to change')
end

%check that materials are not already absorbing boundary materials...
nChangeMats = length(changeMats);
for mCnt = 1:nChangeMats
    if isfield(m.matTypes{changeMats(mCnt)},'parent') && m.matTypes{changeMats(mCnt)}.parent ~= 0
        %warn here
        warning(['Materials with parent materials found in area of absorbing boundaries. '...
                'This indicates that you are trying to add absorbing boundaries over '...
                'absorbing boundaries, which will be inefficient. Use a single call '...
                'to add the boundaries, or remove the previous boundaries first.'])
        break;
    end
end


%need a pointer to the changed material from the existing material
matInvMap = zeros(length(m.matTypes),1);
for cnt = 1:length(changeMats)
    matInvMap(changeMats(cnt)) = cnt;
end

nChangeMats = length(changeMats);

%get params from each material
if K == 0
    if doViscous
        error('Cannot add viscous damping without a scaling term provided')
    end

    K = zeros(nChangeMats,1);
    E = zeros(nChangeMats,1);
    for matType = 1:nChangeMats
        matNum = changeMats(matType);
        if m.matTypes{matNum}.paramsType == 4 || m.matTypes{matNum}.paramsType == 5
            c = m.matTypes{matNum}.paramValues(1);
        else
            if m.matTypes{matNum}.paramsType ~= 0 && m.matTypes{matNum}.paramsType ~= 6
                if c == 0
                    error('Need a velocity value input if not using isotropic materials')
                end
            else
                E(matType) = m.matTypes{matNum}.paramValues(1);
                nu = m.matTypes{matNum}.paramValues(2);
                rho = m.matTypes{matNum}.paramValues(3);
                c0 = sqrt(E(matType)*(1-nu)/(rho*(1+nu)*(1-2*nu)));
                % cSh = sqrt(E/(2*rho*(1+nu)));
                c = c0;
            end
        end


        if doSrm
            K(matType) = 2*pi*f0;
        else
            K(matType) = getDamping(0.01,3,l,c,f0);
        end
        fprintf('K parameter for material %d set to %6.4g per second\n',changeMats(matType),K(matType))
        %end
    end
end


nNewMats = nChangeMats*nAbsVals;
nInitMats = length(m.matTypes);

%define new materials
P = 3;
%alphaVals = ((1:nAbsVals)/nAbsVals).^3;
Xparam = ((1:nAbsVals)/nAbsVals);
newMats = cell(1,nNewMats);

for mCnt = 1:nChangeMats
    mNum = changeMats(mCnt);
    pType = m.matTypes{mNum}.paramsType;
    %get param values, stripping off damping if present
    prevAlpha = 0;
    if pType == 0
        prevParams = m.matTypes{mNum}.paramValues(1:3);
        if length(m.matTypes{mNum}.paramValues) >= 4
            prevAlpha = m.matTypes{mNum}.paramValues(4);
        end
        if doViscous
            warning('Viscous damping unsupported with material type %d', pType)
        end
        denNum = 3;
    elseif pType == 1 || pType == 3
        prevParams = m.matTypes{mNum}.paramValues(1:10);
        if length(m.matTypes{mNum}.paramValues) >= 11
            prevAlpha = m.matTypes{mNum}.paramValues(11);
        end
        denNum = 10;
        if doViscous
            warning('Viscous damping unsupported with material type %d', pType)
        end
        if doSrm
            error('Only isotropic materials supported for SRM')
        end
    elseif pType == 2
        prevParams = m.matTypes{mNum}.paramValues(1:22);
        if length(m.matTypes{mNum}.paramValues) >= 23
            prevAlpha = m.matTypes{mNum}.paramValues(23);
        end
        denNum = 22;
        if doViscous
            warning('Viscous damping unsupported with material type %d', pType)
        end
        if doSrm
            error('Only isotropic materials supported for SRM')
        end
    elseif pType == 4
        %acoustic material
        prevParams = m.matTypes{mNum}.paramValues(1:2);
        if doViscous
            warning('Viscous damping unsupported with material type %d', pType)
        end
        denNum = 2;
        if length(m.matTypes{mNum}.paramValues) >= 3
            prevAlpha = m.matTypes{mNum}.paramValues(3);
        end
    elseif pType == 5
        prevParams = m.matTypes{mNum}.paramValues(1:3);
        denNum = 2;
        if length(m.matTypes{mNum}.paramValues) >= 4
            prevAlpha = m.matTypes{mNum}.paramValues(4);
        end
        if doViscous
            viscPos = 3;
            prevVisc = m.matTypes{mNum}.paramValues(3);
        end
    elseif pType == 6
        prevParams = m.matTypes{mNum}.paramValues(1:4);
        denNum = 3;
        if length(m.matTypes{mNum}.paramValues) >= 5
            prevAlpha = m.matTypes{mNum}.paramValues(5);
        end
        if doViscous
            viscPos = 4;
            prevVisc = m.matTypes{mNum}.paramValues(4);
        end
    else
        error('Unrecognised material type')
    end
    for aCnt = 1:nAbsVals
        newMatNum = (mCnt-1)*nAbsVals+aCnt;
        newMats{newMatNum}.paramsType = pType;

        newParams = prevParams;



        cVal = prevAlpha + Xparam(aCnt).^P*K(mCnt); %this is the damping (alpha) term

        if doSrm
            k0 = 2*pi*f0/c;

            alphaMax = -log(0.01)/(k0*l);
            if pType == 4
                %acoustic
                kPrev = prevParams(1).^2*prevParams(2); %c^2*rho
                kNew = kPrev*exp(-(alphaMax*Xparam(aCnt).^P)*k0*(Xparam(aCnt)*l));

                newParams(1) = sqrt(kNew/prevParams(2)); %c = sqrt(K/rho)
            else
                newParams(1) = prevParams(1)*exp(-(alphaMax*Xparam(aCnt).^P)*k0*(Xparam(aCnt)*l));
            end
        end

        if doViscous
            cVal = prevVisc + Xparam(aCnt).^P*K(mCnt); %this is the damping term

            newMats{newMatNum}.paramValues = newParams(:).';
            newMats{newMatNum}.paramValues(viscPos) = cVal;
        else
            newMats{newMatNum}.paramValues = [newParams(:).' cVal];
        end

        newMats{newMatNum}.parent = mNum;
    end
end

m.matTypes = [m.matTypes(:).' newMats];
clear newMats

dampingParam = reshape(dampingParam,size(m.matTypeRefs));

newMatTypeRefs = nInitMats+(matInvMap(m.matTypeRefs(changeEls(:)))-1)*nAbsVals...
    +round(dampingParam(changeEls(:))*(nAbsVals)+0.5);

m.matTypeRefs(changeEls) = newMatTypeRefs;

end
