---
name: boxd-setup-hermes
description: Install the Hermes agent (Nous Research) — a self-improving CLI agent with a built-in messaging gateway (Telegram/Discord/Slack/WhatsApp/Signal) — inside a boxd VM from your laptop via `boxd machine exec`, using Hermes' official installer (which clones the repo and installs all deps), then hand off the interactive `hermes setup` + `hermes` over SSH. Use when the user says "set up Hermes", "install hermes-agent on a boxd VM", "install the Nous Hermes agent", "spin up Hermes on boxd", or mentions NousResearch/hermes-agent. For the in-VM version (you're already on the VM), use the in-VM `boxd-setup-hermes` skill instead.
---

# boxd-setup-hermes

Installs the **Hermes agent** (Nous Research) inside a boxd VM, then hands the
interactive setup + run back to you over SSH. Hermes is a self-improving CLI agent
with a built-in messaging gateway. Repo: https://github.com/NousResearch/hermes-agent

This runs from your **laptop** and operates on the VM via `boxd machine exec`. If you're
already on the box, use the in-VM `boxd-setup-hermes` skill instead.

## Prerequisites

- `boxd` CLI installed and authenticated (`boxd auth` succeeds).
- A target VM — reuse an existing one, or this skill creates a fresh one.

## What the installer does

`https://hermes-agent.nousresearch.com/install.sh` is Hermes' supported install
path (there's no separate "clone + run a repo setup script" flow — the installer
*is* it). It clones the repo to `~/.hermes/hermes-agent`, installs Python 3.11 (via
`uv`), Node 22, ripgrep, ffmpeg and Playwright Chromium, drops a `hermes` wrapper
at `~/.local/bin/hermes`, and adds `~/.local/bin` to PATH in `~/.bashrc`.

## Workflow

1. **Pick or create the VM.**
   ```bash
   boxd ls --json | jq -r '.[].name'          # reuse one, or:
   boxd new hermes --json              # ~2s
   ```

2. **Install Hermes inside it.** The installer is interactive by default, and
   `boxd machine exec` runs a non-interactive shell with **no TTY** — so
   pass `--non-interactive`. It's a multi-minute install (Python + Node + a
   Chromium download), so **background the call and tail it** instead of blocking:
   ```bash
   boxd machine exec <vm> -- 'curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --non-interactive'
   ```
   Invoke this with the Bash tool's background mode and poll the output file — a
   foregrounded `boxd machine exec` buffers everything until it exits, so a 3-minute
   install looks frozen. Don't pipe it through `tail`/`grep` at the top level
   (same buffering trap).

3. **Verify `hermes` installed.** The wrapper lands at `~/.local/bin/hermes`; use a
   login shell so `~/.bashrc` (PATH) is picked up:
   ```bash
   boxd machine exec <vm> -- 'bash -lc "hermes --version"'
   ```

4. **Hand off to an interactive SSH session.** `hermes setup` asks for an LLM
   provider + API key and `hermes` is interactive — neither belongs in `boxd machine exec`.
   Give the user:
   ```bash
   ssh <vm>.boxd            # the boxd client daemon keeps this ssh alias in sync
   #   then, inside the VM:
   hermes setup             # pick a provider, paste an API key   (or: hermes setup --portal)
   hermes                   # start the agent
   ```

5. **Report:** the VM name, the SSH command, and that `hermes setup` + `hermes` are
   the user's next (interactive) steps. Undo: `boxd machine remove <vm> -y` (only if this
   skill created the VM).

## boxd machine exec caveats (the ones that bite here)

- **Background long execs; never foreground them.** `boxd machine exec` streams stdout
  live, but the foreground Bash tool buffers it until exit. Use background mode +
  poll the output file.
- **Stdin is forwarded, but there's no TTY.** `boxd machine exec` does forward stdin
  when stdin isn't a terminal, so a pipe/heredoc reaches the remote command. What it
  can't give you is a *terminal* — prompts that read from `/dev/tty` or re-prompt on
  bad input still won't work. That's why we install with `--non-interactive` and do
  the interactive `hermes setup` over SSH.
- **Non-interactive shell.** Verify with `bash -lc "…"` so `~/.bashrc` (PATH to
  `~/.local/bin`) is loaded, or call `~/.local/bin/hermes` by full path.

## Optional: expose the messaging gateway

If the user wants Hermes' always-on gateway (messaging + cron) reachable on the
VM's public URL, install it with Hermes' own command and point the proxy at it:
```bash
boxd machine exec <vm> -- 'bash -lc "hermes gateway install"'   # managed gateway service
boxd machine proxy set-port --vm=<vm> --port=<gateway-port>
```
Most users just want the interactive `hermes` CLI — skip this unless asked.

> **Always-on means turning the idle timers off.** A machine goes to standby or
> hibernates after its timeout passes with no network traffic in either direction.
> CPU work, disk work and local timers don't count, and the machine's own DNS, NTP
> and DHCP traffic is ignored. A hibernated machine wakes only on a new connection
> through boxd (HTTPS or SSH, including over the org's tailnet, or
> `boxd machine exec`), not on a raw exposed port and not on its own cron jobs, so
> the gateway's cron stops while the machine sleeps. For a gateway that must stay up:
> `boxd machine config set <vm> auto-suspend.timeout 0` and
> `boxd machine config set <vm> auto-hibernate.timeout 0`.

> **Central secrets:** because the interactive `hermes` runs from the user's SSH
> login shell, it inherits any `boxd env set --secret` / `boxd env set` values — an API
> key set centrally is visible to it without pasting into `hermes setup`. The
> **managed gateway** above is a systemd service and does **not** see central
> vars; it uses the key from `hermes setup`.

## What this skill does NOT do

- Configure an LLM provider or store API keys — that's the user's `hermes setup`.
