param(
    [string]$GodotBinary = "godot"
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

if (-not (Get-Command $GodotBinary -ErrorAction SilentlyContinue) -and -not (Test-Path -LiteralPath $GodotBinary)) {
    throw "Godot binary was not found. Pass -GodotBinary with a Godot 4.7.2 executable path."
}

& $GodotBinary --headless --path $projectRoot --script res://scripts/run/validate_project.gd
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& (Join-Path $projectRoot "addons\gdUnit4\runtest.cmd") --godot_binary $GodotBinary -a res://tests --ignoreHeadlessMode
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output "12 Moons headless validation passed."
