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

## Agent rule
Post-processing should produce not just figures but also a decision:
- validate model
- revise model
- expand batch
- change metric
