function [ mUpdated ] = updateModel( model )
%updateModel - legacy support - updates an older struct to the latest
%format, enabling latest functions to be used.
%   [ mUpdated ] = updateModel( model )
%
%model - existing model
%mUpdated - updated model struct
%
%NB - also checks integrity of struct, i.e. that everything is correct.
%
%Written by Peter Huthwaite, Dec 2016

if ~isfield(model,'prec')
    model.prec = 8;
end
mUpdated.prec = model.prec;

if ~isfield(model,'nDims')
    error('model.nDims field must be set')
end
if model.nDims < 1 || model.nDims > 3
    error('model.nDims field is set to %d, must be in range 1-3.', model.nDims)
end
mUpdated.nDims = model.nDims;

if ~isfield(model,'nDofPerNode')
    fprintf('model.nDofPerNode not set; setting to %d.\n',model.nDims)
    model.nDofPerNode = model.nDims;
end
if model.nDofPerNode < 1 || model.nDofPerNode > 3
    error('model.nDofPerNode field is set to %d, must be in range 1-3.', model.nDofPerNode)
end
if model.nDofPerNode ~= 1 && model.nDofPerNode ~= model.nDims
    warning('Mismatch between model.nDofPerNode = %d and model.nDims = %d', model.nDofPerNode, model.nDims)
end
mUpdated.nDofPerNode = model.nDofPerNode;

if ~isfield(model,'notes')
    model.notes = blanks(1024);
end
notesTemp = deblank(model.notes);
l = length(notesTemp);
model.notes = blanks(1024);
model.notes(1:l) = notesTemp;
model.nodes(l+1) = 0;
mUpdated.notes = model.notes;

if isfield(model,'runName')
   mUpdated.runName = model.runName;
end


if ~isfield(model,'nt')
    error('model.nt field must be set')
end
mUpdated.nt = model.nt;

if ~isfield(model,'dt')
    error('model.dt field must be set')
end
mUpdated.dt = model.dt;

if ~isfield(model,'nNodes')
    %error('model.nNodes field must be set')
    model.nNodes = size(model.nodePos,2);
end
%mUpdated.nNodes = model.nNodes;

if ~isfield(model,'nodePos')
    error('model.nodePos field must be set')
end
if size(model.nodePos,1) ~= model.nDims || size(model.nodePos,2) ~= model.nNodes
    error('model.nodePos must have size model.nDims x model.nNodes')
end
mUpdated.nodePos = model.nodePos;

%-----------------------------------------------------
%elements:
if ~isfield(model,'elNodes')
    error('model.elNodes field must be set')
end
if ~isfield(model,'nEls')
    %error('model.nEls field must be set')
    model.nEls = size(model.elNodes,2);
end

if ~isfield(model,'nNodesPerEl')
    %error('model.nNodesPerEl field must be set')
    model.nNodesPerEl = size(model.elNodes,1);
end
mUpdated.nNodesPerEl = model.nNodesPerEl;

%-----------------------------------------------------
%element references:
if ~isfield(model,'elTypeRefs')
    error('model.elTypesRefs field must be set')
end
mUpdated.elTypeRefs = model.elTypeRefs(:);
if length(model.elTypeRefs) ~= model.nEls
    error('model.elTypeRefs must have length model.nEls')
end
%check it's 1-indexed:
if min(model.elTypeRefs(:)) <= 0
    error('model.elTypeRefs must be 1-indexed')
end

if ~isfield(model,'matTypeRefs')
    error('model.matTypesRefs field must be set')
end
mUpdated.matTypeRefs = model.matTypeRefs(:);
if length(model.matTypeRefs) ~= model.nEls
    error('model.matTypeRefs must have length model.nEls')
end
%check it's 1-indexed:
if min(model.matTypeRefs(:)) <= 0
    error('model.matTypeRefs must be 1-indexed')
end


