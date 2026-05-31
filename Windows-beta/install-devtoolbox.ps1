<#
.SYNOPSIS
    Automated Windows setup for DevToolbox Cheats.
.DESCRIPTION
    Verifies / installs AutoHotkey v1, copies cheatsheets, and deploys cheats.ahk
    to your Startup folder. Running .ahk directly avoids Windows Defender
    false-positive issues with compiled executables.
    Use -CompileExe to also compile cheats.ahk into cheats.exe.
.PARAMETER CompileExe
    Optional. Compiles cheats.ahk to cheats.exe using Ahk2Exe and deploys the
    .exe to the Startup folder instead of the .ahk script.
.EXAMPLE
    # Standard install (AHK script, no EXE -- recommended, AV-safe)
    powershell.exe -ExecutionPolicy Bypass -File .\install-devtoolbox.ps1

    # Optional: compile to EXE (may trigger Windows Defender)
    powershell.exe -ExecutionPolicy Bypass -File .\install-devtoolbox.ps1 -CompileExe
#>
param(
    [switch]$CompileExe
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -- Elevation guard -----------------------------------------------------------
$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isElevated) {
    Write-Warning "Do not run this script as Administrator."
    Write-Warning "Run it as a normal user so files install to your personal profile."
    exit 1
}

# -- Paths ---------------------------------------------------------------------
$ScriptDir       = Split-Path -Parent $MyInvocation.MyCommand.Path
$BaseDir         = Split-Path -Parent $ScriptDir
$SourceCheatsDir = Join-Path $BaseDir "cheats.d"
$UserProfileDir  = $env:USERPROFILE
$DestCheatsDir   = Join-Path $UserProfileDir "cheats.d"
$AhkFile         = Join-Path $ScriptDir "cheats.ahk"
$StartupFolder   = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"

# -- AutoHotkey v1 installer resolution ----------------------------------------
# Known-good fallback URL (last stable v1.1 release as of 2026)
$AhkFallbackVersion = "1.1.37.02"
$AhkFallbackUrl     = "https://github.com/AutoHotkey/AutoHotkey/releases/download/v$AhkFallbackVersion/AutoHotkey_${AhkFallbackVersion}_setup.exe"
$AhkBundled         = Join-Path $ScriptDir "AutoHotkey_${AhkFallbackVersion}_setup.exe"

function Get-AhkV1Exe {
    $candidates = @(
        "$env:ProgramFiles\AutoHotkey\AutoHotkey.exe",
        "$env:ProgramFiles\AutoHotkey\AutoHotkeyU64.exe",
        "${env:ProgramFiles(x86)}\AutoHotkey\AutoHotkey.exe"
    )
    return ($candidates | Where-Object { Test-Path $_ } | Select-Object -First 1)
}

function Assert-AhkV1Version($exePath) {
    $rawVer = (Get-Item $exePath).VersionInfo.ProductVersion
    # ProductVersion is typically "1.1.37.02" -- take the first token before any separator
    $major = [int](($rawVer -replace '[^0-9.]','') -split '\.')[0]
    return $major, $rawVer
}

