#Requires -Version 5.1
<#
    build-mod.ps1 -- packs this Factorio mod into <name>_<version>.zip and copies
    the result into the local Factorio mods folder.

    Normally started through build-mod.bat, but can also be called directly:
        powershell -ExecutionPolicy Bypass -File build-mod.ps1
#>
[CmdletBinding()]
param(
    # Mod root folder. Defaults to the folder this script lives in.
    [string] $ModRoot,
    # Force a specific mods folder instead of auto-detecting it.
    [string] $ModsDir,
    # Only build the zip, never touch the Factorio mods folder.
    [switch] $NoDeploy,
    # Keep already installed older versions of this mod next to the new zip.
    [switch] $KeepOld,
    # Open the output folder in Explorer when everything is done.
    [switch] $Open
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }

# ---------------------------------------------------------------- small helpers
function Write-Head([string] $text) {
    Write-Host ''
    Write-Host ('=== ' + $text + ' ' + ('=' * [Math]::Max(3, 58 - $text.Length))) -ForegroundColor Cyan
}
function Write-Ok([string] $text)   { Write-Host ('  [OK]   ' + $text) -ForegroundColor Green }
function Write-Warn([string] $text) { Write-Host ('  [WARN] ' + $text) -ForegroundColor Yellow }
function Write-Err([string] $text)  { Write-Host ('  [ERR]  ' + $text) -ForegroundColor Red }
function Write-Info([string] $text) { Write-Host ('         ' + $text) -ForegroundColor Gray }

function Get-Sha256([string] $Path) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $fs = [IO.File]::OpenRead($Path)
        try { return ([BitConverter]::ToString($sha.ComputeHash($fs)) -replace '-', '') }
        finally { $fs.Dispose() }
    } finally { $sha.Dispose() }
}

function Show-Folder([string] $Path) {
    if ($Open -and (Test-Path -LiteralPath $Path)) {
        try { Start-Process -FilePath 'explorer.exe' -ArgumentList ('"' + $Path + '"') } catch { }
    }
}

