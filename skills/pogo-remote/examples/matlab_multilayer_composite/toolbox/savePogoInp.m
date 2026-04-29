function [ ] = savePogoInp( fileName, model, fileMajVer, fileMinVer )
%savePogoInp - save a pogo input file
%   savePogoInp( fileName, model, fileMajVer, fileMinVer )
%
% fileName - the filename to save to
% fileMajVer, fileMinVer - what version of the file to save to 
% v1.07 -> v1.12 supported, i.e. fileMajVer = 1 and fileMinVer from 7-12. 
% Note that for backwards compatibility if fileMajVer is
% set but not fileMinVer then both are extracted from fileMajVer assuming
% this is a floating point number.
% model - a structure with the fields to be saved:
%
% model.nDims - 2 or 3 for 2D or 3D
% model.nDofPerNode - as above
% model.runName - not important (unused at present)
% model.dt - time step
% model.nt - number of increments
% model.nodePos - nodal locations; size nDims x nNodes
% model.elNodes - nodes for each element; size nNodesPerElMax x nEls
% model.elTypeRefs - which of the element types each element refers to, length nEls
% model.matTypeRefs - which of the material types each element refers to, length nEls
% model.orientRefs - which of the orientations each element refers to, length nEls
% 
% model.elTypes{n} - structure for each of the element types, referred to by model.elTypeRefs
% model.elTypes{n}.name - element name (matching Abaqus library typically)
% model.elTypes{n}.paramsType - parameters associated with the element type - usually just 0
% 
% model.matTypes{n} - structure for each of the material types, referred to by model.matTypeRefs
% model.matTypes{n}.parent - what is the parent material (0 if no parent) - used in absorbing boundaries
% model.matTypes{n}.paramsType - parameters associated with the element type - 0 means 
% 	paramValues are E, nu, rho, alpha (optional), 1 is anisotropic
% model.matTypes{n}.paramValues - the parameters mentioned above
% 
% model.or{n} can specify orientations
% model.or{n}.paramsType - parameter type (0 normally)
% model.or{n}.paramValues - values for the parameters
%
% From v1.08 onwards, can excite and measure DoF together (e.g. to model a 
% transducer). The parameters below define these groups.
% model.dofGroups{n} - struct for the nth DoF group (referred to later).
% model.dofGroups{n}.dofSpec - which DoF
% model.dofGroups{n}.nodeSpec - which nodes
% model.dofGroups{n}.dofWeight - what is the weighting for each
%
% model.fixNodes - nodes with DOFs to be fixed
% model.fixDof - DOF corresponding to the nodes above. Nodes can appear in
% fixNodes multiple times to specify different DOF.
% 
% model.shot{n} - structure for each shot 
%  several shots can be used in each model to specify different source
%  setups; can be useful for array imaging
% model.shots{n}.ntSig - number of time points for all the signals (commonly just set to model.nt)
% model.shots{n}.dtSig - time step for the signals (commonly just set to model.dt)
% 
% model.shots{n}.sigs{m} - structure for each of the signals used
% 
% model.shots{n}.sigs{m}.isDofGroup - 0 if not, 1 if dofGroups are referred to in dofSpec (NB only from v1.08)
% if 0:
% model.shots{n}.sigs{m}.nodeSpec - nodes the signal is applied to. 
%   NB: while nodes can appear multiple times in nodeSpec, they must be 
%   applied to different DOF. Only a single signal can be applied to each 
%   DOF in the model.
% model.shots{n}.sigs{m}.dofSpec - DOF to apply the signal to (matches nodeSpec) in (range: 1 to model.nDofPerNode)
% if 1:
% model.shots{n}.sigs{m}.dofGroup - dof groups, defined earlier
%
% model.shots{n}.sigs{m}.sigType - 0 force, 1 displacement or (unused at present) 2 velocity
% model.shots{n}.sigs{m}.sigAmps - amplitudes the signals are multiplied by for each dof specified
% model.shots{n}.sigs{m}.sig - signal (length model.ntSig)
% 
% model.measFreq - number of time increments between when history measurements are taken
% model.measStart - starting increment (1 indexed)
% model.measSets{n} - structure for each of the measured node sets
% model.measSets{n}.name - string name for the set
% model.measSets{n}.isDofGroup - do we refer to DoF groups or do we use nodal values (0 or 1)
%if 0:
% model.measSets{n}.measNodes - nodes to take history measurements from
% model.measSets{n}.measDof - degrees of freedom to take history measurements from 
%if 1:
% model.measSets{n}.dofGroup - which Dof groups 
% 
% model.fieldStoreIncs - which increments to output the field at. Omit or empty array if none.
% model.fieldStoreNodes - nodes at which to output the field. Omit if all. Empty array if none.
%
% model.metadata - struct containing metadata, stored as
%   model.metadata.temperature = 20
% or 
%   model.metadata.owner = 'Boris Johnson'
% Note that both text or numerical values should work OK - both will be stored
% as text then interpreted as numbers when loaded back in.
%
% model.mpiDivNum - what is the MPI number associated with this model (i.e. how
%   will the other models refer to this one)
% model.mpi{X}.outNodes and model.mpi{Y}.inNodes - which nodal values should I pass
%   out to process X, and where should I place (overwrite) the nodal values
%   from process Y
%
% For two models ma.mpiDivNum = 2 and mb.mpiDivNum = 5 (just as examples),
% then length(ma.mpi{5}.outNodes) = length(mb.mpi{2}.inNodes), and the same
% for all the other combinations. 
% Generally this means that every model will need to have an extra layer of
% nodes at the boundary which is copied off to the other model. 
% It is critical that the mapping here is consistent - if the stiffnesses
% don't match then instability can easily occur. If this happens, recheck
% your node numbering.
% Note that a model can send values to itself. This can be useful to
% generate periodic boundary conditions.
%
%
% Function should complain if anything important is missing.
% Report bugs to support@pogo.software
%
% Written by P. Huthwaite, March 2014
% Updated some names, April 2014 - PH
% Updaded to v 1.04 (offset start time) May 2016, PH
% Updated to v 1.05 (measurement sets, fieldStoreNodes, measDof optional) May 2016, PH
% Updated to v 1.06 (including ties), PH
% Updated to v 1.07 (including frames), Aug 2016, PH
% Updated to v 1.08 (including dofGroups), Aug 2017, PH
% Updated to v 1.09 (including parent material), Sept 2017, PH
% Updated to warn if unused fields included for debugging purposes, Oct 2017, PH
% Updated to v 1.10 Nov 2017, PH
% Updated to clarify DOF groups separate from fixing
% Updated v 1.10 (number of fix DOF 64-bit int) Dec 2017, PH
% Updated v 1.11 (add metadata) March 2020, PH
% Updated v 1.12 (add file version numbers) April 2020, PH
% Updated v 1.13 (metadata allows arrays) April 2020, PH
% Updated 'frames' to 'shots', May 2020, PH
% Updated v 1.14 (file format), May 2020, PH
% Updated v 1.15 (incorporate MPI information), June 2020, PH

