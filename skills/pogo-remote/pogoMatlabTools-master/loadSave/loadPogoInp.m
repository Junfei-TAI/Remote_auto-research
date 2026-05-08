function [ model ] = loadPogoInp( fileName )
% function [ model ] = loadPogoInp( fileName )
% see savePogoInp for full documentation

addExt = 0;
if verLessThan('matlab','9.1')
    if isempty(strfind(fileName,'.')) %#ok<STREMP>
        addExt = 1;
    end
else
    if ~contains(fileName,'.')
        addExt = 1;
    end
end
if addExt
    fileName = [fileName '.pogo-inp'];
end

fid = fopen(fileName,'rb','n','UTF-8');
if (fid == -1)
    error('File %s could not be opened.', fileName)
    %return;
end

header = readBinaryText(fid,20);

fileMajVer = -1;
fileMinVer = -1;
if strcmp(header, '%pogo-inp1.0') == 1
    fileMajVer = 1;
    fileMinVer = 0;
end
if strcmp(header, '%pogo-inp1.01') == 1
    fileMajVer = 1;
    fileMinVer = 1;
end
if strcmp(header, '%pogo-inp1.02') == 1
    fileMajVer = 1;
    fileMinVer = 2;
end
if strcmp(header, '%pogo-inp1.03') == 1
    fileMajVer = 1;
    fileMinVer = 3;
end
if strcmp(header, '%pogo-inp1.04') == 1
    fileMajVer = 1;
    fileMinVer = 4;
end
if strcmp(header, '%pogo-inp1.05') == 1
    fileMajVer = 1;
    fileMinVer = 5;
end
if strcmp(header, '%pogo-inp1.06') == 1
    fileMajVer = 1;
    fileMinVer = 6;
end
if strcmp(header, '%pogo-inp1.07') == 1
    fileMajVer = 1;
    fileMinVer = 7;
end
if strcmp(header, '%pogo-inp1.08') == 1
    fileMajVer = 1;
    fileMinVer = 8;
end
if strcmp(header, '%pogo-inp1.09') == 1
    fileMajVer = 1;
    fileMinVer = 9;
end
if strcmp(header, '%pogo-inp1.10') == 1
    fileMajVer = 1;
    fileMinVer = 10;
end
if strcmp(header, '%pogo-inp1.11') == 1
    fileMajVer = 1;
    fileMinVer = 11;
end
if strcmp(header, '%pogo-inp') == 1
    fileMajVer = fread(fid, 1, 'int32');
    fileMinVer = fread(fid, 1, 'int32');
end

%disp(fileMajVer)
%disp(fileMinVer)
if fileMajVer == -1
    %fileVer = 1;

    %disp(fileVer)
    %disp(header)
    error('File is wrong format. header: %s.', header)
end

fileVerFull = fileMajVer*1000+fileMinVer;

if fileVerFull > 1017
    warning('Input file version, %d.%d, is too new. Update this function.\nWe will attempt to continue, but note that some features may be incompatible.',fileMajVer,fileMinVer)
end

%disp(fileVer)
model.fileMajVer = fileMajVer;
model.fileMinVer = fileMinVer;



%load in metadata

