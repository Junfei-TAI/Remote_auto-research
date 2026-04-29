---
description: Run a POGO-focused remote simulation workflow with local MATLAB/model iteration and remote execution.
---

Use the **pogo-remote** workflow for this task.

User request:
$ARGUMENTS

Instructions:
- First classify the modeling problem:
  1. layered / sandwich / honeycomb-derived composite
  2. polycrystal / porosity / inclusion-rich internal topology
  3. simple material but complex geometry
- Choose the nearest bundled example family.
- Copy the example into the working directory rather than editing the repo example directly.
- Add consistency checks and preview plots before full runs.
- Run one representative case before any batch expansion.
- Use corrected POGO anisotropic packing, not a naive stiffness-matrix reshape.