fn = fieldnames(model);

fn = remFieldName(fn,'fileVer');
fn = remFieldName(fn,'fileMajVer');
fn = remFieldName(fn,'fileMinVer');

if nargin < 3
    fileMajVer = 1;
    fileMinVer = 15;
elseif nargin < 4
    fileMinVer = round(mod(fileMajVer,1)*100);
    fileMajVer = floor(fileMajVer);
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
    fileName = [fileName '.pogo-inp'];
end

fid = fopen(fileName,'wb');
if (fid == -1) 
    error('File %s could not be opened.', fileName)
end

% header = blanks(20);
% if fileMajVer == 1 && fileMinVer == 7
%     header(1:13) = '%pogo-inp1.07';
% elseif fileMajVer == 1 && fileMinVer == 8
%     header(1:13) = '%pogo-inp1.08';
% elseif fileMajVer == 1 && fileMinVer == 9
%     header(1:13) = '%pogo-inp1.09';
% elseif fileMajVer == 1 && fileMinVer == 10
%     header(1:13) = '%pogo-inp1.10';
% elseif fileMajVer == 1 && fileMinVer == 11
%     header(1:13) = '%pogo-inp1.11';
% elseif fileMajVer == 1 && fileMinVer >= 12
%     header(1:9) = '%pogo-inp';
%     header(10) = 0;
% else
%     error('Only v1.07, v1.08, v1.09, v1.10, v1.11, v1.12, v1.13, v1.14 supported, not %d.%d', fileMajVer, fileMinVer);
% end
% fileVerFull = fileMajVer * 1000 + fileMinVer;
% if fileVerFull >= 1007 && fileVerFull <= 1011
%     header(14) = 0;
% end
% fwrite(fid, header, '*char');

fileVerFull = fileMajVer * 1000 + fileMinVer;

if fileMajVer == 1 && fileMinVer == 7
    header = '%pogo-inp1.07';
elseif fileMajVer == 1 && fileMinVer == 8
    header = '%pogo-inp1.08';
elseif fileMajVer == 1 && fileMinVer == 9
    header = '%pogo-inp1.09';
elseif fileMajVer == 1 && fileMinVer == 10
    header = '%pogo-inp1.10';
elseif fileMajVer == 1 && fileMinVer == 11
    header = '%pogo-inp1.11';
elseif fileMajVer == 1 && fileMinVer >= 12
    header = '%pogo-inp';
else
    error('Only v1.07, v1.08, v1.09, v1.10, v1.11, v1.12, v1.13, v1.14 supported, not %d.%d', fileMajVer, fileMinVer);
end
fwrite(fid, stringSaveTidy(header,20), '*char');

if fileVerFull >= 1012
    fwrite(fid, fileMajVer, 'int32');
    fwrite(fid, fileMinVer, 'int32');
end
    

if fileVerFull >= 1011
    %save metadata
    
    if ~isfield(model,'metadata')
        metadataNumValues = 0;
    else 
        metadataNumValues = numel(fieldnames(model.metadata));
        fn = remFieldName(fn,'metadata');
    end
    if metadataNumValues == 0
        metadataSize = 4;
        %save this here...
        if fileVerFull >= 1014
            fwrite(fid, stringSaveTidy('metadata',40), '*char');
            fwrite(fid, 1, 'int32');
            fwrite(fid, metadataSize, 'int64');
            fwrite(fid, metadataNumValues, 'int32');
        else
            fwrite(fid, metadataSize, 'int32');
            fwrite(fid, metadataNumValues, 'int32');
        end
    else
        %fid2 = fopen('temp','wb');
        %disp(metadataNumValues)
        mdNames = fieldnames(model.metadata);
        
        if fileMajVer == 1 && (fileMinVer == 11 || fileMinVer == 12)
            %calculate size of metadata in bytes
            metadatastore = cell(metadataNumValues,2);
            metadatalengths = zeros(metadataNumValues,2);

            for c = 1:metadataNumValues
                metadatastore{c,1} = mdNames{c};
                if (length(getfield(model.metadata,mdNames{c})) ~= 1)
                    warning('Unable to store metadata arrays in file format %d, skipping', fileVerFull)
                    metadataNumValues = metadataNumValues - 1;
                    continue;
                end
                metadatastore{c,2} = string(getfield(model.metadata,mdNames{c}));
                metadatalengths(c,1) = strlength(metadatastore{c,1})+1;
                %disp(metadatastore{c,1})
                metadatalengths(c,2) = strlength(metadatastore{c,2})+1;
                    %+1 for terminating nulls
                %disp(metadatastore{c,2})


            end

            metadataSize = 1*4 + sum(sum(metadatalengths)) + metadataNumValues*2*4;
            %include storage of number of values, terminating nulls, lengths

            %disp(totLen)

            fwrite(fid, metadataSize, 'int32');
            fwrite(fid, metadataNumValues, 'int32');

            for c = 1:metadataNumValues
                fwrite(fid, metadatalengths(c,1),'int32');
                fwrite(fid, metadatalengths(c,2),'int32');

                fwrite(fid, metadatastore{c,1},'char');
                fwrite(fid, 0,'char');
                fwrite(fid, metadatastore{c,2},'char');
                fwrite(fid, 0,'char');
            end
        else
            %get size first
            metadataSize = 4;
            for c = 1:metadataNumValues
                %output name length
                metadataSize = metadataSize + 4+(strlength(mdNames{c})+1);
                                
                d = getfield(model.metadata,mdNames{c});
                datatype = blanks(16);
                if ischar(d)
                    d = string(d);
                end
                if isstring(d)
                    metadataSize = metadataSize + 16;
                    metadataSize = metadataSize + 4;
                    metadataSize = metadataSize + strlength(d)+1;
                elseif isnumeric(d)
                    metadataSize = metadataSize + 16;
                    if isinteger(d)
                        saveLen = 4;
                    else
                        saveLen = 8;
                    end
                    s = size(d);
                    sTot = prod(s);
                    if sTot == 1
                        sTot = 1;
                        s = [];
                    end
                    metadataSize = metadataSize + 4;
                    %fwrite(fid, sTot, 'int32');
                    metadataSize = metadataSize + 4*length(s);
                    %fwrite(fid, s, 'int32');
                    metadataSize = metadataSize + saveLen*sTot;
                end
            end
            
            if fileVerFull >= 1014
                fwrite(fid, stringSaveTidy('metadata',40), '*char');
                fwrite(fid, 1, 'int32');
                fwrite(fid, metadataSize, 'int64');
            else
                fwrite(fid, metadataSize, 'int32');
            end
            %startPos = ftell(fid);
            fwrite(fid, metadataNumValues, 'int32');

            for c = 1:metadataNumValues
                %output name length
                fwrite(fid, strlength(mdNames{c})+1,'int32');
                %output name
                fwrite(fid, mdNames{c},'char');
                fwrite(fid, 0,'char');
                
                d = getfield(model.metadata,mdNames{c});
                datatype = blanks(16);
                if ischar(d)
                    d = string(d);
                end
                if isstring(d)
                    datatype(1:6) = 'string';
                    datatype(7) = 0;
                    %output type
                    fwrite(fid, datatype,'char');
                    
                    datalen = strlength(d)+1;
                    %output name length
                    fwrite(fid, datalen,'int32');
                    %output name
                    fwrite(fid, d,'char');                        
                    fwrite(fid, 0,'char');
                elseif isnumeric(d)
                    if isinteger(d)
                        datatype(1:5) = 'int32';
                        datatype(6) = 0;
                        %output type
                        fwrite(fid, datatype,'char');
                        %fwrite(fid, 0,'char');
                        saveType = 'int32';
                    else
                        %floating point, i.e. double
                        datatype(1:6) = 'double';
                        datatype(7) = 0;
                        %output type
                        fwrite(fid, datatype,'char');
                        %fwrite(fid, 0,'char');
                        saveType = 'double';
                    end
                    s = size(d);
                    sTot = prod(s);
                    if sTot == 1
                        s = [];
                    end
                    fwrite(fid, length(s), 'int32');
                    if ~isempty(s)
                        fwrite(fid, s, 'int32');
                    end
                    fwrite(fid, d, saveType);
                    %fwrite(fid, 2, 'double');
