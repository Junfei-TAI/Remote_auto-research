---
name: pogo-remote
description: Use when a task involves general POGO simulation work: MATLAB-based model construction, geometry/material/excitation setup, consistency checks, headless remote generation of `.pogo-inp`, remote POGO execution, retrieval or remote processing of `.pogo-hist`/`.pogo-field`, and iterative or batch simulation studies. Prefer local model editing and validation before remote execution.
---

# POGO Remote

Use this for **general simulation workflows**, not just one demo geometry.

## Mission

Turn a research question into a repeatable POGO workflow:
- understand what must be modeled
- prepare or adapt MATLAB model code
- verify model consistency
- generate `.pogo-inp`
- run POGO remotely
- post-process outputs
- decide whether to iterate or scale to batch runs

## Intake before modeling

Before writing or modifying a MATLAB model, clarify as many of these as possible:

- 2D or 3D
- geometry type
- layer structure / material system
- excitation type
- frequency / cycle count / waveform
- mesh scale or target resolution
- defect presence, type, count, and parameterization
- outputs of interest (`hist`, `field`, ToF, amplitudes, imaging metrics, etc.)
- whether this is a one-off debug run or a batch study

If the user leaves some details unspecified, propose a reasonable modeling plan and proceed.

## Workflow

1. **Model locally first**
   - use a local working copy as canonical
   - keep early iterations small and inspectable
   - prefer one representative case first

2. **Consistency check**
   - use built-in plots or lightweight visualization when available
   - compare geometry, defect placement, excitation location, and receiver placement against the intended physics
   - if the user is deeply involved, ask for confirmation on ambiguous setups
   - in autonomous research mode, self-check and continue

3. **Generate `.pogo-inp`**
   - do it locally if MATLAB is available and practical
   - otherwise run headless on the remote server
   - for headless Linux MATLAB, prefer:
     `QT_QPA_PLATFORM=offscreen matlab -batch ...`

4. **Run POGO remotely**
   - create or reuse `run_pogo.sh`
   - run block generation and solve stages
   - verify expected outputs exist

5. **Post-process**
   - process remotely or download locally depending on data size and tooling
   - prepare scripts around the actual physics question, not just generic plots
   - use results to decide iteration vs. batch expansion

6. **Scale only after validation**
   - once one case is confirmed, expand to multiple defects / frequencies / geometries / parameter sweeps

## How to use the bundled code

Do not treat the example files as fixed end-user deliverables. Treat them as **starting templates**.

### File selection guide

- If you need a **general starting point for layered composite pulse-echo modeling**:
  - start with `examples/matlab_multilayer_composite/MultilayerComposite_PulseEcho_Demo.m`

- If you need a **known-good, previously validated working example** before generalizing:
  - inspect `examples/matlab_multilayer_composite/Validated_Config2_PulseEcho_WorkingExample.m`

- If you need a **workflow reference for textured polycrystal / porosity-rich / inclusion-rich modeling**:
  - inspect `examples/matlab_polycrystal_porosity_textured/README.md`
  - start from `examples/matlab_polycrystal_porosity_textured/TexturedPolycrystal_Porosity_Workflow_Skeleton.m` for a cleaned paradigm-2 entrypoint
  - then inspect `examples/matlab_polycrystal_porosity_textured/EA2pogoINP_2D_FCC_SSalloys_textured.m`
  - use `examples/matlab_polycrystal_porosity_textured/material_packing_reference.m` for corrected anisotropic POGO packing
  - **Note:** this family is a strong reference scaffold for workflow structure and material packing patterns, not a guaranteed self-contained turnkey example — some external dependencies (Neper output, texture-specific preprocessing) may need to be supplied

- If you need a **starting skeleton for complex geometry with simple material behavior**:
  - start with `examples/matlab_complex_geometry_skeleton/ComplexGeometry_2D_Polygon_Skeleton.m`
  - inspect `build_parametric_polygon_demo.m` and `polygon_quad_mesh_from_grid.m`

- If you need the **mesh generation logic** for multilayer composite models:
  - inspect `examples/matlab_multilayer_composite/toolbox/generate_composite_mesh_func_v2.m`

- If you need to **write a `.pogo-inp` file**:
  - use `examples/matlab_multilayer_composite/toolbox/savePogoInp.m`
  - keep its helper `examples/matlab_multilayer_composite/toolbox/stringSaveTidy.m`

- If you need to **generate excitation time-base signals**:
  - use `examples/matlab_multilayer_composite/toolbox/tbgeneration.m`

- If you need to **read `.pogo-hist` output**:
  - use `examples/matlab_multilayer_composite/toolbox/loadPogoHist.m`

- If you need a **starter post-processing script**:
  - start from `examples/matlab_multilayer_composite/postprocess/PostProcess_PulseEcho_Hist_Demo.m`

