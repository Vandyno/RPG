param(
  [string]$Seed = "first_quest_pass",
  [int]$Count = 5,
  [string]$LocationId = "",
  [string]$OutputPath = "res://reports/quest_proposals/first_quest_pass.json"
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$godot = Join-Path $root ".tools\godot\Godot_v4.6-stable_win64_console.exe"
Push-Location $root
try {
  & $godot --headless --path . -s res://scripts/tools/generate_quest_proposals.gd -- `
    $Seed $Count $LocationId $OutputPath
  exit $LASTEXITCODE
}
finally {
  Pop-Location
}
