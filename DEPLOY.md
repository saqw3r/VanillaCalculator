# Deploy Calculator

Two options: **Docker/Podman Compose** or **Direct (CLI)**.

## Configuration

Set once for all options:

```bash
export DOMAIN=calc.example.com          # your domain
export API_PORT=                        # leave empty for auto-select, or set e.g. 3000
```

---

## Option A: Docker/Podman Compose

Run the full stack (Next.js + PostgreSQL) using Docker Compose.

### 1. Build & run

```bash
cd /path/to/VanillaCalculator
docker compose up -d
# or: podman-compose up -d
```

- App listens on `http://127.0.0.1:3000` (both frontend and `/api/` routes)
- PostgreSQL on `localhost:5432`

### 2. Tunnel (ngrok or cloudflared)

```bash
# ngrok
ngrok http 3000

# cloudflared (quick tunnel)
cloudflared tunnel --url http://127.0.0.1:3000
```

Or with a permanent Cloudflare Tunnel config:

`~/.cloudflared/config.yml`:

```yaml
tunnel: <tunnel-id>
credentials-file: ~/.cloudflared/<tunnel-id>.json
ingress:
  - hostname: YOUR_DOMAIN
    service: http://localhost:3000
  - service: http_status:404
```

```bash
sudo systemctl restart cloudflared
```

### 3. Stop

```bash
docker compose down -v
```

---

## Option B: Direct (CLI mode)

Next.js runs directly, PostgreSQL installed on the system — no containers.

### 1. Install dependencies

```bash
sudo apt update && sudo apt install -y postgresql postgresql-client nodejs npm
```

### 2. Set up PostgreSQL

```bash
sudo -u postgres psql -c "CREATE USER calculator WITH PASSWORD 'calculator_pass';"
sudo -u postgres psql -c "CREATE DATABASE calculator OWNER calculator;"
```

### 3. Build & run

```bash
cd /path/to/VanillaCalculator
npm install
npm run build

# Use a specific port, or leave empty for auto-select
if [ -n "$API_PORT" ]; then
  DATABASE_URL="postgres://calculator:calculator_pass@localhost:5432/calculator" \
  npm start -- -p "$API_PORT"
else
  DATABASE_URL="postgres://calculator:calculator_pass@localhost:5432/calculator" \
  npm start
fi
```

Or run as a systemd service with a fixed port:

Create `/etc/systemd/system/calculator.service` (set `YOUR_PORT`):

```ini
[Unit]
Description=Calculator
After=network.target postgresql.service

[Service]
WorkingDirectory=/path/to/VanillaCalculator
ExecStart=/usr/bin/npx next start -p YOUR_PORT
Restart=always
RestartSec=5
Environment=PORT=YOUR_PORT
Environment=DATABASE_URL=postgres://calculator:calculator_pass@localhost:5432/calculator
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now calculator
```

### 4. Tunnel (ngrok or cloudflared)

Replace `YOUR_PORT` with the port the app is running on:

```bash
# ngrok
ngrok http YOUR_PORT

# cloudflared (quick tunnel)
cloudflared tunnel --url http://127.0.0.1:YOUR_PORT
```

Or with a permanent Cloudflare Tunnel config:

`~/.cloudflared/config.yml`:

```yaml
tunnel: <tunnel-id>
credentials-file: ~/.cloudflared/<tunnel-id>.json
ingress:
  - hostname: YOUR_DOMAIN
    service: http://127.0.0.1:YOUR_PORT
  - service: http_status:404
```

```bash
sudo systemctl restart cloudflared
```

---

## Verify

Open `https://YOUR_DOMAIN` in a browser. Try `2 + 3 =` — the result should appear.

API health check:

```bash
curl https://YOUR_DOMAIN/api/history
```

---

## Sandbox CLI

`mysandbox` manages isolated sandbox environments for development and testing.

### Config & Remote execution

`mysandbox` reads configuration from three locations (first found wins):

1. `$MYSANDBOX_CONFIG` — explicit path via environment variable
2. `./mysandbox.config` — config file in the project root
3. `~/.mysandbox.config` — user-level config file

Example config:

```bash
# Run everything on a remote machine via SSH with auto-clone
MYSANDBOX_TARGET="ssh://user@192.168.1.100"
MYSANDBOX_SSH_KEY="/home/user/.ssh/id_rsa"
MYSANDBOX_REMOTE_DIR="/home/user/VanillaCalculator"
MYSANDBOX_REPO_URL="https://github.com/youruser/VanillaCalculator.git"
MYSANDBOX_MODE="cli"

# Or run locally with Docker
# MYSANDBOX_TARGET=""
# MYSANDBOX_MODE="docker"
```

When `MYSANDBOX_TARGET` is set to an `ssh://` URL, all `mysandbox` commands are forwarded to the remote machine via SSH. The remote machine must have:
- SSH key-based authentication configured
- If `MYSANDBOX_REPO_URL` is **set**: the repo is auto-cloned/pulled on every run
- If **not set**: the project must already be cloned at `MYSANDBOX_REMOTE_DIR`

