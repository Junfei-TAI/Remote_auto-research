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
   - keep remote paths stable across iterations

5. **Run remotely**
   - prefer non-interactive commands
   - use `set -euo pipefail` where appropriate
   - monitor progress for long jobs unless the user asked for detached execution

6. **Handle outputs**
   - either download outputs locally or process them remotely
   - keep result naming tied to parameter sets or case IDs

7. **Iterate**
   - use logs/results to decide the next local patch
   - only expand to larger runs after one case is confirmed

## References

- SSH onboarding: `references/ssh_onboarding.md`
- SSH config template: `templates/ssh_config.example`
