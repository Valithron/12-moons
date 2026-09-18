param(
    [string]$GodotBinary = "godot"
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

if (-not (Get-Command $GodotBinary -ErrorAction SilentlyContinue) -and -not (Test-Path -LiteralPath $GodotBinary)) {
    throw "Godot binary was not found. Pass -GodotBinary with a Godot 4.7.2 executable path."
}

function Invoke-GodotScript([string]$scriptPath) {
    $process = Start-Process -FilePath $GodotBinary `
        -ArgumentList @("--headless", "--path", $projectRoot, "--script", $scriptPath) `
        -WorkingDirectory $projectRoot -Wait -NoNewWindow -PassThru
    return $process.ExitCode
}

$manifestExit = Invoke-GodotScript "res://scripts/run/validate_project.gd"
if ($manifestExit -ne 0) {
    exit $manifestExit
}

$runtimeExit = Invoke-GodotScript "res://scripts/run/validate_runtime.gd"
if ($runtimeExit -ne 0) {
    exit $runtimeExit
}

$godotBinaryArgument = '"' + $GodotBinary + '"'
$test_process = Start-Process -FilePath (Join-Path $projectRoot "addons\gdUnit4\runtest.cmd") `
    -ArgumentList @("--godot_binary", $godotBinaryArgument, "-a", "res://tests", "--ignoreHeadlessMode") `
    -WorkingDirectory $projectRoot -Wait -NoNewWindow -PassThru
if ($test_process.ExitCode -ne 0) {
    exit $test_process.ExitCode
}

Write-Output "12 Moons headless validation passed."
