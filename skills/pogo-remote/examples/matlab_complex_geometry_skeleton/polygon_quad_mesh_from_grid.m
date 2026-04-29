function model = polygon_quad_mesh_from_grid(vertices, dx, dy)
% Build a 2D quadrilateral mesh by masking a structured grid with a polygon.

xmin = min(vertices(:,1)); xmax = max(vertices(:,1));
ymin = min(vertices(:,2)); ymax = max(vertices(:,2));

x_nodes = xmin:dx:xmax;
y_nodes = ymin:dy:ymax;
[nx, ny] = deal(numel(x_nodes), numel(y_nodes));

[Xn, Yn] = meshgrid(x_nodes, y_nodes);
model.nodePos = [Xn(:)'; Yn(:)'];

elNodes = [];
for j = 1:ny-1
    for i = 1:nx-1
        n1 = i + (j-1)*nx;
        n2 = i + 1 + (j-1)*nx;
        n3 = i + 1 + j*nx;
        n4 = i + j*nx;
        xc = mean(model.nodePos(1,[n1 n2 n3 n4]));
        yc = mean(model.nodePos(2,[n1 n2 n3 n4]));
        inside = inpolygon(xc, yc, vertices(:,1), vertices(:,2));
        if inside
            elNodes(:, end+1) = [n1; n2; n3; n4]; %#ok<AGROW>
        end
    end
end

model.elNodes = elNodes;
model.elTypes{1}.name = 'CPE4R';
model.elTypes{1}.paramsType = 0;
model.elTypeRefs = ones(size(elNodes,2),1);
model.nDims = 2;
model.nDofPerNode = 2;
model.matTypeRefs = ones(size(elNodes,2),1);

used_nodes = unique(model.elNodes(:));
old_to_new = zeros(1, size(model.nodePos,2));
old_to_new(used_nodes) = 1:numel(used_nodes);
model.nodePos = model.nodePos(:, used_nodes);
model.elNodes = old_to_new(model.elNodes);
end
