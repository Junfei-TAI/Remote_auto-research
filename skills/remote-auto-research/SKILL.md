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
