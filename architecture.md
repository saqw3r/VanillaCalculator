# VanillaCalculator — Architecture

## Overview

VanillaCalculator is a full‑stack calculator application with an isolated pure‑function calculation engine, a Next.js frontend and API layer, pluggable persistence (PostgreSQL / file / skip), and a sandbox orchestration CLI for lifecycle management and deployment.

The project follows a **two‑layer toolchain** pattern:

```
┌──────────────────────────────────────────────────┐
│                  mysandbox                       │
│  Sandbox orchestrator (create / run / stop /    │
│  kill / list / logs / install / uninstall)      │
│  Calls setup.sh for environment tasks           │
└──────────┬───────────────────────────────────────┘
           │ delegates build / start / compose / db
           ▼
┌──────────────────────────────────────────────────┐
│                  setup.sh                        │
│  Environment specifications (build / install /  │
│  check / doctor / start / compose / db cmds)    │
│  Stack‑specific; can be rewritten per team      │
└──────────────────────────────────────────────────┘
```

- **`setup.sh`** contains all stack‑specific knowledge (prerequisites, build, start, compose, DB commands).
- **`mysandbox`** orchestrates sandbox lifecycle by calling `setup.sh` subcommands. The end user runs only `mysandbox`.
- Switching stacks (e.g. from Next.js to another framework) requires rewriting only `setup.sh`.

---

## Layer Architecture

```
                    ┌─────────────┐
                    │   Browser   │  React SPA
                    │  page.js    │  (client‑side)
                    └──────┬──────┘
                           │ fetch() POST /api/calculate
                           │        GET|DELETE /api/history
                    ┌──────▼──────┐
                    │  Next.js    │  Server (App Router)
                    │ API Routes  │
                    └──────┬──────┘
                           │ calculate(a, b, op)
                    ┌──────▼──────┐
                    │ calculator  │  Pure math engine
                    │  .js        │  (zero deps)
                    └──────┬──────┘
                           │ result / error
                    ┌──────▼──────┐
                    │  db.js      │  Persistence layer
                    │             │
        ┌───────────┼─────────────┼───────────┐
        │           │             │           │
   ┌────▼────┐ ┌────▼────┐ ┌────▼────┐  ┌────▼────┐
   │PostgreSQL│ │  File   │ │  Skip   │  │ (future)│
   │   pg    │ │  JSON   │ │  no‑op  │  │         │
   │  pool   │ │  store  │ │         │  │         │
   └─────────┘ └─────────┘ └─────────┘  └─────────┘
```

---

## Component Details

### 1. Calculator Engine (`src/lib/calculator.js`)

A pure function `calculate(num1, num2, operation)` that performs all math logic. It has zero dependencies — no HTTP, no database, no I/O. Every call with the same arguments produces the same result.

**Operations (13):**
- Binary: `+`, `-`, `*`, `/`, `%`, `^`
- Unary: `√`, `x²`, `x⁻¹`, `sin`, `cos`, `log`

**Error handling:**
- Division by zero → throws `"Division by zero"`
- Square root of negative → throws `"Cannot calculate square root of negative number"`
- Log of non‑positive → throws `"Cannot calculate logarithm of non‑positive number"`
- Invalid operation string → throws `"Invalid operation"`
- Missing operand → throws `"Missing operands"`

### 2. UI (`src/app/page.js`)

Single client‑side React component (`'use client'`). All calculations are sent to the server — no client‑side evaluation.

**State variables:**
- `a` — first operand (string for incremental digit input)
- `op` — pending operator
- `b` — second operand
- `r` — result (null until calculated)
- `mem` — memory value (null when empty)
- `loading` — fetch in progress

**Design:**
- Warm cream/beige palette (`#FCF8F4`, `#FFFCF8`)
- 310px wide, centred vertically and horizontally
- Soft shadows, rounded 10px buttons
- `.93` scale press animation
- Inline CSS via `<style>` tag — no external CSS files

