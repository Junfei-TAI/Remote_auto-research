% Validated_Config2_PulseEcho_WorkingExample.m
% Working example adapted from a validated layered-composite pulse-echo run.
% This is intentionally more specific than the generic demo script and can be
% used as a known-good reference before generalizing to new studies.
%
% Composite_Simulation_POGO.m
% Generates a POGO input file for multi-layer composite ultrasound simulation.
% Uses generate_composite_mesh_func_v2.m for meshing.

clear; clc; close all;
set(0, 'DefaultFigureVisible', 'off');
script_dir = fileparts(mfilename('fullpath'));
if ~isempty(script_dir)
    addpath(script_dir);
end

%% 1. Configuration
PogoBaseName = 'Composite_MultiLayer_Sim_config2_pulse-echo_dc';
% --- Geometry & Mesh Parameters ---
geom.a = 5e-3;               % Hex side length (m) - Scaled to meters!
geom.wall_thickness = 0.018e-3;% Honeycomb wall thickness (m)

% Mesh Density
% Note: Ensure element size is small enough for frequency (lambda/10 rule)
meshParams.n_hex = 10;     
meshParams.n_base_y = 10;  

% Layer Definition (Thickness in meters)
% Mat IDs: 1=Honeycomb, 2=Filler, 3=Plate1, 4=Plate2, etc.
layers = {
    struct('type', 'plate', 'matTypeRefs', 1, 'thickness', 2.5e-3, 'ply', 40), ...
    struct('type', 'plate', 'matTypeRefs', 1, 'thickness', 0.1e-3, 'ply', 2), ...
    struct('type', 'plate', 'matTypeRefs', 1, 'thickness', 3.65e-3, 'ply', 60), ...
    struct('type', 'plate', 'matTypeRefs', 1, 'thickness', 0.1e-3, 'ply', 2), ...
    struct('type', 'plate', 'matTypeRefs', 1, 'thickness', 3.65e-3, 'ply', 60)}; % from bottom to top layers

%%%%%%%%%%%%%%%%%%% for config without honeycomb %%%%%%%%%%%%%%%%%%%
% Sample Size
X_sample = 0.050; % unit: m
Y_sample = 0.050;
Z_sample = []; % calculate from layers definition

meshParams.X_mesh = 0.1e-3; % unit: m ( < wavelength / 10.)
meshParams.Y_mesh = 0.1e-3;
meshParams.Z_mesh = 0.2e-3;

if isempty(Z_sample)
    Z_sample = sum(cellfun(@(L) L.thickness, layers));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Domain Size
has_honeycomb = any(cellfun(@(L) strcmp(L.type, 'honeycomb') || ...
    strcmp(L.type, 'honeycomb_with_filler'), layers));
if has_honeycomb
    domain.total_x = ceil(X_sample / geom.a) * geom.a; % align to honeycomb pitch
    domain.total_y = ceil(Y_sample / geom.a) * geom.a;
else
    domain.total_x = X_sample;      % Total length in X (m)
    domain.total_y = Y_sample;      % Total length in Y (m)
end


%% 2. Defect List (for multi-file generation)
% Defect definitions (meters)
% All defects are centered in the model XY
% Sizes in XY (mm -> m): 10, 16, 20 (kept as defined below)
% Z centers (mm -> m) and thickness (mm -> m) per defect
xy_center = [X_sample/2, Y_sample/2];
xy_sizes = [
    0.010, 0.010;
    0.010, 0.010;
    0.016, 0.016;
    0.016, 0.016;
    0.020, 0.020;
    0.020, 0.020
];
z_centers = [
    0.00255;
    0.00630;
    0.00255;
    0.00630;
    0.00255;
    0.00630
];
z_thickness = [
    0.0001;
    0.0001;
    0.0001;
    0.0001;
    0.0001;
    0.0001
];

