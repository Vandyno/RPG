param(
  [int]$Width = 0,
  [int]$Height = 0
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
  $moviePath = "reports\smoke.png"
  $godotArgs = @("--path", ".")
  if (($Width -gt 0) -xor ($Height -gt 0)) {
    throw "Pass both width and height, or neither."
  }
  if ($Width -gt 0 -and $Height -gt 0) {
    $moviePath = "reports\smoke_${Width}x${Height}.png"
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
  }
  $godotArgs += @("--write-movie", $moviePath, "--quit-after", "3", "--fixed-fps", "30")
  & $godot @godotArgs
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