**Keyboard:** digits `0–9`, `.`, `Enter`/`=`, `Backspace`, `Escape`/`Delete`, all operators (`+`, `-`, `*`, `/`, `%`, `^`). Ctrl/Alt/Meta combinations are filtered out.

### 3. API Routes

**`POST /api/calculate`** — Accepts `{ num1, num2, operation }`, delegates to `calculate()`, persists the request and result/error to the database via `query()`, returns `{ result }` or `{ error }` with status 400.

**`GET /api/history`** — Returns last 100 calculations ordered by `created_at DESC`.

**`DELETE /api/history`** — Clears all history, returns 204 No Content.

All routes gracefully handle database unavailability by returning empty results or swallowing errors.

### 4. Persistence (`src/lib/db.js`)

Three modes controlled by `DB_MODE` env var:

| Mode | Description |
|---|---|
| `postgres` (default) | Connects via `pg` Pool using `DATABASE_URL`. Auto‑creates `calculations` table on first connect. |
| `file` | Stores calculations in `<SANDBOX_DIR>/calculations.json`. Simulates basic SQL operations (INSERT, SELECT LIMIT, DELETE). |
| `skip` | All queries return `{ rows: [] }`. No persistence. |

The `query(sql, params)` function abstracts all three modes behind a single interface. The `file` mode reads/writes a JSON file atomically.

### 5. Sandbox Orchestrator (`mysandbox`)

A bash script (728 lines) that manages isolated sandbox instances. Each sandbox is a directory under `$SANDBOX_DIR/<name>/` containing:

```
<name>/
├── pid             # Next.js server process PID
├── port            # Assigned port number
├── db_port         # (container mode) PostgreSQL port
├── db_mode         # "postgres" | "file" | "skip" | "docker"
├── container_tool  # (container mode) "docker" | "podman"
├── tunnel_method   # "ngrok" | "cloudflared"
├── tunnel_url      # Public tunnel URL
├── tunnel_pid      # Tunnel process PID
├── output.log      # Server stdout/stderr
└── calculations.json  # (file mode only)
```

**Command flow:**

```
mysandbox create <name>
  ├── Reap stale sandbox (if exists)
  ├── build_api()        → setup.sh build (if needed)
  ├── resolve_db_mode()  → interactive prompt (or existing file)
  ├── cli_start_api()    → setup.sh start <port> <db_mode> <sandbox>
  │   or docker_start_api() → setup.sh compose-start ...
  ├── Wait for server (curl polling, 15s timeout)
  ├── start_tunnel()     → ngrok (primary), cloudflared (fallback)
  └── print_info()       → URL, store path, DB connection string

mysandbox kill <name>
  ├── cli_cleanup() / docker_cleanup()
  │   ├── stop_tunnel()  → kill tunnel_pid
  │   ├── cli_stop_api() → kill pid; sleep 1
  │   │   or docker_stop_api() → setup.sh compose-stop ...
  │   └── safe_rm()      → rm -rf sandbox directory
  └── echo "removed"
```

**Tunnel resolution order:** ngrok → cloudflared. First available wins. Tunnel URL is written to `tunnel_url` and `tunnel_method` files.

**Remote mode:** When `MYSANDBOX_TARGET=ssh://user@host` is set, the script forwards all commands via SSH. It ensures the repo exists on the remote (auto‑clone if `MYSANDBOX_REPO_URL` is set) and `exec`s into an interactive SSH session.

### 6. Environment Specifications (`setup.sh`)

Standalone bash script (384 lines) providing environment setup tasks. Called by `mysandbox` for build, start, compose, and DB operations, and can also be used directly as an entry point for new users.

