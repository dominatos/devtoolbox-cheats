# Zenity & Yad Pango Markup Bug — Analysis & Implementation Plan

## 1. Analysis of the Cause

**The Problem:**
You observed that Yad fallback in compact mode and Zenity in general have problems listing categories and cheatsheets. Symptoms include:
- Missing categories (e.g., "Backups & S3", "Dev & Tools", "Files & Archives")
- Strange duplicated entries in the UI (e.g., "Package Managers" appearing multiple times)
- Corrupted or empty rows

**The Root Cause:**
Zenity and Yad use GTK/Pango to render text in their dialogs (specifically in `--list`, `--info`, and `--entry`). Pango interprets the ampersand character (`&`) as the start of an HTML/XML entity (e.g., `&amp;`). 

Because category names like `Backups & S3` and cheatsheet titles contain unescaped `&` characters, Pango fails to parse the markup. This causes Yad/Zenity to either:
1. Completely drop the item (causing it to disappear).
2. Render an empty/blank cell, which pushes the list out of alignment or leaves ghost rows (which appear as duplicates).

Our testing confirmed that `yad --list` and `yad --info` emit `Gtk-WARNING **: Failed to set text from markup` when fed these strings.

---

## 2. Proposed Changes

We will fix this centrally within the **Cross-DE Abstraction Layer** of the scripts. This ensures the fix applies automatically to all menus (`compactMenu`, `standaloneMenu`, `browseAllCheatsFS`, etc.) without needing to change how cheatsheets are parsed or stored.

### Target Files:
- `devtoolbox-cheats.30s.sh` (Main script)
- `devtoolbox-cheats-zenity-cheatslist-DEV.30s.sh` (DEV variant)
- `devtoolbox-cheats-separate-menu-DEV.30s.sh` (DEV variant)

### Step 1: Fix `list_dialog`
We will intercept the items before they are passed to `yad` or `zenity`, escape the `&` to `&amp;`, and then unescape the user's selection when it returns.

```bash
    yad)
      if [[ $# -gt 0 ]]; then
        local escaped_items=()
        for item in "$@"; do escaped_items+=("${item//&/&amp;}"); done
        printf '%s\n' "${escaped_items[@]}" | yad --list --title="$title" --column="$col" --center --width="$w" --height="$h" 2>/dev/null | cut -d'|' -f1 | sed 's/&amp;/\&/g'
      else
        sed 's/&/\&amp;/g' | yad --list --title="$title" --column="$col" --center --width="$w" --height="$h" 2>/dev/null | cut -d'|' -f1 | sed 's/&amp;/\&/g'
      fi
      ;;
    zenity)
      # (Same escaping logic applied for Zenity)
```

### Step 2: Fix `info_dialog` and `input_dialog`
These dialogs also suffer from the same Pango markup bug. We will escape the text strings passed to them:

```bash
info_dialog() {
    # ...
    yad)     yad --info --title="$title" --text="${msg//&/&amp;}" --center 2>/dev/null ;;
    zenity)  zenity --info --title="$title" --text="${msg//&/&amp;}" 2>/dev/null ;;
    # ...
}

input_dialog() {
    # ...
    yad)     yad --entry --title="$title" --text="${prompt//&/&amp;}" --center 2>/dev/null ;;
    zenity)  zenity --entry --title="$title" --text="${prompt//&/&amp;}" 2>/dev/null ;;
    # ...
}
```

> [!NOTE]
> `text_dialog` uses `--text-info` which natively handles raw text and does not interpret Pango markup by default. It does not require escaping.

---

## 3. Verification Plan

1. **Syntax Check:** Run `bash -n` on all modified scripts.
2. **Linting Check:** Run `shellcheck` to ensure bash substitutions are safe.
3. **Execution Test:** Run `DEVTOOLBOX_DE=terminal ./devtoolbox-cheats.30s.sh` and force `yad` selection in the code.
4. **Visual Verification:** Open the `compactMenu` or `browseAllCheatsFS`. Confirm that "Backups & S3" and all other `&` categories are now visible and that no duplicate ghost rows appear.
5. **Selection Test:** Click on a category with `&` (e.g., `Dev & Tools`) and confirm it correctly opens the cheatsheets for that category (proving that the unescaping `sed` command correctly returned the original string).

## User Review Required

Does this analysis align with the symptoms you experienced? I am ready to implement this fix across the scripts once you approve.
