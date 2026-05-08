function [str] = readBinaryText(fid, len)
rawRead = fread(fid, len, 'uint8').';
nullTerm = find(rawRead == 0,1);
if ~isempty(nullTerm)
    rawRead(nullTerm:end) = 0;
end
rawRead = char(rawRead);
str = deblank(rawRead);
end
