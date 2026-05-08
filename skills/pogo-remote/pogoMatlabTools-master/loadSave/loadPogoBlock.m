function [ block, fileVer, header ] = loadPogoBlock( fileName )
%loadPogoBlock - load block file data from Pogo FE
%
% [ block, fileVer, header ] = loadPogoBlock( fileName )
%
%fileName - the file name
%fileVer - file version
%header - output of the file header
%
%block - a structure containing the following:
%nBlocks - the number of blocks
%blockWidth - the width of the blocks in memory
%blockHeight - the block height
%blockData - which nodes belong in each block (so
%   an array of (1:nBlocks, 1:blockWidth, 1:blockHeight) specifying the
%   (zero indexed) node numbers at each point. -1 means unused (not all
%   blocks are completely filled.
%blockLinksB - links between different blocks (1:nBlocks*nBlockLinks) size;
%   this is the block number linked to
%blockLinksR - links between different blocks (1:nBlocks*nBlockLinks) size;
%   this is the row linked to
%blockLinksC - links between different blocks (1:nBlocks*nBlockLinks) size;
%   this is the column linked to (NB col must be multiplied by 8 to get the
%   actual column position in the block)
%blockLinks - raw blocklink data from the file; repetition of the 3 parts
%   above, but will be file version dependent
%
%
% Written by P. Huthwaite, March 2014
% Updated to output as struct April 2014, PH

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
    fileName = [fileName '.pogo-block'];
end

fid = fopen(fileName,'rb');
if (fid == -1)
    disp('File could not be opened.')
    return;
end

header = deblank(fread(fid, 20, '*char')');
fileVer = -1;
if strcmp(header, '%pogo-block1.0')
    fileVer = 1000;
end
if strcmp(header, '%pogo-block1.01')
    fileVer = 1001;
end


if fileVer == -1
    error('File is wrong format: %s.', header)
end

block.nBlocks = fread(fid, 1, 'int32');
block.blockWidth = fread(fid, 1, 'int32');
block.blockHeight = fread(fid, 1, 'int32');

block.blockData = fread(fid, block.blockWidth*block.blockHeight*block.nBlocks, 'int32');

block.blockData = reshape(block.blockData,[block.blockWidth, block.blockHeight, block.nBlocks]);

nBlockLinks = fread(fid, 1, 'int32');

block.blockLinks = fread(fid, nBlockLinks*block.nBlocks, 'int32');
block.blockLinks = reshape(block.blockLinks,[nBlockLinks, block.nBlocks]);
if fileVer >= 1001
    %24 bits, 4 bits, 4 bits
    block.blockLinksB = floor(block.blockLinks/256);
    pos = mod(block.blockLinks,256);
    block.blockLinksR = floor(pos/16);
    block.blockLinksC = mod(pos,16);
else
    %28 bits, 2 bits, 2 bits - old version
    block.blockLinksB = floor(block.blockLinks/16);
    pos = mod(blockLinks,16);
    block.blockLinksR = floor(pos/4);
    block.blockLinksC = mod(pos,4);
end

fclose(fid);

end