%                     disp(length(s))
%                     disp(s)
%                     disp(d)
                    %disp(saveType)
                else
                    d
                    
                    error('metadata unsupported type')
                end
            end
            %endPos = ftell(fid);
            %disp(endPos - startPos)
            %disp(metadataSize)
        end
    end
end

if fileVerFull >= 1014
    fwrite(fid, stringSaveTidy('generalInfo',40), '*char');
    fwrite(fid, 1, 'int32');
    
    writePos = ftell(fid);
    sectSize = 0;
    fwrite(fid, sectSize, 'int64');
    startPos = ftell(fid);
end

if ~isfield(model,'prec')
    model.prec = 8;
    %disp('model.prec undefined; setting to 8.')
end
fwrite(fid, model.prec, 'int32');
fn = remFieldName(fn,'prec');

precString = 'float32';
if model.prec == 8
    precString = 'float64';
end

maxUint = uint32(uint64(2)^32-1);

if fileMajVer >= 1 && fileMinVer >= 10
    dofSaveString = 'uint64'; 
else
    dofSaveString = 'int32'; 
end

if ~isfield(model,'nDims')
    error('model.nDims field must be set')
end
if model.nDims < 1 || model.nDims > 3 
    error('model.nDims field is set to %d, must be in range 1-3.', model.nDims)
end
fwrite(fid, model.nDims, 'int32');
fn = remFieldName(fn,'nDims');

if ~isfield(model,'nDofPerNode')
    fprintf('model.nDofPerNode not set; setting to %d.\n',model.nDims)
    model.nDofPerNode = model.nDims;
end
if model.nDofPerNode < 1 || model.nDofPerNode > 3 
    error('model.nDofPerNode field is set to %d, must be in range 1-3.', model.nDofPerNode)
end
if model.nDofPerNode ~= 1 && model.nDofPerNode ~= model.nDims
    warning('Mismatch between model.nDofPerNode = %d and model.nDims = %d', model.nDofPerNode, model.nDims)
end
fwrite(fid, model.nDofPerNode, 'int32');
fn = remFieldName(fn,'nDofPerNode');

if ~isfield(model,'notes')
    model.notes = blanks(1024);
end
notesTemp = deblank(model.notes);
l = length(notesTemp);
model.notes = blanks(1024);
model.notes(1:l) = notesTemp;
model.nodes(l+1) = 0;
fwrite(fid, model.notes, '*char');
fn = remFieldName(fn,'notes');

if ~isfield(model,'runName')
    k = strfind(fileName,'.');
    if ~isempty(k)
        model.runName = fileName(1:k-1);
    else
        model.runName = fileName;
    end
    %fprintf('model.runName not set; setting to %s.\n',model.runName)
end
lrn = length(model.runName);
if lrn >= 79
    lrn = 79;
end
runNameWrite = blanks(80);
runNameWrite(1:lrn) = model.runName(1:lrn);
runNameWrite(lrn+1) = 0;
fwrite(fid, runNameWrite, '*char');
fn = remFieldName(fn,'runName');

if ~isfield(model,'nt')
    error('model.nt field must be set')
end
fwrite(fid, model.nt, 'uint32');
fn = remFieldName(fn,'nt');

if ~isfield(model,'dt')
    error('model.dt field must be set')
end
fwrite(fid, model.dt, precString);
fn = remFieldName(fn,'dt');

if fileVerFull >= 1014
    %end of genInfo section
    
    %go back and put the section size in at the beginning
    curPos = ftell(fid);
    sectSize = curPos - startPos;
    fseek(fid, writePos,-1);
    fwrite(fid, sectSize, 'int64');
    fseek(fid, curPos,-1);
end

if fileVerFull >= 1014
    fwrite(fid, stringSaveTidy('nodes',40), '*char');
    fwrite(fid, 1, 'int32');
    
    writePos = ftell(fid);
    sectSize = 0;
    fwrite(fid, sectSize, 'int64');
    startPos = ftell(fid);
end

if ~isfield(model,'nNodes')
    %error('model.nNodes field must be set')
    model.nNodes = size(model.nodePos,2);
end
fwrite(fid, model.nNodes, 'uint32');
fn = remFieldName(fn,'nNodes');

if ~isfield(model,'nodePos')
    error('model.nodePos field must be set')
end
if size(model.nodePos,1) ~= model.nDims || size(model.nodePos,2) ~= model.nNodes
    error('model.nodePos must have size model.nDims x model.nNodes')
end
fwrite(fid, model.nodePos, precString);
fn = remFieldName(fn,'nodePos');

if fileVerFull >= 1014
    %end of nodes section
    %go back and put the section size in at the beginning
    curPos = ftell(fid);
    sectSize = curPos - startPos;
    fseek(fid, writePos,-1);
    fwrite(fid, sectSize, 'int64');
    fseek(fid, curPos,-1);
end

%-----------------------------------------------------

if fileVerFull >= 1014
    fwrite(fid, stringSaveTidy('elements',40), '*char');
    fwrite(fid, 1, 'int32');
    
    writePos = ftell(fid);
    sectSize = 0;
    fwrite(fid, sectSize, 'int64');
    startPos = ftell(fid);
end


%elements:
if ~isfield(model,'elNodes')
    error('model.elNodes field must be set')
end
if ~isfield(model,'nEls')
    %error('model.nEls field must be set')
    model.nEls = size(model.elNodes,2);
end
fwrite(fid, model.nEls, 'uint32');
fn = remFieldName(fn,'nEls');