if (fileVerFull >= 1011)
    if (fileVerFull >= 1014)
        [sectSize, sectVer] = skipToFileSection(fid,'metadata');
        metadataSize = sectSize;
    else
        metadataSize = fread(fid, 1, 'int32');
    end
    metadataNumValues = fread(fid, 1, 'int32');
    for mCnt = 1:metadataNumValues

        if fileMajVer == 1 && (fileMinVer == 11 || fileMinVer == 12)

            mdNameLength = fread(fid, 1, 'int32');
            mdValueLength = fread(fid, 1, 'int32');

            rawRead = fread(fid, mdNameLength, 'uint8').';
            nullTerm = find(rawRead == 0,1);
            if ~isempty(nullTerm)
                rawRead(nullTerm:end) = 0;
            end
            rawRead = char(rawRead);
            rawRead = deblank(rawRead);

            mdName = deblank(rawRead);

            %mdName = fread(fid,[1,mdNameLength],'char');

            rawRead = fread(fid, mdValueLength, 'uint8').';
            nullTerm = find(rawRead == 0,1);
            if ~isempty(nullTerm)
                rawRead(nullTerm:end) = 0;
            end
            rawRead = char(rawRead);
            rawRead = deblank(rawRead);

            mdValue = deblank(rawRead);

            %mdValue = fread(fid,[1,mdValueLength],'char');
            %fprintf('%s: %s\n',mdName, mdValue)
            mdValueNum = str2double(mdValue);
            if isempty(mdValueNum) || isnan(mdValueNum)
                eval(sprintf('model.metadata.%s = ''%s'';\n', mdName,mdValue))
            else
                eval(sprintf('model.metadata.%s = %d;\n', mdName,mdValueNum))
            end
        else
            mdNameLength = fread(fid, 1, 'int32');

            %load in the name
            rawRead = fread(fid, mdNameLength, 'uint8').';
            nullTerm = find(rawRead == 0,1);
            if ~isempty(nullTerm)
                rawRead(nullTerm:end) = 0;
            end
            rawRead = char(rawRead);
            rawRead = deblank(rawRead);

            mdName = deblank(rawRead);


            %load in the data type
            rawRead = fread(fid, 16, 'uint8').';
            nullTerm = find(rawRead == 0,1);
            if ~isempty(nullTerm)
                rawRead(nullTerm:end) = 0;
            end
            rawRead = char(rawRead);
            rawRead = deblank(rawRead);

            datatype = deblank(rawRead);

            if strcmp(datatype, 'string')
                mdValueLength = fread(fid, 1, 'int32');

                %mdName = fread(fid,[1,mdNameLength],'char');

                rawRead = fread(fid, mdValueLength, 'uint8').';
                nullTerm = find(rawRead == 0,1);
                if ~isempty(nullTerm)
                    rawRead(nullTerm:end) = 0;
                end
                rawRead = char(rawRead);
                rawRead = deblank(rawRead);

                mdValue = deblank(rawRead);

                %mdValue = fread(fid,[1,mdValueLength],'char');
                %fprintf('%s: %s\n',mdName, mdValue)
                mdValueNum = str2double(mdValue);
                if isempty(mdValueNum) || isnan(mdValueNum)
                    eval(sprintf('model.metadata.%s = ''%s'';\n', mdName,mdValue))
                else
                    eval(sprintf('model.metadata.%s = %d;\n', mdName,mdValueNum))
                end
            else
                metaDims = fread(fid, 1, 'int32');
                if metaDims == 0
                    metaVals = fread(fid, 1, datatype);
                else

                    metaShape = fread(fid, metaDims, 'int32');
                    metaShape = reshape(metaShape,1,[]);
                    metaVals = fread(fid, metaShape, datatype);
                    %totVals = prod(metaShape);
                    %metaVals = fread(fid, totVals, datatype);
                    %metaVals = reshape(metaVals, metaShape);
                end
                eval(sprintf('model.metadata.%s = metaVals;\n', mdName))
            end
        end
    end
end

%--------------------------------------------------------------
if (fileVerFull >= 1014)
    skipToFileSection(fid,'generalInfo');
end


maxUint = uint32(uint64(2)^32-1);

if fileVerFull >= 1010
    dofSaveString = 'uint64';
else
    dofSaveString = 'int32';
end

model.prec = fread(fid, 1, 'int32');
if model.prec == 8
    precString = 'float64';
else
    precString = 'float32';
end
%model.prec
model.nDims = fread(fid, 1, 'int32');

if fileVerFull >= 1016
    model.globalDof = fread(fid, 1, 'int32');
else
    model.globalDof = 0;
end

if fileVerFull >= 1002
    model.nDofPerNode = fread(fid, 1, 'int32');
else
    %nDofPerNode = -1;
end

rawRead = fread(fid, 1024, 'uint8').';
nullTerm = find(rawRead == 0,1);
if ~isempty(nullTerm)
    rawRead(nullTerm:end) = 0;
end
rawRead = char(rawRead);
rawRead = deblank(rawRead);

notes = rawRead;
if ~isempty(notes)
    model.notes = notes;
end


rawRead = fread(fid, 80, 'uint8').';
nullTerm = find(rawRead == 0,1);
if ~isempty(nullTerm)
    rawRead(nullTerm:end) = 0;
end
rawRead = char(rawRead);
rawRead(~isstrprop(rawRead,'alphanum')) = '';
rawRead = deblank(rawRead);
model.runName = rawRead;

