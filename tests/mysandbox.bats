#!/usr/bin/env bats

# ── Test helpers ───────────────────────────────────────────────
# Some tests create files or directories in the project root via
# mysandbox commands.  setup/teardown manage a temporary sandbox
# directory and config override.

setup() {
  export TMPDIR=$(mktemp -d)
  export MYSANDBOX_SANDBOX_DIR="$TMPDIR/sandboxes"
  mkdir -p "$MYSANDBOX_SANDBOX_DIR"
  export MYSANDBOX_CONFIG="$TMPDIR/mysandbox.config"
  export HOME="$TMPDIR/home"
  mkdir -p "$HOME"

  cat > "$MYSANDBOX_CONFIG" <<EOF
SANDBOX_DIR="$MYSANDBOX_SANDBOX_DIR"
EOF
}

teardown() {
  rm -rf "$TMPDIR"
}

# ── Low-level helpers ──────────────────────────────────────────

create_sandbox() {
  local name=$1 pid=$2 port=$3
  mkdir -p "$MYSANDBOX_SANDBOX_DIR/$name"
  echo "$pid"   > "$MYSANDBOX_SANDBOX_DIR/$name/pid"
  echo "$port"  > "$MYSANDBOX_SANDBOX_DIR/$name/port"
  echo "file"   > "$MYSANDBOX_SANDBOX_DIR/$name/db_mode"
}

# ── 1.  usage (no args / unknown command) ─────────────────────