if ~isfield(model,'nNodesPerEl')
    %error('model.nNodesPerEl field must be set')
    model.nNodesPerEl = size(model.elNodes,1);
end
fwrite(fid, model.nNodesPerEl, 'int32');
fn = remFieldName(fn,'nNodesPerEl');

%-----------------------------------------------------
%element references:
if ~isfield(model,'elTypeRefs')
    error('model.elTypesRefs field must be set')
end
model.elTypeRefs = model.elTypeRefs(:);
if length(model.elTypeRefs) ~= model.nEls
    error('model.elTypeRefs must have length model.nEls')
end
%check it's 1-indexed:
if min(model.elTypeRefs(:)) <= 0
    error('model.elTypeRefs must be 1-indexed')
end
fwrite(fid, model.elTypeRefs-1, 'int32'); %NB change to zero indexing for file
fn = remFieldName(fn,'elTypeRefs');


if ~isfield(model,'matTypeRefs')
    error('model.matTypesRefs field must be set')
end
model.matTypeRefs = model.matTypeRefs(:);
if length(model.matTypeRefs) ~= model.nEls
    error('model.matTypeRefs must have length model.nEls')
end
%check it's 1-indexed:
if min(model.matTypeRefs(:)) <= 0
    error('model.matTypeRefs must be 1-indexed')
end
fwrite(fid, model.matTypeRefs-1, 'int32'); %NB change to zero indexing for file
fn = remFieldName(fn,'matTypeRefs');

if ~isfield(model,'orientRefs')
    model.orientRefs = zeros(model.nEls,1);
    %error('model.orientRefs field must be set')
end
model.orientRefs = model.orientRefs(:);
if length(model.orientRefs) ~= model.nEls
    error('model.orientRefs must have length model.nEls')
end
%check it's 1-indexed:
if min(model.orientRefs(:)) <= -1 %NB unused values are set to 0, or -1 in zero indexing
    error('model.orientRefs must be 1-indexed')
end
fwrite(fid, model.orientRefs-1, 'int32'); %NB change to zero indexing for file
fn = remFieldName(fn,'orientRefs');

%-----------------------------------------------------

if size(model.elNodes,1) ~= model.nNodesPerEl || size(model.elNodes,2) ~= model.nEls
    error('model.elNodes must have size model.nNodesPerEl x model.nEls')
end
%check it's 1-indexed:
if min(model.elNodes(:)) < 0 %NB unused set to 0, or -1 in zero indexing
    error('model.elNodes must be 1-indexed')
end
if max(model.elNodes(:)) > model.nNodes 
    error('model.elNodes points to nodes which are greater than the number of nodes')
end

elNodesWrite = uint32(model.elNodes)-1; %move to zero indexing
elNodesWrite(model.elNodes == 0) = maxUint; %unused values

%fwrite(fid, model.elNodes-1, 'int32'); %NB change to zero indexing for file
fwrite(fid, elNodesWrite, 'uint32');
clear elNodesWrite
fn = remFieldName(fn,'elNodes');

if fileVerFull >= 1014
    %end of nodes section
    %go back and put the section size in at the beginning
    curPos = ftell(fid);
    sectSize = curPos - startPos;
    fseek(fid, writePos,-1);
    fwrite(fid, sectSize, 'int64');
    fseek(fid, curPos,-1);
end

%-----------------------------------------------------

if fileVerFull >= 1014
    fwrite(fid, stringSaveTidy('pml',40), '*char');
    fwrite(fid, 1, 'int32');
    
    writePos = ftell(fid);
    sectSize = 0;
    fwrite(fid, sectSize, 'int64');
    startPos = ftell(fid);
end

if ~isfield(model,'nPmlSets')
    model.nPmlSets = 0;
end
if model.nPmlSets ~= 0
    error('model.nPmlSets > 0, but PMLs unsupported.')
end
fwrite(fid, model.nPmlSets, 'int32');

if ~isfield(model,'nPmlParams')
    model.nPmlParams = 0;
end
if model.nPmlParams ~= 0
    error('model.nPmlParams > 0, but PMLs unsupported.')
end
fwrite(fid, model.nPmlParams, 'int32');

if fileVerFull >= 1014
    %end of pml section
    %go back and put the section size in at the beginning
    curPos = ftell(fid);
    sectSize = curPos - startPos;
    fseek(fid, writePos,-1);
    fwrite(fid, sectSize, 'int64');
    fseek(fid, curPos,-1);
end

%-----------------------------------------------------

if fileVerFull >= 1014
    fwrite(fid, stringSaveTidy('elTypes',40), '*char');
    fwrite(fid, 1, 'int32');
    
    writePos = ftell(fid);
    sectSize = 0;
    fwrite(fid, sectSize, 'int64');
    startPos = ftell(fid);
end

if ~isfield(model,'elTypes')
    error('model.elTypes is not defined.')
end
model.nElTypes = length(model.elTypes);
if max(model.elTypeRefs(:)) > model.nElTypes
    error('Range error on model.elTypeRefs, greater than length(model.elTypes)')
end
fwrite(fid, model.nElTypes, 'int32');
fn = remFieldName(fn,'nElTypes');
fn = remFieldName(fn,'elTypes');
for eCnt = 1:model.nElTypes
    if ~isfield(model.elTypes{eCnt},'name')
        error('model.elTypes{%d}.name is not defined.',eCnt)
    end
    
    elType = model.elTypes{eCnt}.name;
    
    %processing in case it's a messed up string!
    nullTerm = find(elType == 0,1);
    if ~isempty(nullTerm)
        elType(nullTerm:end) = 0;
    end
    elType(~isstrprop(elType,'alphanum')) = '';
    elType = deblank(elType);
    
    l = length(elType);
    
    %disp(elType);
    %disp(l);
    
    elTypeSave = blanks(20);
    elTypeSave(1:l) = elType;
    elTypeSave(l+1) = 0;
    fwrite(fid, elTypeSave, '*char');
    if ~isfield(model.elTypes{eCnt},'paramsType')
        %warning('model.elTypes{%d}.paramsType is not defined.\nSetting to 0.',eCnt)
        model.elTypes{eCnt}.paramsType = 0;
    end
    fwrite(fid, model.elTypes{eCnt}.paramsType, 'int32');
    
    if ~isfield(model.elTypes{eCnt},'paramValues')
        %error('model.elTypes{%d}.paramValues is not defined.',eCnt)
        model.elTypes{eCnt}.nParams = 0;
        fwrite(fid, model.elTypes{eCnt}.nParams, 'int32');
    else
        model.elTypes{eCnt}.paramValues = model.elTypes{eCnt}.paramValues(:);
        model.elTypes{eCnt}.nParams = length(model.elTypes{eCnt}.paramValues);
        fwrite(fid, model.elTypes{eCnt}.nParams, 'int32');
        fwrite(fid, model.elTypes{eCnt}.paramValues, precString);
    end    
end

