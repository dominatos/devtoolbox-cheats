<#
.SYNOPSIS
    Silent background updater for DevToolbox Cheats cheatsheets.
.DESCRIPTION
    Downloads the latest cheats.d folder from the GitHub repository and
    overwrites the local copy. Designed to run unattended via Task Scheduler.
    All output is logged to %USERPROFILE%\cheats_updater.log.
#>
$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"   # Prevent Invoke-WebRequest from hanging in hidden sessions

$CheatsDir   = "$env:USERPROFILE\cheats.d"
$RepoZipUrl  = "https://github.com/dominatos/devtoolbox-cheats/archive/refs/heads/main.zip"
$TempDir     = Join-Path $env:TEMP "devtoolbox-cheats-update-$PID"
$ZipFile     = Join-Path $env:TEMP "devtoolbox-main-$PID.zip"
$LogFile     = "$env:USERPROFILE\cheats_updater.log"
$LockFile    = Join-Path $env:TEMP "devtoolbox-update.lock"
$MaxLogBytes = 512KB

function Write-UpdateLog($Message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "[$timestamp] $Message" -ErrorAction SilentlyContinue
}

# -- Log rotation: trim to last 200 lines if oversized -------------------------
if ((Test-Path $LogFile) -and (Get-Item $LogFile).Length -gt $MaxLogBytes) {
    try {
        $lines = Get-Content $LogFile -Tail 200
        Set-Content -Path $LogFile -Value $lines -ErrorAction SilentlyContinue
    } catch { }
}

# -- Lock file: prevent overlapping runs ---------------------------------------
try {
    $null = New-Item -Path $LockFile -Value $PID -ErrorAction Stop
} catch {
    $lockAge = (Get-Date) - (Get-Item $LockFile).LastWriteTime
    if ($lockAge.TotalMinutes -lt 30) {
        Write-UpdateLog "Skipped: Another update is already running (lock age: $([int]$lockAge.TotalMinutes) min)."
        exit 0
    }
    Write-UpdateLog "Removing stale lock file (age: $([int]$lockAge.TotalMinutes) min)."
    Remove-Item $LockFile -Force
    $null = New-Item -Path $LockFile -Value $PID -ErrorAction SilentlyContinue
}

# -- Connectivity check --------------------------------------------------------
try {
    $null = [System.Net.Dns]::GetHostAddresses("github.com")
} catch {
    Write-UpdateLog "Skipped: No network connectivity to github.com."
    if (Test-Path $LockFile) { Remove-Item $LockFile -Force -ErrorAction SilentlyContinue }
    exit 0
}

# -- Main update logic ---------------------------------------------------------
try {
    Write-UpdateLog "Starting background update..."

    # Clean up any leftover temp files from previous runs
    if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
    if (Test-Path $ZipFile) { Remove-Item $ZipFile -Force }

    Write-UpdateLog "Downloading latest cheatsheets..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $RepoZipUrl -OutFile $ZipFile -UseBasicParsing -TimeoutSec 60
    Write-UpdateLog "Download complete ($([math]::Round((Get-Item $ZipFile).Length / 1KB)) KB)."

    # Validate downloaded file is non-empty
    if (-not (Test-Path $ZipFile) -or (Get-Item $ZipFile).Length -eq 0) {
        Write-UpdateLog "Error: Downloaded file is missing or empty."
        exit 1
    }

    Write-UpdateLog "Extracting archive..."
    Expand-Archive -Path $ZipFile -DestinationPath $TempDir -Force

    $SourceCheats = Join-Path $TempDir "devtoolbox-cheats-main\cheats.d"
    if (-not (Test-Path $SourceCheats)) {
        Write-UpdateLog "Error: Extracted archive does not contain expected 'cheats.d' directory."
        exit 1
    }

    # Verify extraction produced actual cheatsheet files
    $fileCount = (Get-ChildItem $SourceCheats -Recurse -File).Count
    if ($fileCount -eq 0) {
        Write-UpdateLog "Error: Extracted cheats.d contains no files."
        exit 1
    }

    if (-not (Test-Path $CheatsDir)) {
        New-Item -ItemType Directory -Path $CheatsDir -Force | Out-Null
    }

    # Pre-create all subdirectories from source to work around PowerShell 5.1
    # Copy-Item -Recurse bug where deleted destination subdirectories are not recreated
    Get-ChildItem -Path $SourceCheats -Directory -Recurse | ForEach-Object {
        $targetDir = Join-Path $CheatsDir $_.FullName.Substring($SourceCheats.Length)
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
    }

    Write-UpdateLog "Copying $fileCount files to $CheatsDir..."
    Copy-Item -Path "$SourceCheats\*" -Destination $CheatsDir -Recurse -Force
    Write-UpdateLog "Update successful ($fileCount files)."

} catch {
    Write-UpdateLog "Update failed: $_"
    exit 1
} finally {
    # Cleanup temp files and lock regardless of success/failure
    if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $ZipFile) { Remove-Item $ZipFile -Force -ErrorAction SilentlyContinue }
    if (Test-Path $LockFile) { Remove-Item $LockFile -Force -ErrorAction SilentlyContinue }
}
