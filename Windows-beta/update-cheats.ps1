<#
.SYNOPSIS
    Silent background updater for DevToolbox Cheats cheatsheets.
.DESCRIPTION
    Downloads the latest cheats.d folder from the GitHub repository and
    overwrites the local copy. Designed to run unattended via Task Scheduler.
    All output is logged to %USERPROFILE%\cheats_updater.log.
#>
$ErrorActionPreference = "Stop"

$CheatsDir   = "$env:USERPROFILE\cheats.d"
$RepoZipUrl  = "https://github.com/dominatos/devtoolbox-cheats/archive/refs/heads/main.zip"
$TempDir     = Join-Path $env:TEMP "devtoolbox-cheats-update-$PID"
$ZipFile     = Join-Path $env:TEMP "devtoolbox-main-$PID.zip"
$LogFile     = "$env:USERPROFILE\cheats_updater.log"
$MaxLogBytes = 512KB

function Write-Log($Message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "[$timestamp] $Message" -ErrorAction SilentlyContinue
}

# -- Log rotation: trim to last 512 KB if oversized ----------------------------
if ((Test-Path $LogFile) -and (Get-Item $LogFile).Length -gt $MaxLogBytes) {
    try {
        $lines = Get-Content $LogFile -Tail 200
        Set-Content -Path $LogFile -Value $lines -ErrorAction SilentlyContinue
    } catch { }
}

# -- Connectivity check --------------------------------------------------------
try {
    $null = [System.Net.Dns]::GetHostAddresses("github.com")
} catch {
    Write-Log "Skipped: No network connectivity to github.com."
    exit 0
}

# -- Main update logic ---------------------------------------------------------
try {
    Write-Log "Starting background update..."

    # Clean up any leftover temp files from previous runs
    if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
    if (Test-Path $ZipFile) { Remove-Item $ZipFile -Force }

    Write-Log "Downloading latest cheatsheets..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $RepoZipUrl -OutFile $ZipFile -UseBasicParsing -TimeoutSec 60

    # Validate downloaded file is non-empty
    if (-not (Test-Path $ZipFile) -or (Get-Item $ZipFile).Length -eq 0) {
        Write-Log "Error: Downloaded file is missing or empty."
        exit 1
    }

    Write-Log "Extracting archive..."
    Expand-Archive -Path $ZipFile -DestinationPath $TempDir -Force

    $SourceCheats = Join-Path $TempDir "devtoolbox-cheats-main\cheats.d"
    if (-not (Test-Path $SourceCheats)) {
        Write-Log "Error: Extracted archive does not contain expected 'cheats.d' directory."
        exit 1
    }

    # Verify extraction produced actual cheatsheet files
    $fileCount = (Get-ChildItem $SourceCheats -Recurse -File).Count
    if ($fileCount -eq 0) {
        Write-Log "Error: Extracted cheats.d contains no files."
        exit 1
    }

    if (-not (Test-Path $CheatsDir)) {
        New-Item -ItemType Directory -Path $CheatsDir -Force | Out-Null
    }

    Write-Log "Copying $fileCount files to $CheatsDir..."
    Copy-Item -Path "$SourceCheats\*" -Destination $CheatsDir -Recurse -Force
    Write-Log "Update successful ($fileCount files)."

} catch {
    Write-Log "Update failed: $_"
    exit 1
} finally {
    # Cleanup temp files regardless of success/failure
    if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $ZipFile) { Remove-Item $ZipFile -Force -ErrorAction SilentlyContinue }
}