if ~isfield(model,'orientRefs')
    model.orientRefs = zeros(model.nEls,1);
    %error('model.orientRefs field must be set')
end
mUpdated.orientRefs = model.orientRefs(:);
if length(model.orientRefs) ~= model.nEls
    error('model.orientRefs must have length model.nEls')
end
%check it's 1-indexed:
if min(model.orientRefs(:)) <= -1 %NB unused values are set to 0, or -1 in zero indexing
    error('model.orientRefs must be 1-indexed')
end
%-----------------------------------------------------

if size(model.elNodes,1) ~= model.nNodesPerEl || size(model.elNodes,2) ~= model.nEls
    error('model.elNodes must have size model.nNodesPerEl x model.nEls')
end
%check it's 1-indexed:
if min(model.elNodes(:)) < 0 %NB unused set to 0, or -1 in zero indexing
    error('model.elNodes must be 1-indexed')
end
if max(model.elNodes(:)) > model.nNodes
    error('model.elNodes points to nodes which are greater than the number of nodes')
end
mUpdated.elNodes = model.elNodes;

%-----------------------------------------------------

if ~isfield(model,'elTypes')
    error('model.elTypes is not defined.')
end
model.nElTypes = length(model.elTypes);
if max(model.elTypeRefs(:)) > model.nElTypes
    error('Range error on model.elTypeRefs, greater than length(model.elTypes)')
end

for eCnt = 1:model.nElTypes
    if ~isfield(model.elTypes{eCnt},'name')
        error('model.elTypes{%d}.name is not defined.',eCnt)
    end

    if ~isfield(model.elTypes{eCnt},'paramsType')
        %warning('model.elTypes{%d}.paramsType is not defined.\nSetting to 0.',eCnt)
        model.elTypes{eCnt}.paramsType = 0;
    end


    model.elTypes{eCnt}.paramValues = model.elTypes{eCnt}.paramValues(:);

end
mUpdated.elTypes = model.elTypes;

%-----------------------------------------------------


if ~isfield(model,'matTypes')
    error('model.matTypes is not defined.')
end
model.nMatTypes = length(model.matTypes);
if max(model.matTypeRefs(:)) > model.nMatTypes
    error('Range error on model.matTypeRefs, greater than length(model.matTypes)')
end

for eCnt = 1:model.nMatTypes

    if ~isfield(model.matTypes{eCnt},'paramsType')
        %warning('model.matTypes{%d}.paramsType is not defined.\nSetting to 0.',eCnt)
        model.matTypes{eCnt}.paramsType = 0;
    end
    %fwrite(fid, model.matTypes{eCnt}.paramsType, 'int32');

    if ~isfield(model.matTypes{eCnt},'paramValues')
        error('model.matTypes{%d}.paramValues is not defined.',eCnt)
    end
    model.matTypes{eCnt}.paramValues = model.matTypes{eCnt}.paramValues(:);
    %nMatParams = length(model.matTypes{eCnt}.paramValues);
    %fwrite(fid, nMatParams, 'int32');
    %fwrite(fid, model.matTypes{eCnt}.paramValues, precString);
end
mUpdated.matTypes = model.matTypes;


%-----------------------------------------------------

if ~isfield(model,'or')
    %error('model.or is not defined.')
    model.nOr = 0;
else
    model.nOr = length(model.or);
end

%fwrite(fid, model.nOr, 'int32');
if model.nOr > 0
    if max(model.orientRefs(:)) > model.nOr
        error('Range error on model.orientRefs, greater than length(model.or)')
    end
else
    if max(model.orientRefs(:)) ~= 0 || min(model.orientRefs(:)) ~= 0
        error('model.or undefined, so orientRefs should all be 0')
    end
end

