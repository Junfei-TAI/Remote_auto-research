function [sectSize, sectVer] = skipToFileSection(fid, sectName, verbose)
if nargin < 3
    verbose = 0;
end

found = 0;
while ~feof(fid)
    sectNameRead = readBinaryText(fid,40);
    sectVer = fread(fid, 1, 'int32');
    sectSize = fread(fid, 1, 'int64');
    if verbose >= 1
        disp(sectNameRead)
    end
    if strcmp(sectNameRead, sectName)
        found = 1;
        break
    end
    if feof(fid)
        error('Section name %s not found', sectName)
    end
    fseek(fid,sectSize,0);
end
if ~found
    error('Section name %s not found', sectName)
end

end
