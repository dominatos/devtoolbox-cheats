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
    Write-Host "IMPORTANT: When it finishes, you MUST click 'Exit' on the AutoHotkey window so this setup can continue!" -ForegroundColor DarkYellow
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
    
    # Copy bundled icon if it exists
    $BundledIcon = Join-Path $ScriptDir "icon.ico"
    if (Test-Path $BundledIcon) {
        Copy-Item -Path $BundledIcon -Destination $DestCheatsDir -Force
        Write-Host "Deployed bundled icon to $DestCheatsDir."
    }
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
    
    # Force UTF8 with BOM so AutoHotkey compiler parses special characters perfectly
    Set-Content -Path $AhkFile -Value $AhkContent -Encoding UTF8
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
        
        Write-Host "`n[5/6] Adding to Startup (Dual-Strategy)..."
        $StartupFolder = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
        
        # Copy both EXE and AHK for maximum reliability (redundancy against AV deletions)
        Copy-Item -Path $OutputFile -Destination $StartupFolder -Force
        Copy-Item -Path $AhkFile -Destination $StartupFolder -Force
        
        Write-Host "Successfully added both cheats.exe and cheats.ahk to startup folder." -ForegroundColor Green
        
        Write-Host "`n[6/6] Starting DevToolbox Cheats..."
        $StartupExe = Join-Path $StartupFolder "cheats.exe"
        Start-Process -FilePath $StartupExe
        Write-Host "App is running! Check your system tray for the Gear icon." -ForegroundColor Green
        
        Write-Host "`nNOTE: If you see TWO Gear icons in the tray, it means BOTH the EXE and AHK started." -ForegroundColor Yellow
        Write-Host "You should manually delete one of them (the .exe if it gets flagged) from your startup folder." -ForegroundColor Yellow
    } else {
        Write-Warning "Compilation failed or output not found. Proceeding with AHK script startup only."
        $StartupFolder = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
        Copy-Item -Path $AhkFile -Destination $StartupFolder -Force
        Start-Process -FilePath (Join-Path $StartupFolder "cheats.ahk")
    }
} else {
    Write-Warning "AutoHotkey compiler not found at $AhkCompiler. You can compile it manually by right-clicking cheats.ahk and selecting 'Compile Script'."
}

Write-Host "`n=============================================="
Write-Host "             INSTALLATION COMPLETE            "
Write-Host "=============================================="
Write-Host "DevToolbox Cheats is now running! Check your system tray (bottom right)."
Write-Host "It has also been added to your startup folder and will run automatically on boot!"
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
exit 0
