param(
  [int]$Width = 1152,
  [int]$Height = 648,
  [string]$Mode = "dialogue"
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $root
try {
  New-Item -ItemType Directory -Force -Path "reports" | Out-Null
  New-Item -ItemType File -Force -Path "reports\.gdignore" | Out-Null
  $godot = Join-Path $root ".tools\godot\Godot_v4.6-stable_win64_console.exe"
  $suffix = if ($Mode -eq "dialogue") { "${Width}x${Height}" } else { "${Mode}_${Width}x${Height}" }
  $outputPath = "res://reports/content_panel_${suffix}.png"
  & $godot --path "." --script "res://scripts/tools/capture_content_panel.gd" -- $Width $Height $outputPath $Mode
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}
finally {
  Pop-Location
}
