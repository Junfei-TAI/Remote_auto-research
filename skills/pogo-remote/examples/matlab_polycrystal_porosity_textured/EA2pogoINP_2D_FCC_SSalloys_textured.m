% EA2pogoINP_2D_FCC_SSalloys_textured.m
% Cleaned reference version for Paradigm 2:
% textured polycrystal / porosity-rich / inclusion-rich modeling.
%
% Important:
% - This is a reference workflow, not a guaranteed turnkey script.
% - It uses the corrected anisotropic POGO material packing via
%   material_packing_reference.m.
% - Cij ordering here is not the same as Bunge-convention indexing.
% - Some orientation-rotation helpers may need to be supplied by the user.

clear;
close all;
clc;
set(0, 'DefaultFigureVisible', 'off');

script_dir = fileparts(mfilename('fullpath'));
toolbox_dir = fullfile(script_dir, '..', 'matlab_multilayer_composite', 'toolbox');
addpath(script_dir);
if exist(toolbox_dir, 'dir')
    addpath(toolbox_dir);
end

input_dir = fullfile(script_dir, 'input_texture_data');
output_dir = fullfile(script_dir, 'output_pogo_inp');
pore_map_file = fullfile(script_dir, 'input_texture_data', 'porosity_map.mat');

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

filesX = dir(fullfile(input_dir, '0SigX*.txt'));
if isempty(filesX)
    error(['No orientation files matching 0SigX*.txt were found in: ', input_dir, ...
           '. Populate input_texture_data/ or adapt the input pattern.']);
end

if ~exist('savePogoInp', 'file')
    error('savePogoInp.m is not on the path. Ensure the bundled toolbox is available.');
end
if ~exist('material_packing_reference', 'file')
    error('material_packing_reference.m is required but missing from the path.');
end

