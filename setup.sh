#!/usr/bin/env bash
set -euo pipefail

# ── VanillaCalculator Environment Specifications ──────────────────────────
# This file defines the environment requirements and setup procedures.
# It is called by mysandbox for build/setup tasks, and can also be used
# directly as an entry point for new users.

# Resolve script directory (same pattern as mysandbox)
script_path="${BASH_SOURCE[0]}"
while [ -L "$script_path" ]; do script_path="$(readlink "$script_path")"; done
SCRIPT_DIR="$(cd "$(dirname "$script_path")" && pwd)"

if [ ! -f "$SCRIPT_DIR/package.json" ]; then
  script_path="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || true)"
  [ -n "$script_path" ] && SCRIPT_DIR="$(cd "$(dirname "$script_path")" && pwd)"
fi
if [ ! -f "$SCRIPT_DIR/package.json" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

# ── Environment Specifications ─────────────────────────────────────────────

MIN_NODE="18.0.0"
MIN_NPM="8.0.0"

PROJECT_NAME="VanillaCalculator"
STACK="Node.js / Next.js"

# ── Helpers ─────────────────────────────────────────────────────────────────

version_ge() {
  local v1=$1 v2=$2
  while [ -n "$v1" ] || [ -n "$v2" ]; do
    local p1="${v1%%.*}" p2="${v2%%.*}"
    v1="${v1#*.}"; [ "$v1" = "$p1" ] && v1=""
    v2="${v2#*.}"; [ "$v2" = "$p2" ] && v2=""
    p1="${p1:-0}" p2="${p2:-0}"
    [ "$p1" -lt "$p2" ] && return 1
    [ "$p1" -gt "$p2" ] && return 0
  done
  return 0
}

# ── Command implementations ────────────────────────────────────────────────

check_prereqs() {
  local ok=true

  if command -v node &>/dev/null; then
    local node_ver
    node_ver=$(node --version | sed 's/^v//')
    if version_ge "$node_ver" "$MIN_NODE"; then
      echo "  node --version  v${node_ver}  (ok, need >=${MIN_NODE})"
    else
      echo "  node --version  v${node_ver}  (too old, need >=${MIN_NODE})" >&2
      ok=false
    fi
  else
    echo "  node  not found (need >=${MIN_NODE})" >&2
    echo "  Install: https://nodejs.org/en/download/" >&2
    ok=false
  fi

  if command -v npm &>/dev/null; then
    local npm_ver
    npm_ver=$(npm --version)
    if version_ge "$npm_ver" "$MIN_NPM"; then
      echo "  npm --version   v${npm_ver}  (ok, need >=${MIN_NPM})"
    else
      echo "  npm --version   v${npm_ver}  (too old, need >=${MIN_NPM})" >&2
      ok=false
    fi
  else
    echo "  npm  not found (need >=${MIN_NPM})" >&2
    echo "  Install with Node.js: https://nodejs.org/en/download/" >&2
    ok=false
  fi

  $ok
}

install_deps() {
  echo "  Installing dependencies..." >&2
  (cd "$SCRIPT_DIR" && npm ci)
  echo "  Dependencies installed." >&2
}

build_app() {
  echo "  Building application..." >&2
  (cd "$SCRIPT_DIR" && npm run build)
  echo "  Build complete." >&2
}

doctor() {
  echo "=== ${PROJECT_NAME} Environment Doctor ==="
  echo ""
  echo "Stack: ${STACK}"
  echo ""

  echo "-- Prerequisites --"

  if command -v node &>/dev/null; then
    local node_ver
    node_ver=$(node --version | sed 's/^v//')
    if version_ge "$node_ver" "$MIN_NODE"; then
      echo "  node     v${node_ver}  ok"
    else
      echo "  node     v${node_ver}  too old (need >=${MIN_NODE})" >&2
    fi
  else
    echo "  node     not found" >&2
  fi

  if command -v npm &>/dev/null; then
    local npm_ver
    npm_ver=$(npm --version)
    if version_ge "$npm_ver" "$MIN_NPM"; then
      echo "  npm      v${npm_ver}  ok"
    else
      echo "  npm      v${npm_ver}  too old (need >=${MIN_NPM})" >&2
    fi
  else
    echo "  npm      not found" >&2
  fi

  echo ""
  echo "-- Optional tools --"

  if command -v docker &>/dev/null; then
    echo "  docker   $(docker --version 2>/dev/null | head -1)"
  else
    echo "  docker   not installed"
  fi

  if command -v podman &>/dev/null; then
    echo "  podman   $(podman --version 2>/dev/null | head -1)"
  else
    echo "  podman   not installed"
  fi

  if command -v psql &>/dev/null; then
    echo "  psql     $(psql --version 2>/dev/null | head -1)"
  else
    echo "  psql     not installed"
  fi

  echo ""
  echo "-- Project state --"

  if [ -d "$SCRIPT_DIR/node_modules" ]; then
    echo "  node_modules  present"
  else
    echo "  node_modules  missing (run 'setup.sh install')"
  fi

  if [ -f "$SCRIPT_DIR/.next/build-manifest.json" ]; then
    echo "  build         complete"
  else
    echo "  build         not built (run 'setup.sh build')"
  fi

  if [ -d "$SCRIPT_DIR/.git" ]; then
    echo "  git repo      yes"
  else
    echo "  git repo      no"
  fi

  echo ""
  echo "-- Sandbox state --"

  if [ -d "/tmp/mysandbox" ]; then
    local found=false
    for dir in /tmp/mysandbox/*/; do
      [ -d "$dir" ] || continue
      found=true
      name=$(basename "$dir")
      port=$(cat "$dir/port" 2>/dev/null || echo "?")
      if [ -f "$dir/pid" ] && kill -0 "$(cat "$dir/pid")" 2>/dev/null; then
        echo "  ${name}  running  :${port}"
      else
        echo "  ${name}  stopped  :${port}"
      fi
    done
    $found || echo "  no sandboxes"
  else
    echo "  no sandboxes"
  fi
}

show_env() {
  echo "# Environment variables for ${PROJECT_NAME}"
  echo "# Copy and adjust as needed."
  echo ""
  echo "# Database (PostgreSQL)"
  echo "DB_MODE=postgres"
  echo "DATABASE_URL=postgres://calculator:calculator_pass@localhost:5432/calculator"
  echo ""
  echo "# Database (file-based store)"
  echo "# DB_MODE=file"
  echo "# SANDBOX_DIR=./.sandbox-data"
  echo ""
  echo "# API (empty = same origin)"
  echo "NEXT_PUBLIC_API_URL=http://localhost:3000"
}

# ── Sandbox implementation commands (called by mysandbox) ──────────────────

cmd_start() {
  local port=$1 db_mode=$2 sandbox_dir=$3
  mkdir -p "$sandbox_dir"
  export SANDBOX_DIR="$sandbox_dir"
  if [ "$db_mode" = "postgres" ]; then
    local db_name
    db_name="calculator_$(basename "$sandbox_dir")"
    export DB_MODE=postgres DATABASE_URL="postgres://calculator:calculator_pass@localhost:5432/${db_name}"
  elif [ "$db_mode" = "file" ]; then
    export DB_MODE=file
  else
    export DB_MODE=skip
  fi
  (
    cd "$SCRIPT_DIR"
    nohup npx next start -p "$port" > "$sandbox_dir/output.log" 2>&1
  ) &
  echo $! > "$sandbox_dir/pid"
}

cmd_compose_start() {
  local name=$1 port=$2 db_port=$3 compose_file=$4 container_tool=$5
  API_PORT=$port DB_PORT=$db_port $container_tool compose -p "$name" -f "$compose_file" up -d
}

cmd_compose_stop() {
  local name=$1 compose_file=$2 container_tool=$3
  $container_tool compose -p "$name" -f "$compose_file" down -v 2>/dev/null || true
}

cmd_db_create() {
  local db_name=$1 pg_user=$2
  if command -v psql &>/dev/null; then
    if sudo -n -u postgres psql -c "CREATE DATABASE ${db_name} OWNER $pg_user;" 2>/dev/null; then
      return 0
    fi
    if psql -U "$pg_user" -c "CREATE DATABASE ${db_name} OWNER $pg_user;" 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

cmd_db_drop() {
  local db_name=$1 pg_user=$2
  if command -v psql &>/dev/null; then
    sudo -n -u postgres psql -c "DROP DATABASE IF EXISTS ${db_name};" 2>/dev/null || \
    psql -U "$pg_user" -c "DROP DATABASE IF EXISTS ${db_name};" 2>/dev/null || true
  fi
}

# ── Wizard (no args) ──

wizard() {
  echo "=== ${PROJECT_NAME} Bootstrap ==="
  echo ""
  echo "This wizard will:"
  echo ""
  echo "  [1/4]  Check Node.js and npm availability"
  echo "  [2/4]  Install project dependencies (npm ci)"
  echo "  [3/4]  Build the application (npm run build)"
  echo "  [4/4]  Start the sandbox (mysandbox run default)"
  echo ""
  read -p "Press Enter to continue..."

  echo ""
  echo "[1/4] Prerequisites"
  if ! check_prereqs; then
    echo ""
    echo "Prerequisites not met. Please install the required tools and try again." >&2
    exit 1
  fi

  echo ""
  echo "[2/4] Dependencies"
  install_deps

  echo ""
  echo "[3/4] Build"
  build_app

  echo ""
  echo "[4/4] Launch"
  echo "────────────────────────────────────────"
  exec "$SCRIPT_DIR/mysandbox" run default
}

# ── Usage ──

usage() {
  echo "${PROJECT_NAME} -- Environment setup and sandbox launcher"
  echo ""
  echo "Usage: ./setup.sh <command> [args...]"
  echo ""
  echo "Setup commands:"
  echo "  (no args)  Setup wizard: check, install, build, then launch sandbox"
  echo "  build      Check prerequisites, install deps, build application"
  echo "  install    Install dependencies only (npm ci)"
  echo "  check      Quick prerequisite check (exit code 0/1)"
  echo "  doctor     Full environment diagnostic"
  echo "  env        Print required environment variables"
  echo ""
  echo "Sandbox commands (delegated to mysandbox):"
  echo "  run <name>     Start sandbox in foreground"
  echo "  create <name>  Create and start sandbox in background"
  echo "  stop [name]    Stop sandbox(es)"
  echo "  list           List sandboxes"
  echo "  kill <name>    Stop and remove a sandbox"
  echo "  logs <name>    Tail sandbox logs"
  echo ""
  echo "Implementation commands (called by mysandbox):"
  echo "  start <port> <db_mode> <sandbox_dir>"
  echo "  compose-start <name> <port> <db_port> <compose_file> <ct>"
  echo "  compose-stop <name> <compose_file> <ct>"
  echo "  db-create <db_name> <pg_user>"
  echo "  db-drop <db_name> <pg_user>"
  echo ""
  echo "Options:"
  echo "  --help, -h  Show this help"
}

# ── Main ──

case "${1:-}" in
  build)
    check_prereqs
    install_deps
    build_app
    ;;
  install)
    install_deps
    ;;
  check)
    check_prereqs
    ;;
  doctor)
    doctor
    ;;
  env)
    show_env
    ;;
  help|--help|-h)
    usage
    ;;
  start)
    [ $# -eq 4 ] || { echo "Usage: setup.sh start <port> <db_mode> <sandbox_dir>" >&2; exit 1; }
    cmd_start "$2" "$3" "$4"
    ;;
  compose-start)
    [ $# -eq 6 ] || { echo "Usage: setup.sh compose-start <name> <port> <db_port> <compose_file> <ct>" >&2; exit 1; }
    cmd_compose_start "$2" "$3" "$4" "$5" "$6"
    ;;
  compose-stop)
    [ $# -eq 4 ] || { echo "Usage: setup.sh compose-stop <name> <compose_file> <ct>" >&2; exit 1; }
    cmd_compose_stop "$2" "$3" "$4"
    ;;
  db-create)
    [ $# -eq 3 ] || { echo "Usage: setup.sh db-create <db_name> <pg_user>" >&2; exit 1; }
    cmd_db_create "$2" "$3"
    ;;
  db-drop)
    [ $# -eq 3 ] || { echo "Usage: setup.sh db-drop <db_name> <pg_user>" >&2; exit 1; }
    cmd_db_drop "$2" "$3"
    ;;
  run|create|stop|list|kill|logs)
    exec "$SCRIPT_DIR/mysandbox" "$@"
    ;;
  "")
    wizard
    ;;
  *)
    echo "Unknown command: $1" >&2
    usage >&2
    exit 1
    ;;
esac
