function [ m ] = loadVtuMesh( fileName )
%loadVtuMesh - load in a VTU mesh as a Pogo model
%
%   [ m ] = loadVtuMesh( fileName )
%
% fileName - fileName to load
% m - model struct (see savePogoInp help for details)
%
% Written by P. Huthwaite, 2017
% Not to be distributed.

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
    fileName = [fileName '.vtu'];
end
fid = fopen(fileName, 'r');

xmlstrs = {fgetl(fid)};
singleStr = xmlstrs{1};
firstlinebytes = ftell (fid) - 1;
bytesperchar = round (firstlinebytes / numel (xmlstrs{1}));

find = 1;
while ischar (xmlstrs{find})
    find = find + 1;
    xmlstrs{find,1} = fgetl(fid);
    singleStr = [singleStr xmlstrs{find,1}];
    if ~isempty(strfind (xmlstrs{find,1}, 'AppendedData'))
        xmlstrs = [ xmlstrs; {'</AppendedData>'; '</VTKFile>'} ];
        singleStr = [singleStr '</AppendedData></VTKFile>'];
        break;
    end
end

dataPos = ftell (fid) + bytesperchar;
%disp(singleStr)
docNode = xmlreadstring(singleStr);

vtkNode = docNode.getDocumentElement;

%vtkNode.getNodeName
% Get all the "Entry" nodes
unstructGrid = vtkNode.getFirstChild;

pieceData = unstructGrid.getFirstChild;

nNodes = str2double(pieceData.getAttribute('NumberOfPoints'));
nEls = str2double(pieceData.getAttribute('NumberOfCells'));

pDataArray = pieceData.getElementsByTagName('Points').item(0).getElementsByTagName('DataArray').item(0);

nodeDataLoc = str2double(pDataArray.getAttribute('offset'));

cellDataArrays = pieceData.getElementsByTagName('Cells').item(0).getElementsByTagName('DataArray').item(0);
conOffset = -1;
offsetsOffset = -1;
typesOffset = -1;

while ~isempty(cellDataArrays)
    if strcmpi(cellDataArrays.getNodeName, 'DataArray')
        if strcmpi(cellDataArrays.getAttribute('Name'), 'connectivity')
            conOffset = str2double(cellDataArrays.getAttribute('offset'));
        elseif strcmpi(cellDataArrays.getAttribute('Name'), 'offsets')
            offsetsOffset = str2double(cellDataArrays.getAttribute('offset'));
        elseif strcmpi(cellDataArrays.getAttribute('Name'), 'types')
            typesOffset = str2double(cellDataArrays.getAttribute('offset'));
        end
    end
    cellDataArrays = cellDataArrays.getNextSibling;
end


%read in binary bits
fseek(fid,dataPos+nodeDataLoc,-1);
nbytes = fread(fid,1,'int32');
nodePos = fread(fid,[3,nNodes],'float32');

m.nodePos = nodePos(1:2,:);

% figure
% plot(nodeLocs(1,:),nodeLocs(2,:),'k.')

fseek(fid,dataPos+conOffset,-1);
nbytes = fread(fid,1,'int32');
elNodes = fread(fid,[3,nEls],'int32');

m.elNodes = elNodes+1;

m.elTypes{1}.name = 'CPE3';
m.elTypes{1}.paramsType = 0;

m.nDims = 2;
m.nDofPerNode = 2;
m.elTypeRefs = ones(nEls,1);


fclose(fid);

end
