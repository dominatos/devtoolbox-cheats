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

Once the script completes, the DevToolbox Cheats application will automatically launch and place itself in your system tray. It has also been added to your Windows startup folder automatically (`shell:startup`) using a **dual-file strategy** (`cheats.exe` + `cheats.ahk`) for maximum reliability because Windows Defender may occasionally flag the compiled `cheats.exe` as `Trojan:Script/Wacatac.H!ml`.

> [!NOTE]
> We now use a professional **Gear icon** in the tray instead of the default "H" icon.

---

## 🛡️ Antivirus & False Positives (Wacatac)

Windows Defender may occasionally flag the compiled `cheats.exe` as `Trojan:Script/Wacatac.H!ml`. 
- **This is a safe false positive.** It occurs because AutoHotkey's compilation process bundles a script with an interpreter, which heuristic scanners sometimes find suspicious. 
- **Our Solution:** To ensure the tool remains functional even if your antivirus deletes the EXE, our installer automatically copies the original `.ahk` script to your startup folder as well. Windows will run the script directly using the installed AutoHotkey interpreter, which is almost never flagged by antivirus software.

---

## 🛠 Manual Installation

If you prefer a manual setup, or if the automated script fails, follow these steps:

### 1. Install AutoHotkey
Run the included installer executable (`AutoHotkey_1.1.37.02_setup.exe`), or download it directly from the [official AutoHotkey website](https://www.autohotkey.com/). Proceed with the standard installation. Please note that it is tested only on AutoHotkey v1.

### 2. Copy the Cheatsheets
Copy the `cheats.d` folder from the root of this project to your Windows User directory.
You should end up with a folder at `C:\Users\YourUsername\cheats.d\`.

The script now automatically detects your Windows user profile path, so no manual editing is required!

3. This process will generate a native Windows executable called `cheats.exe` in the same folder.

> [!IMPORTANT]
> **Technical Note: Encoding (BOM)**
> If you see artifacts like `â€”` in your menu after compiling manually, it means the file was saved as "UTF-8" instead of **"UTF-8 with BOM"**. 
> - **Notepad++ Fix:** Open `cheats.ahk`, click the **Encoding** menu, select ** convert to UTF-8 with BOM**, and save.
> - **VS Code Fix:** Open the file, click "UTF-8" in the bottom status bar, select "Save with Encoding", and choose "UTF-8 with BOM".
> - **AutoHotkey v1** requires this BOM to correctly interpret special characters like em-dashes and symbols.

### ❓ Customizing the Tray Icon
You can use your own `.ico` file! 
1. Rename your icon file to `icon.ico`.
2. Place it inside your **`cheats.d`** folder (the one in your User directory).
3. The script will automatically detect it and use it on the next launch.

### 5. Run & Auto-Start
- **To run immediately:** Double-click `cheats.exe` or `cheats.ahk`. You will see a new **Gear icon** in your system tray. Right-click it to access your cheatsheets.
- **To run on boot:** Hold the `Windows Key` and press `R` to open the Run dialog. Type `shell:startup` and press Enter. Copy **both** `cheats.exe` and `cheats.ahk` into this Startup folder for maximum reliability.

---

## ❓ Troubleshooting: Duplicate Icons
If you see **two Gear icons** in your system tray after a reboot, it means both the EXE and the AHK script were launched. 
1. Right-click the duplicate icons and select **Exit** for both.
2. Open your startup folder (`shell:startup`).
3. Delete one of the files—preferably the `.exe` if it was the one being flagged by your antivirus.
4. Restart the remaining file.
