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

  & "$PSScriptRoot\test_gdunit.ps1"
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
  Pop-Location
}
