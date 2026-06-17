function export_pogo_field_xdmf(fieldPath, outDir, caseName)
%EXPORT_POGO_FIELD_XDMF Convert a POGO field file to ParaView XDMF + raw binaries.
%
% The default output is a temporal point-cloud field. This is intentional for
% runs that use model.fieldStoreNodes: the field file contains only sampled
% nodes, so the original full-element connectivity is no longer valid.
%
% Usage:
%   export_pogo_field_xdmf('case.pogo-field')
%   export_pogo_field_xdmf('case.pogo-field', 'paraview_field', 'case')

if nargin < 1 || isempty(fieldPath)
    error('fieldPath is required. Usage: export_pogo_field_xdmf(''case.pogo-field'', ''out_dir'', ''case_name'')');
end
if nargin < 2 || isempty(outDir)
    [fieldDir, fieldBase, ~] = fileparts(fieldPath);
    outDir = fullfile(fieldDir, [fieldBase '_xdmf']);
end
if nargin < 3 || isempty(caseName)
    [~, caseName, ~] = fileparts(fieldPath);
end

thisFile = mfilename('fullpath');
[thisDir, ~, ~] = fileparts(thisFile);
pogoToolsRoot = fileparts(thisDir);
addpath(fullfile(pogoToolsRoot, 'loadSave'));

if ~isfolder(outDir)
    mkdir(outDir);
end

fprintf('Loading POGO field: %s\n', fieldPath);
field = loadPogoField(fieldPath);

nFrames = numel(field.times);
nDof = field.nDofPerNode;
if nDof < 1 || nDof > 3
    error('Unsupported nDofPerNode=%d', nDof);
end

if isfield(field, 'nodeNums')
    pointNodeNums = unique(field.nodeNums(:), 'stable');
else
    pointNodeNums = (1:size(field.nodeLocs, 2)).';
end
if max(pointNodeNums) > size(field.nodeLocs, 2) || min(pointNodeNums) < 1
    error('field.nodeNums contains node ids outside field.nodeLocs.');
end
nPoints = numel(pointNodeNums);
pointLocs = field.nodeLocs(:, pointNodeNums);
if size(pointLocs, 1) == 1
    pointLocs = [pointLocs; zeros(2, size(pointLocs, 2))];
elseif size(pointLocs, 1) == 2
    pointLocs = [pointLocs; zeros(1, size(pointLocs, 2))];
elseif size(pointLocs, 1) > 3
    pointLocs = pointLocs(1:3, :);
end

pointsPath = fullfile(outDir, [caseName '_points_f32.bin']);
write_float32_matrix(pointsPath, pointLocs.');

nodeNumsPath = fullfile(outDir, [caseName '_node_numbers_i32.bin']);
write_int32_vector(nodeNumsPath, int32(pointNodeNums(:)));

dispFiles = strings(nFrames, 1);
magFiles = strings(nFrames, 1);
for frameIdx = 1:nFrames
    dispVec = zeros(nPoints, 3, 'single');
    mag = zeros(nPoints, 1, 'single');
    if isfield(field, 'u')
        vals = field.u(:, frameIdx);
        for dof = 1:nDof
            mask = field.dofNums == dof;
            nodeNumsForDof = field.nodeNums(mask);
            valsForDof = vals(mask);
            [isPresent, pointIdx] = ismember(nodeNumsForDof, pointNodeNums);
            pointIdx = pointIdx(isPresent);
            valsForDof = valsForDof(isPresent);
            dispVec(pointIdx, dof) = single(valsForDof);
        end
    else
        dispVec(:, 1) = single(field.ux(:, frameIdx));
        if isfield(field, 'uy')
            dispVec(:, 2) = single(field.uy(:, frameIdx));
        end
        if isfield(field, 'uz')
            dispVec(:, 3) = single(field.uz(:, frameIdx));
        end
    end
    mag(:) = sqrt(sum(dispVec.^2, 2));

    dispName = sprintf('%s_u_%04d_f32.bin', caseName, frameIdx);
    magName = sprintf('%s_umag_%04d_f32.bin', caseName, frameIdx);
    dispPath = fullfile(outDir, dispName);
    magPath = fullfile(outDir, magName);
    write_float32_matrix(dispPath, dispVec);
    write_float32_matrix(magPath, mag);
    dispFiles(frameIdx) = dispName;
    magFiles(frameIdx) = magName;
end

xdmfPath = fullfile(outDir, [caseName '.xdmf']);
write_xdmf(xdmfPath, caseName, nPoints, field.times(:), ...
    [caseName '_points_f32.bin'], dispFiles, magFiles);

summaryPath = fullfile(outDir, [caseName '_xdmf_summary.txt']);
fid = fopen(summaryPath, 'w');
if fid == -1
    error('Could not open summary path: %s', summaryPath);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'fieldPath=%s\n', fieldPath);
