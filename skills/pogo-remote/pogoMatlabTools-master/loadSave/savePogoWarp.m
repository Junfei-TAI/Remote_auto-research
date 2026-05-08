function [  ] = savePogoWarp( fileName, w, fileMajVer, fileMinVer )
%savePogoField - save data into the Pogo warp format
%
%   savePogoWarp( fileName, w, fileVer )
%
%fileName - the file name
%fileMajVer - the required major file version (defaults to latest, currently 1)
%fileMinVer - the required minor file version (defaults to latest, currently 0)
%w - the warp data struct to be saved, containing the following fields:
%
%w.scale - scale data in (N-1) dimensions, where N is the number of
%dimensions for the model to apply the warping to.
%w.d - vector of spacings in each of the dimensions for w.scale grid
%w.c - centre locations in each of the dimensions for the w.scale grid
%w.zero - 'zero' location for the mesh - the location in the scaled
%dimension which remains unchanged
%w.perms - vector of N dimensions, indicating whether they are the scaling
%direction or which of the scaling dimensions they correspond to. e.g.
%   w.perms = [2, 1, 0];
% would indicate that the x dimension in the model corresponded to the
% second dimension of the grid, y would correspond to the first dimension
% and z would be the scaling direction.
%Written by P. Huthwaite, June 2022

if nargin < 3
    fileMajVer = 1;
    if nargin < 4
        fileMinVer = 0;
    end
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
    fileName = [fileName '.pogo-warp'];
end

    fid = fopen(fileName,'wb');
    if (fid == -1)
        error('File %s could not be opened.', fileName)
    end


    header = '%pogo-warp';
    fwrite(fid, stringSaveTidy(header,20), '*char');

    fwrite(fid, fileMajVer, 'int32');
    fwrite(fid, fileMinVer, 'int32');


    %fwrite(fid, header, '*char');

    %start section
    fwrite(fid, stringSaveTidy('generalInfo',40), '*char');
    fwrite(fid, 1, 'int32');

    writePos = ftell(fid);
    sectSize = 0;
    fwrite(fid, sectSize, 'int64');
    startPos = ftell(fid);

    if isfield(w,'prec')
        prec = w.prec;
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

    if ~isfield(w,'perms')
        error('Permutations missing (need to specify perms)')
    end

    ndims = length(w.perms);
    fwrite(fid,ndims,'int32');

    %output permutation for dimensions
    if max(w.perms) > ndims-1 || min(w.perms) < 0
        disp(w.perms)
        error('Range error on perms')
    end
    fwrite(fid,w.perms-1,'int32');

    %complete section
    curPos = ftell(fid);
    sectSize = curPos - startPos;
    fseek(fid, writePos,-1);
    fwrite(fid, sectSize, 'int64');
    fseek(fid, curPos,-1);

    %start section - gridInfo
    fwrite(fid, stringSaveTidy('gridInfo',40), '*char');
    fwrite(fid, 1, 'int32');
    writePos = ftell(fid);
    sectSize = 0;
    fwrite(fid, sectSize, 'int64');
    startPos = ftell(fid);

    n = size(w.scale);
    n(n == 1) = [];
    if length(n) ~= ndims-1
        disp(n)
        error("Incorrect sized grid for number of model dimensions. %d should be %d.",length(n), ndims-1)
    end
    %n1, n2 (or just n1 if 2d)
    fwrite(fid, n, 'int32');


    %d1, d2 - grid spacing
    if ~isfield(w,'d')
        error("Field d missing")
    end
    if length(w.d) ~= ndims-1
        error("Incorrect size of d: %d",length(d))
    end
    fwrite(fid, w.d, precStr);


    if length(w.c) ~= ndims-1
        error("Incorrect size of c: %d",length(c))
    end
    %c1 - centre position of grid
    if ~isfield(w,'c')
        error("Field c missing")
    end
    fwrite(fid, w.c, precStr);


    %zero plane
    fwrite(fid, w.zero, precStr);

    %complete section
    curPos = ftell(fid);
    sectSize = curPos - startPos;
    fseek(fid, writePos,-1);
    fwrite(fid, sectSize, 'int64');
    fseek(fid, curPos,-1);

    %start section
    fwrite(fid, stringSaveTidy('scale',40), '*char');
    fwrite(fid, 1, 'int32');
    writePos = ftell(fid);
    sectSize = 0;
    fwrite(fid, sectSize, 'int64');
    startPos = ftell(fid);

    %values
    fwrite(fid, w.scale, precStr);

    %complete section
    curPos = ftell(fid);
    sectSize = curPos - startPos;
    fseek(fid, writePos,-1);
    fwrite(fid, sectSize, 'int64');
    fseek(fid, curPos,-1);

    fclose(fid);
end