for eCnt = 1:model.nOr

    if ~isfield(model.or{eCnt},'paramsType')
        error('model.or{%d}.paramsType is not defined.',eCnt)
    end
    %fwrite(fid, model.or{eCnt}.paramsType, 'int32');

    if ~isfield(model.or{eCnt},'paramValues')
        error('model.or{%d}.paramValues is not defined.',eCnt)
    end
    model.or{eCnt}.paramValues = model.or{eCnt}.paramValues(:);
    %nOrParams = length(model.or{eCnt}.paramValues);
    %fwrite(fid, nOrParams, 'int32');
    %fwrite(fid, model.or{eCnt}.paramValues, precString);
end
if isfield(model,'or')
    mUpdated.or = model.or;
end

%-----------------------------------------------------

if ~isfield(model,'fixNodes')
    model.nFixDof = 0;
    %fwrite(fid, model.nFixDof, 'int32');
else
    if ~isfield(model,'fixDof')
        error('model.fixNodes defined but model.fixDof not.')
    end
    model.fixNodes = model.fixNodes(:);
    model.fixDof = model.fixDof(:);
    model.nFixDof = length(model.fixNodes);
    if model.nFixDof ~= length(model.fixDof)
        error('model.fixNodes and model.fixDof have different lengths.')
    end
    %fwrite(fid, model.nFixDof, 'int32');
    n = model.fixNodes;
    d = model.fixDof;
    if max(n(:)) > model.nNodes || min(n(:)) <= 0
        error('Range error on model.fixNodes. Should be 1 indexed node values')
    end
    if max(d(:)) > model.nDofPerNode || min(d(:)) <= 0
        error('Range error on model.fixDof. Should be 1 indexed DOF values')
    end
    model.fixDofD = (n(:)-1) * 4 + d(:)-1;

    %fwrite(fid, model.fixDofD, 'int32');

end
mUpdated.fixNodes = model.fixNodes;
mUpdated.fixDof = model.fixDof;

%-----------------------------------------------------

if isfield(model,'ties')
%if fileVer >= 1.06
    nTieSets = length(model.ties);
    fwrite(fid, nTieSets, 'int32');

    for tCnt = 1:nTieSets
        if ~isfield(model.ties{tCnt},'tieTransform')
            error('Missing tie transform information for tie set %d',tCnt)
        end
        %fwrite(fid,model.ties{tCnt}.tieTransform,precString);

        if ~isfield(model.ties{tCnt},'masterNodes') || ~isfield(model.ties{tCnt},'slaveNodes')
            error('Missing master nodes or slave nodes definition for tie set %d',tCnt)
        end
        %model.ties{tCnt}.tieTransform = fread(fid,[model.nDofPerNode, model.nDofPerNode],precString);
        nTies = length(model.ties{tCnt}.masterNodes);
        nTies2 = length(model.ties{tCnt}.slaveNodes);
        if nTies ~= nTies2
            error('Master and slave node vectors should be the same length for tie set %d',tCnt)
        end
        %fwrite(fid, nTies, 'int32');

        %fwrite(fid,model.ties{tCnt}.masterNodes,'int32');
        %fwrite(fid,model.ties{tCnt}.slaveNodes,'int32');
    end
    mUpdated.ties = model.ties;
end

%-----------------------------------------------------
if ~isfield(model,'frames')
    %old format. Copy to new.
    model.frames = cell(1);
    model.frames{1}.sigs = model.sigs;
    %model.frames{1}.nSigs = model.nSigs;
    model.frames{1}.ntSig = model.ntSig;
    model.frames{1}.dtSig = model.dtSig;
end

nFrames = length(model.frames);
% fwrite(fid, nFrames, 'int32');