- If you need the **standard remote solver script**:
  - copy or generate `assets/run_pogo.sh` in the remote run directory

### Tool map

- `MultilayerComposite_PulseEcho_Demo.m`
  - generic scaffold
  - best for adaptation to new research questions

- `Validated_Config2_PulseEcho_WorkingExample.m`
  - reference case that already reflects a real successful run pattern
  - best for checking “what a working full script looks like”

- `matlab_polycrystal_porosity_textured/`
  - paradigm-2 reference family for internally complex materials
  - best for workflow structure, grain/region assignment logic, and corrected anisotropic material packing guidance

- `matlab_complex_geometry_skeleton/`
  - paradigm-3 starter family for geometry-first modeling
  - best for vertex/parameter definition, geometry preview, and simple mesh-sanity workflow

- `toolbox/generate_composite_mesh_func_v2.m`
  - main mesh builder for the multilayer composite example
  - useful when geometry or layer representation must change

- `toolbox/savePogoInp.m`
  - serializes a MATLAB model struct into a POGO input file

- `toolbox/loadPogoHist.m`
  - reads POGO history output for signal analysis

- `toolbox/plot3DOutline.m`, `toolbox/getElCents.m`, `toolbox/genGrid3D.m`
  - geometry inspection and helper utilities

- `postprocess/PostProcess_PulseEcho_Hist_Demo.m`
  - minimal history-processing starter
  - extend it to match the physics question

## Assembly workflow for agents

When starting a new POGO task, use this sequence:

1. Choose the nearest example family.
   - For layered composites, start from `matlab_multilayer_composite/`.

2. Copy the example script into the user’s actual working directory.
   - Do not repeatedly mutate the repo example in place unless the user explicitly wants the example itself updated.

3. Edit the copied script around these blocks:
   - geometry
   - layer stack
   - material assignment
   - excitation and receivers
   - defect parameterization
   - output controls

4. Ensure helper paths are available.
   - add the script directory
   - add the local toolbox subdirectory if using bundled helpers

5. Reduce to a debug-scale run first.
   - one case
   - one defect
   - one excitation condition
   - limited parameter sweep

6. Generate preview plots or setup figures if possible.
   - use them to catch geometry or sensor-placement mistakes early

7. Only after the model is credible, generate `.pogo-inp` and run remotely.

## How to map a research question to code edits

Use this mental mapping:

- **Change geometry family**
  - first classify the geometry/modeling problem into one of the three paradigms in `references/pogo_geometry_paradigms.md`
  - start by replacing or rewriting the geometry/layer-definition section
  - may require updates inside the mesh-generation helper

- **Change from no-defect to defect study**
  - edit the defect list / defect parameterization section
  - keep one defect first, then expand

- **Change pulse-echo to pitch-catch or through-transmission**
  - mostly edit generator/receiver definitions
  - then update post-processing logic accordingly

- **Change frequency or cycles**
  - edit excitation generation parameters
  - reconsider mesh size and timestep if the wavelength changes substantially

- **Change material system**
  - update material tensors/properties
  - confirm layer/material indexing remains consistent

- **Need field output rather than only history traces**
  - adjust the model/output settings before export
  - prefer remote post-processing if field files become very large

- **Need batch studies**
  - only after one case is validated
  - expand loops over defects, frequencies, thicknesses, or geometries
  - keep filenames deterministic and parameter-encoded

## Consistency-check expectations

Before calling the model “ready”, check:

- geometry dimensions match the intent
- defect coordinates are physically plausible
- source and receiver locations match the experiment or research concept
- mesh size is consistent with the target frequency/wavelength
- timestep and endtime are adequate for the propagation path
- output type matches the question being asked

If the model has visualization code, use it. If it does not, add a minimal preview figure or numerical sanity checks.

## Post-processing guidance

Do not stop at successful solver completion.

After a run, decide whether to:

- download `.pogo-hist` and process locally
- keep `.pogo-field` remote and post-process there
- generate summary figures/metrics for iteration

Choose post-processing based on the physics question:

- time traces
- envelopes
- time-of-flight
- reflection amplitude
- defect imaging / maps
- field snapshots or movies

The included post-processing demo is only a starter, not a full analysis framework.

## Included resources

- `assets/run_pogo.sh` — standard remote runner template
- `references/pogo_model_intake.md` — modeling checklist
- `references/pogo_geometry_paradigms.md` — three major geometry/material modeling paradigms
- `examples/matlab_multilayer_composite/` — sanitized multilayer composite example with helper functions and post-processing starter scripts
- `references/pogo_adaptation_guide.md` — detailed guidance on choosing and adapting the bundled example files
- `references/workflow_recipes.md` — common simulation workflow recipes
- `references/postprocess_patterns.md` — common post-processing patterns
- `references/automated_research_loop.md` — iteration, validation, and scale-up strategy
