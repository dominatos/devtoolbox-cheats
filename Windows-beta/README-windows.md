# 🪟 DevToolbox Cheats - Windows Setup Guide

Welcome! This guide will help you install and run **devtoolbox-cheats** on your Windows computer.

Since Windows works a bit differently than Linux or Mac, we use a tool called **[AutoHotkey](https://www.autohotkey.com/)** to create a handy menu in your system tray (the area near your clock). This menu will let you quickly open your cheatsheets in your default text editor (like Notepad).

---

## 🚀 Automatic Setup (Recommended for beginners)

We have created an automated installer that does all the hard work for you. It installs what you need and sets up your files.

### Step 1: Open PowerShell
1. Click your Windows **Start menu** (the Windows icon in the bottom left).
2. Type the word `PowerShell`.
3. Click on **Windows PowerShell** in the search results to open it.

### Step 2: Run the Installer
Next, we need to tell PowerShell to run our setup file.
1. Find the folder where you downloaded these files. Click on the address bar at the top of your folder window to see the path, right-click, and select **Copy**. (It might look something like `C:\Users\YourName\Downloads\devtoolbox-cheats\Windows-beta`).
2. In the blue PowerShell window, type `cd` (which means "change directory"), press **Space**, and then paste the path to your folder inside quote marks. Press **Enter**.
   *Example:*
   ```powershell
   cd "C:\path\to\devtoolbox-cheats\Windows-beta"
   ```
3. Now, type the following command exactly as it is and press **Enter**:
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File .\install-devtoolbox.ps1
   ```
   *(Don't worry about the complex text—it just tells your computer it's safe to run our installer!)*

### Step 3: Install AutoHotkey
While the PowerShell script is running, an **AutoHotkey** installation window will automatically pop up.
- Click **Yes** if Windows asks for permission.
- Click **Express Installation** when the setup window appears.
- Once it finishes installing, return to your PowerShell window and it will automatically continue!

### Step 4: Start the App!
When the text stops moving in the PowerShell window and you see "INSTALLATION COMPLETE", you are done! You can close PowerShell.
Look inside your `Windows-beta` folder again. You should now see a new application file named **cheats.exe** (it usually has a green square icon with a white "H").
- **Double-click `cheats.exe`** to start it.
- Check your system tray (bottom-right of your screen, near the volume and Wi-Fi icons; you might need to click the `^` arrow to see hidden icons). You will see a new green "H" icon. Right-click it to safely access your cheatsheets!

**Note:** The setup script automatically adds the app to your Windows Startup folder, so it will run on its own from now on when you turn on your PC!

---

## 🛠 Manual Setup (If the automatic setup fails)

If the steps above didn't work or you prefer doing things manually, you can set it up in a few easy steps:

### 1. Install AutoHotkey
Find the file named `AutoHotkey_1.1.37.02_setup.exe` in this folder and double-click it. You can also download it directly from the **[official AutoHotkey website](https://www.autohotkey.com/)**. Follow the simple on-screen instructions to install it. Just click "Express Installation" when asked.

### 2. Copy the Cheatsheets Folder
1. Go back to the main `devtoolbox-cheats` folder (one folder up).
2. Right-click the folder named `cheats.d` and select **Copy**.
3. Go to your personal User folder. This is usually `C:\Users\YourName\`.
4. Right-click an empty space and select **Paste**. You should now see the `cheats.d` folder sitting there.

### 3. Edit the Settings
1. Go back into this `Windows-beta` folder.
2. Right-click the file named `cheats.ahk` and select **Open with... > Notepad**.
3. Near the top, you will see these lines:
   ```text
   CHEATS_DIR = C:\Users\<USER>\cheats.d
   LOG_FILE = C:\Users\<USER>\cheats_debug.log
   ```
4. Change `<USER>` to your actual Windows username. *(For example: `C:\Users\John\cheats.d`)*
5. Click **File > Save**, then close Notepad.

### 4. Create the App
1. Right-click on that same `cheats.ahk` file and choose **Compile Script**.
2. Wait a second, and a new `cheats.exe` file will appear right next to it! *(If you don't see "Compile Script", double check that AutoHotkey is fully installed).*

### 5. Run It
- Double-click `cheats.exe` to run it right now. It will appear in your system tray (bottom right).
- **To make it start automatically every time you start your computer:** Press the **Windows Key** and **R** together, type `shell:startup`, and press **Enter**. A new folder will open. Drag or copy your `cheats.exe` file into this startup folder!