defect_list = struct('center', {}, 'size', {});
for xi = 1:size(xy_sizes, 1)
    defect_list(end+1) = struct( ...
        'center', [xy_center(1), xy_center(2), z_centers(xi)], ...
        'size', [xy_sizes(xi,1), xy_sizes(xi,2), z_thickness(xi)]);
end

%% 3. Mesh Generation and File Export (loop per defect)
for defect_idx = 2:2
% for defect_idx = 1:length(defect_list)
fprintf('Generating mesh for defect %d/%d...\n', defect_idx, length(defect_list));
% Important: The mesh function was originally written for mm. 
% We need to pass mm values if we want to reuse the exact logic, or adjust scale.
% Assuming the function logic is unit-agnostic but depends on relative inputs.
% Let's convert to mm for the function call, then scale back to meters if needed.
% However, since we updated inputs to meters above, let's just pass them.
% CAUTION: The original code had `a=5` (mm). If we pass `a=0.005`, ensure `tol` logic holds.
% Let's stick to MM for generation to be safe with tolerances, then scale at end.

geom_mm = geom; geom_mm.a = geom.a * 1e3; geom_mm.wall_thickness = geom.wall_thickness * 1e3;
domain_mm = domain; domain_mm.total_x = domain.total_x * 1e3; domain_mm.total_y = domain.total_y * 1e3;
domain_mm.total_z = Z_sample * 1e3;

meshParams_mm = meshParams;
meshParams_mm.X_mesh = meshParams.X_mesh * 1e3;
meshParams_mm.Y_mesh = meshParams.Y_mesh * 1e3;
meshParams_mm.Z_mesh = meshParams.Z_mesh * 1e3;

layers_mm = layers;
for i = 1:length(layers)
    layers_mm{i}.thickness = layers{i}.thickness * 1e3;
end

[model, num_elems] = generate_composite_mesh_func_v2(geom_mm, meshParams_mm, domain_mm, layers_mm);

% Scale mesh back to meters
model.nodePos = model.nodePos * 1e-3; 
fprintf('Mesh generated: %d nodes, %d elements.\n', size(model.nodePos, 2), num_elems);

%% 3.1 Defect Definition (single defect centered in model)
has_defect = true;
if has_defect
    fprintf('Applying defects...\n');

    % Use the current defect (already centered in model XY)
    current_defect = defect_list(defect_idx);

    % Get element centers for filtering
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
    in_defect = ...
        abs(px - c(1)) <= s(1)/2 & ...
        abs(py - c(2)) <= s(2)/2 & ...
        abs(pz - c(3)) <= s(3)/2;

    defect_elem_idx = find(in_defect);

    if ~isempty(defect_elem_idx)
        fprintf('  Found %d elements in defect regions. Removing them...\n', length(defect_elem_idx));

        % Remove elements
        model.elNodes(:, defect_elem_idx) = [];
        model.matTypeRefs(defect_elem_idx) = [];
        if isfield(model, 'elTypeRefs')
            model.elTypeRefs(defect_elem_idx) = [];
        end

        % Cleanup Unused Nodes
        used_nodes = unique(model.elNodes(:));

        % Map old indices to new
        new_idx_map = zeros(1, size(model.nodePos, 2));
        new_idx_map(used_nodes) = 1:length(used_nodes);

        % Update
        model.elNodes = new_idx_map(model.elNodes);
        model.nodePos = model.nodePos(:, used_nodes);

        fprintf('  Defects applied. Updated nodes: %d, elements: %d\n', size(model.nodePos,2), size(model.elNodes,2));
    else
        warning('No elements found in defect definition regions.');
    end
end

%% 3. Simulation Parameters
frequency = 2250; % kHz --> ~1.3 mm wavelength
cycles = 2;
timedelay = 0e-5; % 10 microseconds delay
timestep = 2e-9; % unit: s  min_mesh / v / 2, 2e-9 is enough for honeycomb wall ~ 0.018e-3 m.
endtime = 4e-5;  % unit: s  for propagation distance (endtime-timedelay)*v, should be larger than model direction (eg thichness or length)
phase = 0;

