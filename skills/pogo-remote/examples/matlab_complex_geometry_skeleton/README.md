# Complex geometry POGO skeleton

This folder represents **Paradigm 3**: simple material model, complex geometry.

Use it when the geometry definition and mesh strategy are the hard parts.

## Intent

This skeleton demonstrates a recommended sequence:
1. define geometry from vertices or parameters
2. visualize and confirm geometry
3. choose a meshing strategy
4. generate a simple mesh-compatible model region
5. check mesh quality/sanity
6. add excitation/receiver logic
7. export a POGO input file

## Current implementation

The included example uses a **2D polygon + structured background grid** approach:
- define or derive polygon vertices
- keep only cells whose centroids lie inside the polygon
- build a quadrilateral mesh from the surviving cells

This is not a universal solution, but it is a useful starting skeleton for irregular 2D domains.

## Files

- `ComplexGeometry_2D_Polygon_Skeleton.m` — main skeleton script
- `build_parametric_polygon_demo.m` — simple parametric geometry-to-vertices example
- `polygon_quad_mesh_from_grid.m` — structured-grid masking helper
