function [ hist, fileVerFull, prec, header, histLoc ] = loadPogoHist( fileName )
%loadPogoHist - load history data from Pogo FE
%
% [ hist, fileVer, prec, header ] = loadPogoHist( fileName )
%
%fileName - the file name
%fileVer - the version of the read file
%metadata - struct containing the model metadata
%prec - the precision of the read file (bytes)
%header - the header from the file
%hist - a struct containing the following fields:
%nt - the number of measurement times
%dt - the time spacing between measurement times (s)
%startMeas - the time for the first time point
%sets - a struct inside hist, containing each set name (default is 'main' if
%       unspecified), which is itself a struct, containing:
%nodeNums - the numbers of the nodes at which measurements are given
%nodeDofs - the degree of freedom for each measurement
%nodePos - location of each node; dimension fast, node number slow
%histTraces - the measurements. Time is fast, node number slow
%
% Written by P. Huthwaite, September 2012
% Updated with better error messages 21/5/2013 PH
% Updated to save as struct April 2014, PH
% Updaded to v 1.01 (save start time) May 2016, PH
% Updated to v 1.02 - load multiple sets May 2016, PH
% Updated to fix pure number set names, Oct 2016, PH
% Updated to v 1.03 - deal with dofGroups Aug 2017, PH
% Updated to v 1.04 - include metadata, March 2020, PH
% Updated to load in dofGroup coordinates, April 2020, PH
% Updated to v 1.05 - include new versioning approach April 2020 PH
% UPdated to v 1.06 - metadata with arrays, May 2020, PH
% Updated to v 1.07 - include sections in the file, July 2020, PH
% Updated to v 1.08 - allow global degrees of freedom, July 2024, PH

%extract just the filename itself for processing the extension
k = strfind(fileName,'/');
if ~isempty(k)
    k = k(end);
    justFile = extractAfter(fileName,k);
else
    justFile = fileName;
end

addExt = 0;
if verLessThan('matlab','9.1')
    if isempty(strfind(justFile,'.')) %#ok<STREMP>
        addExt = 1;
    end
else
    if ~contains(justFile,'.')
        addExt = 1;
    end
end
if addExt
    fileName = [fileName '.pogo-hist'];
end

