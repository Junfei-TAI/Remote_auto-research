function [ field, fileVerFull, header, fieldLoc ] = loadPogoField( fileName )
%loadPogoField - load field data from Pogo FE
%
% [ field, fileVer, header ] = loadPogoField( fileName )
%
%fileName - the file name
%fileVer - the file version
%header - the header for the file
%
%field - a struct containing:
%nodeLocs - the locations of the nodes, dims fast, node numbers slow
%times - the times at which field values are recorded
%ux, uy, uz - displacements at nodes in x, y and z (if available) directions
%nodeNums - which node numbers in the original mesh the values correspond to
%
%metadata - struct containing the model metadata
%
% Written by P. Huthwaite, September 2012
% Updated to include 3D support, 28/3/12 -- PH
% Updated to load to struct April 2014, PH
% Updated to v 1.03 (potentially restrict nodes at which field is saved)
%       with nodeNums field, May 2016, PH
% Minor update (record file precision), March 2018, PH
% Updated to v 1.05 - include new versioning approach April 2020 PH
% Updated to v 1.06 - metadata with arrays, May 2020, PH
% Updated to v 1.07 - include sections in the file, July 2020, PH
% Minor update to allow dofs == 1 too
% Updated to v 1.08 - multiple dofs in file, Aug 2024, PH
% Updated to v 1.09 - include dof weighting and maximum values, Oct 2024, PH
% Updated to v 1.10 - include mesh information, PH
% Updated to v 1.11 - tidy up mesh information, April 2025, PH

fileName = char(fileName);

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
    fileName = [fileName '.pogo-field'];
