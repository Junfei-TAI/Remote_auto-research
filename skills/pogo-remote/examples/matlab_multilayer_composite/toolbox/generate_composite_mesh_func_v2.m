function [model, num_elems] = generate_composite_mesh_func_v2(geom, meshParams, domain, layers)
% generate_composite_mesh_func
% Generates a structured finite element mesh for a multi-layer composite
% structure involving honeycomb and solid plates.
%
% Inputs:
%   geom: struct with fields 'a' (hex side) and 'wall_thickness'
%   meshParams: struct with fields 'n_hex', 'n_base_y'
%   domain: struct with fields 'total_x', 'total_y'
%   layers: cell array of structs defining the layer stack
%
% Outputs:
%   model: struct containing nodePos, elNodes, matTypeRefs, etc.
%   num_elems: number of elements generated

% If no honeycomb layers are present, fall back to a regular grid mesh.
has_honeycomb = any(cellfun(@(L) strcmp(L.type, 'honeycomb') || ...
    strcmp(L.type, 'honeycomb_with_filler'), layers));
if ~has_honeycomb
    [model, num_elems] = generate_plate_only_mesh(geom, meshParams, domain, layers);
    return;
end

%% 2. Geometry Calculation (Z-Shape Base)

a = geom.a;
wall_thickness = geom.wall_thickness;

% Derived dimensions
z_length = a/2 + wall_thickness/sqrt(3)/2; 
z_width = wall_thickness;
base_x = a + a/2;
base_y = a*sqrt(3)/2;

% Define Z-shape vertices (2D)
% Top leg
x0 = 0; y0 = base_y;
x1 = x0 + z_length; y1 = y0;
x2 = x1 + a/2; y2 = z_width;
x3 = base_x; y3 = z_width;
% Bottom leg (symmetry)
x4 = base_x; y4 = 0;
x5 = base_x - z_length; y5 = 0;
x6 = x5 + (base_y - z_width - y5) / ((y2 - y1) / (x2 - x1)); y6 = base_y - z_width;
x7 = 0; y7 = base_y - z_width;

Z2D = [x0 y0; x1 y1; x2 y2; x3 y3; x4 y4; x5 y5; x6 y6; x7 y7];

%% 3. 2D Mesh Seeding (Structured)

n_hex = meshParams.n_hex;
n_base_y = meshParams.n_base_y;

% Important horizontal lines
y_lines = [0, linspace(z_width, base_y-z_width, n_base_y-1), base_y];

% Inclined lines segments
inclined1 = [x1 y1; x2 y2];
inclined2 = [x5 y5; x6 y6];

% Vertical lines
x_lines = [0, base_x];

% Collect intersections
seeds = [];
for y = y_lines
    % Vertical intersections
    for x = x_lines
        seeds = [seeds; x y];
    end
    % Inclined 1 intersection
    if (y >= min(inclined1(:,2)) && y <= max(inclined1(:,2)))
        x = interp1(inclined1(:,2), inclined1(:,1), y);
        seeds = [seeds; x y];
    end
    % Inclined 2 intersection
    if (y >= min(inclined2(:,2)) && y <= max(inclined2(:,2)))
        x = interp1(inclined2(:,2), inclined2(:,1), y);
        seeds = [seeds; x y];
    end
end

% Add internal structured seeds
% Extend inclined lines to boundaries
if (y2 ~= y1), x8 = x1 + (x2-x1)*(0 - y1)/(y2-y1); else, x8=x1; end
if (y6 ~= y5), x9 = x5 + (x6-x5)*(base_y - y5)/(y6-y5); else, x9=x5; end

% Define interpolation segments on boundaries
x_bottom = linspace(0, x5, n_hex);
x_top = linspace(0, x9, n_hex);
x_bottom_right = linspace(x8, base_x, n_hex);
x_top_right = linspace(x1, base_x, n_hex);

y_horiz = linspace(z_width, base_y-z_width, n_base_y-1);

% Interpolate vertical lines between top and bottom segments
for i = 2:n_hex-1
    % Left part
    for j = 1:length(y_horiz)
        y = y_horiz(j);
        x = x_bottom(i) + (x_top(i) - x_bottom(i)) * (y / base_y);
        seeds = [seeds; x y];
    end
    % Right part
    for j = 1:length(y_horiz)
        y = y_horiz(j);
        x = x_bottom_right(i) + (x_top_right(i) - x_bottom_right(i)) * (y / base_y);
        seeds = [seeds; x y];
    end
