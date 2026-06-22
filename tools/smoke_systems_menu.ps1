param(
  [int]$Width = 1152,
  [int]$Height = 648,
  [string]$Tab = "inventory"
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $root
try {
  New-Item -ItemType Directory -Force -Path "reports" | Out-Null
  New-Item -ItemType File -Force -Path "reports\.gdignore" | Out-Null
  $godot = Join-Path $root ".tools\godot\Godot_v4.6-stable_win64_console.exe"
  $outputPath = "res://reports/systems_menu_${Tab}_${Width}x${Height}.png"
  & $godot --path "." --script "res://scripts/tools/capture_systems_menu.gd" -- $Width $Height $outputPath $Tab
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}
finally {
  Pop-Location
}
