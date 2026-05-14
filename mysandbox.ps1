param(
  [Parameter(Position=0)][string]$Command,
  [Parameter(Position=1)][string]$Name,
  [Parameter(Position=2)][string]$Service = "calculator-api"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ComposeFile = Join-Path $ScriptDir "backend" "docker-compose.yml"

if (!(Test-Path $ComposeFile)) {
  Write-Error "docker-compose.yml not found at $ComposeFile"
  exit 1
}

function Find-Port($base) {
  $port = $base
  while ((netstat -an 2>$null) -match ":$port\s") { $port++ }
  $port
}

switch ($Command) {
  "create" {
    if (!$Name) { Write-Error "Usage: mysandbox create <name>"; exit 1 }
    $apiPort = Find-Port 8081
    $dbPort = Find-Port ($apiPort + 1000)
    Write-Host "Creating sandbox '$Name' (API :$apiPort  DB :$dbPort)"
    $env:API_PORT = $apiPort; $env:DB_PORT = $dbPort
    docker compose -p $Name -f $ComposeFile up -d
    Write-Host "Sandbox '$Name' is live."
    Write-Host "  API  http://localhost:$apiPort"
    Write-Host "  DB   postgresql://calculator:calculator_pass@localhost:$dbPort/calculator"
  }
  "list" {
    docker ps --filter "label=com.docker.compose.project" --format "table {{.Names}}`t{{.Ports}}`t{{.Status}}"
  }
  "kill" {
    if (!$Name) { Write-Error "Usage: mysandbox kill <name>"; exit 1 }
    Write-Host "Removing sandbox '$Name'..."
    docker compose -p $Name -f $ComposeFile down -v
    Write-Host "Done."
  }
  "logs" {
    if (!$Name) { Write-Error "Usage: mysandbox logs <name> [service]"; exit 1 }
    docker compose -p $Name -f $ComposeFile logs -f $Service
  }
  "db" {
    if (!$Name) { Write-Error "Usage: mysandbox db <name>"; exit 1 }
    docker compose -p $Name -f $ComposeFile exec db psql -U calculator -d calculator
  }
  default {
    Write-Host @"
Usage: mysandbox <command> [name] [service]

Commands:
  create <name>   Create & start a new sandbox
  list            List running sandboxes
  kill <name>     Stop & remove a sandbox (deletes volumes)
  logs <name>     Tail logs of a sandbox
  db <name>       Open psql shell for a sandbox
"@
  }
}
