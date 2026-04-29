function [ hist, fileVer, prec, header ] = loadPogoHist( fileName )
%loadPogoHist - load history data from Pogo FE
%
% [ hist, fileVer, prec, header ] = loadPogoHist( fileName )
%
%fileName - the file name
%fileVer - the version of the read file
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
    fileName = [fileName '.pogo-hist'];
end



    fid = fopen(fileName,'rb');
    if (fid == -1) 
        error('File %s could not be opened.', fileName)
    end

    header = deblank(fread(fid, 20, '*char')');
    
    fileVer = -1;
    if strcmp(header, '%pogo-hist1.0') == 1
        fileVer = 1;
    end
    if strcmp(header, '%pogo-hist1.01') == 1
        fileVer = 1.01;
    end
    if strcmp(header, '%pogo-hist1.02') == 1
        fileVer = 1.02;
    end
    if strcmp(header, '%pogo-hist1.03') == 1
        fileVer = 1.03;
    end
    if fileVer == -1
        error('File is wrong format. header: %s.', header)
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

    nDims = fread(fid, 1, 'int32');
    %return
    if fileVer < 1.02
        nMeas = fread(fid, 1, 'int32');
    else
        nMeasSets = fread(fid, 1, 'int32');
    end
    ntMeas = fread(fid, 1, 'int32');
    dtMeas = fread(fid, 1, precStr);
    
    if fileVer >= 1.01
        startMeas = fread(fid, 1, precStr);
    end
    if fileVer < 1.02
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
            if (fileVer >= 1.03 && max(tempStr.nodeDofs) == 0) 
                % group data rather than nodes
                tempStr.dofGroup = tempStr.nodeNums;
                tempStr = rmfield(tempStr,'nodeNums');
                tempStr = rmfield(tempStr,'nodeDofs');
                tempStr = rmfield(tempStr,'nodePos');
            end
                
            eval(sprintf('hist.sets.%s = tempStr;\n', name))
            
        end
    end
    
    
    fclose(fid);

    hist.nt = ntMeas;
    hist.dt = dtMeas;
    if fileVer >= 1.01
        hist.startMeas = startMeas;
    else
        hist.startMeas = 0;
    end

    
end

