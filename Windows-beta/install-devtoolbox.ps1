<#
.SYNOPSIS
    Automated Windows setup for DevToolbox Cheats.
.DESCRIPTION
    This script checks for Administrator rights, installs AutoHotkey silently,
    copies the 'cheats.d' folder to the current user's location,
    updates the configuration in 'cheats.ahk', and compiles it.
#>

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BaseDir = Split-Path -Parent $ScriptDir
$SourceCheatsDir = Join-Path $BaseDir "cheats.d"
$UserProfileDir = $env:USERPROFILE
$DestCheatsDir = Join-Path $UserProfileDir "cheats.d"

# Step 1: Install AutoHotkey
Write-Host "`n[1/4] Installing AutoHotkey..."
$AhkInstaller = Join-Path $ScriptDir "AutoHotkey_1.1.37.02_setup.exe"
if (Test-Path $AhkInstaller) {
    Write-Host "Found AutoHotkey installer. An installation window will pop up soon."
    Write-Host "Please follow the on-screen instructions to install it (Express Installation is recommended)."
    Write-Host "Waiting for you to finish the installation..."
    Start-Process -FilePath $AhkInstaller -Wait
    Write-Host "AutoHotkey installation finished."
} else {
    Write-Warning "Could not find AutoHotkey_1.1.37.02_setup.exe in $ScriptDir"
    Write-Warning "You will need to install AutoHotkey manually."
}

# Step 2: Copy cheats.d
Write-Host "`n[2/4] Copying cheats.d to your User Profile ($DestCheatsDir)..."
if (Test-Path $SourceCheatsDir) {
    if (Test-Path $DestCheatsDir) {
        Write-Host "Target directory already exists. Overwriting files..."
        Copy-Item -Path "$SourceCheatsDir\*" -Destination $DestCheatsDir -Recurse -Force
    } else {
        Copy-Item -Path $SourceCheatsDir -Destination $DestCheatsDir -Recurse -Force
    }
    Write-Host "Successfully copied cheatsheets."
} else {
    Write-Warning "Could not find source cheats.d at $SourceCheatsDir. Ensure this folder is complete."
}

# Step 3: Update cheats.ahk
Write-Host "`n[3/4] Configuring user paths in cheats.ahk..."
$AhkFile = Join-Path $ScriptDir "cheats.ahk"
if (Test-Path $AhkFile) {
    $AhkContent = Get-Content -Path $AhkFile
    
    # Replace the generic <USER> with the actual Windows username
    $AhkContent = $AhkContent -replace "<USER>", $env:USERNAME
    
    Set-Content -Path $AhkFile -Value $AhkContent
    Write-Host "Paths updated to point to $UserProfileDir."
} else {
    Write-Warning "Could not find cheats.ahk at $AhkFile."
}

# Step 4: Compile cheats.ahk
Write-Host "`n[4/4] Compiling cheats.ahk to cheats.exe..."
$AhkCompiler = "$env:ProgramFiles\AutoHotkey\Compiler\Ahk2Exe.exe"
if (Test-Path $AhkCompiler) {
    $OutputFile = Join-Path $ScriptDir "cheats.exe"
    Write-Host "Compiling script..."
    Start-Process -FilePath $AhkCompiler -ArgumentList "/in `"$AhkFile`" /out `"$OutputFile`"" -Wait
    
    if (Test-Path $OutputFile) {
        Write-Host "Compilation successful! Executable is ready at: $OutputFile" -ForegroundColor Green
        
        Write-Host "`n[5/5] Adding to Startup..."
        $StartupFolder = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
        Copy-Item -Path $OutputFile -Destination $StartupFolder -Force
        Write-Host "Successfully copied cheats.exe to startup folder." -ForegroundColor Green
    } else {
        Write-Warning "Compilation failed or output not found."
    }
} else {
    Write-Warning "AutoHotkey compiler not found at $AhkCompiler. You can compile it manually by right-clicking cheats.ahk and selecting 'Compile Script'."
}

Write-Host "`n=============================================="
Write-Host "             INSTALLATION COMPLETE            "
Write-Host "=============================================="
Write-Host "You can now start DevToolbox Cheats by double-clicking cheats.exe"
Write-Host "It has also been added to your startup folder and will run automatically on boot!"
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
exit 0
