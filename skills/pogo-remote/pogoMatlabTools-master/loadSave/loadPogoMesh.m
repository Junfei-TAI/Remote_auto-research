function [ model ] = loadPogoMesh( fileName )
% function [ model ] = loadPogoMesh( fileName )
% Loads a Pogo mesh from the .pogo-mesh format into a model struct

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
    fileName = [fileName '.pogo-mesh'];
end

fid = fopen(fileName,'rb','n','UTF-8');
if (fid == -1)
    error('File %s could not be opened.', fileName)
    %return;
end

header = readBinaryText(fid,20);

fileMajVer = -1;
fileMinVer = -1;

if strcmp(header, '%pogo-mesh') == 1
    fileMajVer = fread(fid, 1, 'int32');
    fileMinVer = fread(fid, 1, 'int32');
end
if fileMajVer == -1
    error('File is wrong format. header: %s.', header)
end

fileVerFull = fileMajVer*1000+fileMinVer;

if fileVerFull > 1000
    warning('Mesh file version, %d.%d, is too new. Update this function.',fileMajVer,fileMinVer)
    warning('We will attempt to continue, but note that some features may be incompatible.')
end

%disp(fileVer)
model.fileMajVer = fileMajVer;
model.fileMinVer = fileMinVer;



%load in metadata
%placeholder for metadata in future - not supported right now
%[sectSize, sectVer] = skipToFileSection(fid,'metadata');


skipToFileSection(fid,'generalInfo');


maxUint = uint32(uint64(2)^32-1);


model.prec = fread(fid, 1, 'int32');
if model.prec == 8
    precString = 'float64';
else
    precString = 'float32';
end
%model.prec
model.nDims = fread(fid, 1, 'int32');

%--------------------------------------------------------------
skipToFileSection(fid,'nodes');

nNodes = fread(fid, 1, 'uint32');
model.nodePos = fread(fid, [model.nDims,nNodes], precString);

%--------------------------------------------------------------
skipToFileSection(fid,'elements');

nEls = fread(fid, 1, 'uint32');
nNodesPerEl = fread(fid, 1, 'int32');

model.elNodes = fread(fid, [nNodesPerEl,nEls], 'uint32')+1;

model.elTypes{1}.name = 'CPE3';
model.elTypes{1}.paramsType = 0;

model.nDims = 2;
model.nDofPerNode = 2;
model.elTypeRefs = ones(nEls,1);

fclose(fid);

end
