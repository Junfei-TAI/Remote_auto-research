# Remote Simulation Artifact Management

Use this reference when a remote research run may produce large binaries or long-running batch outputs.

## Source of truth

- Local repo is the source of truth for code, generators, post-processing scripts, and reports.
- Remote project root is the source of truth for large generated artifacts that are impractical to commit.
- Every report should state where the large remote data live and which script generated the compact results.

## Commit policy

Commit:
- source code and workflow scripts
- small configuration files
- generation summaries
- CSV/JSON tables
- selected figures
- result reports

Do not commit by default:
- raw histories, fields, checkpoints, block files
- generated `.pogo-inp` if too large
- large compressed arrays unless explicitly needed
- temporary logs from exploratory failed runs

## Remote directory pattern

Prefer a stable structure:

```text
<remote_root>/<project_name>/
  runs/<stage>/<case_id>/...
  results/<stage>/tables|figures|logs...
  docs/results/...
  scripts/...
```

Case IDs should encode the parameters needed to identify the run. Avoid spaces and ambiguous names.

## Retrieval pattern

1. Post-process on the remote server when raw outputs are large.
2. Archive compact outputs:
   ```bash
   tar -cf /tmp/project_stage_results.tar results/<stage> docs/results/<stage-report>.md
   ```
3. Download the archive and extract locally.
4. Commit compact artifacts, not raw data.

## Batch completion evidence

Before declaring a remote batch complete, verify:

- expected case directories exist
- expected output counts match the plan
- logs show completed runs, not just started processes
- post-processing scripts ran without errors
- compact artifacts were retrieved and opened/read locally

## Interrupted runs

Batch scripts should be restartable:

- skip cases with complete expected outputs
- log start and end times per case
- write enough context to diagnose which case failed
- never delete partial outputs automatically unless the user approves