histLoc = 0;

    fid = fopen(fileName,'rb');
    if (fid == -1)
        error('File %s could not be opened.', fileName)
    end

    header = deblank(fread(fid, 20, '*char')');

    if strcmp(header, '%pogo-hist1.0') == 1
        fileMajVer = 1;
        fileMinVer = 0;
    elseif strcmp(header, '%pogo-hist1.01') == 1
        fileMajVer = 1;
        fileMinVer = 1;
    elseif strcmp(header, '%pogo-hist1.02') == 1
        fileMajVer = 1;
        fileMinVer = 2;
    elseif strcmp(header, '%pogo-hist1.03') == 1
        fileMajVer = 1;
        fileMinVer = 3;
    elseif strcmp(header, '%pogo-hist1.04') == 1
        fileMajVer = 1;
        fileMinVer = 4;
    elseif strcmp(header, '%pogo-hist') == 1
        fileMajVer = -1;
    else
        error('File is wrong format. header: %s.\nThere may be an update available for this function.', header)
    end
    if fileMajVer == -1
        fileMajVer = fread(fid, 1, 'int32');
        fileMinVer = fread(fid, 1, 'int32');
    end
%     if fileMajVer > 1 || fileMajVer < 1
%         error('File format major version, %d, is unrecognised.\nThere may be an update available for this function.', fileMajVer)
%     end
%     if fileMajVer == 1 && (fileMinVer < 0 || fileMinVer > 6)
%         error('File format minor version, %d, is unrecognised.\nThere may be an update available for this function.', fileMinVer)
%     end
    fileVerFull = fileMajVer*1000+fileMinVer;

    if fileVerFull > 1008
        warning('History file version, %d.%d, is too new. Update this function.',fileMajVer,fileMinVer)
        warning('We will attempt to continue, but note that some features may be incompatible.')
    end

    hist.fileMajVer = fileMajVer;
    hist.fileMinVer = fileMinVer;


    %load in metadata here
    if fileVerFull >= 1004
        if fileVerFull >= 1007
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
                    eval(sprintf('hist.metadata.%s = ''%s'';\n', mdName,mdValue))
                else
                    eval(sprintf('hist.metadata.%s = %d;\n', mdName,mdValueNum))
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
                        eval(sprintf('hist.metadata.%s = ''%s'';\n', mdName,mdValue))
                    else
                        eval(sprintf('hist.metadata.%s = %d;\n', mdName,mdValueNum))
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
                    eval(sprintf('hist.metadata.%s = metaVals;\n', mdName))
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
        error('Specified precision (%d) unsupported. Should be 4 or 8.', prec)
    end
    if prec == 4
	precStr = 'float32';
    else
        precStr = 'float64';
    end
    hist.prec = prec;

    nDims = fread(fid, 1, 'int32');
    %return
    if fileVerFull >= 1008
        hist.globalDof = fread(fid, 1, 'int32');
        hist.dofsPresent = fread(fid, 1, 'int32');
    end
    if fileVerFull < 1002
        nMeas = fread(fid, 1, 'int32');
    else
        nMeasSets = fread(fid, 1, 'int32');
    end
    ntMeas = fread(fid, 1, 'int32');
    dtMeas = fread(fid, 1, precStr);

    if fileVerFull >= 1001
        startMeas = fread(fid, 1, precStr);
    end

    %--------------------------------------------------------------
    if (fileVerFull >= 1007)
        skipToFileSection(fid,'measSets');
    end

    if fileVerFull < 1002
        hist.sets.main.nodeNums = zeros(nMeas,1);
        hist.sets.main.nodeDofs = zeros(nMeas,1);
        hist.sets.main.nodePos = zeros(nDims,nMeas);
        hist.sets.main.histTraces = zeros(ntMeas,nMeas);

        for cnt = 1:nMeas
            hist.sets.main.nodeNums(cnt) = fread(fid, 1, 'int32')+1;
            hist.sets.main.nodeDofs(cnt) = fread(fid, 1, 'int32')+1;
            hist.sets.main.nodePos(:,cnt) = fread(fid, nDims, precStr);
            hist.sets.main.histTraces(1:ntMeas,cnt) = fread(fid, ntMeas, precStr);
        end
    else
        %hist.set = cell(nMeasSets,1);
        histLoc = ftell(fid);

        for sCnt = 1:nMeasSets
			rawRead = fread(fid, 20, 'uint8').';
			nullTerm = find(rawRead == 0,1);
			if ~isempty(nullTerm)
				rawRead(nullTerm:end) = 0;
			end
			rawRead = char(rawRead);
			rawRead = deblank(rawRead);

			name = rawRead;
            %hist.set{sCnt}.name = deblank(name(:).');
            name = deblank(name(:).');
            trueName = name;
            %do some processing on name to remove special characters
            name = strrep(name,'.','p'); %any points to p
            name = regexprep(name, '^(\W*)', 's'); %any initial non-word characters to s
            name = regexprep(name, '(\W*)', '_'); %any non-word characters to _
            name = regexprep(name, '^(\d*)', 'n$1'); %any initial numbers to n


            nMeas = fread(fid,1,'int32');

            if nMeas == 0
                error('nMeas is zero')
            end

            clear tempStr

            tempStr.nodeNums = zeros(nMeas,1);
            tempStr.nodeDofs = zeros(nMeas,1);
            tempStr.nodePos = zeros(nDims,nMeas);
            tempStr.histTraces = zeros(ntMeas,nMeas);
            tempStr.name = trueName;

            for cnt = 1:nMeas
                tempStr.nodeNums(cnt) = fread(fid, 1, 'int32')+1;
                tempStr.nodeDofs(cnt) = fread(fid, 1, 'int32')+1;
                tempStr.nodePos(:,cnt) = fread(fid, nDims, precStr);
                tempStr.histTraces(:,cnt) = fread(fid, ntMeas, precStr);
            end
            if (fileVerFull >= 1003 && max(tempStr.nodeDofs) == 0)
                % group data rather than nodes
                tempStr.dofGroup = tempStr.nodeNums;
                tempStr = rmfield(tempStr,'nodeNums');
                tempStr = rmfield(tempStr,'nodeDofs');
                %tempStr = rmfield(tempStr,'nodePos');
            end

            eval(sprintf('hist.sets.%s = tempStr;\n', name))

        end
    end


    fclose(fid);

    hist.nt = ntMeas;
    hist.dt = dtMeas;
    if fileVerFull >= 1001
        hist.startMeas = startMeas;
    else
        hist.startMeas = 0;
    end


end