% Generate Excitation Signal
sig_filename = ['tb_',num2str(frequency),'kHz_',num2str(cycles),'cyc.dat'];
tb_signal = tbgeneration(frequency, cycles, timedelay, timestep, endtime, phase, sig_filename);

% Pogo Settings
model.prec = 8;
model.runName = 'Job';
model.nt = round(endtime/timestep);
model.dt = timestep;

%% 4. Excitation & Receivers

fprintf('Setting up boundary conditions and excitation...\n');

% --- Generator (Excitation) ---
% Define region for excitation
X_gen = X_sample / 2;
Y_gen = Y_sample / 2;
Z_gen = min(model.nodePos(3,:));

excit_radius = 3e-3; % 3mm radius transducer
% To simulate a point source (extreme condition), set excit_radius very small 
% (smaller than half the element size) or exactly 0.
% excit_radius = 0; 

dx2 = (model.nodePos(1,:) - X_gen).^2;
dy2 = (model.nodePos(2,:) - Y_gen).^2;
tolZ = 1e-4;

node_index_generator = find( ...
    abs(model.nodePos(3,:) - Z_gen) <= tolZ & ...
    (dx2 + dy2) <= excit_radius^2 ...
);

% Fallback: If radius is too small and no nodes are selected, find the single nearest node
if isempty(node_index_generator)
    fprintf('Excitation radius too small (Point Source Mode). Selecting nearest node.\n');
    [~, nearest_idx] = min(dx2 + dy2 + (model.nodePos(3,:) - Z_gen).^2);
    node_index_generator = nearest_idx;
end

model.shots{1,1}.ntSig = length(tb_signal);
model.shots{1,1}.dtSig = tb_signal(2,1) - tb_signal(1,1);
model.shots{1,1}.sigs{1,1}.sigType = 0; % Force
model.shots{1,1}.sigs{1,1}.isDofGroup = 0;
model.shots{1,1}.sigs{1,1}.dofSpec = ones(length(node_index_generator),1)*3; % Z-direction
model.shots{1,1}.sigs{1,1}.nodeSpec = node_index_generator';
model.shots{1,1}.sigs{1,1}.sigAmps = ones(length(node_index_generator),1) * 1e-13; % Amplitude
model.shots{1,1}.sigs{1,1}.sig = tb_signal(:,2);

% --- Receiver ---
% Define region for receiver (e.g., pulse-echo)
X_rec = X_gen; 
Y_rec = Y_gen;
Z_rec = Z_gen;

% or other position for pitch-catch
% X_rec = 0.075;
% Y_rec = 0.075;
% Z_rec = min(model.nodePos(3,:));

dx2_bot = (model.nodePos(1,:) - X_rec).^2;
dy2_bot = (model.nodePos(2,:) - Y_rec).^2;

node_index_receiver = find( ...
    abs(model.nodePos(3,:) - Z_rec) <= tolZ & ...
    (dx2_bot + dy2_bot) <= excit_radius^2 ...
);

% Fallback: Point Receiver Mode
if isempty(node_index_receiver)
    fprintf('Receiver radius too small (Point Receiver Mode). Selecting nearest node.\n');
    [~, nearest_idx] = min(dx2_bot + dy2_bot + (model.nodePos(3,:) - Z_rec).^2);
    node_index_receiver = nearest_idx;
end