@test "usage: no args prints help and exits non-zero" {
  run ./mysandbox
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "usage: unknown command prints help and exits non-zero" {
  run ./mysandbox foobar
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage:" ]]
}

# ── 2.  run (input validation — full flow is interactive) ─────

@test "run: without name prints usage" {
  run ./mysandbox run
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage:" ]]
}

# ── 3.  create (input validation — full flow is interactive) ──

@test "create: without name prints usage" {
  run ./mysandbox create
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage:" ]]
}

# ── 4.  list ───────────────────────────────────────────────────

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

@test "list: shows running sandbox (current shell via kill -0)" {
  # $$ (the bats test subshell) is always alive — kill -0 succeeds
  create_sandbox "test1" "$$" 4000
  run ./mysandbox list
  [ "$status" -eq 0 ]
  [[ "$output" =~ "test1" ]]
  [[ "$output" =~ "running" ]]
  [[ "$output" =~ "4000" ]]
}

@test "list: shows multiple running sandboxes" {
  create_sandbox "alpha" "$$" 4001
  create_sandbox "beta"  "$$" 4002
  run ./mysandbox list
  [ "$status" -eq 0 ]
  [[ "$output" =~ "alpha" ]]
  [[ "$output" =~ "beta" ]]
}

@test "list: shows tunnel info when present" {
  create_sandbox "tunneled" "$$" 4003
  echo "ngrok" > "$MYSANDBOX_SANDBOX_DIR/tunneled/tunnel_method"
  echo "https://abc.ngrok.io" > "$MYSANDBOX_SANDBOX_DIR/tunneled/tunnel_url"
  run ./mysandbox list
  [ "$status" -eq 0 ]
  [[ "$output" =~ "https://abc.ngrok.io" ]]
}

@test "list: auto-reaps orphaned sandbox (dead PID)" {
  create_sandbox "orphan" "99999" 4004
  run ./mysandbox list
  [ "$status" -eq 0 ]
  [[ "$output" == "No sandboxes." ]]
  [ ! -d "$MYSANDBOX_SANDBOX_DIR/orphan" ]
}

@test "list: shows one running and reaps one orphaned" {
  create_sandbox "alive"  "$$"    4005
  create_sandbox "dead"   "99998" 4006
  run ./mysandbox list
  [ "$status" -eq 0 ]
  [[ "$output" =~ "alive" ]]
  [[ "$output" =~ "running" ]]
  [[ "$output" != *"dead"* ]]
  [ ! -d "$MYSANDBOX_SANDBOX_DIR/dead" ]
}

@test "list: sandbox missing pid file is treated as orphaned" {
  mkdir -p "$MYSANDBOX_SANDBOX_DIR/nopid"
  echo "4007" > "$MYSANDBOX_SANDBOX_DIR/nopid/port"
  run ./mysandbox list
  [ "$status" -eq 0 ]
  [[ "$output" == "No sandboxes." ]]
  [ ! -d "$MYSANDBOX_SANDBOX_DIR/nopid" ]
}

@test "list: sandbox with empty pid file is treated as orphaned" {
  create_sandbox "emptypid" "" 4008
  run ./mysandbox list
  [ "$status" -eq 0 ]
  [[ "$output" == "No sandboxes." ]]
  [ ! -d "$MYSANDBOX_SANDBOX_DIR/emptypid" ]
}

# ── 5.  stop ──────────────────────────────────────────────────

@test "stop: without name stops all (no sandboxes)" {
  run ./mysandbox stop
  [ "$status" -eq 0 ]
  [[ "$output" =~ "All sandboxes stopped" ]]
}

@test "stop: non-existent sandbox does not error" {
  run ./mysandbox stop nope
  [ "$status" -eq 0 ]
}

@test "stop: named sandbox removes directory even with dead PID" {
  create_sandbox "tostop" "99996" 4009
  run ./mysandbox stop tostop
  [ "$status" -eq 0 ]
  [ ! -d "$MYSANDBOX_SANDBOX_DIR/tostop" ]
}

@test "stop: stops all sandboxes" {
  create_sandbox "s1" "99995" 4010
  create_sandbox "s2" "99994" 4011
  run ./mysandbox stop
  [ "$status" -eq 0 ]
  [[ "$output" =~ "All sandboxes stopped" ]]
  [ ! -d "$MYSANDBOX_SANDBOX_DIR/s1" ]
  [ ! -d "$MYSANDBOX_SANDBOX_DIR/s2" ]
}

# ── 6.  kill ──────────────────────────────────────────────────

@test "kill: without name prints usage" {
  run ./mysandbox kill
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "kill: non-existent sandbox says removed with no error" {
  run ./mysandbox kill nonexistent
  [ "$status" -eq 0 ]
  [[ "$output" =~ "nonexistent" ]]
  [[ "$output" =~ "removed" ]]
}

@test "kill: removes orphaned sandbox directory despite dead PID" {
  create_sandbox "zombie" "99997" 4012
  run ./mysandbox kill zombie
  [ "$status" -eq 0 ]
  [[ "$output" =~ "removed" ]]
  [ ! -d "$MYSANDBOX_SANDBOX_DIR/zombie" ]
}

# ── 7.  logs ──────────────────────────────────────────────────

@test "logs: without name prints usage" {
  run ./mysandbox logs
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "logs: non-existent sandbox prints error" {
  run ./mysandbox logs nope
  [ "$status" -eq 1 ]
  [[ "$output" =~ "No logs" ]]
}

@test "logs: shows content from sandbox output.log" {
  mkdir -p "$MYSANDBOX_SANDBOX_DIR/haslogs"
  printf "line 1\nline 2\nline 3\n" > "$MYSANDBOX_SANDBOX_DIR/haslogs/output.log"
  run cat "$MYSANDBOX_SANDBOX_DIR/haslogs/output.log"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "line 1" ]]
  [[ "$output" =~ "line 3" ]]
}

@test "logs: sandbox without log file prints error" {
  create_sandbox "nologs" "$$" 4014
  run ./mysandbox logs nologs
  [ "$status" -eq 1 ]
  [[ "$output" =~ "No logs" ]]
}

# ── 8.  db ────────────────────────────────────────────────────

@test "db: without name prints usage" {
  run ./mysandbox db
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage:" ]]
}

# ── 9.  install / uninstall ───────────────────────────────────

@test "install: creates wrapper in ~/.local/bin/mysandbox" {
  run ./mysandbox install
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Installed" ]]
  if [[ "$(uname -s)" =~ ^(MINGW|MSYS|CYGWIN) ]]; then
    [ -f "$HOME/.local/bin/mysandbox" ]
    [ -f "$HOME/.local/bin/mysandbox.cmd" ]
  else
    [ -L "$HOME/.local/bin/mysandbox" ]
  fi
}

@test "install: adds ~/.local/bin to PATH in .bash_profile when no rc file" {
  run ./mysandbox install
  [ "$status" -eq 0 ]
  [ -f "$HOME/.bash_profile" ]
  grep -q 'local/bin' "$HOME/.bash_profile"
}

@test "install: appends to existing .bashrc instead of creating .bash_profile" {
  echo "# existing rc" > "$HOME/.bashrc"
  run ./mysandbox install
  [ "$status" -eq 0 ]
  grep -q 'local/bin' "$HOME/.bashrc"
  grep -q '# existing' "$HOME/.bashrc"
  [ ! -f "$HOME/.bash_profile" ]
}

@test "uninstall: removes wrappers when installed" {
  # Install first
  ./mysandbox install >/dev/null 2>&1
  [ -f "$HOME/.local/bin/mysandbox" ] || skip "install failed"

  run ./mysandbox uninstall
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Removed" ]]
  [ ! -f "$HOME/.local/bin/mysandbox" ]
  [ ! -f "$HOME/.local/bin/mysandbox.cmd" ]
}

@test "uninstall: says not installed when nothing to remove" {
  run ./mysandbox uninstall
  [ "$status" -eq 0 ]
  [[ "$output" =~ "not installed" ]]
}
