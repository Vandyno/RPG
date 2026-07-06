$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $root
try {
  & "$PSScriptRoot\check_project.ps1"
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  & "$PSScriptRoot\lint.ps1"
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  & "$PSScriptRoot\test_gut.ps1"
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  & "$PSScriptRoot\godot.ps1" --headless --path . --script scripts\tools\verify_body_loot_transfer_click.gd
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  & "$PSScriptRoot\godot.ps1" --headless --path . --script scripts\tools\verify_rpg_ui_real_clicks.gd
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  & "$PSScriptRoot\godot.ps1" --headless --path . --script scripts\tools\verify_debug_character_creator_clicks.gd
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  & "$PSScriptRoot\test_gdunit.ps1"
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
  Pop-Location
}