# --------------------------------------------------------------- resolve paths
if ([string]::IsNullOrWhiteSpace($ModRoot)) { $ModRoot = $PSScriptRoot }
if ([string]::IsNullOrWhiteSpace($ModRoot)) { $ModRoot = (Get-Location).Path }
if (-not (Test-Path -LiteralPath $ModRoot)) { throw ('Mod root not found: ' + $ModRoot) }
$ModRoot = (Resolve-Path -LiteralPath $ModRoot).Path.TrimEnd('\')

Write-Host ''
Write-Host '  Factorio mod packager' -ForegroundColor White
Write-Host '  ---------------------' -ForegroundColor DarkGray
Write-Info ('mod root : ' + $ModRoot)

# ---------------------------------------------------------------- 1. info.json
Write-Head 'Read info.json'
$infoPath = Join-Path $ModRoot 'info.json'
if (-not (Test-Path -LiteralPath $infoPath)) {
    throw 'info.json was not found. Put build-mod.bat / build-mod.ps1 in the mod root folder.'
}
try {
    $bytes = [IO.File]::ReadAllBytes($infoPath)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $infoText = [Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
    } else {
        $infoText = [Text.Encoding]::UTF8.GetString($bytes)
    }
    $info = $infoText | ConvertFrom-Json
} catch {
    throw ('Could not parse info.json : ' + $_.Exception.Message)
}

$ModName = [string]$info.name
if ([string]::IsNullOrWhiteSpace($ModName)) {
    $ModName = Split-Path -Leaf $ModRoot
    Write-Warn ('info.json has no "name" - using the folder name "' + $ModName + '"')
}
$ModVer = ([string]$info.version).Trim()
if ([string]::IsNullOrWhiteSpace($ModVer)) { throw 'info.json has no "version" field.' }
if ($ModVer -notmatch '^\d+\.\d+\.\d+$') {
    Write-Warn ('version "' + $ModVer + '" is not major.minor.patch - packaging anyway')
}

Write-Ok ($ModName + '  v' + $ModVer)
if (-not [string]::IsNullOrWhiteSpace([string]$info.title)) { Write-Info ('title    : ' + $info.title) }
Write-Info ('f.version: ' + [string]$info.factorio_version)

# --------------------------------------------------------------- 2. file list
Write-Head 'Collect files'
# Files that must never end up inside the published archive.
$skipFiles = @(
    'build-mod.bat',
    'build-mod.ps1',
    '.gitignore',
    '.gitattributes',
    'ghost-reader.code-workspace',
    'PERF_OPTIMIZATION.md',
    'Thumbs.db',
    '.DS_Store'
)
# Development-only folders (nothing in the mod references them at runtime).
$skipDirs = @('.git', '.vscode', '.idea', '.svn', 'tools', 'node_modules', '__pycache__')

$files = @()
foreach ($f in @(Get-ChildItem -LiteralPath $ModRoot -Recurse -File -Force -ErrorAction SilentlyContinue)) {
    $rel      = $f.FullName.Substring($ModRoot.Length).TrimStart('\')
    $segments = $rel -split '\\'

    if ($skipDirs -contains $segments[0]) { continue }
    if ($skipFiles -contains $f.Name) { continue }

    $inSkippedDir = $false
    foreach ($seg in $segments) {
        if ($skipDirs -contains $seg) { $inSkippedDir = $true; break }
    }
    if ($inSkippedDir) { continue }

    # previous build artifacts sitting in the mod root
    if ($segments.Count -eq 1) {
        if ($f.Name -like ($ModName + '_*.zip') -or $f.Name -like ($ModName + '_*.zip.disabled')) { continue }
    }
    # editor / dev clutter
    if ($f.Name -like '*.log' -or $f.Name -like '*.tmp' -or $f.Name -like '*.bak' -or $f.Name -like '*~') { continue }

    $files += [pscustomobject]@{ Full = $f.FullName; Rel = $rel; Size = $f.Length }
}

if ($files.Count -eq 0) { throw 'Nothing to package - the file list is empty.' }
foreach ($must in @('info.json', 'control.lua')) {
    if (-not ($files | Where-Object { $_.Rel -eq $must })) {
        Write-Warn ('expected root file is missing from the package: ' + $must)
    }
}
$totalKB = [Math]::Round((($files | Measure-Object -Property Size -Sum).Sum) / 1KB, 1)
Write-Ok ($files.Count.ToString() + ' files, ' + $totalKB + ' KB before compression')
foreach ($f in ($files | Where-Object { $_.Rel -notmatch '\\' } | Sort-Object Rel)) {
    Write-Info ('  ' + $f.Rel)
}

# ------------------------------------------------------------- 3. build the zip
Write-Head 'Build zip'
$ZipName   = $ModName + '_' + $ModVer + '.zip'
$OutputZip = Join-Path $ModRoot $ZipName

$tmpDir = Join-Path $env:TEMP ('factorio-pack-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
$tmpZip = Join-Path $env:TEMP ([Guid]::NewGuid().ToString('N') + '.zip')
try {
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

    # stage the files so that nothing extra (old zips, git metadata, ...) is packed
    foreach ($f in $files) {
        $dest = Join-Path $tmpDir $f.Rel
        $destDir = Split-Path -Parent $dest
        if (-not (Test-Path -LiteralPath $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Copy-Item -LiteralPath $f.Full -Destination $dest -Force
    }

    # no extra top-level folder and forward slashes = exactly what Factorio expects
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::CreateFromDirectory(
        $tmpDir,
        $tmpZip,
        [IO.Compression.CompressionLevel]::Optimal,
        $false,
        [Text.Encoding]::UTF8)

    $archive = [IO.Compression.ZipFile]::OpenRead($tmpZip)
    try { $entryCount = $archive.Entries.Count } finally { $archive.Dispose() }
} finally {
    if (Test-Path -LiteralPath $tmpDir) { Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($entryCount -lt 2) { throw 'The produced archive looks empty - aborting.' }

Move-Item -LiteralPath $tmpZip -Destination $OutputZip -Force
$zipItem = Get-Item -LiteralPath $OutputZip
Write-Ok ($ZipName + '  (' + $entryCount + ' entries, ' + [Math]::Round($zipItem.Length / 1KB, 1) + ' KB)')
Write-Info $OutputZip

foreach ($old in @(Get-ChildItem -LiteralPath $ModRoot -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne $ZipName -and $_.Name -like ($ModName + '_*.zip') })) {
    try {
        Remove-Item -LiteralPath $old.FullName -Force
        Write-Info ('removed old build: ' + $old.Name)
    } catch {
        Write-Warn ('could not remove old build ' + $old.Name)
    }
}

# ----------------------------------------------------------------- 4. deploy
if ($NoDeploy) {
    Write-Head 'Deploy'
    Write-Warn '-NoDeploy was given - the archive was only built locally.'
    Show-Folder $ModRoot
    Write-Host ''
    exit 0
}

Write-Head 'Find the Factorio mods folder'

function Test-FactorioDataDir([string] $Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    if (Test-Path -LiteralPath (Join-Path $Path 'bin\x64\factorio.exe')) { return $true }
    return $false
}

if ([string]::IsNullOrWhiteSpace($ModsDir)) {
    $installDirs = New-Object 'System.Collections.Generic.List[string]'

    # 1) the path Factorio's own installer records in the registry
    foreach ($reg in @('HKCU:\Software\Factorio', 'HKLM:\SOFTWARE\Factorio', 'HKLM:\SOFTWARE\WOW6432Node\Factorio')) {
        try {
            $item = Get-ItemProperty -Path $reg -ErrorAction SilentlyContinue
            if ($null -ne $item) {
                foreach ($prop in @('InstallDir', 'installDir', 'Path')) {
                    if ($item.PSObject.Properties.Name -contains $prop) {
                        $installDirs.Add([string]$item.$prop)
                        break
                    }
                }
            }
        } catch { }
    }

    $dataDir = $null
    foreach ($d in $installDirs) {
        if (Test-FactorioDataDir $d) { $dataDir = $d.TrimEnd('\'); break }
    }

    # 2) the standard user data folder (always exists when the game was started once)
    if (-not $dataDir -and $env:APPDATA) {
        $std = Join-Path $env:APPDATA 'Factorio'
        if (Test-Path -LiteralPath (Join-Path $std 'mods')) { $dataDir = $std }
    }

    # 3) portable / standalone installs on any drive
    if (-not $dataDir) {
        $roots = New-Object 'System.Collections.Generic.List[string]'
        $roots.Add($ModRoot.Substring(0, 3))
        foreach ($d in @('C:\', 'D:\', 'E:\', 'F:\', 'G:\')) { if (-not $roots.Contains($d)) { $roots.Add($d) } }
        foreach ($root in $roots) {
            if (-not (Test-Path -LiteralPath $root)) { continue }
            foreach ($sub in @(
                    'Factorio',
                    'Games\Factorio',
                    'Game\Factorio',
                    'Program Files\Factorio',
                    'Program Files (x86)\Factorio',
                    'Steam\steamapps\common\Factorio',
                    'SteamLibrary\steamapps\common\Factorio')) {
                $cand = Join-Path $root $sub
                if (Test-FactorioDataDir $cand) { $dataDir = $cand.TrimEnd('\'); break }
            }
            if ($dataDir) { break }
        }
    }

    if ($dataDir) {
        $ModsDir = Join-Path $dataDir 'mods'
        Write-Ok ('found Factorio data folder: ' + $dataDir)
    }
}

if (-not [string]::IsNullOrWhiteSpace($ModsDir)) {
    try { $ModsDir = (Resolve-Path -LiteralPath $ModsDir).Path }
    catch { throw ('mods folder does not exist: ' + $ModsDir) }
} else {
    Write-Warn 'The Factorio mods folder could not be detected automatically.'
    Write-Host ''
    Write-Host '  Type the full path of the mods folder and press Enter (Enter = skip):' -ForegroundColor Yellow
    $typed = Read-Host '  mods folder'
    if (-not [string]::IsNullOrWhiteSpace($typed)) {
        $typed = $typed.Trim().Trim('"')
        if (Test-Path -LiteralPath $typed) { $ModsDir = (Resolve-Path -LiteralPath $typed).Path }
        else { Write-Err ('not a folder: ' + $typed) }
    }
}

if ([string]::IsNullOrWhiteSpace($ModsDir)) {
    Write-Warn 'Deploy skipped. The archive itself is ready:'
    Write-Info $OutputZip
    Show-Folder $ModRoot
    Write-Host ''
    exit 0
}

try { $ModsDir = $ModsDir.TrimEnd('\') } catch { }

if (Get-Process -Name 'factorio' -ErrorAction SilentlyContinue) {
    Write-Warn 'Factorio is running - close it before enabling the new version.'
}

$target = Join-Path $ModsDir $ZipName
$upToDate = $false
if (Test-Path -LiteralPath $target) {
    try { $upToDate = ((Get-Sha256 $OutputZip) -eq (Get-Sha256 $target)) } catch { $upToDate = $false }
}

if ($upToDate) {
    Write-Ok ('already installed and identical: ' + $target)
} else {
    try {
        Copy-Item -LiteralPath $OutputZip -Destination $target -Force
    } catch {
        Write-Err ('could not write to the mods folder: ' + $_.Exception.Message)
        Write-Warn 'The archive is still available here - copy it manually:'
        Write-Info $OutputZip
        Show-Folder $ModRoot
        Write-Host ''
        exit 2
    }
    $size = [Math]::Round((Get-Item -LiteralPath $target).Length / 1KB, 1)
    Write-Ok ('installed: ' + $target + '  (' + $size + ' KB)')
}

if (-not $KeepOld) {
    $stale = @(Get-ChildItem -LiteralPath $ModsDir -File -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -ne $ZipName -and
            ($_.Name -like ($ModName + '_*.zip') -or $_.Name -like ($ModName + '_*.zip.disabled'))
        } | Sort-Object LastWriteTime -Descending)

    if ($stale.Count -gt 0) {
        $answer = 'y'
        if ($upToDate) {
            Write-Host ''
            Write-Host ('  ' + $stale.Count + ' older version(s) of ' + $ModName + ' are still in the mods folder:') -ForegroundColor Yellow
            foreach ($s in $stale) { Write-Info ('  ' + $s.Name) }
            $answer = Read-Host '  Delete them? [Y/n]'
        }
        if ($answer -notmatch '^(n|no)$') {
            foreach ($s in $stale) {
                try {
                    Remove-Item -LiteralPath $s.FullName -Force
                    Write-Info ('deleted old version: ' + $s.Name)
                } catch {
                    Write-Warn ('could not delete ' + $s.Name + ' - ' + $_.Exception.Message)
                }
            }
            Write-Ok 'old versions cleaned up'
        } else {
            Write-Info 'old versions kept - Factorio always loads the newest zip'
        }
    }
}

Write-Host ''
Write-Host ('  ' + $ZipName + ' is installed in:') -ForegroundColor Green
Write-Host ('  ' + $ModsDir) -ForegroundColor Green
Write-Host '  Start Factorio and enable the mod to test it.' -ForegroundColor Gray

Show-Folder $ModsDir
Write-Host ''
exit 0