| Command | Purpose | Called by |
|---|---|---|
| `check` | Verify Node.js and npm versions | User directly |
| `doctor` | Full system diagnostic | User directly |
| `install` | Install system dependencies | User directly |
| `build` | `npm ci && npm run build` | `mysandbox build_api()` |
| `start` | `nohup npx next start -p <port>` | `mysandbox cli_start_api()` |
| `compose-start` | `docker/podman compose up -d` | `mysandbox docker_start_api()` |
| `compose-stop` | `docker/podman compose down -v` | `mysandbox docker_stop_api()` |
| `db-create` | Create PostgreSQL database | `mysandbox resolve_db_mode()` |
| `db-drop` | Drop PostgreSQL database | `mysandbox cli_drop_db()` |

The wizard mode (no arguments) walks through: prerequisites → install → build → launch.

### 7. Windows Support

- **`mysandbox.cmd`** — Bootstrap `.cmd` shim at repo root. Finds Git Bash and runs `bash mysandbox <args>`. Windows‑native shells (cmd.exe, PowerShell) resolve it via `PATHEXT`.
- **`mysandbox install`** — Generates two shims in `~/.local/bin/`:
  - `mysandbox.cmd` — for cmd.exe / PowerShell
  - `mysandbox` — bash wrapper for Git Bash
  - Adds `~/.local/bin` to `PATH` in shell rc file (or creates `~/.bash_profile` if none exists)
- **`safe_rm`** — Cross‑platform directory removal. Tries `rm -rf` first; falls back to `cmd //c rmdir` on Windows.

---

## Data Flow

### Calculation Request

```
1. User presses "5" → display shows "5"
2. User presses "+"     → stores "5" as a, sets op="+"
3. User presses "3"     → display shows "3" (b)
4. User presses "="     → fetch(POST /api/calculate, {num1:5, num2:3, operation:"+"})
                          └─ API route:
                               ├─ calculate(5, 3, "+") → 8
                               └─ query("INSERT INTO calculations ...", [5, 3, "+", 8, null])
5. Display shows "8"    → sets r=8
```

### History Request

```
User opens history panel → fetch(GET /api/history)
                            └─ API route:
                                 └─ query("SELECT * FROM calculations ORDER BY created_at DESC LIMIT 100")
                                      └─ Returns JSON array of calculations
```

---

## Testing

The test suite uses **BATS** (Bash Automated Testing System) and covers the `mysandbox` CLI:

```bash
# Run full suite
npm test
# or: npx bats tests/mysandbox.bats

# Filter by command
npx bats --filter list tests/mysandbox.bats
npx bats --filter kill tests/mysandbox.bats
```

**Test design principles:**
- No background processes needed — `$$` (current shell PID) is used for `kill -0` checks
- Temporary `SANDBOX_DIR` with mock sandbox files replaces real sandbox directories
- `HOME` is overridden for install/uninstall tests
- Config files override `SANDBOX_DIR` and other variables
- Each test is isolated via `setup`/`teardown`

---

## File Map

```
.
├── mysandbox              # Sandbox orchestration CLI (728 lines)
├── mysandbox.cmd          # Windows bootstrap shim
├── setup.sh               # Environment specifications (384 lines)
├── package.json           # Next.js project config + test scripts
├── next.config.mjs        # Next.js configuration
├── Dockerfile             # Multi‑stage production build
├── docker-compose.yml     # App + PostgreSQL 18 services
├── DEPLOY.md              # Deployment documentation
├── features_plan.md       # Feature list with status
├── architecture.md        # This file
├── public/
│   └── favicon.svg        # SVG favicon
├── src/
│   ├── app/
│   │   ├── layout.js      # Root layout (metadata, favicon)
│   │   ├── page.js        # Calculator UI (React, 400+ lines)
│   │   └── api/
│   │       ├── calculate/route.js   # POST /api/calculate
│   │       └── history/route.js     # GET|DELETE /api/history
│   └── lib/
│       ├── calculator.js  # Pure math engine
│       └── db.js          # Persistence layer (3 modes)
└── tests/
    ├── mysandbox.bats     # CLI test suite (30 tests)
    └── simple_test.sh     # Smoke test helper
```
