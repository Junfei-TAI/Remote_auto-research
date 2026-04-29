# POGO model intake checklist

Use these questions to frame a new simulation task.

## Geometry
- 2D or 3D?
- Plate, layered plate, honeycomb sandwich, spar, pipe, rail, other?
- Physical dimensions?
- Symmetry or periodicity available?

## Materials
- Isotropic or anisotropic?
- Number of materials/layers?
- Elastic constants and density known?
- Any adhesive / filler / air-gap / delamination representation needed?

## Excitation and sensing
- Pulse-echo, pitch-catch, through-transmission, guided wave, array imaging?
- Center frequency?
- Number of cycles?
- Source/receiver geometry and placement?
- Which displacement/stress components matter?

## Defects / features
- No defect, one defect, or parameterized defect family?
- Defect type: void, notch, delamination, inclusion, crack surrogate, thickness loss?
- Which parameters vary: size, depth, orientation, count, position?

## Numerics
- Target mesh size or wavelength rule?
- Time step / end time requirements?
- Need absorbing boundaries or not?
- Need field output in addition to history traces?

## Study style
- One representative debug case?
- Batch sweep after validation?
- Local post-processing or remote post-processing?
