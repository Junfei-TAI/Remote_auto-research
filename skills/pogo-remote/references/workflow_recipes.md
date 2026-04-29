# POGO workflow recipes

These are reusable patterns for common simulation studies.

## Recipe 1: Baseline validation run
- choose one model
- no defect or one representative defect
- one excitation condition
- generate preview figures
- run remotely
- inspect whether signal arrival times and output structure are plausible

## Recipe 2: Pulse-echo defect study
- define one source/receiver location or one probe patch
- keep a healthy baseline case
- vary defect parameters one dimension at a time initially
- compare traces, envelopes, and reflection timing

## Recipe 3: Pitch-catch / through-transmission study
- define separate source and receiver locations
- verify path geometry visually
- compare transmitted and reflected information
- adapt post-processing to transmission loss, phase, or ToF metrics

## Recipe 4: Geometry iteration study
- keep material and signal settings fixed
- vary geometry while preserving naming conventions
- verify geometry and mesh quality every time before expensive runs

## Recipe 5: Batch parameter sweep
- only after at least one validated representative case
- make filenames parameter-encoded
- avoid recomputing completed cases
- store compact summaries in addition to raw outputs
