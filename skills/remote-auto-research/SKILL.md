---
name: remote-auto-research
description: Use when an agent needs a reusable workflow for remote engineering or scientific research, especially local-debug/remote-run tasks over SSH, long-running compute jobs, MATLAB model generation, simulation pipelines, or iterative result-driven refinement. Choose general-code-remote for generic remote execution and pogo-remote for POGO simulation workflows.
---

# Remote Auto Research

This is an umbrella workflow.

## Routing

- Use **general-code-remote** when the task is mainly about running long or heavy code on a remote Linux server.
- Use **pogo-remote** when the task involves MATLAB model construction, `.pogo-inp` generation, POGO execution, simulation result retrieval, or simulation-specific post-processing.

## Global policy

- Prefer **local-debug, remote-run**.
- Never store or invent SSH secrets.
- First inspect whether SSH aliases/keys already exist locally.
- If SSH is not configured, follow the onboarding flow in `../general-code-remote/references/ssh_onboarding.md`.
- Keep the local working copy as the source of truth.
- Validate one representative case before scaling to batch execution.
- Treat remote compute as part of a closed research loop, not just a command runner:
  `local edit -> local syntax/smoke validation -> remote staging -> representative run -> remote post-process -> retrieve compact artifacts -> interpret -> scale`.
- Do not blindly download large raw artifacts. Prefer remote post-processing for multi-GB histories, fields, videos, checkpoints, and arrays; retrieve figures, CSV/JSON summaries, reports, and only the raw subset needed for debugging.
- Keep remote project directories stable and project-scoped. Create a dedicated remote root per research project rather than mixing runs in generic scratch directories.
- Make long jobs resumable. Use deterministic case directories, expected-output counts, logs, and skip-completed logic before launching a batch.
- Record enough metadata to reproduce the run: code commit or archive, parameters, remote path, command, expected outputs, and post-processing script.

## Remote simulation loop

For simulation-heavy research, use this default sequence:

1. **Plan the smallest credible case**
   - one geometry, one frequency/parameter set, one defect or baseline
   - define expected files and success criteria before running

2. **Generate and validate locally when practical**
   - syntax checks, unit tests, model summaries, geometry previews
   - if local runtime is unavailable, do a remote smoke run before scaling

3. **Stage remote inputs**
   - use `tar`/`scp` or `rsync`
   - include only required code/config/input data
   - preserve relative paths so post-processing scripts run unchanged

4. **Run representative remote case**
   - verify process starts, outputs are produced, and logs are meaningful
   - inspect one output before launching the full batch

5. **Scale with checkpointing**
   - skip cases with complete expected outputs
   - log per-case start/end/error status
   - avoid rerunning expensive completed cases

6. **Post-process where the data lives**
   - process large raw outputs on the remote host
   - retrieve compact artifacts for local git: tables, reports, figures, scripts

7. **Interpret before iterating**
   - update the analysis model, not just the simulation
   - if imaging or metrics are ambiguous, add simpler channel-level diagnostics before generating more raw data

## Artifact policy

- Commit source code, workflow scripts, model summaries, small tables, reports, and selected figures.
- Do not commit large generated binaries (`.pogo-hist`, `.pogo-field`, `.pogo-block`, giant arrays, raw videos).
- If a generated input is too large to commit, commit the generator workflow and summary instead.
- If a raw artifact is essential, document the remote path and retrieval command in the result report.

See `references/remote_simulation_artifact_management.md` for practical patterns.