for fCnt = 1:nFrames
    f = model.frames{fCnt};

    if ~isfield(f,'sigs')
        error('model.frames{%d}.sigs is not defined',fCnt)
    end
    nSigs = length(f.sigs);
    %fwrite(fid, nSigs, 'int32');

    if ~isfield(f,'ntSig')
        error('model.frames{%d}.ntSig is not defined',fCnt)
    end
    %fwrite(fid, f.ntSig, 'int32');

    if ~isfield(f,'dtSig')
        error('model.frames{%d}.dtSig is not defined',fCnt)
    end
    %fwrite(fid, f.dtSig, precString);

    for sCnt = 1:nSigs
        s = f.sigs{sCnt};
        if ~isfield(s,'nodeSpec')
            error('model.frames{%d}.sigs{%d}.nodeSpec is not defined',fCnt,sCnt)
        end
        if ~isfield(s,'dofSpec')
            error('model.frames{%d}.sigs{%d}.dofSpec is not defined',fCnt,sCnt)
        end
        if ~isfield(s,'sigAmps')
            error('model.frames{%d}.sigs{%d}.sigAmps is not defined',fCnt,sCnt)
        end
        s.nodeSpec = s.nodeSpec(:);
        s.dofSpec = s.dofSpec(:);
        s.sigAmps = s.sigAmps(:);
        l = length(s.nodeSpec);
        if l ~= length(s.dofSpec)
            error('model.frames{%d}.sigs{%d}.dofSpec must be the same length as model.frames{%d}.sigs{%d}.nodeSpec',fCnt,sCnt,fCnt,sCnt)
        end
        %check for duplicates
        hash = s.nodeSpec + s.dofSpec/10;
        anyRepeated = length(unique(hash)) - length(hash);
        if anyRepeated
            hash
            error('%d duplicate dof-node pairs found in model.frames{%d}.sigs{%d}.nodeSpec and model.frames{%d}.sigs{%d}.dofSpec',anyRepeated,fCnt,sCnt, fCnt,sCnt)
        end

        %fwrite(fid, l, 'int32');

        if ~isfield(s,'sigType')
            error('model.frames{%d}.sigs{%d}.sigType is not defined',fCnt,sCnt)
        end
        if s.sigType > 2 || s.sigType < 0
            error('model.frames{%d}.sigs{%d}.sigType has wrong value',fCnt,sCnt)
        end
        %fwrite(fid, s.sigType, 'int32');

        if max(s.nodeSpec) > model.nNodes || min(s.nodeSpec) < 1
            error('Range error on model.frames{%d}.sigs{%d}.nodeSpec',fCnt,sCnt)
        end
        if max(s.dofSpec) > model.nDofPerNode || min(s.dofSpec) < 1
            error('Range error on model.frames{%d}.sigs{%d}.dofSpec',fCnt,sCnt)
        end

        dofSpec = (s.nodeSpec(:) - 1)*4 + (s.dofSpec(:) - 1);
        %fwrite(fid, dofSpec, 'int32');

        if length(s.sigAmps) ~= l
            error('model.frames{%d}.sigs{%d}.dofSpec must be the same length as model.frames{%d}.sigs{%d}.sigAmps',fCnt,sCnt,fCnt,sCnt)
        end
        %fwrite(fid, s.sigAmps, precString);

        if length(s.sig) ~= f.ntSig
            error('model.frames{%d}.sigs{%d}.sig must be the same length as given by model.frames{%d}.ntSigs',fCnt,sCnt,fCnt)
        end
        %fwrite(fid, s.sig, precString);

    end
end
mUpdated.frames = model.frames;

%-----------------------------------------------------
if isfield(model,'measSets')

else
    %just for backward compatibility
    model.measSets = cell(1);
    model.measSets{1}.name = 'main';

    if ~isfield(model,'measNodes')
        error('model.measNodes is not defined')
    end
    if ~isfield(model,'measDof')
        error('model.measDof is not defined')
    end

    model.measSets{1}.measNodes = model.measNodes(:);
    if isfield(model,'measDof')
        model.measSets{1}.measDof = model.measDof(:);
    end


end


nMeasSets = length(model.measSets);

%fwrite(fid, nMeasSets, 'int32');

if ~isfield(model,'measFreq')
    error('model.measFreq is not defined')