if fileVerFull >= 1014
    %end of elTypes section
    %go back and put the section size in at the beginning
    curPos = ftell(fid);
    sectSize = curPos - startPos;
    fseek(fid, writePos,-1);
    fwrite(fid, sectSize, 'int64');
    fseek(fid, curPos,-1);
end

%-----------------------------------------------------

if fileVerFull >= 1014
    fwrite(fid, stringSaveTidy('matTypes',40), '*char');
    fwrite(fid, 1, 'int32');
    
    writePos = ftell(fid);
    sectSize = 0;
    fwrite(fid, sectSize, 'int64');
    startPos = ftell(fid);
end


if ~isfield(model,'matTypes')
    error('model.matTypes is not defined.')
end
model.nMatTypes = length(model.matTypes);
if max(model.matTypeRefs(:)) > model.nMatTypes
    error('Range error on model.matTypeRefs, greater than length(model.matTypes)')
end
fwrite(fid, model.nMatTypes, 'int32');
fn = remFieldName(fn,'nMatTypes');
fn = remFieldName(fn,'matTypes');
for eCnt = 1:model.nMatTypes
	if fileMajVer >= 1 && fileMinVer >= 9
		% model.matTypes{n}.parent
		if ~isfield(model.matTypes{eCnt},'parent')
			fwrite(fid, -1, 'int32');		
		else
			fwrite(fid, model.matTypes{eCnt}.parent-1, 'int32');
		end
	end
    
    if ~isfield(model.matTypes{eCnt},'paramsType')
        %warning('model.matTypes{%d}.paramsType is not defined.\nSetting to 0.',eCnt)
        model.matTypes{eCnt}.paramsType = 0;
    end
    fwrite(fid, model.matTypes{eCnt}.paramsType, 'int32');
    
    if ~isfield(model.matTypes{eCnt},'paramValues')
        error('model.matTypes{%d}.paramValues is not defined.',eCnt)
    end
    model.matTypes{eCnt}.paramValues = model.matTypes{eCnt}.paramValues(:);
    nMatParams = length(model.matTypes{eCnt}.paramValues);
    fwrite(fid, nMatParams, 'int32');
    fwrite(fid, model.matTypes{eCnt}.paramValues, precString);
end

if fileVerFull >= 1014
    %end of matTypes section
    %go back and put the section size in at the beginning
    curPos = ftell(fid);
    sectSize = curPos - startPos;
    fseek(fid, writePos,-1);
    fwrite(fid, sectSize, 'int64');
    fseek(fid, curPos,-1);
end

%-----------------------------------------------------

if fileVerFull >= 1014
    fwrite(fid, stringSaveTidy('orientations',40), '*char');
    fwrite(fid, 1, 'int32');
    
    writePos = ftell(fid);
    sectSize = 0;
    fwrite(fid, sectSize, 'int64');
    startPos = ftell(fid);
end

if ~isfield(model,'or')
    %error('model.or is not defined.')
    model.nOr = 0;
else
    model.nOr = length(model.or);
end
fwrite(fid, model.nOr, 'int32');
fn = remFieldName(fn,'nOr');
if model.nOr > 0
    if max(model.orientRefs(:)) > model.nOr
        error('Range error on model.orientRefs, greater than length(model.or)')
    end
else
    if max(model.orientRefs(:)) ~= 0 || min(model.orientRefs(:)) ~= 0
        error('model.or undefined, so orientRefs should all be 0')
    end
end

for eCnt = 1:model.nOr
    
    if ~isfield(model.or{eCnt},'paramsType')
        error('model.or{%d}.paramsType is not defined.',eCnt)
    end
    fwrite(fid, model.or{eCnt}.paramsType, 'int32');
    
    if ~isfield(model.or{eCnt},'paramValues')
        error('model.or{%d}.paramValues is not defined.',eCnt)
    end
    model.or{eCnt}.paramValues = model.or{eCnt}.paramValues(:);
    nOrParams = length(model.or{eCnt}.paramValues);
    fwrite(fid, nOrParams, 'int32');
    fwrite(fid, model.or{eCnt}.paramValues, precString);
end
fn = remFieldName(fn,'or');

if fileVerFull >= 1014
    %end of orientations section
    %go back and put the section size in at the beginning
    curPos = ftell(fid);
    sectSize = curPos - startPos;
    fseek(fid, writePos,-1);
    fwrite(fid, sectSize, 'int64');
    fseek(fid, curPos,-1);
end

%-----------------------------------------------------

if fileVerFull >= 1014
    fwrite(fid, stringSaveTidy('fixDof',40), '*char');
    fwrite(fid, 1, 'int32');
    
    writePos = ftell(fid);
    sectSize = 0;
    fwrite(fid, sectSize, 'int64');
    startPos = ftell(fid);
end

if ~isfield(model,'fixNodes') 
    model.nFixDof = 0;
    if fileMajVer >= 1 && fileMinVer >= 10
        fwrite(fid, model.nFixDof, 'uint64');
    else
        fwrite(fid, model.nFixDof, 'uint32');
    end
else
    if ~isfield(model,'fixDof')
        error('model.fixNodes defined but model.fixDof not.')
    end
    model.fixNodes = model.fixNodes(:);
    model.fixDof = model.fixDof(:);
    model.nFixDof = length(model.fixNodes);
    if model.nFixDof ~= length(model.fixDof)
        error('model.fixNodes and model.fixDof have different lengths.')
    end
    if fileMajVer >= 1 && fileMinVer >= 10
        fwrite(fid, model.nFixDof, 'uint64');
    else
        fwrite(fid, model.nFixDof, 'uint32');
    end
    if fileMajVer >= 1 && fileMinVer >= 10
        n = uint64(model.fixNodes);
        d = uint64(model.fixDof);
    else
        n = uint32(model.fixNodes);
        d = uint32(model.fixDof);
    end
    
    if max(n(:)) > model.nNodes || min(n(:)) <= 0
        error('Range error on model.fixNodes. Should be 1 indexed node values')
    end
    if max(d(:)) > model.nDofPerNode || min(d(:)) <= 0
        error('Range error on model.fixDof. Should be 1 indexed DOF values')
    end
    model.fixDofD = (n(:)-1) * 4 + d(:)-1;
    
    fwrite(fid, model.fixDofD, dofSaveString); 
end
fn = remFieldName(fn,'fixDof');
fn = remFieldName(fn,'nFixDof');
fn = remFieldName(fn,'nFixNodes');
fn = remFieldName(fn,'fixNodes');


if fileVerFull >= 1014
    %end of fixDof section
    %go back and put the section size in at the beginning
    curPos = ftell(fid);
    sectSize = curPos - startPos;
    fseek(fid, writePos,-1);
    fwrite(fid, sectSize, 'int64');
    fseek(fid, curPos,-1);
end

%-----------------------------------------------------

if fileVerFull >= 1014
    fwrite(fid, stringSaveTidy('ties',40), '*char');
    fwrite(fid, 1, 'int32');
    
    writePos = ftell(fid);
    sectSize = 0;
    fwrite(fid, sectSize, 'int64');
    startPos = ftell(fid);