fprintf(fid, 'xdmfPath=%s\n', xdmfPath);
fprintf(fid, 'nPoints=%d\n', nPoints);
fprintf(fid, 'nFrames=%d\n', nFrames);
fprintf(fid, 'nDofPerNode=%d\n', nDof);
fprintf(fid, 'timeStart=%0.12g\n', field.times(1));
fprintf(fid, 'timeEnd=%0.12g\n', field.times(end));

fprintf('Wrote XDMF: %s\n', xdmfPath);
fprintf('Wrote %d points x %d frames to %s\n', nPoints, nFrames, outDir);
end

function write_float32_matrix(path, arr)
fid = fopen(path, 'wb');
if fid == -1
    error('Could not open binary output: %s', path);
end
cleanup = onCleanup(@() fclose(fid));
% XDMF binary DataItem expects C-order/row-major layout. MATLAB stores arrays
% column-major, so transpose 2-D matrices before linearizing to keep rows
% contiguous, e.g. [x y z] per point for an N x 3 coordinate array.
if ismatrix(arr) && size(arr, 2) > 1
    out = single(arr.');
else
    out = single(arr(:));
end
count = fwrite(fid, out(:), 'float32');
if count ~= numel(arr)
    error('Short write for %s: wrote %d of %d float32 values.', path, count, numel(arr));
end
end

function write_int32_vector(path, arr)
fid = fopen(path, 'wb');
if fid == -1
    error('Could not open binary output: %s', path);
end
cleanup = onCleanup(@() fclose(fid));
count = fwrite(fid, int32(arr(:)), 'int32');
if count ~= numel(arr)
    error('Short write for %s: wrote %d of %d int32 values.', path, count, numel(arr));
end
end

function write_xdmf(path, caseName, nPoints, times, pointsFile, dispFiles, magFiles)
fid = fopen(path, 'w');
if fid == -1
    error('Could not open XDMF output: %s', path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '<?xml version="1.0" ?>\n');
fprintf(fid, '<!DOCTYPE Xdmf SYSTEM "Xdmf.dtd" []>\n');
fprintf(fid, '<Xdmf Version="3.0">\n');
fprintf(fid, '  <Domain>\n');
fprintf(fid, '    <Grid Name="%s" GridType="Collection" CollectionType="Temporal">\n', caseName);
for frameIdx = 1:numel(times)
    fprintf(fid, '      <Grid Name="frame_%04d" GridType="Uniform">\n', frameIdx);
    fprintf(fid, '        <Time Value="%.12g" />\n', times(frameIdx));
    fprintf(fid, '        <Topology TopologyType="Polyvertex" NumberOfElements="%d" />\n', nPoints);
    fprintf(fid, '        <Geometry GeometryType="XYZ">\n');
    fprintf(fid, '          <DataItem Format="Binary" DataType="Float" Precision="4" Endian="Little" Dimensions="%d 3">%s</DataItem>\n', nPoints, pointsFile);
    fprintf(fid, '        </Geometry>\n');
    fprintf(fid, '        <Attribute Name="displacement" AttributeType="Vector" Center="Node">\n');
    fprintf(fid, '          <DataItem Format="Binary" DataType="Float" Precision="4" Endian="Little" Dimensions="%d 3">%s</DataItem>\n', nPoints, dispFiles(frameIdx));
    fprintf(fid, '        </Attribute>\n');
    fprintf(fid, '        <Attribute Name="displacement_magnitude" AttributeType="Scalar" Center="Node">\n');
    fprintf(fid, '          <DataItem Format="Binary" DataType="Float" Precision="4" Endian="Little" Dimensions="%d">%s</DataItem>\n', nPoints, magFiles(frameIdx));
    fprintf(fid, '        </Attribute>\n');
    fprintf(fid, '      </Grid>\n');
end
fprintf(fid, '    </Grid>\n');
fprintf(fid, '  </Domain>\n');
fprintf(fid, '</Xdmf>\n');
end
