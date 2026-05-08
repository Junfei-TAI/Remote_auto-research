# Long-Running Remote Jobs

Use this reference for remote commands that may run for many minutes, hours, or days.

## Runner script requirements

A long-running batch runner should usually include:

```bash
#!/usr/bin/env bash
set -euo pipefail

for case_dir in runs/stage/*; do
  n=$(find "$case_dir" -maxdepth 1 -name '*.expected-output' | wc -l)
  if [ "$n" -ge "$EXPECTED" ]; then
    echo "[$(date -Is)] skip $case_dir ($n outputs)"
    continue
  fi
  echo "[$(date -Is)] run $case_dir"
  (cd "$case_dir" && ./run_case.sh)
  echo "[$(date -Is)] done $case_dir"
done
```

Adjust the output check to the real expected artifact type.

## Monitoring

Poll evidence, not hope:

```bash
pgrep -a <process-name> || true
tail -n 40 <batch>.log
find runs/<stage> -name '<expected-pattern>' | wc -l
du -sh runs/<stage> results/<stage>
```

For detached jobs:

```bash
nohup ./run_batch.sh >batch.nohup 2>&1 & echo $!
```

Store the PID only as a convenience; output counts and logs are stronger evidence.

## Failure handling

- If a command fails from network/sandbox access locally, rerun with proper escalation rather than changing the workflow.
- If the remote job fails, inspect the failing case log and leave partial outputs in place.
- Fix the local canonical script first, then restage.
- Rerun the same resumable batch runner; do not manually reimplement the loop in ad hoc shell unless necessary.

## Retrieval

For large outputs, run post-processing remotely and download compact artifacts first. Use raw output retrieval only for small representative debug subsets.
