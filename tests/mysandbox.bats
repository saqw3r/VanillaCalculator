#!/usr/bin/env bats

setup() {
  export TMPDIR=$(mktemp -d)
  export MYSANDBOX_SANDBOX_DIR="$TMPDIR/sandboxes"
  mkdir -p "$MYSANDBOX_SANDBOX_DIR"

  cat > "$TMPDIR/mysandbox.config" <<EOF
SANDBOX_DIR="$MYSANDBOX_SANDBOX_DIR"
EOF
  export MYSANDBOX_CONFIG="$TMPDIR/mysandbox.config"
}

teardown() {
  rm -rf "$TMPDIR"
}

# ── Helper ────────────────────────────────────────────────────

create_sandbox() {
  local name=$1 pid=$2 port=$3
  mkdir -p "$MYSANDBOX_SANDBOX_DIR/$name"
  echo "$pid"   > "$MYSANDBOX_SANDBOX_DIR/$name/pid"
  echo "$port"  > "$MYSANDBOX_SANDBOX_DIR/$name/port"
  echo "file"   > "$MYSANDBOX_SANDBOX_DIR/$name/db_mode"
}

# ── list (no background process needed) ────────────────────────

@test "list: no sandbox dir prints No sandboxes" {
  rm -rf "$MYSANDBOX_SANDBOX_DIR"
  run ./mysandbox list
  [ "$status" -eq 0 ]
  [[ "$output" == "No sandboxes." ]]
}

@test "list: empty sandbox dir prints No sandboxes" {
  run ./mysandbox list
  [ "$status" -eq 0 ]
  [[ "$output" == "No sandboxes." ]]
}

@test "list: auto-reaps orphaned sandbox" {
  create_sandbox "orphan" "99999" 4004
  run ./mysandbox list
  [ "$status" -eq 0 ]
  [[ "$output" == "No sandboxes." ]]
  [ ! -d "$MYSANDBOX_SANDBOX_DIR/orphan" ]
}

@test "list: shows tunnel info even with orphaned sandbox" {
  mkdir -p "$MYSANDBOX_SANDBOX_DIR/tunonly"
  echo "99998" > "$MYSANDBOX_SANDBOX_DIR/tunonly/pid"
  echo "4003"  > "$MYSANDBOX_SANDBOX_DIR/tunonly/port"
  echo "file"  > "$MYSANDBOX_SANDBOX_DIR/tunonly/db_mode"
  echo "ngrok" > "$MYSANDBOX_SANDBOX_DIR/tunonly/tunnel_method"
  echo "https://abc.ngrok.io" > "$MYSANDBOX_SANDBOX_DIR/tunonly/tunnel_url"
  run ./mysandbox list
  [ "$status" -eq 0 ]
  [[ "$output" == "No sandboxes." ]]
  [ ! -d "$MYSANDBOX_SANDBOX_DIR/tunonly" ]
}

# ── list (background process needed) ──────────────────────────

@test "list: shows running sandbox" {
  (while true; do sleep 1; done) &
  local pid=$!
  create_sandbox "test1" "$pid" 4000
  run ./mysandbox list
  kill "$pid" 2>/dev/null || true
  [ "$status" -eq 0 ]
  [[ "$output" =~ "test1" ]]
  [[ "$output" =~ "running" ]]
  [[ "$output" =~ "4000" ]]
}

@test "list: shows multiple running sandboxes" {
  (while true; do sleep 1; done) &
  local p1=$!
  (while true; do sleep 1; done) &
  local p2=$!
  create_sandbox "alpha" "$p1" 4001
  create_sandbox "beta"  "$p2" 4002
  run ./mysandbox list
  kill "$p1" "$p2" 2>/dev/null || true
  [ "$status" -eq 0 ]
  [[ "$output" =~ "alpha" ]]
  [[ "$output" =~ "beta"  ]]
}

@test "list: shows one running and reaps one orphaned" {
  (while true; do sleep 1; done) &
  local pid=$!
  create_sandbox "alive"  "$pid"   4005
  create_sandbox "dead"   "99998" 4006
  run ./mysandbox list
  kill "$pid" 2>/dev/null || true
  [ "$status" -eq 0 ]
  [[ "$output" =~ "alive" ]]
  [[ "$output" =~ "running" ]]
  [[ "$output" != *"dead"* ]]
  [ ! -d "$MYSANDBOX_SANDBOX_DIR/dead" ]
}

# ── kill (no background process) ───────────────────────────────

@test "kill: non-existent sandbox says removed with no error" {
  run ./mysandbox kill nonexistent
  [ "$status" -eq 0 ]
  [[ "$output" =~ "nonexistent" ]]
  [[ "$output" =~ "removed" ]]
}

@test "kill: orphaned sandbox removes directory despite dead PID" {
  create_sandbox "zombie" "99997" 4008
  run ./mysandbox kill zombie
  if [ -d "$MYSANDBOX_SANDBOX_DIR/zombie" ]; then
    echo "BUG: orphaned sandbox directory remained after kill" >&2
    echo "cli_stop_api kill failure causes set -e to skip safe_rm" >&2
    false
  fi
  [ "$status" -eq 0 ]
  [[ "$output" =~ "zombie" ]]
  [[ "$output" =~ "removed" ]]
}

# ── stop (no background process) ───────────────────────────────

@test "stop: stops all sandboxes" {
  (while true; do sleep 1; done) &
  local p1=$!
  (while true; do sleep 1; done) &
  local p2=$!
  create_sandbox "s1" "$p1" 4010
  create_sandbox "s2" "$p2" 4011
  run ./mysandbox stop
  kill "$p1" "$p2" 2>/dev/null || true
  [ "$status" -eq 0 ]
  [[ "$output" =~ "All sandboxes stopped" ]]
  [ ! -d "$MYSANDBOX_SANDBOX_DIR/s1" ]
  [ ! -d "$MYSANDBOX_SANDBOX_DIR/s2" ]
}
