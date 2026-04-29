# SSH onboarding flow

Use this flow only when no usable SSH alias/key setup is available.

## Goal

Enable future agent tasks to use a short SSH alias without storing secrets inside the repo.

## Steps

1. Check whether `~/.ssh/config` already contains a suitable host alias.
2. Check whether a usable private key exists in `~/.ssh/`.
3. If no key exists, generate a dedicated SSH key pair locally.
4. Ask the user to install the public key on the target server, or automate it only if a secure approved path exists.
5. Add a **host alias** to `~/.ssh/config` using placeholders such as:
   - `Host <alias>`
   - `HostName <server-ip-or-name>`
   - `User <username>`
   - `Port 22`
   - `IdentityFile ~/.ssh/<keyname>`
6. Verify with a non-interactive SSH test.
7. Record only the alias name in summaries, not the secret material.

## Rules

- Never commit real SSH keys.
- Never copy a user's full `~/.ssh/config` into the repo.
- Never ask the user to paste private key contents into chat.
