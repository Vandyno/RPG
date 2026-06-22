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
  $args = @(
    "--headless",
    "--path", ".",
    "-s", "res://addons/gut/gut_cmdln.gd",
    "-gdir", "res://tests/unit",
    "-gexit",
    "-gjunit_xml_file", "res://reports/gut_results.xml"
  )
  & $godot @args
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}
finally {
  Pop-Location
}