for ind = 1:length(filesX)
    model = struct();
    model.grain_Orientations = dlmread(fullfile(input_dir, filesX(ind).name))';
    PogoFilename = [filesX(ind).name(1:end-4) '_10MHz'];
    disp(filesX(ind).name(1:end-4));

    %% Stimulation signal
    frequency = 10000; % kHz
    cycles = 5;
    timedelay = 0;
    timestep = 2e-10;
    endtime = 3e-6;
    phase = 0;
    sig_file = ['tb_',num2str(frequency),'kHz_',num2str(cycles),'cyc_',num2str(timestep),'_',num2str(endtime),'.dat'];
    tb_signal = tbgeneration(frequency, cycles, timedelay, timestep, endtime, phase, sig_file);

    %% Structured outer domain
    X_mesh = 10e-6;
    Y_mesh = 10e-6;
    X_sample = 5e-3;
    Y_sample = 10e-3;
    X_cubic = X_sample;
    Y_cubic = Y_sample;
    X_nodePos = 0:X_mesh:X_cubic;
    Y_nodePos = 0:Y_mesh:Y_cubic;

    for y = 1:length(Y_nodePos)
        for x = 1:length(X_nodePos)
            idx = x + (y-1)*length(X_nodePos);
            model.nodePos(1,idx) = X_nodePos(x); %#ok<SAGROW>
            model.nodePos(2,idx) = Y_nodePos(y); %#ok<SAGROW>
        end
    end

    for y = 1:length(Y_nodePos)-1
        for x = 1:length(X_nodePos)-1
            idx = x + (y-1)*(length(X_nodePos)-1);
            model.elNodes(1,idx) = x + (y-1)*length(X_nodePos); %#ok<SAGROW>
            model.elNodes(2,idx) = x + (y-1)*length(X_nodePos) + 1; %#ok<SAGROW>
            model.elNodes(4,idx) = x + y*length(X_nodePos); %#ok<SAGROW>
            model.elNodes(3,idx) = x + y*length(X_nodePos) + 1; %#ok<SAGROW>
        end
    end

    model.elTypes{1}.name = 'CPE4R';
    model.elTypes{1}.paramsType = 0;
    model.nDims = 2;
    model.nDofPerNode = 2;
    model.elTypeRefs = ones(length(model.elNodes(1,:)),1);

    %% Optional porosity-map preview
    if exist(pore_map_file, 'file')
        data = load(pore_map_file);
        fieldNames = fieldnames(data);
        original_array = data.(fieldNames{1});
        downsampled_array = original_array(1:10:end, 1:10:end);
        downsampled_array = abs(downsampled_array - max(max(downsampled_array))) + 1;
        figure;
        imagesc(downsampled_array');
        colormap('jet');
        colorbar;
        title('Downsampled porosity/map preview');
        axis image;
        set(gca, 'YDir', 'normal');
        saveas(gcf, fullfile(output_dir, [PogoFilename '_porosity_preview.png']));
        close(gcf);
    end

    %% Element centers
    model.matTypeRefs = ones(length(model.elNodes(1,:)),1);
    center = ones(2,length(model.elNodes(1,:)));
    for i = 1:length(model.elNodes(1,:))
        center(1,i) = mean(model.nodePos(1,model.elNodes(:,i)));
        center(2,i) = mean(model.nodePos(2,model.elNodes(:,i)));
    end

    X_lim_low = (X_cubic-X_sample)/2;
    X_lim_up = X_lim_low + X_sample;
    Y_lim_low = (Y_cubic-Y_sample)/2;
    Y_lim_up = Y_lim_low + Y_sample;

    ele_index = find((center(1,:)>=X_lim_low) & ...
                     (center(1,:)<=X_lim_up) & ...
                     (center(2,:)>=Y_lim_low) & ...
                     (center(2,:)<=Y_lim_up));

    for i = 1:length(ele_index)
        model.matTypeRefs(ele_index(i),1) = i;
    end

    %% Settings except for material
    model.prec = 8;
    model.runName = 'Job';
    model.nt = round(endtime/timestep);
    model.dt = timestep;

    %% Generator
    model.shots{1,1}.ntSig = length(tb_signal);
    model.shots{1,1}.dtSig = tb_signal(2,1) - tb_signal(1,1);
    Y_pos = Y_cubic;
    X_lim_up = X_cubic + X_mesh/2;
    X_lim_low = -X_mesh/2;
    Y_lim_up = Y_pos + Y_mesh/2;
    Y_lim_low = Y_pos - Y_mesh/2;

    node_index_generator = find((model.nodePos(1,:)>=X_lim_low) & ...
                                (model.nodePos(1,:)<=X_lim_up) & ...
                                (model.nodePos(2,:)>=Y_lim_low) & ...
                                (model.nodePos(2,:)<=Y_lim_up));

    model.shots{1,1}.sigs{1,1}.sigType = 0;
    model.shots{1,1}.sigs{1,1}.isDofGroup = 0;
    model.shots{1,1}.sigs{1,1}.dofSpec = ones(length(node_index_generator),1)*2;
    model.shots{1,1}.sigs{1,1}.nodeSpec = node_index_generator';
    model.shots{1,1}.sigs{1,1}.sigAmps = ones(length(node_index_generator),1)*1e-13;
    model.shots{1,1}.sigs{1,1}.sig = tb_signal(:,2);

    %% Boundary
    left_nodes = find(abs(model.nodePos(1,:)-0) <= X_mesh/2);
    right_nodes = find(abs(model.nodePos(1,:)-X_cubic) <= X_mesh/2);
    model.fixNodes = [left_nodes right_nodes];
    model.fixDof = ones(length(model.fixNodes),1);

    %% Receiver
    X_lim_low = (X_cubic-X_sample)/2 - X_mesh/2;
    X_lim_up = X_lim_low + X_sample + X_mesh/2;
    Y_lim_low = -X_mesh/2;
    Y_lim_up = X_mesh/2;
    node_index_receiver2 = find((model.nodePos(1,:)>=X_lim_low) & ...
                                (model.nodePos(1,:)<=X_lim_up) & ...
                                (model.nodePos(2,:)>=Y_lim_low) & ...
                                (model.nodePos(2,:)<=Y_lim_up));
    node_index_receiver = [node_index_generator node_index_receiver2];

    model.measSets{1,1}.name = 'main';
    model.measSets{1,1}.isDofGroup = 0;
    model.measSets{1,1}.measDof = repmat((1:model.nDims)', length(node_index_receiver), 1);
    model.measSets{1,1}.measNodes = reshape(repmat(node_index_receiver, model.nDims, 1), length(node_index_receiver)*model.nDims, 1);
    model.measFreq = 1;
    model.measStart = 1;
    model.fieldStoreIncs = round((1:5:10)/10*model.nt)';

    %% Material settings
    Density = 8000;
    C11 = 2.046e11; C12 = 1.377e11; C13 = 1.377e11;
    C21 = C12; C22 = C11; C23 = C12;
    C31 = C13; C32 = C23; C33 = C11;
    C44 = 1.262e11; C55 = C44; C66 = C44;

    pore_model = false;
    if pore_model
        % Example placeholder: map all non-background regions to a second material.
        v_air = 343; nu_air = 0.01; rho_air = 1.2;
        K_air = v_air^2 * rho_air;
        E_air = 3*K_air*(1-2*nu_air);
        model.matTypeRefs(model.matTypeRefs > 1) = 2;
        model.matTypes{1,1}.paramsType = 0;
        model.matTypes{1,1}.paramValues = [200e9, 0.3, Density];
        model.matTypes{2,1}.paramsType = 0;
        model.matTypes{2,1}.paramValues = [E_air, nu_air, rho_air];
    else
        [unique_columns, ~, idx] = unique(model.grain_Orientations', 'rows', 'stable');
        model.matTypeRefs = idx;
        unique_columns = unique_columns';
        SM_origin = [C11, C12, C13, 0, 0, 0; ...
                     C21, C22, C23, 0, 0, 0; ...
                     C31, C32, C33, 0, 0, 0; ...
                     0, 0, 0, C44, 0, 0; ...
                     0, 0, 0, 0, C55, 0; ...
                     0, 0, 0, 0, 0, C66];

        if ~exist('StiffnessMatrixRotate2', 'file')
            error(['StiffnessMatrixRotate2.m is required for rotated anisotropic stiffness generation. ', ...
                   'Provide it in this example folder or on the MATLAB path before running this script.']);
        end

        for i = 1:length(unique_columns(1,:))
            SM_rotated = StiffnessMatrixRotate2( ...
                SM_origin, ...
                -unique_columns(1,i)*pi/180, ...
                -unique_columns(2,i)*pi/180, ...
                -unique_columns(3,i)*pi/180);
            model.matTypes{i,1}.paramsType = 2;
            model.matTypes{i,1}.paramValues = material_packing_reference(SM_rotated, Density);
        end
    end

    %% Quick material-map preview
    [X, X1] = meshgrid(min(model.nodePos(1,:))+X_mesh/2:X_mesh:max(model.nodePos(1,:))); %#ok<NASGU>
    [Y1, Y] = meshgrid(min(model.nodePos(2,:))+Y_mesh/2:Y_mesh:max(model.nodePos(2,:))); %#ok<NASGU>
    Z2 = zeros(1, length(model.matTypeRefs));
    for k = 1:length(model.matTypeRefs)
        Z2(k) = model.matTypes{model.matTypeRefs(k),1}.paramValues(1);
    end
    Z2 = reshape(Z2,[length(X),length(Y)])';
    figure;
    imagesc(Z2/max(max(Z2)));
    set(gca, 'YDir', 'normal');
    title('Material-map preview');
    saveas(gcf, fullfile(output_dir, [PogoFilename '_material_map.png']));
    close(gcf);

    %% Save pogo-inp file
    model = rmfield(model,'grain_Orientations');
    fullFilePath = fullfile(output_dir, [PogoFilename '.pogo-inp']);
    savePogoInp(fullFilePath, model, 1, 15);
    clear model PogoFilename;
end
