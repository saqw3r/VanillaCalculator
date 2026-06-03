# VanillaCalculator — Features Plan

## Legend

| Status | Meaning |
|---|---|
| ✅ | Implemented |
| 🔷 | In progress |
| ◻️ | Planned |
| ❌ | Removed / deprecated |

---

## 1. Calculator Engine

| Feature | Status | Notes |
|---|---|---|
| Addition (`+`) | ✅ | `src/lib/calculator.js` |
| Subtraction (`-`) | ✅ | |
| Multiplication (`*`) | ✅ | |
| Division (`/`) | ✅ | Throws on zero divisor |
| Percentage (`%`) | ✅ | `a * b / 100` |
| Exponentiation (`^`) | ✅ | `Math.pow(a, b)` |
| Square root (`√`) | ✅ | Unary; throws on negative input |
| Square (`x²`) | ✅ | Unary |
| Reciprocal (`1/x`) | ✅ | Unary; throws on zero |
| Sine (`sin`) | ✅ | Unary; radians |
| Cosine (`cos`) | ✅ | Unary; radians |
| Base‑10 log (`log`) | ✅ | Unary; throws on non‑positive |
| Input validation | ✅ | Type coercion, error propagation |
| Pure function, zero dependencies | ✅ | No HTTP, no DB, no side effects |

## 2. User Interface

| Feature | Status | Notes |
|---|---|---|
| Two‑line display (expression + value) | ✅ | `src/app/page.js` |
| Digit buttons (0–9) | ✅ | |
| Decimal point (`.`) | ✅ | |
| Negate (`±`) | ✅ | |
| Clear all (`C`) | ✅ | |
| Backspace (`⌫`) | ✅ | |
| Memory store / recall / clear / add / subtract (`MS`, `MR`, `MC`, `M+`, `M−`) | ✅ | |
| Scientific buttons (`sin`, `cos`, `log`, `√`, `x²`, `1/x`) | ✅ | |
| Keyboard support (digits, operators, Enter, Backspace, Escape) | ✅ | Ctrl/Alt/Meta filtered out |
| Pastel minimalistic design (60‑30‑10 rule) | ✅ | |
| Button press animation (scale + opacity) | ✅ | |
| Loading indicator (`...`) | ✅ | |
| Result replaces display after calculation | ✅ | |
| Mount‑guarded fetch (no state updates after unmount) | ✅ | |

## 3. API Layer

| Feature | Status | Notes |
|---|---|---|
| `POST /api/calculate` | ✅ | `src/app/api/calculate/route.js` |
| `GET /api/history` (last 100) | ✅ | `src/app/api/history/route.js` |
| `DELETE /api/history` (clear all) | ✅ | Returns 204 |
| Error responses (400) | ✅ | |
| DB persistence errors silently swallowed | ✅ | API stays up without a database |

## 4. Persistence

| Feature | Status | Notes |
|---|---|---|
| PostgreSQL via `pg` Pool | ✅ | `src/lib/db.js`, auto‑creates `calculations` table |
| File‑based JSON store | ✅ | `DB_MODE=file`, writes to `<sandbox>/calculations.json` |
| Skip mode (no persistence) | ✅ | `DB_MODE=skip`, all queries return `[]` |
| Configurable via `DB_MODE` env var | ✅ | |
| Configurable `SANDBOX_DIR` for file mode | ✅ | |

## 5. Sandbox Orchestration (`mysandbox`)

| Feature | Status | Notes |
|---|---|---|
| `create <name>` — background sandbox | ✅ | |
| `run <name>` — foreground sandbox (Ctrl+C) | ✅ | |
| `stop [name]` — stop one / all sandboxes | ✅ | |
| `list` — show running sandboxes | ✅ | Auto‑reaps orphaned sandboxes |
| `kill <name>` — stop & remove sandbox | ✅ | |
| `logs <name>` — tail sandbox logs | ✅ | |
| `db <name>` — open psql shell for sandbox | ✅ | |
| `install` — register in system PATH | ✅ | Symlink on Linux; `.cmd` + bash wrapper on Windows |
| `uninstall` — remove from system | ✅ | |
| `find_port` — auto‑select free port | ✅ | Uses `ss` (Linux) or `netstat` (Windows) |
| `safe_rm` — cross‑platform `rm -rf` | ✅ | Falls back to `cmd //c rmdir` on Windows |
| Interactive `resolve_db_mode` prompt | ✅ | File / container / install / skip |
| Tunnel support (ngrok + cloudflared) | ✅ | `start_tunnel` / `stop_tunnel` |
| Remote SSH execution (`MYSANDBOX_TARGET`) | ✅ | Forward commands via `ssh -t` |
| Config file support (`mysandbox.config`) | ✅ | |
| Docker / Podman detection | ✅ | |

## 6. Environment Specifications (`setup.sh`)

| Feature | Status | Notes |
|---|---|---|
| `check` — verify prerequisites | ✅ | Node ≥18, npm ≥8 |
| `doctor` — full system diagnostic | ✅ | |
| `install` — install system dependencies | ✅ | |
| `build` — `npm ci` + `npm run build` | ✅ | |
| `start` — start Next.js with env config | ✅ | |
| `compose-start` / `compose-stop` | ✅ | Docker / Podman compose lifecycle |
| `db-create` / `db-drop` | ✅ | PostgreSQL database management |
| Wizard mode (no args) | ✅ | Walks through prereqs → install → build → launch |
| Passthrough to `mysandbox` | ✅ | `run`/`create`/`stop`/`list`/`kill`/`logs` delegate |

## 7. Deployment

| Feature | Status | Notes |
|---|---|---|
| Dockerfile (multi‑stage) | ✅ | `node:22-alpine` |
| docker-compose.yml (app + postgres 18) | ✅ | With health checks, persistent volume |
| Direct CLI deployment (system PostgreSQL) | ✅ | |
| File‑based deployment (no database server) | ✅ | |
| ngrok tunnel | ✅ | Primary tunnel provider |
| cloudflared tunnel (fallback) | ✅ | Trycloudflare |
| Cross‑platform install (Linux, macOS, Windows) | ✅ | `mysandbox install` handles all three |
| `DEPLOY.md` documentation | ✅ | |

## 8. Testing

| Feature | Status | Notes |
|---|---|---|
| BATS test suite for `mysandbox` CLI | ✅ | `tests/mysandbox.bats` — 30 tests |
| `list` command tests | ✅ | 9 tests covering all states |
| `stop` / `kill` command tests | ✅ | Boundary and error cases |
| `logs` / `db` command tests | ✅ | Input validation |
| `install` / `uninstall` tests | ✅ | File creation, PATH updates |
| `usage` tests | ✅ | No args, unknown command |
| GitHub Actions / CI | ◻️ | Planned |
| Calculator engine unit tests | ◻️ | Planned |
| API route integration tests | ◻️ | Planned |
| UI component tests | ◻️ | Planned |

## 9. Planned / Future

| Feature | Status | Notes |
|---|---|---|
| History panel in UI | ◻️ | Browse past calculations |
| Dark mode toggle | ◻️ | |
| Responsive / mobile layout | ◻️ | |
| Decimal precision configuration | ◻️ | |
| Export history (CSV / JSON) | ◻️ | |
| Multi‑user sandbox isolation | ◻️ | |
| WebSocket live updates | ◻️ | |
| CI/CD pipeline | ◻️ | GitHub Actions |
