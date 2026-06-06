# VanillaCalculator

A full‑stack calculator with an isolated math engine, Next.js frontend, pluggable persistence, and a sandbox CLI for lifecycle management.

## Quick Start

```bash
# Clone and enter
git clone <repo> && cd VanillaCalculator

# Install & register mysandbox in PATH
sudo ./mysandbox install        # Linux/macOS
# or: bash mysandbox install     # if not executable

# Start a sandbox (interactive prompts you for storage mode)
mysandbox run mybox

# Open in browser
open http://127.0.0.1:<port>
```

## Commands

| Command | Description |
|---|---|
| `mysandbox run <name>` | Start sandbox in foreground (Ctrl+C to stop) |
| `mysandbox create <name>` | Create & start sandbox in background |
| `mysandbox stop [name]` | Stop one sandbox, or all if no name |
| `mysandbox list` | List running sandboxes |
| `mysandbox kill <name>` | Stop & permanently remove a sandbox |
| `mysandbox logs <name>` | Tail sandbox logs |
| `mysandbox db <name>` | Open psql shell for a sandbox |
| `mysandbox install` | Register mysandbox in PATH |
| `mysandbox uninstall` | Remove mysandbox from system |

## Storage Modes

When creating a sandbox, you choose how data is persisted:

- **1) File-based** — zero setup, persists to a local JSON file
- **2) Container mode** — runs PostgreSQL in Docker/Podman
- **3) PostgreSQL** — uses an existing system PostgreSQL installation
- **s) Skip** — run without persistence (volatile)

## Examples

```bash
# Create a sandbox named "demo" in background
mysandbox create demo

# Check its status
mysandbox list

# Run one in foreground with an auto‑assigned tunnel URL
mysandbox run staging

# Tail logs
mysandbox logs demo

# Drop into a psql shell
mysandbox db demo

# Stop and remove
mysandbox kill demo
```

## Architecture

The project follows a two‑layer toolchain:

```
mysandbox          — sandbox orchestrator (CLI)
    └─ calls ── setup.sh   — environment specs (build, start, DB)
```

`setup.sh` contains all stack‑specific knowledge. Switching frameworks means rewriting only `setup.sh` — `mysandbox` stays the same.

## Cross‑Platform

Windows, Linux, macOS. On Windows, Git Bash or WSL is required — `mysandbox install` generates `.cmd` shims for cmd.exe and PowerShell.