model.nt = fread(fid, 1, 'uint32');
model.dt = fread(fid, 1, precString);

%--------------------------------------------------------------
if (fileVerFull >= 1014)
    skipToFileSection(fid,'nodes');
end


nNodes = fread(fid, 1, 'uint32');
model.nodePos = fread(fid, [model.nDims,nNodes], precString);


%--------------------------------------------------------------
if (fileVerFull >= 1014)
    skipToFileSection(fid,'elements');
end

nEls = fread(fid, 1, 'uint32');
nNodesPerEl = fread(fid, 1, 'int32');
model.elTypeRefs = fread(fid, nEls, 'int32')+1;
model.matTypeRefs = fread(fid, nEls, 'int32')+1;
model.orientRefs = fread(fid, nEls, 'int32')+1;

if fileMajVer == 1  && fileMinVer >= 10
    elNodesRead = fread(fid, [nNodesPerEl, nEls], 'uint32');
    model.elNodes = elNodesRead+1;
    model.elNodes(elNodesRead == uint64(2)^32-1) = 0;
else
    model.elNodes = fread(fid, [nNodesPerEl, nEls], 'int32')+1;
end

if fileMajVer == 1  && fileMinVer >= 3
    %--------------------------------------------------------------
    if (fileVerFull >= 1014)
        skipToFileSection(fid,'pml');
    end
    nPmlSets = fread(fid, 1, 'int32');
    if nPmlSets ~= 0
        nPmlSets
        error('nPmlSets > 0, but PML reading unsupported by this version.')
    end

    nPmlParams = fread(fid, 1, 'int32');
    if nPmlParams ~= 0
        error('nPmlParams > 0, but PML reading unsupported by this version.')
    end
end


if feof(fid)
    %error('Unexpected EOF found')
    disp('Unexpected EOF found')
    dbstack
    fclose(fid);
    return
end

%--------------------------------------------------------------
if (fileVerFull >= 1014)
    skipToFileSection(fid,'elTypes');
end

nElTypes = fread(fid,1,'int32');
model.elTypes = cell(nElTypes,1);
for eCnt = 1:nElTypes
    %rawRead = fread(fid, 20, '*char').';
    rawRead = fread(fid, 20, 'uint8').';
    elType = rawRead;

    %processing in case it's a messed up string!
    nullTerm = find(elType == 0,1);
    if ~isempty(nullTerm)
        elType(nullTerm:end) = 0;
    end
    elType = char(elType);
    elType(~isstrprop(elType,'alphanum')) = '';
    elType = deblank(elType);

    model.elTypes{eCnt}.name = elType;
    model.elTypes{eCnt}.paramsType = fread(fid,1,'int32');
    nElParams = fread(fid,1,'int32');
    if nElParams > 0
        model.elTypes{eCnt}.paramValues = fread(fid,nElParams,precString);
    end
end


if feof(fid)
    %error('Unexpected EOF found')
    disp('Unexpected EOF found')
    dbstack
    fclose(fid);
    return
end

%--------------------------------------------------------------
if (fileVerFull >= 1014)
    skipToFileSection(fid,'matTypes');
end

nMatTypes = fread(fid,1,'int32');
model.matTypes = cell(nMatTypes,1);
for eCnt = 1:nMatTypes
	if fileMajVer == 1  && fileMinVer >= 9
		model.matTypes{eCnt}.parent = fread(fid,1,'int32')+1;
	end
    model.matTypes{eCnt}.paramsType = fread(fid,1,'int32');
    nMatParams = fread(fid,1,'int32');
    model.matTypes{eCnt}.paramValues = fread(fid,nMatParams,precString);
    %return
end

%--------------------------------------------------------------
if (fileVerFull >= 1014)
    skipToFileSection(fid,'orientations');
end

nOr = fread(fid,1,'int32');
if nOr > 0
    model.or = cell(nOr,1);
    for eCnt = 1:nOr
        model.or{eCnt}.paramsType = fread(fid,1,'int32');
        nOrParams = fread(fid,1,'int32');
        model.or{eCnt}.paramValues = fread(fid,nOrParams,precString);
    end
end

if feof(fid)
    %error('Unexpected EOF found')
    disp('Unexpected EOF found')
    dbstack
    fclose(fid);
    return
end

