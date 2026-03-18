# 🪟 DevToolbox Cheats - Windows Setup

This directory contains everything needed to run **devtoolbox-cheats** on Windows using [AutoHotkey](https://www.autohotkey.com/). 

Because Windows doesn't natively support Bash and Linux dialog tools cleanly in the tray, we use an AutoHotkey script (`cheats.ahk`) to create a native Windows system tray menu that opens the markdown cheatsheets in your default text editor.

---

## 🚀 Quick Automated Installation

We provide a PowerShell script that interactively installs AutoHotkey (if missing), copies the cheatsheets to your user directory, configures the necessary paths, compiles the executable, and automatically adds it to your startup folder.

### Fast Track: One-Liner Installation
If you already have `git` and just want to get up and running instantly, open a standard **PowerShell** window *(do **not** run as Administrator)* and paste this exact command:
```powershell
git clone https://github.com/dominatos/devtoolbox-cheats.git; cd devtoolbox-cheats\Windows-beta; powershell.exe -ExecutionPolicy Bypass -File .\install-devtoolbox.ps1
```
*(After running it, skip straight to step 3 below!)*

---
### Or Follow Step-by-Step:

### 1. Clone the Repository
If you haven't already, run `git clone` to get a local copy of the `devtoolbox-cheats` repository to your Windows machine:
```cmd
git clone https://github.com/dominatos/devtoolbox-cheats.git
```

### 2. Run the Installer
1. Open up a standard **PowerShell** window.
   *(Do **not** run as Administrator! If you run it as an Administrator, the script will incorrectly install the cheatsheets and auto-start shortcuts to the `Administrator` user profile instead of your own).*
2. Navigate to the Windows directory of the cloned repository:
   ```powershell
   cd "C:\path\to\devtoolbox-cheats\Windows-beta"
   ```
3. Run the installer script, bypassing the execution policy:
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File .\install-devtoolbox.ps1
   ```
3. **AutoHotkey Installation:** During the process, an AutoHotkey installer window will appear. Follow the interactive prompts (Express Installation is recommended). 
   > **IMPORTANT:** When the installation is completely done, make sure to click **Exit** on the AutoHotkey window so the deployment script can resume!

Once the script completes, the `cheats.exe` application will automatically launch and place itself in your system tray. It has also been added to your Windows startup folder automatically (`shell:startup`), so it will run continuously on boot!

---

## 🛠 Manual Installation

If you prefer a manual setup, or if the automated script fails, follow these steps:

### 1. Install AutoHotkey
Run the included installer executable (`AutoHotkey_1.1.37.02_setup.exe`), or download it directly from the [official AutoHotkey website](https://www.autohotkey.com/). Proceed with the standard installation. Please note that it is tested only on AutoHotkey v1.

### 2. Copy the Cheatsheets
Copy the `cheats.d` folder from the root of this project to your Windows User directory.
You should end up with a folder at `C:\Users\YourUsername\cheats.d\`.

### 3. Update the Script Paths
Open `cheats.ahk` in a text editor (like Notepad or VS Code). At the top of the file, locate these two lines:
```autohotkey
CHEATS_DIR = C:\Users\<USER>\cheats.d
LOG_FILE = C:\Users\<USER>\cheats_debug.log
```
Replace `<USER>` with your actual Windows username. Save the file.

### 4. Compile the Script
1. Find `cheats.ahk` in the File Explorer.
2. Right-click on `cheats.ahk` and select **Compile Script**.
   *(If you don't see this option, run `Ahk2Exe.exe` from your AutoHotkey compiler folder, usually `C:\Program Files\AutoHotkey\Compiler\`).*
3. This process will generate a native Windows executable called `cheats.exe` in the same folder.

### 5. Run & Auto-Start
- **To run immediately:** Double-click `cheats.exe`. You will see a new green "H" icon in your system tray. Right-click it to access your cheatsheets.
- **To run on boot:** Hold the `Windows Key` and press `R` to open the Run dialog. Type `shell:startup` and press Enter. Copy (or create a shortcut to) `cheats.exe` into this Startup folder.
