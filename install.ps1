#Requires -Version 5.0
<#
  OnyxFox installer - Windows (PowerShell)
  https://github.com/balakumardev/onyxfox  (MIT)

  Installs the Firefox-side files into your default profile:
    - user.js        -> profile root    (enables userChrome + disables sidebar.revamp)
    - userChrome.css -> profile\chrome  (the auto-hide vertical-tabs chrome)

  The Sidebery CSS must be pasted/imported by hand (see README). Existing
  user.js / userChrome.css are backed up to *.onyxfox.bak first.

  Usage:
    powershell -ExecutionPolicy Bypass -File .\install.ps1 [-DryRun] [-Force] [-ProfilePath <dir>]
#>
[CmdletBinding()]
param(
  [switch]$DryRun,
  [switch]$Force,
  [string]$ProfilePath = ""
)
$ErrorActionPreference = "Stop"

function Say($m){ Write-Host $m }
function Ok($m){ Write-Host "+ $m" -ForegroundColor Green }
function Warn($m){ Write-Host "! $m" -ForegroundColor Yellow }
function Err($m){ Write-Host "x $m" -ForegroundColor Red }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Src = Join-Path $ScriptDir "src"
if (-not (Test-Path (Join-Path $Src "user.js")) -or -not (Test-Path (Join-Path $Src "userChrome.css"))) {
  Err "Cannot find src\user.js and src\userChrome.css next to this script."; exit 1
}

$FfDir = Join-Path $env:APPDATA "Mozilla\Firefox"

if ($ProfilePath -ne "") {
  $ProfileDir = $ProfilePath
} else {
  $Ini = Join-Path $FfDir "profiles.ini"
  if (-not (Test-Path $Ini)) { Err "No profiles.ini at $Ini - is Firefox installed and run once?"; exit 1 }
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
  if (-not $rel) { Err "Could not determine a profile. Re-run with -ProfilePath <dir>."; exit 1 }
  $rel = $rel -replace '/','\'
  if ($rel -match '^[A-Za-z]:\\' -or $rel -match '^\\\\') { $ProfileDir = $rel } else { $ProfileDir = Join-Path $FfDir $rel }
}

if (-not (Test-Path $ProfileDir)) { Err "Profile dir not found: $ProfileDir"; exit 1 }

Say ""
Say "OnyxFox installer"
Say "  profile: $ProfileDir"
if ($DryRun) { Warn "dry-run: nothing will be written" }

if (-not $Force) {
  $ff = Get-Process firefox -ErrorAction SilentlyContinue
  if ($ff) { Err "Firefox looks like it is running. Close it fully, then re-run (or use -Force)."; exit 1 }
}

$ChromeDir = Join-Path $ProfileDir "chrome"
$UserJs = Join-Path $ProfileDir "user.js"
$MS = "// >>> OnyxFox >>>"
$ME = "// <<< OnyxFox <<<"

function Backup-Once($f) {
  if (-not (Test-Path $f)) { return }
  $bak = "$f.onyxfox.bak"
  if (Test-Path $bak) { return }
  if ($DryRun) { Say "  [dry-run] back up $(Split-Path $f -Leaf)" }
  else { Copy-Item $f $bak; Ok "backed up existing $(Split-Path $f -Leaf)" }
}

# --- userChrome.css ---
Backup-Once (Join-Path $ChromeDir "userChrome.css")
if ($DryRun) { Say "  [dry-run] create chrome\ and write userChrome.css" }
else {
  if (-not (Test-Path $ChromeDir)) { New-Item -ItemType Directory -Path $ChromeDir | Out-Null }
  Copy-Item (Join-Path $Src "userChrome.css") (Join-Path $ChromeDir "userChrome.css") -Force
  Ok "installed chrome\userChrome.css"
}

# --- user.js (append a marked block; preserve other prefs) ---
Backup-Once $UserJs
if ($DryRun) { Say "  [dry-run] add OnyxFox prefs block to user.js" }
else {
  if (Test-Path $UserJs) {
    $content = Get-Content $UserJs
    $out = New-Object System.Collections.Generic.List[string]
    $skip = $false
    foreach ($l in $content) {
      if ($l -eq $MS) { $skip = $true; continue }
      if ($skip -and $l -eq $ME) { $skip = $false; continue }
      if (-not $skip) { $out.Add($l) }
    }
    Set-Content -Path $UserJs -Value $out -Encoding ASCII
  }
  $block = @(
    $MS,
    "// Added by OnyxFox - remove this block (or run uninstall.ps1) to revert.",
    'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);',
    'user_pref("sidebar.revamp", false);',
    $ME
  )
  Add-Content -Path $UserJs -Value $block -Encoding ASCII
  Ok "installed user.js prefs"
}

Say ""
Ok "Firefox-side install complete."
Say ""
Say "Two manual steps left (Sidebery cannot be scripted):"
Say "  1. Install Sidebery: https://addons.mozilla.org/firefox/addon/sidebery/"
Say "  2. Sidebery -> Settings -> Styles editor: paste src\sidebery-amoled.css"
Say "     (or import sidebery\onyxfox.sidebery.json - see README),"
Say "     then set Sidebery Color scheme = dark."
Say ""
Say "Then fully restart Firefox. Revert anytime with .\uninstall.ps1"
