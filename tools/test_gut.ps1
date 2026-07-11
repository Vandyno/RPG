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
  $testSuites = @(
    @{ Name = "characters"; Path = "characters" },
    @{ Name = "core"; Path = "core" },
    @{ Name = "data"; Path = "data" },
    @{ Name = "main_actions"; Path = "main/actions" },
    @{ Name = "main_flows"; Path = "main/flows" },
    @{ Name = "main_input"; Path = "main/input" },
    @{ Name = "main_runtime"; Path = "main/runtime" },
    @{ Name = "managers_actors"; Path = "managers/actors" },
    @{ Name = "managers_content"; Path = "managers/content" },
    @{ Name = "managers_persistence"; Path = "managers/persistence" },
    @{ Name = "managers_world"; Path = "managers/world" },
    @{ Name = "player"; Path = "player" },
    @{ Name = "project"; Path = "project" },
    @{ Name = "tools_capture"; Path = "tools/capture" },
    @{ Name = "tools_verify"; Path = "tools/verify" },
    @{ Name = "ui_content"; Path = "ui/content" },
    @{ Name = "ui_controls"; Path = "ui/controls" },
    @{ Name = "ui_rpg"; Path = "ui/rpg" },
    @{ Name = "ui_shell"; Path = "ui/shell" },
    @{ Name = "ui_systems"; Path = "ui/systems" },
    @{ Name = "ui_text"; Path = "ui/text" },
    @{ Name = "ui_world"; Path = "ui/world" },
    @{ Name = "world"; Path = "world" }
  )
  foreach ($suite in $testSuites) {
    $args = @(
      "--headless",
      "--path", ".",
      "-s", "res://addons/gut/gut_cmdln.gd",
      "-gdir", "res://tests/unit/$($suite.Path)",
      "-gexit",
      "-gjunit_xml_file", "res://reports/gut_results_$($suite.Name).xml"
    )
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $suiteOutput = @(& $godot @args 2>&1)
    $suiteExitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    $suiteOutput | ForEach-Object { Write-Output ([string]$_) }
    if ($suiteExitCode -ne 0) {
      exit $suiteExitCode
    }
    $suiteText = $suiteOutput -join "`n"
    if (
      $suiteText -match "SCRIPT ERROR: Parse Error:" -or
      $suiteText -match "ERROR: Failed to load script"
    ) {
      Write-Error "GUT suite '$($suite.Name)' could not load every test script."
      exit 1
    }
  }

  $realClickScripts = @(
    "scripts\tools\verify\verify_body_loot_transfer_click.gd",
    "scripts\tools\verify\verify_spawn_slice_public_input.gd",
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
