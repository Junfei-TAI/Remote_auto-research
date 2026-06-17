# POGO post-processing patterns

Choose the post-processing pattern based on the research question.

## History-trace focused
Use when the question is about:
- arrival time
- reflection timing
- amplitude change
- waveform shape
- envelope comparison

Typical outputs:
- time traces
- Hilbert envelopes
- normalized comparisons
- ToF estimates
- defect-vs-baseline overlays

## Field-data focused
Use when the question is about:
- wave propagation patterns
- mode conversion
- spatial localization
- energy distribution
- snapshots or movies

Typical outputs:
- selected time snapshots
- peak field maps
- animated propagation sequences
- spatial ROI summaries
- ParaView-readable `.xdmf` + `.bin` wavefield exports

For large 2D/3D fields, prefer headless remote conversion rather than GUI export.
Use `pogoMatlabTools-master/visual/export_pogo_field_xdmf.m` (with `loadSave/` on the MATLAB path) to convert `.pogo-field` to a temporal
XDMF dataset. If `model.fieldStoreNodes` was used, the converter exports a
sampled-node `Polyvertex` point cloud with displacement vector and magnitude.
Do not attach the original full element connectivity to a sampled-node field:
many elements will reference nodes that were not saved.

## Imaging / mapping focused
Use when the question is about:
- defect localization
- area/depth mapping
- C-scan-like summaries
- parameter maps

Typical outputs:
- depth maps
- amplitude maps
- reconstructed imaging metrics
- defect ranking tables

## Remote vs local choice
- prefer local for modest `.pogo-hist` analyses and interactive plotting
- prefer remote for very large `.pogo-field` workflows or heavy batch aggregation
- keep multi-GB `.pogo-field` files on the remote host and export compact or
  visualization-ready derivatives there first

## Agent rule
Post-processing should produce not just figures but also a decision:
- validate model
- revise model
- expand batch
- change metric

Before claiming a ParaView export is usable, check:
- the XDMF references non-empty `.bin` files
- point coordinate min/max match expected geometry units and bounds
- vector arrays are written in row-major XDMF order, not MATLAB column-major
  order