end

if isfield(model,'ties')
%if fileVer >= 1.06
    nTieSets = length(model.ties);
    fwrite(fid, nTieSets, 'int32');
        
    for tCnt = 1:nTieSets
        if ~isfield(model.ties{tCnt},'tieTransform')
            error('Missing tie transform information for tie set %d',tCnt)
        end
        fwrite(fid,model.ties{tCnt}.tieTransform,precString);
        
        if ~isfield(model.ties{tCnt},'masterNodes') || ~isfield(model.ties{tCnt},'slaveNodes')
            error('Missing master nodes or slave nodes definition for tie set %d',tCnt)
        end
        %model.ties{tCnt}.tieTransform = fread(fid,[model.nDofPerNode, model.nDofPerNode],precString);
        nTies = length(model.ties{tCnt}.masterNodes);
        nTies2 = length(model.ties{tCnt}.slaveNodes);
        if nTies ~= nTies2
            error('Master and slave node vectors should be the same length for tie set %d',tCnt)
        end
        fwrite(fid, nTies, 'int32');
        
        fwrite(fid,model.ties{tCnt}.masterNodes,'uint32');
        fwrite(fid,model.ties{tCnt}.slaveNodes,'uint32');
    end
else
    nTieSets = 0;
    fwrite(fid, nTieSets, 'int32');
end
fn = remFieldName(fn,'ties');

if fileVerFull >= 1014
    %end of ties section
    %go back and put the section size in at the beginning
    curPos = ftell(fid);
    sectSize = curPos - startPos;
    fseek(fid, writePos,-1);
    fwrite(fid, sectSize, 'int64');
    fseek(fid, curPos,-1);
end

%-----------------------------------------------------

if fileVerFull >= 1014
    fwrite(fid, stringSaveTidy('dofGroups',40), '*char');
    fwrite(fid, 1, 'int32');
    
    writePos = ftell(fid);
    sectSize = 0;
    fwrite(fid, sectSize, 'int64');
    startPos = ftell(fid);
end

if fileMajVer >= 1 && fileMinVer >= 8
    if ~isfield(model,'dofGroups') 
        fwrite(fid, 0, 'int32');
    else
        nDofGroups = length(model.dofGroups);
        fwrite(fid, nDofGroups, 'int32');
        for dCnt = 1:nDofGroups
            nDof = length(model.dofGroups{dCnt}.dofWeight(:));
            fwrite(fid, nDof, 'int32');
            if ~isequal(size(model.dofGroups{dCnt}.dofSpec), size(model.dofGroups{dCnt}.nodeSpec))
                size(model.dofGroups{dCnt}.dofSpec)
                size(model.dofGroups{dCnt}.nodeSpec)
                error('dofGroups{%d} .dofSpec and .nodeSpec have mismatching sizes ', dCnt)
            end
            if fileMajVer >= 1 && fileMinVer >= 10
                dofSpec = uint64(model.dofGroups{dCnt}.dofSpec(:))-1 + (uint64(model.dofGroups{dCnt}.nodeSpec(:))-1)*4;
            else
                dofSpec = model.dofGroups{dCnt}.dofSpec(:)-1 + (model.dofGroups{dCnt}.nodeSpec(:)-1)*4;
            end
            fwrite(fid, dofSpec, dofSaveString);
            fwrite(fid, model.dofGroups{dCnt}.dofWeight(:), precString);
        end
    end
    fn = remFieldName(fn,'dofGroups');
end

if fileVerFull >= 1014
    %end of nodes section
    %go back and put the section size in at the beginning
    curPos = ftell(fid);
    sectSize = curPos - startPos;
    fseek(fid, writePos,-1);
    fwrite(fid, sectSize, 'int64');
    fseek(fid, curPos,-1);
end

%-----------------------------------------------------

if fileVerFull >= 1014
    fwrite(fid, stringSaveTidy('signals',40), '*char');
    fwrite(fid, 1, 'int32');
    
    writePos = ftell(fid);
    sectSize = 0;
    fwrite(fid, sectSize, 'int64');
    startPos = ftell(fid);
end

if isfield(model,'frames')
    warning('Your input model refers to frames - this is deprecated so you should change any references to shots instead, which have the same functionality. Frames will stop being supported completely in a future version.')
    if isfield(model,'shots')
        error('Both shots and frames found in a single model. Shots is the new name. Switch everything to this.')
    end
    model.shots = model.frames;
    fn = remFieldName(fn,'frames');
end

if ~isfield(model,'shots')
    %old format. Copy to new.
    model.shots = cell(1);
    model.shots{1}.sigs = model.sigs;
    %model.shots{1}.nSigs = model.nSigs;
    model.shots{1}.ntSig = model.ntSig;
    model.shots{1}.dtSig = model.dtSig;
    fn = remFieldName(fn,'nSigs');
    fn = remFieldName(fn,'sigs');
    fn = remFieldName(fn,'ntSig');
    fn = remFieldName(fn,'dtSig');
end



nShots = length(model.shots);
fwrite(fid, nShots, 'int32');

fn = remFieldName(fn,'shots');

