#Requires -Version 5.0
<#
  OnyxFox uninstaller - Windows (PowerShell)
  Restores the *.onyxfox.bak backups the installer made (or removes our files
  if there were no originals). Does not touch the Sidebery Style Editor CSS -
  clear that inside Sidebery -> Settings -> Styles editor yourself.

  Usage:
    powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 [-DryRun] [-ProfilePath <dir>]
#>
[CmdletBinding()]
param(
  [switch]$DryRun,
  [string]$ProfilePath = ""
)
$ErrorActionPreference = "Stop"

function Say($m){ Write-Host $m }
function Ok($m){ Write-Host "+ $m" -ForegroundColor Green }
function Warn($m){ Write-Host "! $m" -ForegroundColor Yellow }
function Err($m){ Write-Host "x $m" -ForegroundColor Red }

$FfDir = Join-Path $env:APPDATA "Mozilla\Firefox"

if ($ProfilePath -ne "") {
  $ProfileDir = $ProfilePath
} else {
  $Ini = Join-Path $FfDir "profiles.ini"
  if (-not (Test-Path $Ini)) { Err "No profiles.ini at $Ini."; exit 1 }
  $lines = Get-Content $Ini
  $rel = ""
  $inInstall = $false
  foreach ($line in $lines) {
    if ($line -match '^\[Install') { $inInstall = $true; continue }
    if ($line -match '^\[') { $inInstall = $false }
    if ($inInstall -and $line -match '^Default=(.+)$') { $rel = $Matches[1]; break }
  }
  if ($rel -eq "") {
    $paths = $lines | Where-Object { $_ -match '^Path=(.+)$' } | ForEach-Object { ($_ -replace '^Path=','') }
    $rel = ($paths | Where-Object { $_ -match 'default-release' } | Select-Object -First 1)
    if (-not $rel) { $rel = ($paths | Select-Object -First 1) }
  }
  $rel = $rel -replace '/','\'
  if ($rel -match '^[A-Za-z]:\\' -or $rel -match '^\\\\') { $ProfileDir = $rel } else { $ProfileDir = Join-Path $FfDir $rel }
}
if (-not (Test-Path $ProfileDir)) { Err "Profile dir not found: $ProfileDir"; exit 1 }

Say ""
Say "OnyxFox uninstaller"
Say "  profile: $ProfileDir"
if ($DryRun) { Warn "dry-run: nothing will be changed" }

$ChromeDir = Join-Path $ProfileDir "chrome"
$UserJs = Join-Path $ProfileDir "user.js"
$MS = "// >>> OnyxFox >>>"
$ME = "// <<< OnyxFox <<<"

# --- userChrome.css ---
$UC = Join-Path $ChromeDir "userChrome.css"
$UCbak = "$UC.onyxfox.bak"
if (Test-Path $UCbak) {
  if ($DryRun) { Say "  [dry-run] restore userChrome.css from backup" }
  else { Move-Item -Force $UCbak $UC; Ok "restored your original userChrome.css" }
} elseif ((Test-Path $UC) -and (Select-String -Path $UC -Pattern 'OnyxFox - userChrome.css' -Quiet)) {
  if ($DryRun) { Say "  [dry-run] remove OnyxFox userChrome.css" }
  else { Remove-Item -Force $UC; Ok "removed OnyxFox userChrome.css" }
} else {
  Warn "no OnyxFox userChrome.css found (nothing to do)"
}

# --- user.js ---
$UJbak = "$UserJs.onyxfox.bak"
if (Test-Path $UJbak) {
  if ($DryRun) { Say "  [dry-run] restore user.js from backup" }
  else { Move-Item -Force $UJbak $UserJs; Ok "restored your original user.js" }
} elseif (Test-Path $UserJs) {
  if ($DryRun) { Say "  [dry-run] strip OnyxFox block from user.js" }
  else {
    $content = Get-Content $UserJs
    $out = New-Object System.Collections.Generic.List[string]
    $skip = $false
    foreach ($l in $content) {
      if ($l -eq $MS) { $skip = $true; continue }
      if ($skip -and $l -eq $ME) { $skip = $false; continue }
      if (-not $skip) { $out.Add($l) }
    }
    if (($out | Where-Object { $_ -match '\S' }).Count -eq 0) { Remove-Item -Force $UserJs }
    else { Set-Content -Path $UserJs -Value $out -Encoding ASCII }
    Ok "removed OnyxFox prefs from user.js"
  }
}

Say ""
Ok "Uninstall complete."
Say "Sidebery CSS: clear it in Sidebery -> Settings -> Styles editor if you want it gone."
