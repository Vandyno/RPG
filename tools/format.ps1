$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $root
try {
  $files = rg --files -g "*.gd" -g "!addons/**"
  if ($files) {
    gdformat @files
  }
}
finally {
  Pop-Location
}
