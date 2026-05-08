---
name: general-code-remote
description: Use when code should be edited and minimally validated locally, then uploaded and executed on a remote Linux server over SSH because the workload is long-running, compute-heavy, or dependent on remote software/hardware. This skill must not store personal SSH settings; it should first check for usable SSH aliases/keys and otherwise start a user-guided setup flow.
---

# General Code Remote

Use this for **non-POGO** or generic remote execution tasks.

## SSH policy

Never store the user's private SSH configuration in this skill.

Instead:
1. check whether usable SSH config/aliases already exist locally
2. if yes, use them
3. if no, start the setup flow in `references/ssh_onboarding.md`

You may inspect:
- `~/.ssh/config`
- available private keys in `~/.ssh/`
- whether the remote host is reachable

Do not expose private key contents in logs or summaries.

## Workflow

1. **Intake**
   - identify local source files
   - identify expected outputs
   - identify remote target directory and runtime command
   - identify whether results should be processed remotely or downloaded locally
   - estimate raw artifact size and decide retrieval policy before running

2. **Patch locally**
   - keep local changes minimal
   - create a backup for fragile scripts if needed
   - reduce the workload to one representative case where practical

3. **Validate locally**
   - syntax check, lint, unit test, or small smoke test if available
   - if the needed runtime is not installed locally, state the fallback and continue with remote execution

4. **Stage remotely**
   - use `scp` for a few files
   - use `rsync` for directories or repeated iteration
   - use `tar` when preserving relative paths and many small files is simpler than recursive copy
   - keep remote paths stable across iterations
   - stage into a project-specific remote root, not a shared scratch pile

5. **Run remotely**
   - prefer non-interactive commands
   - use `set -euo pipefail` where appropriate
   - monitor progress for long jobs unless the user asked for detached execution
   - for batches, write a small runner that logs per-case status and skips cases whose expected outputs already exist

6. **Handle outputs**
   - either download outputs locally or process them remotely
   - keep result naming tied to parameter sets or case IDs
   - process large outputs remotely and download compact artifacts first: CSV/JSON tables, figures, reports, logs
   - download raw outputs only when needed for debugging or user-requested archival

7. **Iterate**
   - use logs/results to decide the next local patch
   - only expand to larger runs after one case is confirmed

## Long-running job pattern

Use this pattern when a command may run for minutes to days:

1. Create a deterministic case directory and expected-output list.
2. Run one case interactively until the first meaningful output appears.
3. For the batch, create a runner script with:
   - `set -euo pipefail`
   - per-case logging with timestamps
   - skip-completed checks
   - clear final output counts
4. Start detached only if continued monitoring is not required:
   - `nohup ./run_batch.sh >batch.nohup 2>&1 & echo $!`
5. Poll by evidence, not assumptions:
   - process list
   - log tail
   - expected output counts
   - file sizes and modification times
6. If interrupted, rerun the same batch runner; it should skip completed cases.

## Remote post-processing pattern

For large remote outputs:

- copy post-processing scripts to the same remote project root
- run syntax checks remotely before processing
- write compact outputs under a stable `results/...` tree
- archive compact outputs with `tar` and download that archive
- keep large intermediate arrays remote unless explicitly needed locally

Good retrieval targets:
- `results/**/tables/*.csv`
- `results/**/figures/*.png`
- `docs/results/*.md`
- small logs and summaries

Avoid routine retrieval of:
- multi-GB binary outputs
- repeated raw histories/checkpoints
- full remote working directories

## References

- SSH onboarding: `references/ssh_onboarding.md`
- SSH config template: `templates/ssh_config.example`
- Long jobs: `references/long_running_remote_jobs.md`
