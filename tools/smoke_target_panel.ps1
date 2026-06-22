param(
  [int]$Width = 1152,
  [int]$Height = 648
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $root
try {
  New-Item -ItemType Directory -Force -Path "reports" | Out-Null
  New-Item -ItemType File -Force -Path "reports\.gdignore" | Out-Null
  $godot = Join-Path $root ".tools\godot\Godot_v4.6-stable_win64_console.exe"
  $outputPath = "res://reports/target_panel_${Width}x${Height}.png"
  & $godot --path "." --script "res://scripts/tools/capture_target_panel.gd" -- $Width $Height $outputPath
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}
finally {
  Pop-Location
}
