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
$InstallDir      = Join-Path $env:LOCALAPPDATA "devtoolbox-cheats"

# -- AutoHotkey v1 installer resolution ----------------------------------------
# Known-good fallback URL (last stable v1.1 release as of 2026)
$AhkFallbackVersion = "1.1.37.02"
$AhkFallbackUrl     = "https://github.com/AutoHotkey/AutoHotkey/releases/download/v$AhkFallbackVersion/AutoHotkey_${AhkFallbackVersion}_setup.exe"
$AhkBundled         = Join-Path $ScriptDir "AutoHotkey_${AhkFallbackVersion}_setup.exe"
# SHA-256 of the official AutoHotkey v1.1.37.02 setup.exe from GitHub releases
# Verified against: https://github.com/AutoHotkey/AutoHotkey/releases/tag/v1.1.37.02
$AhkExpectedHash    = "49a48e879f7480238d2fe17520ac19afe83685aac0b886719f9e1eac818b75cc"

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
    $downloadUrl = $AhkFallbackUrl

    try {
        Write-Host "  Downloading from: $downloadUrl"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $downloadUrl -OutFile $destPath -UseBasicParsing -TimeoutSec 60
        Write-Host "  Download complete." -ForegroundColor Green
        
        Write-Host "  Verifying SHA-256 hash..."
        $fileHash = (Get-FileHash -Path $destPath -Algorithm SHA256).Hash.ToLower()
        if ($fileHash -ne $AhkExpectedHash) {
            Write-Warning "SHA-256 mismatch! Expected: $AhkExpectedHash"
            Write-Warning "                      Got: $fileHash"
            Write-Warning "File may be tampered or corrupted."
            Remove-Item $destPath -Force
            return $false
        }
        Write-Host "  SHA-256 hash verified." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  Download failed: $_"
        return $false
    }
}

# -- Step 1: Verify / Install AutoHotkey v1 ------------------------------------
Write-Host "`n[1/5] Checking AutoHotkey v1 installation..."

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
    
    $fileHash = (Get-FileHash -Path $installerPath -Algorithm SHA256).Hash.ToLower()
    if ($fileHash -ne $AhkExpectedHash) {
        Write-Warning "Installer SHA-256 hash mismatch before execution. Aborting."
        Write-Warning "Expected: $AhkExpectedHash"
        Write-Warning "     Got: $fileHash"
        exit 1
    }

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
Write-Host "`n[2/5] Copying cheatsheets to $DestCheatsDir..."
if (-not (Test-Path $SourceCheatsDir)) {
    Write-Warning "Source cheats.d not found at $SourceCheatsDir."
    exit 1
}
try {
    if (Test-Path $DestCheatsDir) {
        Write-Host "  Directory exists -- updating files..."
        Copy-Item -Path "$SourceCheatsDir\*" -Destination $DestCheatsDir -Recurse -Force
    } else {
        Copy-Item -Path $SourceCheatsDir -Destination $DestCheatsDir -Recurse -Force
    }
    Write-Host "  Cheatsheets copied." -ForegroundColor Green
} catch {
    Write-Warning "Failed to copy cheatsheets: $_"
    exit 1
}

$BundledIcon = Join-Path $ScriptDir "icon.ico"
if (Test-Path $BundledIcon) {
    try {
        Copy-Item -Path $BundledIcon -Destination $DestCheatsDir -Force
        Write-Host "  Custom icon deployed to $DestCheatsDir."
    } catch {
        Write-Warning "  Could not copy icon (non-critical): $_"
    }
}

# -- Step 3: Re-save cheats.ahk with UTF-8 BOM ---------------------------------
Write-Host "`n[3/5] Ensuring cheats.ahk is saved with UTF-8 BOM..."
if (-not (Test-Path $AhkFile)) {
    Write-Warning "cheats.ahk not found at $AhkFile."
    exit 1
}
try {
    $AhkContent = Get-Content -Path $AhkFile -Raw
    # Set-Content -Encoding UTF8 on Windows PowerShell 5.x writes UTF-8 with BOM
    Set-Content -Path $AhkFile -Value $AhkContent -Encoding UTF8
    Write-Host "  Encoding verified." -ForegroundColor Green
} catch {
    Write-Warning "Failed to re-encode cheats.ahk: $_"
    exit 1
}

# -- Step 4: Deploy to Startup folder ------------------------------------------
$StartupEntry = $null