for fCnt = 1:nShots
    f = model.shots{fCnt};
   
    if ~isfield(f,'sigs') 
        error('model.shots{%d}.sigs is not defined',fCnt)
    end
    nSigs = length(f.sigs);
    fwrite(fid, nSigs, 'int32');

    if ~isfield(f,'ntSig') 
        f.ntSig = model.nt;
        warning('model.shots{%d}.ntSig is not defined - setting to model.nt',fCnt)
    end
    fwrite(fid, f.ntSig, 'int32');

    if ~isfield(f,'dtSig') 
        f.dtSig = model.dt;
        warning('model.shots{%d}.dtSig is not defined - setting to model.dt',fCnt)
    end
    fwrite(fid, f.dtSig, precString);

    for sCnt = 1:nSigs
        s = f.sigs{sCnt};
        if fileMajVer >= 1 && fileMinVer >= 8
            if ~isfield(s,'isDofGroup') 
                isDofGroup = 0;
            else
                isDofGroup = s.isDofGroup;
            end
        else
            if ~isfield(s,'isDofGroup') 
                isDofGroup = 0;
            elseif s.isDofGroup == 0
                isDofGroup = 0;
            else
                error('Cannot refer to DofGroups using v1.07');
            end
        end
        
        if isDofGroup
            if ~isfield(s,'dofGroup') 
                error('model.shots{%d}.sigs{%d}.dofGroup is not defined',fCnt,sCnt)
            end
            s.dofGroup = s.dofGroup(:);  
            l = length(s.dofGroup);
        else
            if ~isfield(s,'nodeSpec') 
                error('model.shots{%d}.sigs{%d}.nodeSpec is not defined',fCnt,sCnt)
            end
            if ~isfield(s,'dofSpec') 
                error('model.shots{%d}.sigs{%d}.dofSpec is not defined',fCnt,sCnt)
            end
            s.nodeSpec = s.nodeSpec(:);
            s.dofSpec = s.dofSpec(:);
            l = length(s.nodeSpec);
            if l ~= length(s.dofSpec) 
                error('model.shots{%d}.sigs{%d}.dofSpec must be the same length as model.shots{%d}.sigs{%d}.nodeSpec',fCnt,sCnt,fCnt,sCnt)
            end
        end
        if ~isfield(s,'sigAmps') 
            error('model.shots{%d}.sigs{%d}.sigAmps is not defined',fCnt,sCnt)
        end
        
        s.sigAmps = s.sigAmps(:);
        
        %check for duplicates
        if (fileMajVer >= 1 && fileMinVer >= 8)  && isDofGroup == 0
            hash = s.nodeSpec + s.dofSpec/10;
            anyRepeated = length(hash) - length(unique(hash));
            if anyRepeated
                %hash
                error('%d duplicate dof-node pairs found in model.shots{%d}.sigs{%d}.nodeSpec and model.shots{%d}.sigs{%d}.dofSpec',anyRepeated,fCnt,sCnt, fCnt,sCnt)
            end
        end

        fwrite(fid, l, 'int32');

        if ~isfield(s,'sigType') 
            error('model.shots{%d}.sigs{%d}.sigType is not defined',fCnt,sCnt)
        end
        if s.sigType > 2 || s.sigType < 0
            error('model.shots{%d}.sigs{%d}.sigType has wrong value',fCnt,sCnt)
        end
        fwrite(fid, s.sigType, 'int32');
        
        if fileMajVer >= 1 && fileMinVer >= 8
            fwrite(fid, isDofGroup, 'int8');
        end

        if isDofGroup == 0
            if max(s.nodeSpec) > model.nNodes || min(s.nodeSpec) < 1
                error('Range error on model.shots{%d}.sigs{%d}.nodeSpec',fCnt,sCnt)
            end
            if max(s.dofSpec) > model.nDofPerNode || min(s.dofSpec) < 1
                error('Range error on model.shots{%d}.sigs{%d}.dofSpec',fCnt,sCnt)
            end
        
            if fileMajVer >= 1 && fileMinVer >= 10
                dofSpec = (uint64(s.nodeSpec(:)) - 1)*4 + (uint64(s.dofSpec(:)) - 1);
            else
                dofSpec = (s.nodeSpec(:) - 1)*4 + (s.dofSpec(:) - 1);
            end
        else
            dofSpec = s.dofGroup(:)-1;
        end
        fwrite(fid, dofSpec, dofSaveString);

        if length(s.sigAmps) ~= l
            error('model.shots{%d}.sigs{%d}.dofSpec must be the same length as model.shots{%d}.sigs{%d}.sigAmps',fCnt,sCnt,fCnt,sCnt)
        end
        fwrite(fid, s.sigAmps, precString);

        if length(s.sig) ~= f.ntSig
            error('model.shots{%d}.sigs{%d}.sig must be the same length as given by model.shots{%d}.ntSigs',fCnt,sCnt,fCnt)
        end
        if length(s.sig(:)) ~= f.ntSig
            error('model.shots{%d}.sigs{%d}.sig must by a vector.',fCnt,sCnt)
        end
        fwrite(fid, s.sig, precString);

    end
end

if fileVerFull >= 1014
    %end of signals section
    %go back and put the section size in at the beginning
    curPos = ftell(fid);
    sectSize = curPos - startPos;
    fseek(fid, writePos,-1);
    fwrite(fid, sectSize, 'int64');
    fseek(fid, curPos,-1);
end

%-----------------------------------------------------

if fileVerFull >= 1014
    fwrite(fid, stringSaveTidy('measurements',40), '*char');
    fwrite(fid, 1, 'int32');
    
    writePos = ftell(fid);
    sectSize = 0;
    fwrite(fid, sectSize, 'int64');
    startPos = ftell(fid);
end

if isfield(model,'measSets') 
    
else
    if ~isfield(model,'measNodes')
        %error('model.measNodes is not defined')
        if isfield(model,'measDof') 
            error('model.measDof is defined but model.measNodes is not')
        end
        model.measSets = cell(0);
    else 
    
        %just for backward compatibility
        model.measSets = cell(1);
        model.measSets{1}.name = 'main';

        if ~isfield(model,'measDof') 
            error('model.measDof is not defined')
        end

        model.measSets{1}.measNodes = model.measNodes(:);
        if isfield(model,'measDof') 
            model.measSets{1}.measDof = model.measDof(:);
        end

        fn = remFieldName(fn,'measNodes');
        fn = remFieldName(fn,'measDof');
    end
end

nMeasSets = length(model.measSets);

fwrite(fid, nMeasSets, 'int32');
fn = remFieldName(fn,'measSets');
    
if nMeasSets == 0
    warning('No history data output requested')
    model.measFreq = 1;
end

if ~isfield(model,'measFreq') 
    error('model.measFreq is not defined')
end
fwrite(fid, model.measFreq, 'int32');
fn = remFieldName(fn,'measFreq');

if ~isfield(model,'measStart') 
    model.measStart = 1;
%    warning('measStart undefined; setting to 1')
end
fwrite(fid, model.measStart-1, 'int32');
fn = remFieldName(fn,'measStart');

