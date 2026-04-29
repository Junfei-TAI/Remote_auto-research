---
description: Run a remote engineering/scientific research workflow with local-debug/remote-run strategy.
---

Use the **remote-auto-research** subagent workflow for this task.

User request:
$ARGUMENTS

Instructions:
- Route to `general-code-remote` for generic remote execution tasks.
- Route to `pogo-remote` for MATLAB/POGO simulation tasks.
- Prefer local-debug, remote-run.
- Never assume or invent SSH credentials.
- First check whether usable SSH aliases/keys already exist locally.
- Validate one representative case before batch expansion.
