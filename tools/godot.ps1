$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$godot = Join-Path $root ".tools\godot\Godot_v4.6-stable_win64_console.exe"

if (!(Test-Path $godot)) {
  throw "Local Godot binary not found at $godot. Re-run the tool install step."
}

& $godot @args
exit $LASTEXITCODE
