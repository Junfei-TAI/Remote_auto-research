% MultilayerComposite_PulseEcho_Demo.m
% Sanitized example for layered-composite POGO model generation.
% Adapt geometry, materials, excitation, and defect definitions to the research question.

clear; clc; close all;
set(0, 'DefaultFigureVisible', 'off');
script_dir = fileparts(mfilename('fullpath'));
addpath(script_dir);
addpath(fullfile(script_dir, 'toolbox'));

%% 0. Study mode
% Keep early debugging to one case; expand after validation.
study.run_single_case = true;
study.defect_indices = 1;   % Example: 1, or 1:6 for batch later
study.generate_field_output = true;

%% 1. Configuration
PogoBaseName = 'MultilayerComposite_PulseEcho_Demo';

% Geometry parameters
geom.a = 5e-3;
geom.wall_thickness = 0.018e-3;

% Layer definition example
layers = {
    struct('type', 'plate', 'matTypeRefs', 1, 'thickness', 2.5e-3, 'ply', 40), ...
    struct('type', 'plate', 'matTypeRefs', 1, 'thickness', 0.1e-3, 'ply', 2), ...
    struct('type', 'plate', 'matTypeRefs', 1, 'thickness', 3.65e-3, 'ply', 60), ...
    struct('type', 'plate', 'matTypeRefs', 1, 'thickness', 0.1e-3, 'ply', 2), ...
    struct('type', 'plate', 'matTypeRefs', 1, 'thickness', 3.65e-3, 'ply', 60)};

% Sample size
X_sample = 0.050;
Y_sample = 0.050;
Z_sample = sum(cellfun(@(L) L.thickness, layers));

% Mesh parameters
meshParams.n_hex = 10;
meshParams.n_base_y = 10;
meshParams.X_mesh = 0.2e-3;
meshParams.Y_mesh = 0.2e-3;
meshParams.Z_mesh = 0.2e-3;

% Domain size
has_honeycomb = any(cellfun(@(L) strcmp(L.type, 'honeycomb') || strcmp(L.type, 'honeycomb_with_filler'), layers));
if has_honeycomb
    domain.total_x = ceil(X_sample / geom.a) * geom.a;
    domain.total_y = ceil(Y_sample / geom.a) * geom.a;
else
    domain.total_x = X_sample;
    domain.total_y = Y_sample;
end

%% 2. Defect parameterization example
xy_center = [X_sample/2, Y_sample/2];
xy_sizes = [0.010, 0.010; 0.016, 0.016; 0.020, 0.020];
z_centers = [0.00255; 0.00630; 0.00255];
z_thickness = [0.0001; 0.0001; 0.0001];

defect_list = struct('center', {}, 'size', {});
for xi = 1:size(xy_sizes, 1)
    defect_list(end+1) = struct( ...
        'center', [xy_center(1), xy_center(2), z_centers(xi)], ...
        'size', [xy_sizes(xi,1), xy_sizes(xi,2), z_thickness(xi)]);
end

if study.run_single_case
    defect_indices = study.defect_indices;
else
    defect_indices = 1:length(defect_list);
end

