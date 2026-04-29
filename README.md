# Remote_auto-research

Reusable agent workflows for **remote engineering/scientific research**.

This repo is designed around one default strategy:

- **debug locally**
- **run heavy/long jobs remotely**
- **pull back or process results remotely**
- **iterate the model/code**

It currently provides two reusable modules:

1. **general-code-remote** — for long-running remote code execution over SSH
2. **pogo-remote** — for MATLAB → POGO simulation workflows

## Security principle

This repo must **never** store personal SSH secrets, API keys, host passwords, or your actual `~/.ssh/config`.

Agents using these workflows should:

- first check whether usable SSH configuration already exists locally
- if not, enter a user-guided SSH setup flow
- use placeholders/templates only inside this repo

## Suggested layout

- `skills/remote-auto-research/` — umbrella skill
- `skills/general-code-remote/` — generic SSH remote-run workflow
- `skills/pogo-remote/` — POGO-specific workflow and examples

## Typical usage

### General remote job

- patch locally
- validate locally if possible
- stage files to server
- run remotely with SSH
- fetch or remotely post-process outputs

### POGO job

- confirm model intent with the user or by autonomous intake
- build/debug MATLAB model locally
- generate `.pogo-inp` locally or remotely
- run `run_pogo.sh` remotely
- post-process `.pogo-hist` / `.pogo-field`
- expand to batch runs only after one case is validated

## Notes

- Example MATLAB/POGO code in this repo is intended as a **sanitized starting point**, not a fixed model.
- Keep large generated artifacts (`.pogo-inp`, `.pogo-hist`, `.pogo-field`, figures, temp files) out of git.
