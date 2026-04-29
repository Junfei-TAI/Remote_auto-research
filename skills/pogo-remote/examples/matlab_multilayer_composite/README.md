# Multilayer composite POGO MATLAB example

This folder contains a sanitized starting point for multilayer composite ultrasonic modeling.

## What it is

- a **3D layered composite** demo
- can be adapted to include or exclude honeycomb-like layers
- supports pulse-echo style workflows as a starting point
- includes basic helper functions for meshing, POGO input writing, excitation generation, plotting, and history loading

## What to customize

- layer stack and material definitions
- geometry dimensions
- mesh size
- excitation type / frequency / cycles
- defect parameterization
- post-processing objective

## Notes

- This is an example scaffold, not a universal final model.
- Keep one representative case for early debugging.
- Use headless MATLAB on remote servers when needed.
