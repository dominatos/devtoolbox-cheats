# 📂 Managing Custom Cheatsheets

DevToolbox Cheats makes it easy to use your own custom cheatsheets and change the default directory where they are stored (`~/cheats.d` by default).

This guide explains how to create your own cheatsheets and how to configure a custom directory across different Desktop Environments (DEs).

## 1. Creating Custom Cheatsheets

You have two main approaches to managing custom cheatsheets:
1. **Mix with Official Cheats:** Place them directly in the default `~/cheats.d/` folder.
2. **Fully Isolated:** Configure a completely different directory (e.g., `~/my-cheats`).

### Approach A: Mixing with Official Cheats (Recommended)
You can simply add your own `.md` files to the default `~/cheats.d/` directory! You can create entirely new categories (folders), or place your files inside existing category folders (like `network/` or `basics/`) to have them appear alongside the official cheats.

**Will the updater overwrite my files?** 
No! The built-in `cheats-updater.sh` is designed to be smart. When you run `cheats-updater update`, it will:
- Update the official files.
- Completely ignore any new `.md` files or folders you've created. It will leave them alone and mark them as `(custom)` in the update output.
*(Note: Do not edit the official `.md` files directly if you want to keep your changes, as the updater will overwrite them. Always create a new file like `mysql-custom.md`.)*

### Approach B: Fully Isolated Directory
If you prefer a completely separate directory (e.g. to sync via Nextcloud/Git), you can configure the app to look elsewhere instead of `~/cheats.d/`.

### Directory Structure & Metadata
Whether you use the default folder or a custom one, cheatsheets are Markdown files organized in subfolders. The subfolder name determines the category.

```text
~/cheats.d/
├── my-custom-category/
│   ├── git-aliases.md
│   └── docker-tips.md
└── network/                  <-- You can use existing category folders!
    ├── nginx-custom.md
    └── ssh-keys.md
```

### Metadata Format
Each `.md` file must contain metadata in the first 80 lines:

```markdown
Title: My Git Aliases
Group: My Custom Category
Icon: 🧬
Order: 1

# My Git Aliases
...
```

- **Title:** Display name in the menu.
- **Group:** Category name (should match folder intent). This is what actually shows up as the category name in the UI.
- **Icon:** Emoji or system icon name.
- **Order:** Sort order within the group (1-999).

### How to Add a New Category Folder
To create a brand new category from scratch, simply create a new folder and add a `.md` file inside it:

```bash
# 1. Create a new folder
mkdir -p ~/cheats.d/my-custom-tools

# 2. Create your markdown file inside it
touch ~/cheats.d/my-custom-tools/first-cheat.md
```
Then, add the metadata shown above to `first-cheat.md`. Make sure the `Group:` field matches your intended category name.

### Seeing Changes in the UI
Both GNOME (Argos) and KDE Plasma handle your custom categories automatically:

- **🟠 GNOME (Argos):** Argos refreshes the menu every 30 seconds automatically based on the script's filename (`.30s.sh`). To see your new category instantly, you can either just wait a few seconds, or toggle the Argos extension off and on to force an immediate refresh.
- **🔵 KDE Plasma:** The widget uses a lightning-fast JSON cache and automatically detects changes in the background. If you don't see your new category immediately, right-click the widget -> **Configure DevToolbox Cheats...** and ensure **Auto-Rebuild Cache** is checked.

---

## 2. Configuring a Custom Directory (Per DE)

If you want to use a different folder (e.g., `~/Documents/my-cheats` or a synced Nextcloud/Dropbox folder) instead of the default `~/cheats.d`, follow the instructions for your Desktop Environment:

### 🔵 KDE Plasma 5 / 6
In KDE, you can change the directory directly through the widget GUI:
1. Right-click the **DevToolbox Cheats** widget on your panel.
2. Select **Configure DevToolbox Cheats...**
3. In the configuration window, find the **Cheats Directory** field.
4. Change it from `~/cheats.d` to your custom path (e.g., `/home/username/Documents/my-cheats`).
5. Click **Apply** or **OK**.

### 🟠 GNOME (Argos Extension)
Argos runs the script from its config directory. You can set the environment variable globally or modify the script:

**Option A (Modify Script):**
1. Open `~/.config/argos/devtoolbox-cheats.30s.sh` (or whichever name it has) in your text editor.
2. Add `export CHEATS_DIR="/path/to/your/custom/dir"` near the top of the file.

**Option B (Global Environment):**
1. Add `export CHEATS_DIR="/path/to/your/custom/dir"` to your `~/.profile` or `~/.bashrc`.
2. Restart your session or reload the Argos extension.

### 🟢 Dialog Menus & Tiling WMs (XFCE, MATE, Cinnamon, i3, Sway, etc.)
If you launch the cheats via terminal, keybinding, or a panel launcher using the `devtoolbox-cheats-menu` script:
1. Open your shell profile file (e.g., `~/.bashrc`, `~/.zshrc`, or `~/.profile`).
2. Add the following line:
   ```bash
   export CHEATS_DIR="/path/to/your/custom/dir"
   ```
3. Restart your terminal or re-login for the changes to take effect.

*Note: If you run it from a keybinding in i3/Sway, you might need to specify the environment variable in the keybinding command: `exec CHEATS_DIR=~/my-cheats devtoolbox-cheats-menu menu`.*

### 🪟 Windows (Native Tray App)
The Windows AutoHotkey implementation defaults to your user profile's `cheats.d` folder. To change it:
1. Open the source file `Windows-beta/cheats.ahk` in a text editor.
2. Locate line 9:
   ```autohotkey
   CHEATS_DIR := UserProfile . "\cheats.d"
   ```
3. Change it to your desired absolute path, for example:
   ```autohotkey
   CHEATS_DIR := "C:\Users\Username\Documents\my-cheats"
   ```
4. Run the script again or re-compile it using Ahk2Exe.

### 🔄 Auto-Updater Config
If you use the `cheats-updater.sh` and want to update cheats in your custom directory, simply run it with the environment variable:
```bash
CHEATS_DIR=/path/to/your/custom/dir cheats-updater update
```
