---
description: Run a generic SSH-based local-debug/remote-run workflow for long-running code.
---

Use the **general-code-remote** workflow for this task.

User request:
$ARGUMENTS

Instructions:
- Patch locally first.
- Validate locally if possible.
- Upload to the remote server over SSH.
- Run remotely with non-interactive commands.
- Download or remotely process outputs.
- Never store SSH secrets; first inspect whether SSH config already exists.
