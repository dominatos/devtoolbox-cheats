# 🪟 DevToolbox Cheats - Windows Setup

This directory contains everything needed to run **devtoolbox-cheats** on Windows using [AutoHotkey](https://www.autohotkey.com/). 

Because Windows doesn't natively support Bash and Linux dialog tools cleanly in the tray, we use an AutoHotkey script (`cheats.ahk`) to create a native Windows system tray menu that opens the markdown cheatsheets in your default text editor.

---

## 🚀 Quick Automated Installation

We provide a PowerShell script that installs AutoHotkey silently, copies the cheatsheets, configures your specific user path, and compiles the executable for you.

1. Open **PowerShell** as Administrator. You can do this by opening the Start menu, typing `PowerShell`, right-clicking it, and selecting **Run as Administrator**.
2. Navigate to this directory (where you cloned/downloaded the repo):
   ```powershell
   cd "C:\path\to\devtoolbox-cheats\Windows-beta"
   ```
3. Run the installer script:
   ```powershell
   .\install-devtoolbox.ps1
   ```
   > **Note:** If you get an execution policy error, run this first: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` or run directly  `powershell.exe -ExecutionPolicy Bypass -File .\install-devtoolbox.ps1`

Once the script completes, you will have a `cheats.exe` file. Double-click it to start the tray application. You can optionally move this `.exe` file into your Startup folder (`Win + R`, type `shell:startup`) to run it automatically on boot!

---

## 🛠 Manual Installation

If you prefer to set it up manually, or if the automated script fails, follow these steps:

### 1. Install AutoHotkey
Run the included installer executable (`AutoHotkey_1.1.37.02_setup.exe`) and proceed with the default installation or download from official website. Please note that it is tested only on v1 of autohotkey.

### 2. Copy the Cheatsheets
Copy the `cheats.d` folder from the root of this project to your Windows User directory.
Your User directory is usually `C:\Users\YourUsername\`.
You should end up with a folder at `C:\Users\YourUsername\cheats.d\`.

### 3. Update the Script Paths
Open `cheats.ahk` in a text editor (like Notepad or VS Code).
At the top of the file, locate these two lines:
```autohotkey
CHEATS_DIR = C:\Users\<USER>\cheats.d
LOG_FILE = C:\Users\<USER>\cheats_debug.log
```
Replace `<USER>` with your actual Windows username. Save the file.

### 4. Compile the Script
1. Find `cheats.ahk` in the File Explorer.
2. Right-click on `cheats.ahk` and select **Compile Script**.
   *(If you don't see this option, find and run `Ahk2Exe.exe` from your AutoHotkey installation folder, usually `C:\Program Files\AutoHotkey\Compiler\`).*
3. This process will generate a native Windows application called `cheats.exe` in the same folder.

### 5. Run & Auto-Start
- **To run immediately:** Double-click `cheats.exe`. You will see a new icon in your system tray (near the clock). Right-click it to access your cheatsheets!
- **To run on boot:** Hold the `Windows Key` and press `R` to open the Run dialog. Type `shell:startup` and press Enter. Copy (or create a shortcut to) `cheats.exe` into this Startup folder.
