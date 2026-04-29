# POGO adaptation guide

This guide tells an agent how to turn the bundled example files into a task-specific simulation workflow.

## 1. Pick the right starting file

### Use `MultilayerComposite_PulseEcho_Demo.m` when:
- the user wants a new layered-composite model
- the geometry is similar in spirit but not identical to any previous study
- you need a cleaner, more generic scaffold

### Use `Validated_Config2_PulseEcho_WorkingExample.m` when:
- you want a reference for a script that already follows a successful end-to-end pattern
- you suspect a problem in your generalized script and want to compare against a known working arrangement
- you need to recover a working file layout, output definition, or export pattern quickly

### Use `matlab_polycrystal_porosity_textured/` when:
- the problem is dominated by grain orientations, porosity, inclusions, or internal region assignment
- you need a paradigm-2 workflow map rather than just an outer-geometry template
- you need the corrected anisotropic POGO material packing reference

### Use `matlab_complex_geometry_skeleton/` when:
- the outer geometry is the difficult part
- the material is comparatively simple
- you need a geometry-preview and mesh-sanity skeleton before full model specialization

## 1b. First classify the modeling paradigm

Before editing files, classify the task using `pogo_geometry_paradigms.md`:

- layered / sandwich / honeycomb-derived composite
- microstructure / porosity / inclusion-rich material
- simple material but complex geometry

This determines whether the hardest part is:
- layer/material definition
- internal topology generation
- geometric reconstruction and meshing

## 2. Understand the file roles

### Main scripts
- main scripts should define:
  - study mode / case selection
  - geometry
  - materials
  - excitation and receivers
  - export options

### Toolbox files
- `generate_composite_mesh_func_v2.m`
  - adjust only if the geometry abstraction itself must change
  - avoid touching it for simple parameter changes

- `savePogoInp.m`
  - normally do not edit unless file-format behavior itself is wrong

- `loadPogoHist.m`
  - use in post-processing, not model generation

- helper plotting/utilities
  - use to inspect geometry or derive element/node information

## 3. Prefer parameter edits over deep rewrites

Change the smallest layer first:

1. scalar parameters
2. layer definitions
3. excitation/receiver definitions
4. defect parameterization
5. post-processing logic
6. mesh helper internals only if necessary

## 4. A recommended edit order

For a new study, edit in this order:

1. rename run base name
2. set geometry dimensions
3. define layer stack
4. set mesh resolution
5. define defects or remove defects
6. define source/receiver layout
7. set frequency / cycles / time window
8. define outputs
9. add preview plots or checks
10. run one debug case

If the task falls under the complex-geometry paradigm, insert these steps before meshing:
- derive explicit vertices/boundaries/surfaces
- visualize geometry
- decide structured vs unstructured meshing
- inspect mesh quality

## 5. Single-case first policy

Before any sweep or batch:
- reduce loops to one case
- reduce defects to one representative defect or no defect baseline
- reduce output volume if possible
- confirm `.pogo-inp` generation and one full remote run

Then expand.

## 6. When to process remotely vs. locally

### Prefer local processing when:
- only `.pogo-hist` is needed
- files are moderate in size
- local MATLAB or analysis tools are available
- interactive figure inspection is useful

### Prefer remote processing when:
- `.pogo-field` files are very large
- repeated batch processing is needed
- remote compute/storage is much stronger than local
- only compact summary outputs need to be downloaded

## 7. Common adaptation patterns

### Pattern A: baseline model only
- remove or disable defect logic
- keep one clean source/receiver path
- validate arrival times and signal form

### Pattern B: defect sensitivity study
- keep geometry fixed
- vary defect parameters in a controlled loop
- preserve a healthy/baseline case for comparison

### Pattern C: excitation study
- keep geometry fixed
- vary frequency, cycles, source type, or transducer size
- revisit mesh and timestep suitability after each major frequency change

### Pattern D: geometry study
- geometry changes first
- then rebuild defect logic and post-processing expectations
- expect more mesh-helper changes than in other study types

## 8. What an agent should report back

After each meaningful iteration, summarize:
- which file was used as the starting point
- which parameters/blocks were changed
- where the job ran
- what artifacts were produced
- whether the result supports iteration or batch expansion