%--------------------------------------------------------------
if (fileVerFull >= 1014)
    skipToFileSection(fid,'fixDof');
end

if fileVerFull >= 1010
    nFixDof = fread(fid,1,'uint64');
else
    nFixDof = fread(fid,1,'uint32');
end

if nFixDof > 0
    fixDof = fread(fid,nFixDof,dofSaveString);
    if fileVerFull >= 1016
        model.fixDof = mod(fixDof,16)+1;
        model.fixNodes = floor(fixDof/16)+1;
    else
        model.fixDof = mod(fixDof,4)+1;
        model.fixNodes = floor(fixDof/4)+1;
    end
end

%--------------------------------------------------------------
if (fileVerFull >= 1014)
    skipToFileSection(fid,'ties');
end

if fileVerFull >= 1006
    nTieSets = fread(fid,1,'int32');
    if nTieSets > 0
        model.ties = cell(nTieSets,1);

        for tCnt = 1:nTieSets
            model.ties{tCnt}.tieTransform = fread(fid,[model.nDofPerNode, model.nDofPerNode],precString);
            nTies = fread(fid,1,'int32');
            model.ties{tCnt}.masterNodes = fread(fid,[nTies,1],'int32');
            model.ties{tCnt}.slaveNodes = fread(fid,[nTies,1],'int32');
        end
    end
end

%--------------------------------------------------------------
if (fileVerFull >= 1014)
    skipToFileSection(fid,'dofGroups');
end

%DOF groups:
if fileVerFull >= 1008
    nDofGroups = fread(fid,1,'int32');
    for dCnt = 1:nDofGroups
        nDof = fread(fid,1,'int32');
        dofSpec = fread(fid,nDof,dofSaveString);
        if fileVerFull >= 1016
            model.dofGroups{dCnt}.dofSpec = mod(dofSpec,16)+1;
            model.dofGroups{dCnt}.nodeSpec = floor(dofSpec/16)+1;
        else
            model.dofGroups{dCnt}.dofSpec = mod(dofSpec,4)+1;
            model.dofGroups{dCnt}.nodeSpec = floor(dofSpec/4)+1;
        end
        model.dofGroups{dCnt}.dofWeight = fread(fid,nDof,precString);
    end
else
    nDofGroups = 0;
end

%--------------------------------------------------------------
if (fileVerFull >= 1014)
    skipToFileSection(fid,'signals');
end

%shots:
if fileMajVer == 1 && fileMinVer >= 7
    nShots = fread(fid,1,'int32');
else
    nShots = 1;
end

model.shots = cell(nShots,1);
for fCnt = 1:nShots
    %sigs:
    nSigs = fread(fid,1,'int32');
    model.shots{fCnt}.ntSig = fread(fid,1,'int32');
    model.shots{fCnt}.dtSig = fread(fid,1,precString);

    model.shots{fCnt}.sigs = cell(nSigs,1);
    for sCnt = 1:nSigs
        nDofForSig = fread(fid,1,'int32');
        if fileMajVer == 1 && fileMinVer >= 1
            model.shots{fCnt}.sigs{sCnt}.sigType = fread(fid,1,'int32');
        end
        if fileMajVer == 1 && fileMinVer >= 8
            model.shots{fCnt}.sigs{sCnt}.isDofGroup = fread(fid,1,'int8');
        else
            model.shots{fCnt}.sigs{sCnt}.isDofGroup = 0;
        end
        dofSpec = fread(fid,nDofForSig,dofSaveString);
        if model.shots{fCnt}.sigs{sCnt}.isDofGroup == 0
            if fileVerFull >= 1016
                model.shots{fCnt}.sigs{sCnt}.dofSpec = mod(dofSpec,16)+1;
                model.shots{fCnt}.sigs{sCnt}.nodeSpec = floor(dofSpec/16)+1;
            else
                model.shots{fCnt}.sigs{sCnt}.dofSpec = mod(dofSpec,4)+1;
                model.shots{fCnt}.sigs{sCnt}.nodeSpec = floor(dofSpec/4)+1;
            end
        else
            model.shots{fCnt}.sigs{sCnt}.dofGroup = dofSpec+1;
        end

        model.shots{fCnt}.sigs{sCnt}.sigAmps = fread(fid,nDofForSig,precString);
        model.shots{fCnt}.sigs{sCnt}.sig = fread(fid,model.shots{fCnt}.ntSig,precString);
    end

    if feof(fid)
        %error('Unexpected EOF found')
        disp('Unexpected EOF found')
        dbstack
        fclose(fid);
        return
    end
