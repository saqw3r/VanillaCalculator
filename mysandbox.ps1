# mysandbox.ps1 — Windows PowerShell helper
# Run this to add the project directory to your PATH.
# Then "mysandbox" will work from any terminal (relies on Git Bash or WSL).

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($env:Path -split ";" -contains $ScriptDir) {
  Write-Host "mysandbox already in PATH."
  exit 0
}

[Environment]::SetEnvironmentVariable("Path", "$env:Path;$ScriptDir", "User")
$env:Path += ";$ScriptDir"
Write-Host "Added '$ScriptDir' to user PATH."
Write-Host "Run 'mysandbox run demo' to test."
