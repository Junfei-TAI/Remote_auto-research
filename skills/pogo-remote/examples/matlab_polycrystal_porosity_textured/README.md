# Textured polycrystal / porosity-rich POGO example

This folder represents **Paradigm 2**: internally complex materials such as polycrystals, inclusions, and porosity-rich microstructures.

## What this example is for

Use this family when the main challenge is not the outer shape, but the **internal material topology**:
- grain orientations
- textured microstructures
- pores / LoF regions / inclusions
- region-based anisotropic material assignment

## Workflow map from the original code

The original `Readme.txt` pipeline is preserved as `source_Readme.txt` and can be summarized as:

1. generate textured Euler angles
2. convert / export orientation data
3. visualize texture data
4. create grain labels / region labels
5. assign Euler angles to element groups
6. build POGO input
7. solve POGO
8. post-process `.pogo-hist`
9. perform additional Python-side processing if needed

## Important correction: anisotropic material packing

The original `EA2pogoINP_2D_FCC_SSalloys_textured.m` contains an anisotropic material packing pattern that should be replaced by the **POGO-compatible lower-triangular packing used in the validated composite example**.

Use this packing pattern instead:

```matlab
model.matTypes{1,1}.paramValues = [D(1,1); D(1,2); D(2,2); ...
                                   D(1,3); D(2,3); D(3,3); ...
                                   D(1,6); D(2,6); D(3,6); D(6,6); ...
                                   D(1,5); D(2,5); D(3,5); D(6,5); D(5,5); ...
                                   D(1,4); D(2,4); D(3,4); D(6,4); D(5,4); D(4,4); ...
                                   rho; 0];
```

See `material_packing_reference.m`.

### Critical note
The `Cij` ordering here is **not the same as Bunge convention indexing**. Agents must not assume orientation-convention ordering and POGO parameter-packing ordering are interchangeable.

## How an agent should use this folder

- Treat the included files as a **workflow reference family**, not as a polished turnkey package.
- Reuse the pipeline structure:
  - orientation generation
  - grain/region labeling
  - region-to-material assignment
  - anisotropic material packing
  - POGO export
  - post-processing
- Prefer creating a cleaned working copy in the actual research directory rather than editing this folder directly.

## Cleaned example conventions used here

Where practical, the copied scripts have been cleaned to prefer:

- `script_dir`-relative MATLAB paths
- local `input_*` and `output_*` subfolders
- explicit warnings when required external helpers are still missing
- corrected anisotropic packing through `material_packing_reference.m`

The most important files to start from are:

- `TexturedPolycrystal_Porosity_Workflow_Skeleton.m`
- `EA2pogoINP_2D_FCC_SSalloys_textured.m`
- `material_packing_reference.m`

## Current limitations

Some external dependencies referenced by the original scripts are not bundled here in the current environment, so this family currently serves mainly as:
- a paradigm reference
- a source-workflow map
- a material-assignment template

When those external helper functions become available, this family can be upgraded into a fully runnable packaged example.