The `SANDBOX_URL` is printed in the output regardless of whether running locally or remotely.

### Modes

Set via the `MYSANDBOX_MODE` environment variable:

| Mode | Value | PostgreSQL | API runtime | Cleanup |
|---|---|---|---|---|
| **CLI** (default) | `cli` | system Postgres (apt) | `npx next start` | kills process, drops DB, removes files |
| **Docker** | `docker` | `postgres:18-alpine` container | `app` container (from `Dockerfile`) | `docker compose -p <name> down -v` |

```bash
# Use Docker mode for a session
export MYSANDBOX_MODE=docker

# Or inline
MYSANDBOX_MODE=docker mysandbox create demo
```

### Commands

| Command | Description |
|---|---|
| `mysandbox run <name>` | Start sandbox in foreground with public tunnel URL (ngrok or cloudflared). Ctrl+C to stop and clean up |
| `mysandbox create <name>` | Start sandbox in background |
| `mysandbox stop [name]` | Stop one sandbox by name, or stop **all** sandboxes when called without a name |
| `mysandbox kill <name>` | Alias for `stop <name>` — stop & remove a single sandbox |
| `mysandbox list` | List all sandboxes with status, port, PID, and public URL |
| `mysandbox logs <name>` | Tail the API output log |
| `mysandbox db <name>` | Open `psql` shell connected to the sandbox database |
| `mysandbox install` | Register `mysandbox` in the system PATH |
| `mysandbox uninstall` | Remove `mysandbox` from the system |

### Tunnel providers

Tried in order — the first available one that produces a public URL wins:

1. **ngrok** (`ngrok http <port>`) — URL parsed from `http://127.0.0.1:4040/api/tunnels` via Python (up to 20s)
2. **cloudflared** (`cloudflared tunnel --url`) — URL grepped from output for `*.trycloudflare.com` (up to 15s)

The method and URL are stored in the sandbox directory (`/tmp/mysandbox/<name>/tunnel_method`, `tunnel_url`) and printed as:

```
  Public URL (ngrok): https://abc123.ngrok-free.app
  SANDBOX_URL=https://abc123.ngrok-free.app
```

### Examples

```bash
# ── CLI mode (default) ──

# Foreground sandbox (Ctrl+C to stop)
mysandbox run demo
# Sandbox 'demo' starting...
#   API  http://127.0.0.1:8090
#   Public URL (ngrok): https://abc123.ngrok-free.app
#   SANDBOX_URL=https://abc123.ngrok-free.app
#
# Press Ctrl+C to stop the sandbox and clean up.

# Background sandbox
mysandbox create test1
# Sandbox 'test1' is live.
#   API  http://127.0.0.1:8091
#   Public URL (cloudflared): https://xyz789.trycloudflare.com
#   SANDBOX_URL=https://xyz789.trycloudflare.com

# Stop all sandboxes
mysandbox stop

# ── Docker mode ──

MYSANDBOX_MODE=docker mysandbox create test2
MYSANDBOX_MODE=docker mysandbox list
MYSANDBOX_MODE=docker mysandbox stop test2
```

### Sandbox lifecycle

| Step | CLI mode | Docker mode |
|---|---|---|
| Build | `npm run build` (once) | `docker compose build` |
| Database | `CREATE DATABASE calculator_<name>` | Docker container `postgres:18-alpine` |
| API start | `npx next start` on free port | `docker compose -p <name> up -d` |
| Tunnel | `ngrok http <port>` (fallback: `cloudflared tunnel --url`) | same |
| Stop / kill | kill process → drop database → remove `/tmp/mysandbox/<name>/` | `docker compose -p <name> down -v` → remove sandbox directory |
| `stop` (no name) | iterates all sandboxes in `/tmp/mysandbox/`, cleans each | iterates all Docker Compose projects, brings each down |

---

## Installation (all platforms)

### Linux / macOS / ARM (bash)

```bash
# From the project directory:
./mysandbox install

# Or manually:
sudo ln -s "$(pwd)/mysandbox" /usr/local/bin/mysandbox
```

`install` creates a **symlink** (`/usr/local/bin/mysandbox` → `repo/mysandbox`). After install, you can run `mysandbox` from any directory — it resolves the symlink back to the repo root to find all project files. If `/usr/local/bin/` is not writable (no sudo), it falls back to `~/.local/bin/` and adds that to your shell `rc` file.

### Windows

Requires **Git Bash** (from [Git for Windows](https://git-scm.com)) or **WSL**.

**First-time install** — from the repo directory, run `mysandbox install`. The repo-root `mysandbox.cmd` finds Git Bash and bootstraps the install:

```shell
mysandbox install
```

This generates a hardcoded `.cmd` shim at `~/.local/bin/mysandbox.cmd` and adds `~/.local/bin` to `PATH`. After that, `mysandbox` works from any terminal.

If you only need to use it from the repo directory, no install is needed — `mysandbox.cmd` resolves `%~dp0mysandbox` to the bash script in the same folder.

### Uninstall

```bash
./mysandbox uninstall
# or: sudo rm /usr/local/bin/mysandbox
```