model.measSets{1,1}.name = 'main';
model.measSets{1,1}.isDofGroup = 0;
model.measSets{1,1}.measDof = repmat((1:model.nDims)', length(node_index_receiver), 1);
model.measSets{1,1}.measNodes = reshape(repmat(node_index_receiver, model.nDims, 1), [], 1);
model.measFreq = 1; % Output every 1 steps
model.measStart = 1;
model.fieldStoreIncs = round(linspace(1, model.nt, 20))'; % Store 20 frames for visualization

%% 4.1 Setup Visualization (Geometry, Generator, Receiver, Defect)
% Logic from Ultrasound_in_Multilayer_Composites_3D.m

fprintf('Visualizing simulation setup...\n');
figure('Name', 'Simulation Setup', 'Color', 'w');
axis equal; grid on; hold on;
xlabel('X [mm]'); ylabel('Y [mm]'); zlabel('Z [mm]');
view([-45 25]);

% 1. Plot Surface Contour (using plot3DOutline if available, or simplified scatter)
if exist('plot3DOutline', 'file')
    % Approximate mesh size for visualization
    mesh_size_est = geom.a/meshParams.n_hex * 1e-3; % just a guess for plot scaling
    
    % Get current children to identify new plot objects
    h_old = get(gca, 'Children');
    
    plot3DOutline(model.nodePos(1,:), model.nodePos(2,:), model.nodePos(3,:), mesh_size_est);
    
    % Find new children and turn off legend visibility
    h_new = setdiff(get(gca, 'Children'), h_old);
    set(h_new, 'HandleVisibility', 'off');
    
    % Dummy plot for legend
    plot3(NaN, NaN, NaN, 'b-', 'DisplayName', 'Geometry'); 
else
    % Fallback: Scatter of boundary nodes
    k = boundary(model.nodePos(1,:)', model.nodePos(2,:)', model.nodePos(3,:)', 0.5);
    trisurf(k, model.nodePos(1,:)*1e3, model.nodePos(2,:)*1e3, model.nodePos(3,:)*1e3, ...
        'FaceColor','cyan','FaceAlpha',0.1, 'EdgeColor','none', 'DisplayName', 'Geometry');
end

% 2. Plot Generator (Excitation Region)
if ~isempty(node_index_generator)
    scatter3(model.nodePos(1,node_index_generator)*1e3, ...
             model.nodePos(2,node_index_generator)*1e3, ...
             model.nodePos(3,node_index_generator)*1e3, ...
             40, 'k', 'o', 'filled', 'MarkerEdgeColor', 'none', 'DisplayName', 'Generator');
end

% 3. Plot Receiver
if ~isempty(node_index_receiver)
    scatter3(model.nodePos(1,node_index_receiver)*1e3, ...
             model.nodePos(2,node_index_receiver)*1e3, ...
             model.nodePos(3,node_index_receiver)*1e3, ...
             40, 'g', 'd', 'filled', 'MarkerEdgeColor', 'none', 'DisplayName', 'Receiver');
end

% 4. Plot Defect (Approximation based on removed elements hole)
% We can't plot the removed elements directly since they are gone.
% But we can plot the defect CENTER and area.
if exist('has_defect', 'var') && has_defect
    scatter3(current_defect.center(1)*1e3, current_defect.center(2)*1e3, current_defect.center(3)*1e3, ...
             12, 'r', 'filled', 'MarkerEdgeColor', 'none', 'DisplayName', 'Defect Center');

    x = current_defect.center(1) + [-current_defect.size(1)/2, current_defect.size(1)/2, current_defect.size(1)/2, -current_defect.size(1)/2];
    y = current_defect.center(2) + [-current_defect.size(2)/2, -current_defect.size(2)/2, current_defect.size(2)/2, current_defect.size(2)/2];
    z = ones(1, 4) * current_defect.center(3);
    patch(x*1e3, y*1e3, z*1e3, 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'r', 'DisplayName', 'Defect Area');
end

legend('show', 'Location', 'best');
title('3D Model: Setup & Defects');

% figure
% elNo = 1250001;
% plot3(model.nodePos(1, model.elNodes(:,elNo)), model.nodePos(2, model.elNodes(:,elNo)), model.nodePos(3, model.elNodes(:,elNo)))
%% 5. Material Properties

fprintf('Assigning material properties...\n');

% Mat 1: Honeycomb (Paper/Nomex/Al) - Simplified Isotropic for now, or Orthotropic
% Using properties from reference code (approximate)
% E_nomex = 3.4e9; nu_nomex = 0.3; rho_nomex = 48;
% model.matTypes{1,1}.paramsType = 0; % Isotropic
% model.matTypes{1,1}.paramValues = [E_nomex, nu_nomex, rho_nomex];

% Mat 2: Filler (Epoxy/Adhesive)
% E_filler = 3.5e9; nu_filler = 0.35; rho_filler = 1200;
% model.matTypes{2,1}.paramsType = 0;
% model.matTypes{2,1}.paramValues = [E_filler, nu_filler, rho_filler];

% Mat 3: Plate 1 (e.g., E-Glass 7781 - Transversely Isotropic / Orthotropic)
% Using calibrated E-Glass 7781 parameters
rho_C3K = 1522;
D_EG7781 = [38.42 28.06 6.57 0 0 0;
            28.06 38.42 6.57 0 0 0;
            6.57 6.57 12.09 0 0 0;
            0 0 0 3.04 0 0;
            0 0 0 0 3.04 0;
            0 0 0 0 0 5.17]*1e9;
% D_EG7781 = [1.3785 0.0475 0.0475 0 0 0;
%             0.0475 0.1109 0.0475 0 0 0;
%             0.0475 0.0475 0.1109 0 0 0;
%             0 0 0 0.0400 0 0;
%             0 0 0 0 0.0400 0;
%             0 0 0 0 0 0.0317]*1e9;
model.matTypes{1,1}.paramsType = 2; % Anisotropic
model.matTypes{1,1}.paramValues = [D_EG7781(1,1); D_EG7781(1,2); D_EG7781(2,2); 
                                   D_EG7781(1,3); D_EG7781(2,3); D_EG7781(3,3); ...
                                   D_EG7781(1,6); D_EG7781(2,6); D_EG7781(3,6); D_EG7781(6,6); ...
                                   D_EG7781(1,5); D_EG7781(2,5); D_EG7781(3,5); D_EG7781(6,5); D_EG7781(5,5); ...
                                   D_EG7781(1,4); D_EG7781(2,4); D_EG7781(3,4); D_EG7781(6,4); D_EG7781(5,4);D_EG7781(4,4); ...
                                   rho_C3K; 0];

% Mat 4: Plate 2 (e.g., Aluminum or same as Mat 3)
% E_al = 69e9; nu_al = 0.33; rho_al = 2700;
% model.matTypes{1,1}.paramsType = 0;
% model.matTypes{1,1}.paramValues = [E_al, nu_al, rho_al];


%% 6. Absorbing Boundaries 
% Add simple absorbing boundaries at edges X and Y
% fprintf('Adding absorbing boundaries...\n');
% xLims = [min(model.nodePos(1,:)), min(model.nodePos(1,:))+2e-3, max(model.nodePos(1,:))-2e-3, max(model.nodePos(1,:))];
% yLims = [min(model.nodePos(2,:)), min(model.nodePos(2,:))+2e-3, max(model.nodePos(2,:))-2e-3, max(model.nodePos(2,:))];
% zLims = []; % No absorption in Z (thickness direction)
% nAbsVals = 30;
% c0 = 3000; % Approx wave speed
% freq_abs = frequency * 1e3;
% 
% % Only isotropic materials are supported for SRM usually, so this might be tricky with anisotropic plates.
% % Often SRM is applied to specific material IDs.
% % For simplicity in this demo, we skip explicit SRM function call unless you have 'addAbsBound.m' compatible with this model.
% % If available:
% if exist('addAbsBound', 'file')
%    try
%        model = addAbsBound(model, xLims, yLims, zLims, nAbsVals, [], c0, freq_abs);
%    catch
%        warning('Could not apply absorbing boundaries. Check addAbsBound compatibility.');
%    end
% end

%% 7. Export

PogoFilename = sprintf('%s_defect_%02d', PogoBaseName, defect_idx);
fprintf('Saving POGO input file: %s.pogo-inp\n', PogoFilename);
savePogoInp(sprintf([PogoFilename,'.pogo-inp']), model, 1, 15);

fprintf('Done.\n');

end
