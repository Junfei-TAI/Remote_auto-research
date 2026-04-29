# POGO geometry and material paradigms

This guide classifies most POGO modeling tasks into three broad paradigms. An agent should classify the task first, because that determines how geometry should be built, how much of the code can be reused, and where the real modeling difficulty lies.

## Paradigm 1: Layered / sandwich / honeycomb-derived composite models

This is the paradigm best represented by the bundled multilayer composite demo.

### Typical characteristics
- plate-like or laminate-like geometry
- multiple through-thickness layers
- optional honeycomb-like or filler-like layers
- geometry complexity is moderate
- main modeling work is in the **layer stack definition** and related parameters

### What usually changes
- `layers` definition
- layer thicknesses
- whether a honeycomb-like layer exists
- honeycomb parameters such as pitch / wall thickness
- defect definitions
- excitation / receiver arrangement

### What usually stays reusable
- the overall script structure
- multilayer setup flow
- `generate_composite_mesh_func_v2.m` style mesh logic
- `.pogo-inp` export logic
- history-based post-processing pattern

### Recommended workflow
1. start from `MultilayerComposite_PulseEcho_Demo.m` or `Validated_Config2_PulseEcho_WorkingExample.m`
2. modify `layers` and geometry parameters first
3. update defect logic if needed
4. preview and validate geometry/sensor placement
5. run one case
6. only then expand to many defects/frequencies/configurations

## Paradigm 2: Microstructure / polycrystal / inclusion / porosity-rich models

This is the most complex material-definition paradigm.

### Typical characteristics
- geometry may be externally simple, but the **internal material topology** is complex
- multiple grains, inclusions, pores, voids, or custom embedded regions
- the hard part is often **internal domain generation**, not just outer geometry
- may require random generation, imported maps, masks, Voronoi-style partitions, or explicit region definitions

### What usually changes
- the region-generation logic itself
- grain / inclusion / pore placement and parameterization
- material assignment by region membership
- possibly meshing and element labeling strategies

### Modeling mindset
Think of this as:
- define an outer domain
- generate internal subregions or features
- assign materials / voids / defects to those subregions
- validate region topology visually and numerically
- then export to POGO

### Required checks
Because this is the most failure-prone paradigm, always verify:
- region membership logic
- non-overlap or intended overlap rules
- pore / inclusion volume fraction or count
- whether region edges are resolvable by the mesh
- whether the resulting material map matches the intended microstructure

### Recommended workflow
1. restate clearly what the internal structure must represent
2. identify whether the internal structure is:
   - deterministic
   - stochastic
   - image/map driven
   - explicitly coordinate defined
3. build or inspect the internal-feature generator first
4. create a geometry/material preview before full simulation
5. keep one representative small case for early debug
6. only scale to larger domains or many random realizations after validation

### Bundled reference family
Use:
- `examples/matlab_polycrystal_porosity_textured/README.md`
- `examples/matlab_polycrystal_porosity_textured/TexturedPolycrystal_Porosity_Workflow_Skeleton.m`
- `examples/matlab_polycrystal_porosity_textured/EA2pogoINP_2D_FCC_SSalloys_textured.m`
- `examples/matlab_polycrystal_porosity_textured/material_packing_reference.m`

The included family captures the workflow structure and the corrected anisotropic POGO material-packing pattern.

### Note
The currently bundled family comes from the local `POGO-example` workspace. Some original external dependencies referenced by that source are still not bundled here, so the family is presently a strong reference scaffold rather than a guaranteed self-contained turnkey example.

## Paradigm 3: Simple material, complex geometry

This paradigm covers cases where the material model is easy, but the shape is hard.

### Typical characteristics
- homogeneous isotropic or anisotropic material is sufficient
- geometry is irregular, custom, or parameter-rich
- difficulty lies in defining the shape and meshing it correctly

### Recommended input strategy
Prefer one of these two geometry-definition routes:

1. **Explicit vertex route**
   - the user provides vertices / boundary coordinates / contour points / surfaces
   - the agent organizes them into a consistent coordinate system

2. **Parametric route**
   - the user provides dimensions, radii, angles, offsets, periodicity, thicknesses, etc.
   - the agent converts them into a vertex/edge/surface representation

### Mandatory process for this paradigm
1. summarize the spatial coordinate system explicitly
2. derive or reconstruct the geometry vertices / boundaries / surfaces
3. visualize the geometry for confirmation
4. decide whether structured or unstructured meshing is more appropriate
5. inspect mesh quality before continuing
6. only then proceed to excitation, output, and remote execution

### Meshing strategy guidance
- prefer **structured meshing** when the domain is grid-friendly and regular enough
- prefer **unstructured or custom meshing logic** when the geometry has irregular boundaries or local geometric features
- if no helper exists, the agent should search the available toolbox/scripts for reusable geometry or meshing utilities before writing new logic from scratch

### Required checks
- vertex order and connectivity are consistent
- no self-intersections unless intentional
- geometry dimensions match the intended design
- mesh resolves small features
- element quality is acceptable for stable simulation

### Bundled reference family
Use:
- `examples/matlab_complex_geometry_skeleton/ComplexGeometry_2D_Polygon_Skeleton.m`
- `examples/matlab_complex_geometry_skeleton/build_parametric_polygon_demo.m`
- `examples/matlab_complex_geometry_skeleton/polygon_quad_mesh_from_grid.m`

## Quick classification heuristic

Use this quick triage:

- If the main question is “what is the stack / layer / honeycomb configuration?”
  - use **Paradigm 1**

- If the main question is “how do we represent grains / pores / inclusions / internal heterogeneity?”
  - use **Paradigm 2**

- If the main question is “how do we define and mesh this complicated shape?”
  - use **Paradigm 3**

## Cross-paradigm rule

Always identify the hardest modeling layer first:
- outer geometry
- internal topology
- material assignment
- excitation/sensing
- post-processing target

Then build the workflow around that bottleneck, not around the easiest part.