%% 3. Build and export one or more models
for defect_idx = defect_indices
    fprintf('Generating mesh for defect %d...\n', defect_idx);

    geom_mm = geom; geom_mm.a = geom.a * 1e3; geom_mm.wall_thickness = geom.wall_thickness * 1e3;
    domain_mm = domain; domain_mm.total_x = domain.total_x * 1e3; domain_mm.total_y = domain.total_y * 1e3; domain_mm.total_z = Z_sample * 1e3;
    meshParams_mm = meshParams;
    meshParams_mm.X_mesh = meshParams.X_mesh * 1e3;
    meshParams_mm.Y_mesh = meshParams.Y_mesh * 1e3;
    meshParams_mm.Z_mesh = meshParams.Z_mesh * 1e3;
    layers_mm = layers;
    for i = 1:length(layers)
        layers_mm{i}.thickness = layers{i}.thickness * 1e3;
    end

    [model, num_elems] = generate_composite_mesh_func_v2(geom_mm, meshParams_mm, domain_mm, layers_mm);
    model.nodePos = model.nodePos * 1e-3;
    fprintf('Mesh generated: %d nodes, %d elements.\n', size(model.nodePos, 2), num_elems);

    current_defect = defect_list(defect_idx);
    if exist('getElCents', 'file')
        [px, py, pz] = getElCents(model);
    else
        px = zeros(1, num_elems); py = px; pz = px;
        for ie = 1:num_elems
            nds = model.elNodes(:, ie);
            p = mean(model.nodePos(:, nds), 2);
            px(ie) = p(1); py(ie) = p(2); pz(ie) = p(3);
        end
    end

    c = current_defect.center;
    s = current_defect.size;
    in_defect = abs(px - c(1)) <= s(1)/2 & abs(py - c(2)) <= s(2)/2 & abs(pz - c(3)) <= s(3)/2;
    defect_elem_idx = find(in_defect);
    if ~isempty(defect_elem_idx)
        model.elNodes(:, defect_elem_idx) = [];
        model.matTypeRefs(defect_elem_idx) = [];
        if isfield(model, 'elTypeRefs')
            model.elTypeRefs(defect_elem_idx) = [];
        end
        used_nodes = unique(model.elNodes(:));
        new_idx_map = zeros(1, size(model.nodePos, 2));
        new_idx_map(used_nodes) = 1:length(used_nodes);
        model.elNodes = new_idx_map(model.elNodes);
        model.nodePos = model.nodePos(:, used_nodes);
    end

    %% 4. Signal and acquisition
    frequency = 2250; % kHz
    cycles = 2;
    timedelay = 0;
    timestep = 2e-9;
    endtime = 4e-5;
    phase = 0;

    sig_filename = ['tb_',num2str(frequency),'kHz_',num2str(cycles),'cyc.dat'];
    tb_signal = tbgeneration(frequency, cycles, timedelay, timestep, endtime, phase, sig_filename);

    model.prec = 8;
    model.runName = 'Job';
    model.nt = round(endtime/timestep);
    model.dt = timestep;

    X_gen = X_sample / 2;
    Y_gen = Y_sample / 2;
    Z_gen = min(model.nodePos(3,:));
    excit_radius = 3e-3;
    dx2 = (model.nodePos(1,:) - X_gen).^2;
    dy2 = (model.nodePos(2,:) - Y_gen).^2;
    tolZ = 1e-4;

    node_index_generator = find(abs(model.nodePos(3,:) - Z_gen) <= tolZ & (dx2 + dy2) <= excit_radius^2);
    if isempty(node_index_generator)
        [~, nearest_idx] = min(dx2 + dy2 + (model.nodePos(3,:) - Z_gen).^2);
        node_index_generator = nearest_idx;
    end

    model.shots{1,1}.ntSig = length(tb_signal);
    model.shots{1,1}.dtSig = tb_signal(2,1) - tb_signal(1,1);
    model.shots{1,1}.sigs{1,1}.sigType = 0;
    model.shots{1,1}.sigs{1,1}.isDofGroup = 0;
    model.shots{1,1}.sigs{1,1}.dofSpec = ones(length(node_index_generator),1)*3;
    model.shots{1,1}.sigs{1,1}.nodeSpec = node_index_generator';
    model.shots{1,1}.sigs{1,1}.sigAmps = ones(length(node_index_generator),1) * 1e-13;
    model.shots{1,1}.sigs{1,1}.sig = tb_signal(:,2);

    node_index_receiver = node_index_generator;
    model.measSets.main.measDof = ones(1, length(node_index_receiver))*3;
    model.measSets.main.measNodes = node_index_receiver;
    model.measFreq = 1;

    %% 5. Visualization for consistency check
    figure('Name', 'Simulation Setup', 'Color', 'w');
    scatter3(model.nodePos(1,:)*1e3, model.nodePos(2,:)*1e3, model.nodePos(3,:)*1e3, 1, '.');
    xlabel('X [mm]'); ylabel('Y [mm]'); zlabel('Z [mm]');
    title(sprintf('Defect %02d setup preview', defect_idx));
    view([-45 25]); grid on; drawnow;
    saveas(gcf, sprintf('%s_defect_%02d_setup.png', PogoBaseName, defect_idx));
    close(gcf);

    %% 6. Material placeholder
    % Replace this block with the material definition appropriate to your problem.
    model.nDims = 3;
    model.nDofPerNode = 3;
    model.matTypes{1}.paramsType = 0;
    model.matTypes{1}.paramValues = [3.5e10; 0.25; 1600]; % Example isotropic placeholder

    %% 7. Export
    PogoFilename = sprintf('%s_defect_%02d', PogoBaseName, defect_idx);
    fprintf('Saving POGO input file: %s.pogo-inp\n', PogoFilename);
    savePogoInp([PogoFilename,'.pogo-inp'], model, 1, 15);
end

fprintf('Done. Validate geometry/material choices before scaling to batch runs.\n');