end
%fwrite(fid, model.measFreq, 'int32');
mUpdated.measFreq = model.measFreq;

if ~isfield(model,'measStart')
    model.measStart = 1;
    warning('measStart undefined; setting to 1')
end
%fwrite(fid, model.measStart-1, 'int32');
mUpdated.measStart = model.measStart;

for mSetCnt = 1:nMeasSets
    %write out each node set
    strSave = blanks(20);

    lStr = length(deblank(model.measSets{mSetCnt}.name));
    if lStr + 1 > 20
        error('model.measSets{mSetCnt}.name has more than the max of 19 characters')
    end

    model.measSets{mSetCnt}.measNodes = round(model.measSets{mSetCnt}.measNodes(:));
    nMeas = length(model.measSets{mSetCnt}.measNodes);
    if ~isfield(model.measSets{mSetCnt},'measDof')

        %add a measDof term
        if model.nDofPerNode == 3
            model.measSets{mSetCnt}.measDof = [ones(nMeas,1) 2*ones(nMeas,1) 3*ones(nMeas,1)].';
        else
            model.measSets{mSetCnt}.measDof = [ones(nMeas,1) 2*ones(nMeas,1)].';
        end
        %and replicate original
        model.measSets{mSetCnt}.measNodes = repmat(model.measSets{mSetCnt}.measNodes(:).',[model.nDofPerNode,1]);
        model.measSets{mSetCnt}.measNodes = model.measSets{mSetCnt}.measNodes(:);
        nMeas = length(model.measSets{mSetCnt}.measNodes);
    end
    model.measSets{mSetCnt}.measDof = round(model.measSets{mSetCnt}.measDof(:));
    if nMeas ~= length(model.measSets{mSetCnt}.measDof)
        error('model.measSets{mSetCnt}.measDof and model.measSets{mSetCnt}.measNodes have different lengths')
    end

    hash = model.measSets{mSetCnt}.measNodes + model.measSets{mSetCnt}.measDof/10;
    anyRepeated = length(hash) - length(unique(hash));
    if anyRepeated
        error('%d duplicate dof-node pairs found in model.measSets{mSetCnt}.measNodes and model.measSets{mSetCnt}.measDof', anyRepeated)
    end

    %fwrite(fid, nMeas, 'int32');

    if max(model.measSets{mSetCnt}.measNodes(:)) > model.nNodes || min(model.measSets{mSetCnt}.measNodes(:)) < 1
%         mSetCnt
%         model.nNodes
%         max(model.measSets{mSetCnt}.measNodes(:))
%         min(model.measSets{mSetCnt}.measNodes(:))
        error('Range error on model.measSets{mSetCnt}.measNodes.')
    end
    if max(model.measSets{mSetCnt}.measDof(:)) > model.nDofPerNode || min(model.measSets{mSetCnt}.measDof(:)) < 1
        error('Range error on model.measDof.')
    end
    %measDof = (model.measSets{mSetCnt}.measNodes(:)-1)*4 + (model.measSets{mSetCnt}.measDof(:)-1);
    %fwrite(fid, measDof, 'int32');
end
mUpdated.measSets = model.measSets;
%-----------------------------------------------------
if ~isfield(model,'fieldStoreIncs')
    nFieldStores = 0;
    %fwrite(fid, nFieldStores, 'int32');
else
    nFieldStores = length(model.fieldStoreIncs);
    %fwrite(fid, nFieldStores, 'int32');
    if max(model.fieldStoreIncs) > model.nt || min(model.fieldStoreIncs) < 1
        error('Range error on model.fieldStoreIncs')
    end
    %fwrite(fid, model.fieldStoreIncs-1, 'int32');
    mUpdated.fieldStoreIncs = model.fieldStoreIncs;
end


if isfield(model,'fieldStoreNodes')
    mUpdated.fieldStoreNodes = model.fieldStoreNodes(:);
end





end