end

%--------------------------------------------------------------
if (fileVerFull >= 1014)
    skipToFileSection(fid,'measurements');
end

%meas hist:
if fileMajVer == 1 && fileMinVer >= 5
    nMeasSets = fread(fid,1,'int32');
    model.measSets = cell(nMeasSets,1);

    model.measFreq = fread(fid,1,'int32');
    model.measStart = fread(fid,1,'int32')+1;

    for mSetCnt = 1:nMeasSets

        rawRead = fread(fid, 20, 'uint8').';
        nullTerm = find(rawRead == 0,1);
        if ~isempty(nullTerm)
            rawRead(nullTerm:end) = 0;
        end
        rawRead = char(rawRead);
        rawRead(~isstrprop(rawRead,'alphanum')) = '';
        rawRead = deblank(rawRead);

        name = rawRead;%fread(fid, 20, '*char')';
        model.measSets{mSetCnt}.name = deblank(name);

        nMeas = fread(fid,1,'int32');
        if fileVerFull >= 1008
            model.measSets{mSetCnt}.isDofGroup = fread(fid,1,'int8');
        else
            model.measSets{mSetCnt}.isDofGroup = 0;
        end

        measDof = fread(fid,nMeas,dofSaveString);
        if model.measSets{mSetCnt}.isDofGroup == 0
            if fileVerFull >= 1016
                model.measSets{mSetCnt}.measDof = mod(measDof,16)+1;
                model.measSets{mSetCnt}.measNodes = floor(measDof/16)+1;
            else
                model.measSets{mSetCnt}.measDof = mod(measDof,4)+1;
                model.measSets{mSetCnt}.measNodes = floor(measDof/4)+1;
            end
        else
            model.measSets{mSetCnt}.dofGroup = measDof + 1;
        end
    end


else
    nMeas = fread(fid,1,'int32');
    model.measFreq = fread(fid,1,'int32');
    if fileMajVer == 1 && fileMinVer >= 4
        model.measStart = fread(fid,1,'int32')+1;
    else
        model.measStart = 1;
    end
    model.measSets = cell(1);
    measDof = fread(fid,nMeas,dofSaveString);
    model.measSets{1}.name = 'main';
    if fileVerFull >= 1016
        model.measSets{1}.measDof = mod(measDof,16)+1;
        model.measSets{1}.measNodes = floor(measDof/16)+1;
    else
        model.measSets{1}.measDof = mod(measDof,4)+1;
        model.measSets{1}.measNodes = floor(measDof/4)+1;
    end
end

%--------------------------------------------------------------
if (fileVerFull >= 1014)
    skipToFileSection(fid,'fieldStores');
end

%meas field:
nFieldStores = fread(fid,1,'int32');
if nFieldStores > 0
    model.fieldStoreIncs = fread(fid,nFieldStores,'int32')+1;
end

if fileMajVer == 1 && fileMinVer >= 5
    nFieldNodes = fread(fid,1,'uint32');
    if nFieldNodes ~= maxUint
        model.fieldStoreNodes = fread(fid,nFieldNodes,'uint32')+1;
    end
end


%--------------------------------------------------------------
if (fileVerFull >= 1015)
    skipToFileSection(fid,'mpi');

    nMpiDiv = fread(fid,1,'uint32');

    model.mpiDivNum = fread(fid,1,'uint32')+1; %zero indexed

    if nMpiDiv > 0
        model.mpi = cell(nMpiDiv,1);
        for cnt = 1:nMpiDiv
            nMpiNodes = fread(fid,1,'uint32');
            model.mpi{cnt}.outNodes = fread(fid,nMpiNodes,'uint32')+1;
            nMpiNodes = fread(fid,1,'uint32');
            model.mpi{cnt}.inNodes = fread(fid,nMpiNodes,'uint32')+1;
        end
    end
end

if (fileVerFull >= 1017)
    skipToFileSection(fid,'dofScale');
    nDofScales = fread(fid,1,'uint32');
    if nDofScales > 0
        model.dofScales = fread(fid,nDofScales,precString);
    end
end

fclose(fid);

end