if ($CompileExe) {
    Write-Host "`n[4/5] Compiling cheats.ahk to cheats.exe (optional mode)..."
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
            if (Test-Path (Join-Path $StartupFolder "cheats.ahk")) {
                Remove-Item (Join-Path $StartupFolder "cheats.ahk") -Force
            }
            if (Test-Path (Join-Path $StartupFolder "cheats.lnk")) {
                Remove-Item (Join-Path $StartupFolder "cheats.lnk") -Force
            }
            $StartupEntry = Join-Path $StartupFolder "cheats.exe"
        } else {
            Write-Warning "Compilation failed. Falling back to .ahk startup."
            $CompileExe = $false
        }
    }
}

if (-not $CompileExe) {
    Write-Host "`n[4/5] Deploying cheats shortcut to Startup folder (recommended -- AV-safe)..."
    try {
        $StartupEntry = Join-Path $StartupFolder "cheats.lnk"
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($StartupEntry)
        $Shortcut.TargetPath = $AhkExe
        $Shortcut.Arguments = "`"$AhkFile`""
        $Shortcut.Save()

        Write-Host "  cheats.lnk shortcut added to Startup folder." -ForegroundColor Green

        if (Test-Path (Join-Path $StartupFolder "cheats.exe")) {
            Remove-Item (Join-Path $StartupFolder "cheats.exe") -Force
        }
        if (Test-Path (Join-Path $StartupFolder "cheats.ahk")) {
            Remove-Item (Join-Path $StartupFolder "cheats.ahk") -Force
        }
    } catch {
        Write-Warning "Failed to create startup shortcut: $_"
        exit 1
    }
}

# -- Step 5: Setup Background Updater ------------------------------------------
Write-Host "`n[5/5] Background Updater"
$TaskName = "DevToolboxCheatsUpdater"
$UpdaterEnabled = $false

# Check if the task already exists
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "  Background updater is already configured." -ForegroundColor Green
    $UpdaterEnabled = $true
} else {
    $response = Read-Host "  Do you want to create a scheduled task for updating cheats.d daily? [Y/n]"
    if ([string]::IsNullOrWhiteSpace($response) -or $response -match "^[yY]") {
        Write-Host "  Setting up background updater..."
        $UpdaterScriptSource = Join-Path $ScriptDir "update-cheats.ps1"
        $UpdaterLauncherSource = Join-Path $ScriptDir "update-launcher.vbs"

        if ((Test-Path $UpdaterScriptSource) -and (Test-Path $UpdaterLauncherSource)) {
            $UpdaterScriptDest = Join-Path $InstallDir "update-cheats.ps1"
            $UpdaterLauncherDest = Join-Path $InstallDir "update-launcher.vbs"

            try {
                if (-not (Test-Path $InstallDir)) {
                    New-Item -ItemType Directory -Path $InstallDir -Force -ErrorAction Stop | Out-Null
                }
                Copy-Item -Path $UpdaterScriptSource -Destination $UpdaterScriptDest -Force -ErrorAction Stop
                Copy-Item -Path $UpdaterLauncherSource -Destination $UpdaterLauncherDest -Force -ErrorAction Stop
            } catch {
                Write-Warning "  Failed to copy updater scripts: $_"
            }

            # Register Scheduled Task
            try {
                $Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$UpdaterLauncherDest`""
                $Trigger = New-ScheduledTaskTrigger -Daily -At 12:00PM
                $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

                Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Daily background updater for DevToolbox Cheats" -Force | Out-Null

                Write-Host "  Scheduled task '$TaskName' created successfully." -ForegroundColor Green
                $UpdaterEnabled = $true
            } catch {
                Write-Warning "  Failed to register scheduled task: $_"
                Write-Warning "  You can run update-cheats.ps1 manually to update cheatsheets."
            }
        } else {
            Write-Warning "  Updater scripts not found in $ScriptDir. Skipping task creation."
        }
    } else {
        Write-Host "  Skipping background updater setup."
    }
}

# -- Launch --------------------------------------------------------------------
Write-Host "`nStarting DevToolbox Cheats..."
try {
    if ($CompileExe) {
        Start-Process -FilePath $StartupEntry
    } else {
        Start-Process -FilePath $AhkExe -ArgumentList "`"$AhkFile`""
    }
    Write-Host "App is running! Look for the Gear icon in your system tray." -ForegroundColor Green
} catch {
    Write-Warning "Failed to launch DevToolbox Cheats: $_"
    Write-Warning "You can start it manually from: $StartupEntry"
}

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
if ($UpdaterEnabled) {
    Write-Host "Auto-update  : Enabled (daily at 12:00 PM via Task Scheduler)"
} else {
    Write-Host "Auto-update  : Disabled (re-run installer to enable)"
}
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
exit 0