end

% Add boundary nodes explicitly
seeds = [seeds; 
         [x_bottom' zeros(size(x_bottom'))];
         [x_top' base_y*ones(size(x_top'))];
         [x_bottom_right' zeros(size(x_bottom_right'))];
         [x_top_right' base_y*ones(size(x_top_right'))]];

% Remove duplicates using tolerance to ensure consistent grid
% Using uniquetol to merge close points (critical for structured grid)
seeds = uniquetol(seeds, 1e-9, 'ByRows', true);

%% 4. Supercell Creation (Symmetry & Replication)

% Base unit cell seeds processing (flips)
% Flip seeds against y=0
seeds_flip_y = [seeds(:,1), -seeds(:,2)];
seeds = uniquetol([seeds; seeds_flip_y], 1e-9, 'ByRows', true);
% Flip seeds against x=0
seeds_flip_x = [-seeds(:,1), seeds(:,2)];
seeds = uniquetol([seeds; seeds_flip_x], 1e-9, 'ByRows', true);

% Define Supercell Geometry for material masking later
% Shift origin to positive quadrant for ease
supercell_origin = [base_x, base_y];

% Base Z-shape lists for masking
Z_shapes_base = {
    Z2D;
    [Z2D(:,1), -Z2D(:,2)];
    [-Z2D(:,1), Z2D(:,2)];
    [-Z2D(:,1), -Z2D(:,2)]
};
% Shifted Z-shapes for one supercell
Z_shapes = {};
for k=1:4
    Z_shapes{k} = Z_shapes_base{k} + supercell_origin;
end

% Shift seeds
seeds = seeds + supercell_origin;

% Replicate Supercell to fill domain
supercell_x = 2 * base_x;
supercell_y = 2 * base_y;

nx = ceil(domain.total_x / supercell_x);
ny = ceil(domain.total_y / supercell_y);

all_seeds_2d = [];
% We also need to store Z-shape polygons for the entire domain for filtering
all_Z_polys = {};

for ix = 0:nx-1
    for iy = 0:ny-1
        cell_offset = [ix * supercell_x, iy * supercell_y];
        
        % Replicate seeds
        shifted_seeds = [seeds(:,1) + cell_offset(1), seeds(:,2) + cell_offset(2)];
        all_seeds_2d = [all_seeds_2d; shifted_seeds];
        
        % Replicate Z-shapes (for masking)
        for k = 1:4
            all_Z_polys{end+1} = Z_shapes{k} + cell_offset;
        end
    end
end
% Final deduplication of supercell seeds
all_seeds_2d = uniquetol(all_seeds_2d, 1e-9, 'ByRows', true);

%% 5. 3D Extrusion and Node Generation

fprintf('Generating 3D nodes...\n');

z_nodes = [0];
current_z = 0;
layer_z_ranges = zeros(length(layers), 2);

% Determine Z-levels based on layers and ply counts
for i = 1:length(layers)
    L = layers{i};
    dz = L.thickness / L.ply;
    layer_levels = current_z + (1:L.ply) * dz;
    z_nodes = [z_nodes, layer_levels];
    
    layer_z_ranges(i, 1) = current_z;
    layer_z_ranges(i, 2) = current_z + L.thickness;
    
    current_z = layer_z_ranges(i, 2);
end

% Remove near-duplicate Z levels to avoid zero-thickness elements
z_nodes = sort(unique(z_nodes));
z_tol = 1e-9;
keep_mask = [true, diff(z_nodes) > z_tol];
z_nodes = z_nodes(keep_mask);

if numel(z_nodes) < 2
    error('Z_nodes has fewer than 2 levels. Check layer thicknesses and mesh settings.');
end

% Create full 3D cloud
% (Using repmat/kron approach for speed)
n_2d = size(all_seeds_2d, 1);
n_z = length(z_nodes);
all_seeds_3d = zeros(3, n_2d * n_z);

