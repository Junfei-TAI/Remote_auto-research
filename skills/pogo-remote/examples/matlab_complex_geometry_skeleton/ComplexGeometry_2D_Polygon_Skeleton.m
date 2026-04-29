% ComplexGeometry_2D_Polygon_Skeleton.m
% Skeleton for Paradigm 3: simple material, complex geometry.

clear; clc; close all;
set(0, 'DefaultFigureVisible', 'off');
script_dir = fileparts(mfilename('fullpath'));
addpath(script_dir);
addpath(fullfile(script_dir, '..', 'matlab_multilayer_composite', 'toolbox'));

%% 1. Coordinate system and geometry definition
% Replace this section with either:
% - explicit vertices from the user, or
% - a parametric reconstruction function.
params.width = 20e-3;
params.height = 12e-3;
params.notch_width = 3e-3;
params.notch_depth = 2e-3;
vertices = build_parametric_polygon_demo(params);

%% 2. Geometry preview / consistency check
fig = figure('Color', 'w');
patch(vertices(:,1)*1e3, vertices(:,2)*1e3, [0.8 0.9 1.0], 'EdgeColor', 'k', 'LineWidth', 1.5);
axis equal; grid on;
xlabel('X [mm]'); ylabel('Y [mm]');
title('Geometry preview: confirm vertices/order/shape');
print(fig, 'geometry_preview.png', '-dpng', '-r200');
close(fig);

%% 3. Meshing strategy decision
% This skeleton uses a structured background grid masked by the polygon.
% For more irregular geometries, replace this with another meshing strategy.
dx = 0.25e-3;
dy = 0.25e-3;
model = polygon_quad_mesh_from_grid(vertices, dx, dy);

%% 4. Mesh sanity checks
num_elems = size(model.elNodes, 2);
num_nodes = size(model.nodePos, 2);
fprintf('Generated %d nodes and %d elements.\n', num_nodes, num_elems);
assert(num_elems > 0, 'No elements generated. Check geometry or mesh size.');

centers = zeros(2, num_elems);
areas = zeros(1, num_elems);
for e = 1:num_elems
    nds = model.elNodes(:, e);
    pts = model.nodePos(:, nds)';
    centers(:,e) = mean(pts,1)';
    areas(e) = polyarea(pts(:,1), pts(:,2));
end
assert(all(areas > 0), 'Degenerate or inverted elements detected.');

fig = figure('Color', 'w');
scatter(model.nodePos(1,:)*1e3, model.nodePos(2,:)*1e3, 5, '.'); hold on;
plot([vertices(:,1); vertices(1,1)]*1e3, [vertices(:,2); vertices(1,2)]*1e3, 'r-', 'LineWidth', 1.2);
axis equal; grid on;
xlabel('X [mm]'); ylabel('Y [mm]');
title('Mesh-node preview');
print(fig, 'mesh_preview.png', '-dpng', '-r200');
close(fig);

%% 5. Simple material placeholder
% Replace with isotropic or anisotropic parameters as needed.
model.matTypes{1,1}.paramsType = 0;
model.matTypes{1,1}.paramValues = [70e9, 0.33, 2700];

%% 6. Time signal and run settings
frequency = 1000; % kHz
cycles = 3;
timedelay = 0;
timestep = 5e-9;
endtime = 3e-5;
phase = 0;
sig_filename = ['tb_',num2str(frequency),'kHz_',num2str(cycles),'cyc.dat'];
tb_signal = tbgeneration(frequency, cycles, timedelay, timestep, endtime, phase, sig_filename);

model.prec = 8;
model.runName = 'ComplexGeometry2D';
model.nt = round(endtime/timestep);
model.dt = timestep;

%% 7. Generator and receiver placeholders
xmid = mean(vertices(:,1));
ymax = max(vertices(:,2));
ymin = min(vertices(:,2));

gen_nodes = find(abs(model.nodePos(2,:) - ymax) <= dy/2 & abs(model.nodePos(1,:) - xmid) <= 2*dx);
if isempty(gen_nodes)
    [~, idx] = min((model.nodePos(1,:) - xmid).^2 + (model.nodePos(2,:) - ymax).^2);
    gen_nodes = idx;
end

rec_nodes = find(abs(model.nodePos(2,:) - ymin) <= dy/2 & abs(model.nodePos(1,:) - xmid) <= 2*dx);
if isempty(rec_nodes)
    [~, idx] = min((model.nodePos(1,:) - xmid).^2 + (model.nodePos(2,:) - ymin).^2);
    rec_nodes = idx;
end

model.shots{1,1}.ntSig = length(tb_signal);
model.shots{1,1}.dtSig = tb_signal(2,1) - tb_signal(1,1);
model.shots{1,1}.sigs{1,1}.sigType = 0;
model.shots{1,1}.sigs{1,1}.isDofGroup = 0;
model.shots{1,1}.sigs{1,1}.dofSpec = ones(length(gen_nodes),1) * 2;
model.shots{1,1}.sigs{1,1}.nodeSpec = gen_nodes';
model.shots{1,1}.sigs{1,1}.sigAmps = ones(length(gen_nodes),1) * 1e-13;
model.shots{1,1}.sigs{1,1}.sig = tb_signal(:,2);

model.measSets{1,1}.name = 'main';
model.measSets{1,1}.isDofGroup = 0;
model.measSets{1,1}.measDof = repmat((1:model.nDims)', length(rec_nodes), 1);
model.measSets{1,1}.measNodes = reshape(repmat(rec_nodes, model.nDims, 1), length(rec_nodes)*model.nDims, 1);
model.measFreq = 1;
model.measStart = 1;

%% 8. Export
PogoFilename = 'ComplexGeometry_2D_Polygon_Skeleton';
savePogoInp([PogoFilename, '.pogo-inp'], model, 1, 15);
fprintf('Saved %s.pogo-inp\n', PogoFilename);