function Download-AhkV1Installer($destPath) {
    # Try to resolve the latest v1.x release from GitHub releases API
    $latestUrl = $null
    try {
        Write-Host "  Querying GitHub for the latest AutoHotkey v1 release..."
        $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/AutoHotkey/AutoHotkey/releases" `
                                      -Headers @{ "User-Agent" = "devtoolbox-cheats-installer" } `
                                      -TimeoutSec 10
        # Find the latest tag that starts with "v1."
        $v1release = $releases | Where-Object { $_.tag_name -match '^v1\.' } | Select-Object -First 1
        if ($v1release) {
            $asset = $v1release.assets | Where-Object { $_.name -match '_setup\.exe$' } | Select-Object -First 1
            if ($asset) {
                $latestUrl = $asset.browser_download_url
                Write-Host "  Found latest v1 release: $($v1release.tag_name)"
            }
        }
    } catch {
        Write-Host "  GitHub API unavailable, using known-good fallback URL."
    }

    $downloadUrl = if ($latestUrl) { $latestUrl } else { $AhkFallbackUrl }

    try {
        Write-Host "  Downloading from: $downloadUrl"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $downloadUrl -OutFile $destPath -UseBasicParsing -TimeoutSec 60
        Write-Host "  Download complete." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  Download failed: $_"
        return $false
    }
}

# -- Step 1: Verify / Install AutoHotkey v1 ------------------------------------
Write-Host "`n[1/4] Checking AutoHotkey v1 installation..."

$AhkExe = Get-AhkV1Exe
if ($AhkExe) {
    $major, $rawVer = Assert-AhkV1Version $AhkExe
    if ($major -ne 1) {
        Write-Warning "AutoHotkey v$rawVer detected, but cheats.ahk requires AutoHotkey v1.x."
        Write-Warning "Install v1 from: https://www.autohotkey.com/download/1.x/"
        Write-Warning "(v1 and v2 can coexist; the installer only requires that v1 is present.)"
        exit 1
    }
    Write-Host "  AutoHotkey v$rawVer found at: $AhkExe" -ForegroundColor Green
} else {
    Write-Host "  AutoHotkey v1 not found. Attempting to obtain installer..."

    $installerPath = $null

    # 1st priority: download from official source
    $downloadDest = Join-Path $env:TEMP "ahk_v1_setup.exe"
    $downloaded = Download-AhkV1Installer $downloadDest
    if ($downloaded) {
        $installerPath = $downloadDest
    }

    # 2nd priority: bundled installer shipped alongside this script
    if (-not $installerPath -and (Test-Path $AhkBundled)) {
        Write-Host "  Using bundled installer: $AhkBundled"
        $installerPath = $AhkBundled
    }

    if (-not $installerPath) {
        Write-Warning "Could not obtain an AutoHotkey installer (download failed and no bundled file found)."
        Write-Warning "Please install AutoHotkey v1 manually from: https://www.autohotkey.com/download/1.x/"
        exit 1
    }

    Write-Host ""
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor Yellow
    Write-Host "  |  ACTION REQUIRED: AutoHotkey Setup                       |" -ForegroundColor Yellow
    Write-Host "  |                                                          |" -ForegroundColor Yellow
    Write-Host "  |  1. Choose 'Express Installation' in the window          |" -ForegroundColor Yellow
    Write-Host "  |  2. When finished, click EXIT on the AutoHotkey window   |" -ForegroundColor Yellow
    Write-Host "  |     (the installer WAITS for you -- do NOT skip this!)   |" -ForegroundColor Yellow
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "  Press ENTER when you are ready to launch the AutoHotkey installer"
    Start-Process -FilePath $installerPath -Wait

    # Re-verify after install
    $AhkExe = Get-AhkV1Exe
    if (-not $AhkExe) {
        Write-Warning "AutoHotkey still not detected after installation. Please install manually."
        exit 1
    }
    $major, $rawVer = Assert-AhkV1Version $AhkExe
    if ($major -ne 1) {
        Write-Warning "Detected AutoHotkey v$rawVer after install -- v1 is required."
        exit 1
    }
    Write-Host "  AutoHotkey v$rawVer installed successfully." -ForegroundColor Green
}

# -- Step 2: Copy cheatsheets --------------------------------------------------
Write-Host "`n[2/4] Copying cheatsheets to $DestCheatsDir..."
if (-not (Test-Path $SourceCheatsDir)) {
    Write-Warning "Source cheats.d not found at $SourceCheatsDir."
    exit 1
}
if (Test-Path $DestCheatsDir) {
    Write-Host "  Directory exists -- updating files..."
    Copy-Item -Path "$SourceCheatsDir\*" -Destination $DestCheatsDir -Recurse -Force
} else {
    Copy-Item -Path $SourceCheatsDir -Destination $DestCheatsDir -Recurse -Force
}
Write-Host "  Cheatsheets copied." -ForegroundColor Green

$BundledIcon = Join-Path $ScriptDir "icon.ico"
if (Test-Path $BundledIcon) {
    Copy-Item -Path $BundledIcon -Destination $DestCheatsDir -Force
    Write-Host "  Custom icon deployed to $DestCheatsDir."
}

# -- Step 3: Re-save cheats.ahk with UTF-8 BOM ---------------------------------
Write-Host "`n[3/4] Ensuring cheats.ahk is saved with UTF-8 BOM..."
if (-not (Test-Path $AhkFile)) {
    Write-Warning "cheats.ahk not found at $AhkFile."
    exit 1
}
$AhkContent = Get-Content -Path $AhkFile -Raw
# Set-Content -Encoding UTF8 on Windows PowerShell 5.x writes UTF-8 with BOM
Set-Content -Path $AhkFile -Value $AhkContent -Encoding UTF8
Write-Host "  Encoding verified." -ForegroundColor Green

# -- Step 4: Deploy to Startup folder ------------------------------------------
$StartupEntry = $null

if ($CompileExe) {
    Write-Host "`n[4/4] Compiling cheats.ahk to cheats.exe (optional mode)..."
    $AhkCompiler = "$env:ProgramFiles\AutoHotkey\Compiler\Ahk2Exe.exe"
    if (-not (Test-Path $AhkCompiler)) {
        Write-Warning "Ahk2Exe not found at $AhkCompiler. Falling back to .ahk startup."
        $CompileExe = $false
    } else {
        $OutputFile = Join-Path $ScriptDir "cheats.exe"
        Start-Process -FilePath $AhkCompiler -ArgumentList "/in `"$AhkFile`" /out `"$OutputFile`"" -Wait
        if (Test-Path $OutputFile) {
            Write-Host "  Compilation successful: $OutputFile" -ForegroundColor Green
            Copy-Item -Path $OutputFile -Destination $StartupFolder -Force
            Write-Host "  cheats.exe added to Startup folder." -ForegroundColor Green
            $StartupEntry = Join-Path $StartupFolder "cheats.exe"
        } else {
            Write-Warning "Compilation failed. Falling back to .ahk startup."
            $CompileExe = $false
        }
    }
}

if (-not $CompileExe) {
    Write-Host "`n[4/4] Deploying cheats.ahk to Startup folder (recommended -- AV-safe)..."
    Copy-Item -Path $AhkFile -Destination $StartupFolder -Force
    Write-Host "  cheats.ahk added to Startup folder." -ForegroundColor Green
    $StartupEntry = Join-Path $StartupFolder "cheats.ahk"
}

# -- Launch --------------------------------------------------------------------
Write-Host "`nStarting DevToolbox Cheats..."
Start-Process -FilePath $StartupEntry
Write-Host "App is running! Look for the Gear icon in your system tray." -ForegroundColor Green

Write-Host "`n=============================================="
Write-Host "             INSTALLATION COMPLETE            "
Write-Host "=============================================="
Write-Host ""
if ($CompileExe) {
    Write-Host "Startup mode : cheats.exe (compiled)"
} else {
    Write-Host "Startup mode : cheats.ahk (interpreted -- Windows Defender safe)"
    Write-Host "Tip          : Re-run with -CompileExe if you prefer a compiled executable."
}
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
exit 0