for mSetCnt = 1:nMeasSets
    %write out each node set
    strSave = blanks(20);
    if ~isfield(model.measSets{mSetCnt},'name')
        model.measSets{mSetCnt}.name = 'main';
    end
    
    lStr = length(deblank(model.measSets{mSetCnt}.name));
    if lStr + 1 > 20
        error('model.measSets{mSetCnt}.name has more than the max of 19 characters')
    end
    strSave(1:lStr) = deblank(model.measSets{mSetCnt}.name);
    strSave(lStr+1) = 0;

    fwrite(fid, strSave, '*char');
    
    if fileMajVer >= 1 && fileMinVer >= 8
        if isfield(model.measSets{mSetCnt},'isDofGroup')
            isDofGroup = model.measSets{mSetCnt}.isDofGroup;
        else
            isDofGroup = 0;
        end
    else
        if isfield(model.measSets{mSetCnt},'isDofGroup') && model.measSets{mSetCnt}.isDofGroup ~= 0
            error('Cannot save dofGroup references in version 1.07 or earlier')
        else
            isDofGroup = 0;
        end
    end
    
    
    if isDofGroup == 0
        model.measSets{mSetCnt}.measNodes = round(model.measSets{mSetCnt}.measNodes(:));
        nMeas = length(model.measSets{mSetCnt}.measNodes);
        if ~isfield(model.measSets{mSetCnt},'measDof')  

            %add a measDof term
            if model.nDofPerNode == 3
                model.measSets{mSetCnt}.measDof = [ones(nMeas,1) 2*ones(nMeas,1) 3*ones(nMeas,1)].';
            else
                model.measSets{mSetCnt}.measDof = [ones(nMeas,1) 2*ones(nMeas,1)].';
            end
            %and replicate original
            model.measSets{mSetCnt}.measNodes = repmat(model.measSets{mSetCnt}.measNodes(:).',[model.nDofPerNode,1]);
            model.measSets{mSetCnt}.measNodes = model.measSets{mSetCnt}.measNodes(:);
            nMeas = length(model.measSets{mSetCnt}.measNodes);
        end
        model.measSets{mSetCnt}.measDof = round(model.measSets{mSetCnt}.measDof(:));
        if nMeas ~= length(model.measSets{mSetCnt}.measDof)
            error('model.measSets{mSetCnt}.measDof and model.measSets{mSetCnt}.measNodes have different lengths')
        end

        hash = model.measSets{mSetCnt}.measNodes + model.measSets{mSetCnt}.measDof/10;
        anyRepeated = length(hash) - length(unique(hash));
        if anyRepeated
            error('%d duplicate dof-node pairs found in model.measSets{mSetCnt}.measNodes and model.measSets{mSetCnt}.measDof', anyRepeated)
        end

        fwrite(fid, nMeas, 'int32');
        if fileMajVer >= 1 && fileMinVer >= 8
            fwrite(fid, isDofGroup, 'int8');
        end


        if nMeas > 0
            if max(model.measSets{mSetCnt}.measNodes(:)) > model.nNodes || min(model.measSets{mSetCnt}.measNodes(:)) < 1
                error('Range error on model.measSets{mSetCnt}.measNodes.')
            end
            if max(model.measSets{mSetCnt}.measDof(:)) > model.nDofPerNode || min(model.measSets{mSetCnt}.measDof(:)) < 1
                error('Range error on model.measDof.')
            end

            if fileMajVer >= 1 && fileMinVer >= 10
                measDof = (uint64(model.measSets{mSetCnt}.measNodes(:))-1)*4 + (uint64(model.measSets{mSetCnt}.measDof(:))-1);
            else
                measDof = (model.measSets{mSetCnt}.measNodes(:)-1)*4 + (model.measSets{mSetCnt}.measDof(:)-1);
            end
            
            fwrite(fid, measDof, dofSaveString);
        end
    else
        if max(model.measSets{mSetCnt}.dofGroup) > nDofGroups
            error('Range error on model.measSets{%d}.measNodes. Larger than nDofGroups (%d).',mSetCnt,nDofGroups)
        end
        nMeas = length(model.measSets{mSetCnt}.dofGroup);
        fwrite(fid, nMeas, 'int32');
        fwrite(fid, isDofGroup, 'int8');
        if nMeas > 0
            fwrite(fid, model.measSets{mSetCnt}.dofGroup-1, dofSaveString);
        end
    end
end

if fileVerFull >= 1014
    %end of measurement section
    %go back and put the section size in at the beginning
    curPos = ftell(fid);
    sectSize = curPos - startPos;
    fseek(fid, writePos,-1);
    fwrite(fid, sectSize, 'int64');
    fseek(fid, curPos,-1);
end

%-----------------------------------------------------

if fileVerFull >= 1014
    fwrite(fid, stringSaveTidy('fieldStores',40), '*char');
    fwrite(fid, 1, 'int32');
    
    writePos = ftell(fid);
    sectSize = 0;
    fwrite(fid, sectSize, 'int64');
    startPos = ftell(fid);
end

if ~isfield(model,'fieldStoreIncs') 
    nFieldStores = 0;
    fwrite(fid, nFieldStores, 'int32');
else
    nFieldStores = length(model.fieldStoreIncs);
    fwrite(fid, nFieldStores, 'int32');
    if nFieldStores > 0
        if max(model.fieldStoreIncs) > model.nt || min(model.fieldStoreIncs) < 1
            error('Range error on model.fieldStoreIncs')
        end
        fwrite(fid, model.fieldStoreIncs-1, 'int32');
    end
    fn = remFieldName(fn,'fieldStoreIncs');
end
if nFieldStores == 0
    warning('No field data output requested')
end

if ~isfield(model,'fieldStoreNodes')
    nFieldStoreNodes = maxUint;
else
    nFieldStoreNodes = length(model.fieldStoreNodes(:));
    fn = remFieldName(fn,'fieldStoreNodes');
end

fwrite(fid, nFieldStoreNodes, 'uint32');
if nFieldStoreNodes ~= maxUint
    fwrite(fid, model.fieldStoreNodes(:)-1, 'uint32');
end

if fileVerFull >= 1014
    %end of fieldStores section
    %go back and put the section size in at the beginning
    curPos = ftell(fid);
    sectSize = curPos - startPos;
    fseek(fid, writePos,-1);
    fwrite(fid, sectSize, 'int64');
    fseek(fid, curPos,-1);
end

%-----------------------------------------------------
if fileVerFull >= 1015
    fwrite(fid, stringSaveTidy('mpi',40), '*char');
    fwrite(fid, 1, 'int32');
    
    writePos = ftell(fid);
    sectSize = 0;
    fwrite(fid, sectSize, 'int64');
    startPos = ftell(fid);
    
    if ~isfield(model,'mpi')
        fwrite(fid, 0, 'uint32');
        fwrite(fid, 0, 'uint32');
    else
        
        nMpiDiv = length(model.mpi);
        fwrite(fid, nMpiDiv, 'uint32');

        fwrite(fid, model.mpiDivNum - 1, 'uint32'); %NB zero indexed

        for cnt = 1:nMpiDiv
            if isempty(model.mpi{cnt})
                nMpiNodes = 0;
                fwrite(fid, nMpiNodes, 'uint32');
                fwrite(fid, nMpiNodes, 'uint32');
            else
                nMpiNodes = length(model.mpi{cnt}.outNodes);
                fwrite(fid, nMpiNodes, 'uint32');
                fwrite(fid, model.mpi{cnt}.outNodes-1, 'uint32');
                nMpiNodes = length(model.mpi{cnt}.inNodes);
                fwrite(fid, nMpiNodes, 'uint32');
                fwrite(fid, model.mpi{cnt}.inNodes-1, 'uint32');
            end
        end
        fn = remFieldName(fn,'mpi');
        fn = remFieldName(fn,'mpiDivNum');
    end
    
    %end of mpi section
    %go back and put the section size in at the beginning
    curPos = ftell(fid);
    sectSize = curPos - startPos;
    fseek(fid, writePos,-1);
    fwrite(fid, sectSize, 'int64');
    fseek(fid, curPos,-1);
end
%-----------------------------------------------------



fclose(fid);

if ~isempty(fn)
    warning('Not all fields used in saving. Unused are listed below:')
    for c = 1:length(fn)
        disp(fn{c})
    end
end
end

%-----------------------------------------------------
%-----------------------------------------------------

function [fn] = remFieldName(fn,name)
    for c = 1:length(fn)
        if strcmp(fn{c}, name)
            fn(c,:) = [];
            break
        end
    end
end