end
    fid = fopen(fileName,'rb');
    if (fid == -1)
        error('File %s could not be opened.', fileName)
    end

    header = deblank(fread(fid, 20, '*char')');

    if strcmp(header, '%pogo-field1.0')
        fileMajVer = 1;
        fileMinVer = 0;
        %fileVer = 1;
    elseif strcmp(header, '%pogo-field1.02')
        fileMajVer = 1;
        fileMinVer = 2;
        %fileVer = 1.02;
    elseif strcmp(header, '%pogo-field1.03')
        fileMajVer = 1;
        fileMinVer = 3;
        %fileVer = 1.03;
    elseif strcmp(header, '%pogo-field1.04')
        fileMajVer = 1;
        fileMinVer = 4;
        %fileVer = 1.04;
    elseif strcmp(header, '%pogo-field')
        fileMajVer = -1;
    else
		disp(header)
        error('File is wrong format. header: %s. \nThere may be an update available for this function.',header)
    end
    if fileMajVer == -1
        fileMajVer = fread(fid, 1, 'int32');
        fileMinVer = fread(fid, 1, 'int32');
    end
    fileVerFull = fileMajVer*1000+fileMinVer;
    field.fileMajVer = fileMajVer;
    field.fileMinVer = fileMinVer;
    field.fileVerFull = fileVerFull;
    fieldLoc = 0;

    if fileVerFull > 1011
        warning('Field file version, %d.%d, is too new. Update this function.',fileMajVer,fileMinVer)
        warning('We will attempt to continue, but note that some features may be incompatible.')
    end

    %load in metadata here
    if fileVerFull  >= 1004
        if (fileVerFull >= 1007)
            [sectSize, ~] = skipToFileSection(fid,'metadata');
            metadataSize = sectSize;
        else
            metadataSize = fread(fid, 1, 'int32');
        end
        metadataNumValues = fread(fid, 1, 'int32');
        for mCnt = 1:metadataNumValues
            if fileVerFull == 1004 ||  fileVerFull == 1005
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
                fprintf('%s: %s\n',mdName, mdValue)
                mdValueNum = str2double(mdValue);
                if isempty(mdValueNum) || isnan(mdValueNum)
                    eval(sprintf('field.metadata.%s = ''%s'';\n', mdName,mdValue))
                else
                    eval(sprintf('field.metadata.%s = %d;\n', mdName,mdValueNum))
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
                        eval(sprintf('field.metadata.%s = ''%s'';\n', mdName,mdValue))
                    else
                        eval(sprintf('field.metadata.%s = %d;\n', mdName,mdValueNum))
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
                    eval(sprintf('field.metadata.%s = metaVals;\n', mdName))
                end
            end
        end
    end

    %--------------------------------------------------------------
    if (fileVerFull >= 1007)
        skipToFileSection(fid,'generalInfo');
    end

    prec = fread(fid, 1, 'int32');
    if prec ~= 4 && prec ~= 8
        error('Specified precision %d incorrect. Should be 4 or 8 bytes.', prec)
    end
    field.prec = prec;
    if prec == 4
	precStr = 'float32';
    else
        precStr = 'float64';
    end
    nDims = fread(fid, 1, 'int32');
    nDofPerNode = nDims;
    if fileVerFull >= 1002
        nDofPerNode = fread(fid, 1, 'int32');
        %if nDofPerNode ~= 1 && nDofPerNode ~= 2 && nDofPerNode ~= 3
        %    error('Unsupported value for nDofPerNode: %d',nDofPerNode);
        %end
    end

    %nDofPerNode
    %--------------------------------------------------------------
    if (fileVerFull >= 1007)
        skipToFileSection(fid,'nodes');
    end


    if (fileVerFull >= 1011)
        nNodes = fread(fid, 1, 'int32');
        nodeLocs = fread(fid, [nDims, nNodes], precStr);

        field.nodeLocs = nodeLocs;
    else
        nNodes = fread(fid, 1, 'int32');

        nodeLocs = fread(fid, [nDims, nNodes], precStr);
        if fileVerFull >= 1003
            field.nodeNums = fread(fid, nNodes, 'int32')+1;
        else
            field.nodeNums = 1:nNodes;
        end
        field.nodeNumsModel = field.nodeNums;
    end

    if fileVerFull >= 1008
        nNodesAndDofs = fread(fid, 1, 'int32');
        field.nodeNums = fread(fid, nNodesAndDofs, 'int32')+1;
        field.dofNums = fread(fid, nNodesAndDofs, 'int32')+1;
    end

    %--------------------------------------------------------------

    if (fileVerFull >= 1009)
        skipToFileSection(fid,'dofScale');
        nDofScale = fread(fid, 1, 'uint32');
        field.dofScales = fread(fid, nDofScale, precStr);
    end

    %--------------------------------------------------------------

    if (fileVerFull >= 1010)
        skipToFileSection(fid,'elements');

        nEls = fread(fid, 1, 'uint32');
        nNodesPerEl = fread(fid, 1, 'int32');
        field.mesh.elTypeRefs = fread(fid, nEls, 'int32')+1;
        field.mesh.matTypeRefs = fread(fid, nEls, 'int32')+1;
        field.mesh.orientRefs = fread(fid, nEls, 'int32')+1;

        elNodesRead = fread(fid, [nNodesPerEl, nEls], 'uint32');
        field.mesh.elNodes = elNodesRead+1;
        field.mesh.elNodes(elNodesRead == uint64(2)^32-1) = 0;

        skipToFileSection(fid,'elTypes');

        nElTypes = fread(fid,1,'int32');
        field.mesh.elTypes = cell(nElTypes,1);
        for eCnt = 1:nElTypes
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

            field.mesh.elTypes{eCnt}.name = elType;
            field.mesh.elTypes{eCnt}.paramsType = fread(fid,1,'int32');
            nElParams = fread(fid,1,'int32');
            if nElParams > 0
                field.mesh.elTypes{eCnt}.paramValues = fread(fid,nElParams,precStr);
            end
        end

        skipToFileSection(fid,'matTypes');
        nMatTypes = fread(fid,1,'int32');
        field.mesh.matTypes = cell(nMatTypes,1);
        for eCnt = 1:nMatTypes
	        if fileMajVer == 1  && fileMinVer >= 9
		        field.mesh.matTypes{eCnt}.parent = fread(fid,1,'int32')+1;
	        end
            field.mesh.matTypes{eCnt}.paramsType = fread(fid,1,'int32');
            nMatParams = fread(fid,1,'int32');
            field.mesh.matTypes{eCnt}.paramValues = fread(fid,nMatParams,precStr);
        end

        skipToFileSection(fid,'orientations');
        nOr = fread(fid,1,'int32');
        if nOr > 0
            field.mesh.or = cell(nOr,1);
            for eCnt = 1:nOr
                field.mesh.or{eCnt}.paramsType = fread(fid,1,'int32');
                nOrParams = fread(fid,1,'int32');
                field.mesh.or{eCnt}.paramValues = fread(fid,nOrParams,precStr);
            end
        end

    end

    %--------------------------------------------------------------
    if (fileVerFull >= 1007)
        skipToFileSection(fid,'fieldStores');
    end

    nFieldStores = fread(fid, 1, 'int32');

    times = zeros(nFieldStores,1);

    if (fileVerFull < 1008)
        ux = zeros(nNodes, nFieldStores);
        uy = zeros(nNodes, nFieldStores);
        if nDofPerNode >= 3
            uz = zeros(nNodes, nFieldStores);
        end
        if nDofPerNode >= 2
            uy = zeros(nNodes, nFieldStores);
        end

        for cnt = 1:nFieldStores
            times(cnt) = fread(fid, 1, precStr);
            ux(:,cnt) = fread(fid, nNodes, precStr);
            if nDofPerNode >= 2
                uy(:,cnt) = fread(fid, nNodes, precStr);
                if nDofPerNode >= 3
                    uz(:,cnt) = fread(fid, nNodes, precStr);
                end
            end
        end

    else
        u = zeros(nNodesAndDofs, nFieldStores);

        fieldLoc = ftell(fid);


        for cnt = 1:nFieldStores
            times(cnt) = fread(fid, 1, precStr);
            u(:,cnt) = fread(fid, nNodesAndDofs, precStr);
        end
    end

    if (fileVerFull >= 1009)
        skipToFileSection(fid,'maxValues');
        field.maxValues = fread(fid, nDofPerNode, precStr);
        field.maxValuesPerFrame = fread(fid, [nDofPerNode,nFieldStores], precStr);
    end



    fclose(fid);

    if (fileVerFull < 1008)
        field.ux = ux;
        if nDofPerNode >= 2
            field.uy = uy;
            if nDofPerNode >= 3
                field.uz = uz;
            end
        end
    else
        field.u = u;
    end

    field.nodeLocs = nodeLocs;
    field.times = times;

    field.nDofPerNode = nDofPerNode;
end
