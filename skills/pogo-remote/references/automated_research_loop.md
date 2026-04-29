# Automated research loop for POGO studies

The goal is not just to run one simulation, but to create a reusable iteration loop.

## Phase 1: Problem framing
- restate the physics question
- identify the appropriate geometry/material paradigm
- identify the observable needed to answer the question

## Phase 2: Build a credible prototype
- choose the nearest example family
- modify the smallest number of components first
- run one debug case
- verify setup consistency

## Phase 3: Validate the pipeline
- confirm `.pogo-inp` generation
- confirm remote run stability
- confirm usable outputs
- confirm post-processing yields interpretable signals/metrics

## Phase 4: Decide next branch
After the first credible result, choose one branch:

### Branch A: Iterate the model
Use this if:
- geometry or internal topology looks wrong
- signal interpretation is not credible yet
- mesh/timestep/output choices need refinement

### Branch B: Expand the study
Use this if:
- one case is physically and numerically credible
- the pipeline is stable
- the next scientific question requires parameter sweeps or repeated runs

## Phase 5: Batch execution strategy
When scaling up:
- preserve deterministic filenames
- record parameter sets
- store compact summaries
- prefer remote post-processing when outputs are large
- avoid rerunning completed cases without reason

## Phase 6: Research-grade output
A useful automated loop should produce:
- reproducible scripts
- reusable remote commands
- validated figures/metrics
- clear next-step decisions
- a path from one case to a study campaign
