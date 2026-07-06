param(
  [int]$Width = 1152,
  [int]$Height = 648,
  [string]$Tab = "inventory"
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$projectPath = Join-Path $root "project.godot"
$projectText = $null
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$mutex = New-Object System.Threading.Mutex($false, "Local\VelcorSmokeRenderViewport")
$hasMutex = $false
Push-Location $root
try {
  $hasMutex = $mutex.WaitOne([TimeSpan]::FromMinutes(2))
  if (-not $hasMutex) {
    throw "Timed out waiting for smoke render lock."
  }
  New-Item -ItemType Directory -Force -Path "reports" | Out-Null
  New-Item -ItemType File -Force -Path "reports\.gdignore" | Out-Null
  $godot = Join-Path $root ".tools\godot\Godot_v4.6-stable_win64_console.exe"
  $outputPath = "res://reports/systems_menu_${Tab}_${Width}x${Height}.png"
  $projectText = [System.IO.File]::ReadAllText($projectPath)
  if (
    -not [System.Text.RegularExpressions.Regex]::IsMatch($projectText, 'window/size/viewport_width=\d+') -or
    -not [System.Text.RegularExpressions.Regex]::IsMatch($projectText, 'window/size/viewport_height=\d+')
  ) {
    throw "Could not find project viewport size settings."
  }
  $nextProjectText = $projectText `
    -replace 'window/size/viewport_width=\d+', "window/size/viewport_width=$Width" `
    -replace 'window/size/viewport_height=\d+', "window/size/viewport_height=$Height"
  [System.IO.File]::WriteAllText($projectPath, $nextProjectText, $utf8NoBom)
  & $godot --path "." --script "res://scripts/tools/capture/capture_systems_menu.gd" -- $Width $Height $outputPath $Tab
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}
finally {
  if ($null -ne $projectText) {
    [System.IO.File]::WriteAllText($projectPath, $projectText, $utf8NoBom)
  }
  if ($hasMutex) {
    $mutex.ReleaseMutex()
  }
  $mutex.Dispose()
  Pop-Location
}