% Fill X, Y
all_seeds_3d(1,:) = repmat(all_seeds_2d(:,1)', 1, n_z);
all_seeds_3d(2,:) = repmat(all_seeds_2d(:,2)', 1, n_z);
% Fill Z
all_seeds_3d(3,:) = kron(z_nodes, ones(1, n_2d));

% Sort nodes for structured indexing: Z then Y then X
% Important for the element connectivity logic
all_seeds_3d = all_seeds_3d'; % nx3
[all_seeds_3d, ~] = sortrows(all_seeds_3d, [3 2 1]);
all_seeds_3d = all_seeds_3d'; % 3xn

%% 6. Element Connectivity Generation

fprintf('Generating element connectivity...\n');

tol = 1e-8;
% Detect grid dimensions
% lx: unique x (in first layer, y approx 0)
% We use tolerance for unique determination to match seed generation
mask_x = abs(all_seeds_3d(2,:)) < tol & abs(all_seeds_3d(3,:)) < tol;
lx = numel(uniquetol(all_seeds_3d(1,mask_x), tol));

% ly: unique y
mask_y = abs(all_seeds_3d(1,:)) < tol & abs(all_seeds_3d(3,:)) < tol;
ly = numel(uniquetol(all_seeds_3d(2,mask_y), tol));

% lz: unique z
mask_z = abs(all_seeds_3d(1,:)) < tol & abs(all_seeds_3d(2,:)) < tol;
lz = numel(uniquetol(all_seeds_3d(3,mask_z), tol));

% Verify we have a perfect grid
if lx*ly*lz ~= size(all_seeds_3d, 2)
    warning('Node count mismatch: Expected %d (lx*ly*lz), got %d. Mesh connectivity may be invalid due to irregular grid.', lx*ly*lz, size(all_seeds_3d, 2));
    % Fallback: Try to infer correct lx/ly if possible or error out
end

[X_grid, Y_grid, Z_grid] = ndgrid(1:(lx-1), 1:(ly-1), 1:(lz-1));
idx_func = @(x, y, z) x + (y-1)*lx + (z-1)*lx*ly;

% Generate 8-node brick elements (C3D8)
elNodes = [
    reshape(idx_func(X_grid(:),   Y_grid(:),   Z_grid(:)),   1, []);
    reshape(idx_func(X_grid(:)+1, Y_grid(:),   Z_grid(:)),   1, []);
    reshape(idx_func(X_grid(:)+1, Y_grid(:)+1, Z_grid(:)),   1, []);
    reshape(idx_func(X_grid(:),   Y_grid(:)+1, Z_grid(:)),   1, []);
    reshape(idx_func(X_grid(:),   Y_grid(:),   Z_grid(:)+1), 1, []);
    reshape(idx_func(X_grid(:)+1, Y_grid(:),   Z_grid(:)+1), 1, []);
    reshape(idx_func(X_grid(:)+1, Y_grid(:)+1, Z_grid(:)+1), 1, []);
    reshape(idx_func(X_grid(:),   Y_grid(:)+1, Z_grid(:)+1), 1, [])
];

%% 7. Material Assignment and Filtering

fprintf('Filtering elements and assigning materials...\n');

% Calculate element centers
num_elems = size(elNodes, 2);
el_centers = zeros(3, num_elems);
for i = 1:num_elems
    nodes = elNodes(:, i);
    el_centers(:, i) = mean(all_seeds_3d(:, nodes), 2);
end

matTypeRefs = zeros(num_elems, 1);
keep_elements = true(1, num_elems);

% Optimization: Pre-calculate bounding boxes for Z-polygons to speed up inpolygon
poly_bboxes = zeros(length(all_Z_polys), 4); % [minx maxx miny maxy]
for k = 1:length(all_Z_polys)
    p = all_Z_polys{k};
    poly_bboxes(k,:) = [min(p(:,1)), max(p(:,1)), min(p(:,2)), max(p(:,2))];
end

% Loop through layers and process elements
tol = 1e-8;
for i = 1:length(layers)
    layer = layers{i};
    z_min = layer_z_ranges(i, 1) - tol;
    z_max = layer_z_ranges(i, 2) + tol;
    
    % Find elements in this layer
    layer_elem_indices = find(el_centers(3,:) >= z_min & el_centers(3,:) <= z_max);
    
    if isempty(layer_elem_indices)
        continue;
    end
    
    if strcmp(layer.type, 'plate')
        % Solid plate: assign material, keep all
        matTypeRefs(layer_elem_indices) = layer.matTypeRefs;
        
    elseif strcmp(layer.type, 'honeycomb') || strcmp(layer.type, 'honeycomb_with_filler')
        
        % Get centers for this layer's elements
        centers_x = el_centers(1, layer_elem_indices);
        centers_y = el_centers(2, layer_elem_indices);
        
        is_inside_total = false(size(centers_x));
        
        % Check against all Z-polygons
        for k = 1:length(all_Z_polys)
            % Quick bbox check
            bbox = poly_bboxes(k,:);
            
            % Indices of points potentially inside this polygon
            pot_idx = find(centers_x >= bbox(1) & centers_x <= bbox(2) & ...
                           centers_y >= bbox(3) & centers_y <= bbox(4));
            
            if ~isempty(pot_idx)
                in = inpolygon(centers_x(pot_idx), centers_y(pot_idx), ...
                               all_Z_polys{k}(:,1), all_Z_polys{k}(:,2));
                is_inside_total(pot_idx(in)) = true;
            end
        end
        
        if strcmp(layer.type, 'honeycomb')
            % Keep only inside, delete outside
            keep_subset = is_inside_total;
            matTypeRefs(layer_elem_indices(keep_subset)) = layer.matTypeRefs;
            keep_elements(layer_elem_indices(~keep_subset)) = false;
            
        elseif strcmp(layer.type, 'honeycomb_with_filler')
             % Logic: 
            % The Z-shapes define the WALLS (Honeycomb).
            % The area outside Z-shapes defines the FILLER.
            
            % User Requirement:
            % layer.matTypeRefs now equals 2 (Filler ID)
            % Wall Material should be forced to 1 (Honeycomb ID)
            
            wall_mat = 1; % Forced Honeycomb ID
            
            % Inside Z-shape = Wall Material (Honeycomb = 1)
            matTypeRefs(layer_elem_indices(is_inside_total)) = wall_mat;
            
            % Outside Z-shape = Filler Material (Current Layer ID = 2)
            matTypeRefs(layer_elem_indices(~is_inside_total)) = layer.matTypeRefs;
        end
    end
end

% Filter output data
model.elNodes = elNodes(:, keep_elements);
model.matTypeRefs = matTypeRefs(keep_elements);

% Validate element geometry (detect zero-volume/degenerate elements)
fprintf('Validating element geometry...\n');
num_filtered = size(model.elNodes, 2);
dup_node = false(1, num_filtered);
zero_dim = false(1, num_filtered);
geom_tol = 1e-12;
for i = 1:num_filtered
    n = model.elNodes(:, i);
    if numel(unique(n)) < 8
        dup_node(i) = true;
        continue;
    end
    p = all_seeds_3d(:, n);
    if (max(p(1,:)) - min(p(1,:)) <= geom_tol) || ...
       (max(p(2,:)) - min(p(2,:)) <= geom_tol) || ...
       (max(p(3,:)) - min(p(3,:)) <= geom_tol)
        zero_dim(i) = true;
    end
end
bad_mask = dup_node | zero_dim;
if any(bad_mask)
    fprintf('  Found %d degenerate elements (dup nodes: %d, zero dim: %d).\n', ...
        sum(bad_mask), sum(dup_node), sum(zero_dim));
    error('Degenerate elements detected. Mesh generation needs adjustment before export.');
end

% Clean up unused nodes
fprintf('Cleaning up unused nodes...\n');
used_nodes = false(1, size(all_seeds_3d, 2));
used_nodes(model.elNodes(:)) = true;

old_to_new = zeros(1, size(all_seeds_3d, 2));
idx_map = find(used_nodes);
old_to_new(idx_map) = 1:length(idx_map);

model.nodePos = all_seeds_3d(:, used_nodes);
model.elNodes = old_to_new(model.elNodes);

% Metadata
model.nDims = 3;
model.nDofPerNode = 3;
model.elTypes{1}.name = 'C3D8';
model.elTypes{1}.paramsType = 0;
model.elTypeRefs = ones(length(model.elNodes(1,:)),1);

%% 8. Visualization (Single Periodic Cell)

fprintf('Visualizing single periodic cell...\n');
figure('Name', 'Single Cell Mesh', 'Color', 'w');
axis equal; xlabel('X (mm)'); ylabel('Y (mm)'); zlabel('Z (mm)');
view(3); grid on; hold on;

% 1. Re-calculate centroids for the final model elements to filter a single cell
num_final_elems = size(model.elNodes, 2);
final_centers = zeros(3, num_final_elems);
for i = 1:num_final_elems
    nodes = model.elNodes(:, i);
    final_centers(:, i) = mean(model.nodePos(:, nodes), 2);
end

% 2. Filter for a single supercell (0 <= x <= supercell_x, 0 <= y <= supercell_y)
% Ensure bounds are defined (from Section 4)
if ~exist('supercell_x', 'var')
    supercell_x = 2 * (geom.a + geom.a/2);
    supercell_y = 2 * (geom.a*sqrt(3)/2);
end

% Add a small tolerance for boundary inclusion
viz_tol = 1e-6;
cell_mask = final_centers(1,:) >= -viz_tol & final_centers(1,:) <= supercell_x + viz_tol & ...
            final_centers(2,:) >= -viz_tol & final_centers(2,:) <= supercell_y + viz_tol;

viz_elNodes = model.elNodes(:, cell_mask);
viz_matType = model.matTypeRefs(cell_mask);

if isempty(viz_elNodes)
    warning('No elements found in the single cell range. Plotting all elements instead.');
    viz_elNodes = model.elNodes;
    viz_matType = model.matTypeRefs;
end

% 3. Prepare patch data for the subset
vertices = model.nodePos';
hex_faces = [
    1 2 3 4; 5 6 7 8; % Bottom, Top
    1 2 6 5; 2 3 7 6; % Sides
    3 4 8 7; 4 1 5 8
];

num_viz_elems = size(viz_elNodes, 2);
elNodesT = viz_elNodes';

% Concatenate faces (handle empty case)
if num_viz_elems > 0
    faces_all = [
        elNodesT(:, hex_faces(1,:));
        elNodesT(:, hex_faces(2,:));
        elNodesT(:, hex_faces(3,:));
        elNodesT(:, hex_faces(4,:));
        elNodesT(:, hex_faces(5,:));
        elNodesT(:, hex_faces(6,:))
    ];
    
    % 4. Color setup
    % Replicate material ID for 6 faces per element
    element_colors = repmat(viz_matType, 6, 1);
    
    % 5. Plot with solid faces (Colored by Material)
    patch('Vertices', vertices, 'Faces', faces_all, ...
          'FaceVertexCData', element_colors, ...
          'FaceColor', 'flat', ...
          'EdgeColor', 'k', ...
          'EdgeAlpha', 0.1); % Low alpha for edges to reduce visual clutter
    
    % Custom Colormap:
    % 1=LightBlue (Honeycomb), 2=Yellow (Filler), >2=Distinct colors (Plates/Other)
    max_mat = max(model.matTypeRefs);
    custom_cmap = zeros(max_mat, 3);
    extra_colors = [
        0.70 0.70 0.70; % Gray
        0.90 0.40 0.40; % Red
        0.40 0.70 0.40; % Green
        0.40 0.60 0.90; % Blue
        0.90 0.60 0.20; % Orange
        0.80 0.50 0.80; % Purple
        0.50 0.80 0.80; % Cyan
        0.80 0.80 0.40; % Olive
        0.60 0.40 0.20; % Brown
        0.30 0.30 0.30  % Dark Gray
    ];
    
    for m = 1:max_mat
        if m == 1
            custom_cmap(m,:) = [0.6 0.8 1.0]; % Light Blue (Honeycomb)
        elseif m == 2
            custom_cmap(m,:) = [1.0 1.0 0.0]; % Yellow (Filler)
        else
            % Distinct colors for additional materials
            color_idx = mod(m-3, size(extra_colors, 1)) + 1;
            custom_cmap(m,:) = extra_colors(color_idx, :);
        end
    end
    
    if max_mat > 0
        colormap(custom_cmap);
        c = colorbar;
        c.Label.String = 'Material ID';
        c.Ticks = 1:max_mat;
    end
    title(sprintf('Single Supercell Visualization (%d Elements)', num_viz_elems));
end

num_elems = size(model.elNodes, 2);

end

function [model, num_elems] = generate_plate_only_mesh(geom, meshParams, domain, layers)
% generate_plate_only_mesh
% Uses a cubic grid for non-honeycomb stacks and assigns materials per layer.

fprintf('No honeycomb layers found. Using cubic grid mesh.\n');

% Sample size
X_sample = domain.total_x;
Y_sample = domain.total_y;
if isfield(domain, 'total_z') && ~isempty(domain.total_z)
    Z_sample = domain.total_z;
else
    Z_sample = sum(cellfun(@(L) L.thickness, layers));
end

% Mesh spacing
X_mesh = meshParams.X_mesh;
Y_mesh = meshParams.Y_mesh;
Z_mesh = meshParams.Z_mesh;

% Adjust Z mesh based on ply definition (use minimum ply thickness)
ply_thicknesses = cellfun(@(L) L.thickness / L.ply, layers);
if ~isempty(ply_thicknesses)
    Z_mesh = min(ply_thicknesses);
end

% Generate cubic mesh
X_cubic = X_sample;
Y_cubic = Y_sample;
Z_cubic = Z_sample;

X_nodePos = 0:X_mesh:X_cubic;
Y_nodePos = 0:Y_mesh:Y_cubic;
layer_thicknesses = cellfun(@(L) L.thickness, layers);
if isempty(Z_mesh) || ~isfinite(Z_mesh) || Z_mesh <= 0
    Z_mesh = min(layer_thicknesses);
end

% Build Z nodes using ply counts per layer
Z_nodePos = 0;
current_z = 0;
for i = 1:length(layers)
    t = layers{i}.thickness;
    ply = layers{i}.ply;
    if t <= 0
        continue;
    end
    if isempty(ply) || ~isfinite(ply) || ply <= 0
        ply = max(1, round(t / Z_mesh));
    end
    dz = t / ply;
    local = current_z + (1:ply) * dz;
    Z_nodePos = [Z_nodePos, local];
    current_z = current_z + t;
end
% Remove near-duplicate Z levels to avoid zero-thickness elements
Z_nodePos = unique(Z_nodePos);
Z_nodePos = sort(Z_nodePos);
z_tol = max(1e-9, Z_mesh * 1e-6);
keep_mask = [true, diff(Z_nodePos) > z_tol];
Z_nodePos = Z_nodePos(keep_mask);
% Ensure the top surface is included
if abs(Z_nodePos(end) - Z_cubic) > z_tol
    Z_nodePos = [Z_nodePos, Z_cubic];
end
if numel(Z_nodePos) < 2
    error('Z_nodePos has fewer than 2 levels. Check layer thicknesses and Z_mesh.');
end

lx = length(X_nodePos);
ly = length(Y_nodePos);
lz = length(Z_nodePos);

% 3D grids
[X, Y, Z] = ndgrid(X_nodePos, Y_nodePos, Z_nodePos);

% Node positions
model.nodePos = [X(:)'; Y(:)'; Z(:)'];

% Element nodes
[X, Y, Z] = ndgrid(1:(lx-1), 1:(ly-1), 1:(lz-1));
idx = @(x, y, z) x + (y-1)*lx + (z-1)*lx*ly;
model.elNodes = [reshape(idx(X(:), Y(:), Z(:)), 1, []);
                 reshape(idx(X(:)+1, Y(:), Z(:)), 1, []);
                 reshape(idx(X(:)+1, Y(:)+1, Z(:)), 1, []);
                 reshape(idx(X(:), Y(:)+1, Z(:)), 1, []);
                 reshape(idx(X(:), Y(:), Z(:)+1), 1, []);
                 reshape(idx(X(:)+1, Y(:), Z(:)+1), 1, []);
                 reshape(idx(X(:)+1, Y(:)+1, Z(:)+1), 1, []);
                 reshape(idx(X(:), Y(:)+1, Z(:)+1), 1, [])];

model.elTypes{1}.name = 'C3D8';
model.elTypes{1}.paramsType = 0;
model.nDims = 3;
model.nDofPerNode = 3;
model.elTypeRefs = ones(length(model.elNodes(1,:)),1);

% Assign materials by layer Z-ranges
num_elems = size(model.elNodes, 2);
matTypeRefs = zeros(num_elems, 1);

% Layer ranges
layer_z_ranges = zeros(length(layers), 2);
current_z = 0;
for i = 1:length(layers)
    layer_z_ranges(i, 1) = current_z;
    layer_z_ranges(i, 2) = current_z + layers{i}.thickness;
    current_z = layer_z_ranges(i, 2);
end

% Element centers
el_centers = zeros(3, num_elems);
for i = 1:num_elems
    nodes = model.elNodes(:, i);
    el_centers(:, i) = mean(model.nodePos(:, nodes), 2);
end

tol = 1e-8;
for i = 1:length(layers)
    z_min = layer_z_ranges(i, 1) - tol;
    z_max = layer_z_ranges(i, 2) + tol;
    in_layer = el_centers(3, :) >= z_min & el_centers(3, :) <= z_max;
    matTypeRefs(in_layer) = layers{i}.matTypeRefs;
end

model.matTypeRefs = matTypeRefs;
end
