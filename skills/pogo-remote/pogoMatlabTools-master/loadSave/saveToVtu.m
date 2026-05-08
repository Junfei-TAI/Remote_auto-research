function [ ] = saveToVtu( fileName, model )
%saveToVtk - save a pogo style mesh to Vtu (VTK unstructured mesh) format
%   saveToVtu( fileName, model )
%
% model format as in savePogoInp - only points and elements saved:
%
% model.nodePos - nodal locations; size nDims x nNodes
% model.elNodes - nodes for each element; size nNodesPerElMax x nEls
%
%Written by Peter Huthwaite, Feb 2017
precString = 'Float32';
precLen = 4;
intSize = 4;
charSize = 1;
nPoints = size(model.nodePos,2);
nDims = size(model.nodePos,1);
nEls = size(model.elNodes,2);

%fileName = 't';
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

%preprocessing
%sort elements and offsets
nElNodesMax = size(model.elNodes,1);


nNodesForEl = sum(double(model.elNodes ~= 0),1);
%offsetArray = [0 cumsum(nNodesForEl(1:end-1))]; %get all the offsets
offsetArray = cumsum(nNodesForEl(:)); %get all the offsets
%elArray = setdiff(m.elNodes(:),0)-1; %all nodes not including the zeros
elArray = model.elNodes(:); %all nodes not including the zeros
elArray(elArray == 0) = [];
elArray = elArray-1;


if nDims == 2
    cellType = 5*(nNodesForEl == 3) + 9*(nNodesForEl == 4);
else
    cellType = 10*(nNodesForEl == 4) + 13*(nNodesForEl == 6) + 12*(nNodesForEl == 8);
end

fid = fopen(fileName,'wb');
if (fid == -1)
    error('File %s could not be opened.', fileName)
end

fprintf(fid,'<?xml version="1.0"?>\n');
fprintf(fid,'<VTKFile type="UnstructuredGrid" version="0.1" byte_order="LittleEndian" >\n<UnstructuredGrid>\n');



fprintf(fid,'<Piece NumberOfPoints="%d" NumberOfCells="%d">\n', nPoints, nEls);
fprintf(fid,'<Points>\n');

offset = 0;

fprintf(fid,'<DataArray type="%s" NumberOfComponents="3" format="appended" offset="0" />\n', precString);
offset = offset + nPoints*3*precLen+intSize;
fprintf(fid,'</Points>\n');

fprintf(fid,'<Cells>\n');
fprintf(fid,'<DataArray type="Int32" Name="connectivity" format="appended" offset="%d" />\n', offset);
offset = offset + length(elArray)*intSize+intSize;

fprintf(fid,'<DataArray type="Int32" Name="offsets" format="appended" offset="%d" />\n', offset);
offset = offset + nEls*intSize+intSize;

fprintf(fid,'<DataArray type="UInt8" Name="types" format="appended" offset="%d" />\n', offset);
offset = offset + nEls*charSize+intSize;

fprintf(fid,'</Cells>\n');
fprintf(fid,'</Piece>\n');
fprintf(fid,'</UnstructuredGrid>\n');

fprintf(fid,'<AppendedData encoding="raw">\n_');
%write data here
%points first
nBytes = nPoints*3*precLen;
fwrite(fid, nBytes, 'int32');

if nDims == 2
    savePoints = zeros(3, nPoints);
    savePoints(1:2, :) = model.nodePos;
else
    savePoints = model.nodePos;
end
fwrite(fid, savePoints(:), 'float32');


%cells (elements)
%node definitions:
nBytes = length(elArray)*intSize;
fwrite(fid, nBytes, 'int32');
fwrite(fid, elArray(:), 'int32');

%offset definitions:
nBytes = nEls*intSize;
fwrite(fid, nBytes, 'int32');
fwrite(fid, offsetArray(:), 'int32');

%cell types (5 tri, 9 quad, 10 tet, 12 hex):
nBytes = nEls*charSize;
fwrite(fid, nBytes, 'int32');
fwrite(fid, cellType(1:end), 'char');

fprintf(fid,' \n\n</AppendedData>\n');

fprintf(fid,'</VTKFile>\n');

fclose(fid);

end
