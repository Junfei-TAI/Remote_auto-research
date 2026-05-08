function [] = savePogoBlock(fileName, block)
%Quick function to save Pogo blocks - should not generally be used
%externally
%
% PH - Aug 2024

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

fid = fopen(fileName,'wb');
if (fid == -1)
    error('File %s could not be opened.', fileName)
end

header = '%pogo-block1.01';
fwrite(fid, stringSaveTidy(header,20), '*char');


[blockWidth, blockHeight, nBlocks] = size(block.blockData);

fwrite(fid, nBlocks, 'int32');
fwrite(fid, blockWidth, 'int32');
fwrite(fid, blockHeight, 'int32');

fwrite(fid, block.blockData,'int32');


% block.nBlocks = fread(fid, 1, 'int32');
% block.blockWidth = fread(fid, 1, 'int32');
% block.blockHeight = fread(fid, 1, 'int32');
%
% block.blockData = fread(fid, block.blockWidth*block.blockHeight*block.nBlocks, 'int32');
%
% block.blockData = reshape(block.blockData,[block.blockWidth, block.blockHeight, block.nBlocks]);
%

[nBlockLinks, nBlocks2] = size(block.blockLinks);

fwrite(fid, nBlockLinks, 'int32');
% nBlockLinks = fread(fid, 1, 'int32');
%
fwrite(fid, block.blockLinks, 'int32');
% block.blockLinks = fread(fid, nBlockLinks*block.nBlocks, 'int32');
% block.blockLinks = reshape(block.blockLinks,[nBlockLinks, block.nBlocks]);



fclose(fid);


end
