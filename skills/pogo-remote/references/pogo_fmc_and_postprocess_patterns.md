# POGO FMC and Post-Processing Patterns

Use this reference for phased-array, multi-shot, full-aperture, or imaging-style POGO studies.

## 2D vs 3D execution

Use the correct POGO command pair:

```bash
# 2D
pogoBlock model.pogo-inp
pogoSolve model.pogo-inp

# 3D
pogoBlockGreedy3d model.pogo-inp
pogoSolve3d model.pogo-inp
```

A generic runner should expose the dimension explicitly and default to the correct 2D pair for 2D studies.

## FMC in one input file

Pattern:

- define `model.shots{shot_idx}` for each transmit event
- keep receiver sets common across shots
- expect POGO to output one `.pogo-hist` per shot
- assemble post-processed data as `FMC[tx, rx, time]`

Record:

- shot names and source node counts
- receiver names and node counts
- active array coordinates
- expected number of `.pogo-hist` files

## Full-aperture elements

For realistic finite-width elements:

- TX: select all nodes on the element face; use equal force weights unless a physical apodization is specified
- RX: store all aperture nodes in the measurement set, then average or coherently combine in post-processing
- keep center-only receivers only as a diagnostic, not as a physical replacement for full-aperture measurement

Post-processing choices:

- equal mean of displacement traces: simple physical element average
- coherent sum: phase-sensitive and travel-time-sensitive
- L/C/R subsets: diagnostic for edge effects and aperture phase variation

## Calibration before imaging

Do not default to a single bulk velocity when delay lines, plates, layered media, or guided modes are involved.

Preferred sequence:

1. Run defect-free validation with reference receivers.
2. Pick arrival times for each physical segment.
3. Compare effective velocities against dispersion data or expected wave speeds.
4. Split the travel-time model by segment when necessary.
5. Use that calibration in TFM or other focusing algorithms.

If direct doubling of one-way picks does not match the reflected top echo, use the measured top echo as a round-trip anchor and apply geometric corrections only to the variable part of the path.

## Matched filtering

Use matched filtering when the excitation has many cycles or when raw A-scans are hard to compare.

Outputs to compare:

- raw signed trace
- envelope trace
- matched-filter signed trace
- matched-filter envelope trace

Long tonebursts improve frequency selectivity but reduce axial resolution. Matched filtering helps recover timing/contrast but does not fix a wrong travel-time model.

## Imaging fallback

If TFM gives broad blobs, gradients, or ambiguous contrast:

1. inspect diagonal `TX_i -> RX_i` A-scans
2. map time-window peak/energy versus element x-position
3. inspect signed matched-filter peak for polarity changes
4. compare pitch-catch maps by TX/RX offset
5. only then refine TFM, branch-selective TFM, or modal imaging

A-scan mapping is often more interpretable than TFM when array pitch is too large for the frequency, guided modes overlap, or the physical echo is not a single specular reflector.

## Large data handling

For multi-shot full-aperture histories:

- keep `.pogo-hist` remote
- run post-processing remotely
- retrieve compact CSV/PNG/MD artifacts
- save raw debug subsets only when needed
- avoid committing full FMC arrays unless they are small and central to later analysis
