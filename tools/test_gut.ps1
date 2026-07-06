$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $root
try {
  New-Item -ItemType Directory -Force -Path "reports" | Out-Null
  New-Item -ItemType File -Force -Path "reports\.gdignore" | Out-Null
  & "$PSScriptRoot\import_project.ps1"
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
  $godot = Join-Path $root ".tools\godot\Godot_v4.6-stable_win64_console.exe"
  $testDirs = @(
    "characters",
    "core",
    "data",
    "main",
    "managers",
    "player",
    "project",
    "ui",
    "world"
  )
  foreach ($dir in $testDirs) {
    $args = @(
      "--headless",
      "--path", ".",
      "-s", "res://addons/gut/gut_cmdln.gd",
      "-gdir", "res://tests/unit/$dir",
      "-gexit",
      "-gjunit_xml_file", "res://reports/gut_results_$dir.xml"
    )
    & $godot @args
    if ($LASTEXITCODE -ne 0) {
      exit $LASTEXITCODE
    }
  }

  $realClickScripts = @(
    "scripts\tools\verify\verify_body_loot_transfer_click.gd",
    "scripts\tools\verify\verify_rpg_ui_real_clicks.gd",
    "scripts\tools\verify\verify_debug_character_creator_clicks.gd"
  )
  foreach ($script in $realClickScripts) {
    & "$PSScriptRoot\godot.ps1" --headless --path . --script $script
    if ($LASTEXITCODE -ne 0) {
      exit $LASTEXITCODE
    }
  }
}
finally {
  Pop-Location
}
