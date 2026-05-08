function [  ] = savePogoField( fileName, f, fileVerMaj, fileVerMin )
%savePogoField - save field data into the Pogo field format
%
%   savePogoField( fileName, f, fileVer )
%
%fileName - the file name
%f - the field data struct to be saved, as loaded via loadPogoField
%       (see loadPogoField help for info)
%fileVer - the required file version (defaults to latest, currently v1.03)
%
%Written by P. Huthwaite, March 2018

fileVerFull = fileVerMaj*1000+fileVerMin;
if nargin < 3
    fileVerFull = 1003;
end

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

fid = fopen(fileName,'wb');
    if (fid == -1)
        error('File %s could not be opened.', fileName)
    end

    header = blanks(20);
    if fileVerFull == 1000
        header(1:14) = '%pogo-field1.0';
        header(15:20) = 0;
    elseif fileVerFull == 1002
        header(1:15) = '%pogo-field1.02';
        header(16:20) = 0;
    elseif fileVerFull == 1003
        header(1:15) = '%pogo-field1.03';
        header(16:20) = 0;
    else
        error('Unsupported file version: %f',fileVerFull)
    end

    fwrite(fid, header, '*char');

    if isfield(f,'prec')
        prec = f.prec;
    else
        prec = 8;
    end

    if prec ~= 4 && prec ~= 8
        error('Specified precision %d incorrect. Should be 4 or 8 bytes.', prec)
    end
    fwrite(fid,prec,'int32');

    if prec == 4
	precStr = 'float32';
    else
        precStr = 'float64';
    end


    nDims = size(f.nodeLocs,1);
    nNodes = size(f.nodeLocs,2);
    nDofPerNode = nDims; %assumed

    fwrite(fid, nDims, 'int32');

    if fileVerFull >= 1002
        fwrite(fid, nDofPerNode, 'int32');
    end

    fwrite(fid, nNodes, 'int32');
    fwrite(fid, f.nodeLocs, precStr);

    if fileVerFull >= 1003
        if ~isfield(f,'nodeNums')
            f.nodeNums = 1:nNodes;
        end
        fwrite(fid,f.nodeNums-1,'int32');
    end

    nFieldStores = length(f.times);

    fwrite(fid, nFieldStores, 'int32');

    for cnt = 1:nFieldStores
        fwrite(fid,f.times(cnt),precStr);
        fwrite(fid,f.ux(:,cnt),precStr);
        fwrite(fid,f.uy(:,cnt),precStr);
        if nDofPerNode == 3
            fwrite(fid,f.uz(:,cnt),precStr);
        end
    end

    fclose(fid);
end
