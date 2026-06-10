# Combined Argos Script — Analysis & Implementation Plan

## 1. Analysis of the 3 Existing Argos Scripts

### Script 1: [devtoolbox-cheats.30s.sh](file:///home/sviatoslav/devtoolbox-cheats/devtoolbox-cheats.30s.sh) — "Standard" (928 lines)

**Argos Layout Behavior (lines 872–922):**
- Panel icon: `🗒️ Cheatsheets`
- On **small screens**: flat list of utility actions (Search, FZF, Browse, Export, links) + compact menu launcher
- On **normal screens**: `🛠 DevToolbox Functions` submenu (contains all utilities) → then each **category is a top-level Argos submenu** (`echo "$gi $g"`) with all cheats listed as `-- sub-items` inline
- Clicking a cheat → `showCheat` (base64-encoded path, clipboard copy, viewer)

**Unique Features:**
- Inline submenu expansion — all cheats visible under their category without leaving the Argos dropdown
- No state files, no drill-down — stateless per refresh
- Cache file: `~/.cache/devtoolbox-cheats-beta.idx`

---

### Script 2: [devtoolbox-cheats.30s-zenity-cheatslist-DEV.sh](file:///home/sviatoslav/devtoolbox-cheats/devtoolbox-cheats.30s-zenity-cheatslist-DEV.sh) — "Zenity cheat list" (973 lines)

**Argos Layout Behavior (lines 928–972):**
- Panel icon: `🗒️ Cheatsheets`
- Same small-screen vs normal-screen split
- On normal screens: `🛠 DevToolbox Functions` submenu → each **category is a top-level clickable item** that runs `browseDeep_Cheats` via `param1=browseDeep_Cheats param2='<b64group>'`
- Clicking a category → **opens a Zenity/dialog window** listing that category's cheats (not inline in Argos)

**Unique Features:**
- Categories shown at root, but cheats open in external Zenity dialog (good for small screens or preference for separate window)
- Has `calc_max_argos_groups()` function (screen-aware group count), `_SCREEN_DIMS_CACHED` optimization, `_CACHE_CHECKED` per-process guard
- Cache file: `~/.cache/devtoolbox-cheats-zenity-dev.idx`

---

### Script 3: [devtoolbox-cheats.30s-separate-menu-DEV.sh](file:///home/sviatoslav/devtoolbox-cheats/devtoolbox-cheats.30s-separate-menu-DEV.sh) — "Drill-down" (1086 lines)

**Argos Layout Behavior (lines 1017–1085):**
- **Two modes via state file:**
  - **Normal mode**: Panel icon `🗒️ Cheatsheets` → categories shown as clickable items (`param1=setCategory param2='<b64group>' refresh=true`)
  - **Drill-down mode**: Panel icon changes to `📚 Basics` (selected category) → shows `◀ All categories` back button + all cheats for that category inline
- State file: `$XDG_RUNTIME_DIR/devtoolbox-argos-cat.state` with TTL (60s default)

**Unique Features:**
- Drill-down navigation with stateful rendering (state file + TTL expiry)
- Per-category Argos output cache (`~/.cache/devtoolbox-cheats-argos-dev/`)
- `argos_set_category()`, `argos_clear_category()`, `argos_get_category()` helper functions
- `argos_category_lines()` — cached per-category Argos line generator
- `refresh=true` on cheat items for clean back-navigation
- Cache file: `~/.cache/devtoolbox-cheats-dev.idx`

---

### Shared Code (Lines ~1–700 in all 3 cheatsheet scripts)

All 3 scripts share nearly identical code for:
- Config, clipboard, DE detection, dialog tool detection
- Notification/input/info/list/text dialogs
- Terminal detection, `run_in_terminal()`
- `is_argos()`, emoji utilities, screen size detection, `calc_window_size()`
- Base64 helpers, front-matter parsing, `index_cheats()`, `ensure_cache()`
- `showCheat()`, `searchCheatsFS()`, `browseAllCheatsFS()`, `browseDeep_Cheats()`
- `exportAllCheatsFS()`, `fzfSearch()`, `compactMenu()`, `standaloneMenu()`
- Argos param dispatch `case` block

**Differences between the scripts (beyond shared code):**

| Feature | Standard | Zenity | Drill-down |
|---------|----------|--------|------------|
| Cache file name | `devtoolbox-cheats-beta.idx` | `devtoolbox-cheats-zenity-dev.idx` | `devtoolbox-cheats-dev.idx` |
| `_SCREEN_DIMS_CACHED` | No | Yes | Yes |
| `_CACHE_CHECKED` guard | No | Yes | Yes |
| `calc_max_argos_groups()` | No | Yes | Yes |
| `_B64ENC_FLAG` at startup | No | Yes | Yes |
| Argos category cache dir | No | No | Yes (`ARGOS_CAT_CACHE_DIR`) |
| Argos state file (TTL) | No | No | Yes (`ARGOS_CAT_STATE`, `ARGOS_CAT_TTL`) |
| `argos_*_category()` helpers | No | No | Yes (3 functions) |
| `argos_category_lines()` cache | No | No | Yes |
| Argos menu render | Inline submenus | Click → Zenity dialog | State-based drill-down |
| Dispatch: `setCategory` | No | No | Yes |
| Dispatch: `clearCategory` | No | No | Yes |
| Dispatch: `browseDeep_Cheats` | No | Yes | Yes |
| showCheat clears category | No | No | Yes |

---

## 2. Proposed Plan: Combined Script

### Goal

Create `devtoolbox-cheats-combined.30s.sh` that:
1. Contains **all** shared code (using the best/most-optimized version from the DEV scripts)
2. Contains **all 3 Argos layout renderers** in one file
3. Adds a **layout switcher** accessible from the Argos menu itself (no code editing needed)
4. Stores the chosen layout in a persistent config file
5. Defaults to the "Standard" layout if no preference is set
6. Works identically for non-GNOME DEs (uses `standaloneMenu()` — no change)

> [!NOTE]
> `devtools.1m.sh` is **not** in scope — it remains a separate standalone widget.

### Filename Convention

Argos parses the interval from the filename using the pattern `name.interval.sh`. Placing `-` immediately after the interval (e.g., `devtoolbox-cheats.30s-combined.sh`) breaks this parsing.

**Correct format:** variant name goes **before** `.30s.sh`:
- Source file: `devtoolbox-cheats-combined.30s.sh`
- Argos dest: `devtoolbox-cheats-combined.30s.sh`

### Layout Switcher Mechanism

- **Config file**: `~/.config/devtoolbox-cheats/layout.conf`
  - Contains a single value: `standard`, `zenity`, or `drilldown`
  - Read on every Argos render (tiny file, fast `cat`)
  - Written when user switches layout from the menu

- **Menu entry**: Inside `🛠 DevToolbox Functions` submenu, a new `🔄 Layout` sub-submenu with 3 options:
  ```
  🔄 Layout
  -- ✅ Standard (inline submenus)     | bash=... param1=setLayout param2=standard  refresh=true
  --    Zenity (dialog cheat list)      | bash=... param1=setLayout param2=zenity    refresh=true
  --    Drill-down (category → cheats)  | bash=... param1=setLayout param2=drilldown refresh=true
  ```
  - A `✅` checkmark shows which layout is currently active
  - `refresh=true` causes Argos to re-render immediately after selection

> [!IMPORTANT]
> **Design Decision — Config file location**
> I propose `~/.config/devtoolbox-cheats/layout.conf` (XDG-compliant, persistent across reboots).
> Alternative: environment variable `DEVTOOLBOX_LAYOUT=standard|zenity|drilldown`.
> Please confirm your preference.

---

## 3. Step-by-Step Implementation Plan

### Step 0: Fix existing DEV source filenames (prerequisite)

The existing source files use `-` immediately after `.30s`, which breaks Argos interval parsing. Rename them to follow the correct `name.interval.sh` convention:

| Current filename (broken) | New filename (correct) |
|---------------------------|------------------------|
| `devtoolbox-cheats.30s-zenity-cheatslist-DEV.sh` | `devtoolbox-cheats-zenity-cheatslist-DEV.30s.sh` |
| `devtoolbox-cheats.30s-separate-menu-DEV.sh` | `devtoolbox-cheats-separate-menu-DEV.30s.sh` |

Then update [install-dev.sh](file:///home/sviatoslav/devtoolbox-cheats/install-dev.sh) `VARIANTS` array source filenames to match:

```diff
-  "devtoolbox-cheats.30s-zenity-cheatslist-DEV.sh|devtoolbox-cheats-zenity.30s.sh|2) Zenity cheat list (DEV)|..."
+  "devtoolbox-cheats-zenity-cheatslist-DEV.30s.sh|devtoolbox-cheats-zenity.30s.sh|2) Zenity cheat list (DEV)|..."

-  "devtoolbox-cheats.30s-separate-menu-DEV.sh|devtoolbox-cheats-drilldown.30s.sh|3) Separate drill-down menu (DEV)|..."
+  "devtoolbox-cheats-separate-menu-DEV.30s.sh|devtoolbox-cheats-drilldown.30s.sh|3) Separate drill-down menu (DEV)|..."
```

> [!NOTE]
> The Argos **destination** filenames (`devtoolbox-cheats-zenity.30s.sh`, `devtoolbox-cheats-drilldown.30s.sh`) are already correct — no change needed for those.
> The main script `devtoolbox-cheats.30s.sh` is also correctly named — no change needed.

---

### Step 1: Create the combined script skeleton

- Copy the shared code base from `devtoolbox-cheats-separate-menu-DEV.30s.sh` (renamed in Step 0; it has the most complete/optimized version: `_SCREEN_DIMS_CACHED`, `_CACHE_CHECKED`, `_B64ENC_FLAG`, `calc_max_argos_groups()`)
- Use cache file name: `~/.cache/devtoolbox-cheats-combined.idx` (unique, no conflicts with existing scripts)
- Keep the Argos category cache dir: `~/.cache/devtoolbox-cheats-argos-combined/`
- Keep the state file for drill-down: `$XDG_RUNTIME_DIR/devtoolbox-argos-cat-combined.state`

### Step 2: Add layout config read/write functions

New functions:
- `get_layout()` — reads `~/.config/devtoolbox-cheats/layout.conf`, defaults to `standard`
- `setLayout()` — writes the chosen layout, called from Argos menu (`param1=setLayout param2=<layout>`)

### Step 3: Add the layout switcher menu entry

Inside the `🛠 DevToolbox Functions` submenu, add:
```
echo "🔄 Layout"
echo "-- $check_std Standard (inline submenus)     | bash='$SCRIPT_PATH' param1=setLayout param2=standard terminal=false refresh=true"
echo "-- $check_zen Zenity (dialog cheat list)      | bash='$SCRIPT_PATH' param1=setLayout param2=zenity terminal=false refresh=true"
echo "-- $check_dd  Drill-down (category → cheats)  | bash='$SCRIPT_PATH' param1=setLayout param2=drilldown terminal=false refresh=true"
```

Where `$check_std` / `$check_zen` / `$check_dd` show `✅` for the active layout and empty for others.

### Step 4: Implement the 3 Argos render functions

Create 3 dedicated render functions (Argos stdout):
- `render_argos_standard()` — from [devtoolbox-cheats.30s.sh](file:///home/sviatoslav/devtoolbox-cheats/devtoolbox-cheats.30s.sh) lines 903–920
- `render_argos_zenity()` — from `devtoolbox-cheats-zenity-cheatslist-DEV.30s.sh` (renamed in Step 0) lines 959–967
- `render_argos_drilldown()` — from `devtoolbox-cheats-separate-menu-DEV.30s.sh` (renamed in Step 0) lines 1017–1084 (includes state check)

### Step 5: Wire the main render dispatcher

Replace the single-layout Argos render section with:
```bash
_layout="$(get_layout)"
case "$_layout" in
  zenity)    render_argos_zenity ;;
  drilldown) render_argos_drilldown ;;
  *)         render_argos_standard ;;
esac
```

### Step 6: Update the Argos param dispatch

Add new dispatch entries:
```bash
  setLayout)  setLayout "${2:-}" ; exit 0 ;;
```

Keep all existing dispatch entries from the drill-down variant (superset of all 3).

### Step 7: Add combined as option 5 in [install-dev.sh](file:///home/sviatoslav/devtoolbox-cheats/install-dev.sh)

Add to the `VARIANTS` array:
```bash
"devtoolbox-cheats-combined.30s.sh|devtoolbox-cheats-combined.30s.sh|5) Combined (all layouts)|All 3 layouts in one script. Switch between Standard, Zenity, and Drill-down directly from the Argos menu without editing files."
```

Update the `print_variants` function to show option 5.
Update the dispatch `case` to handle `"5"`.
Update `install_all` references (now 4 variants, option becomes `"5"` for install-all).

---

## 4. Impact Assessment

| Area | Impact |
|------|--------|
| Existing 3 scripts | **None** — new file only, no modifications to originals |
| `devtools.1m.sh` | **None** — stays separate, untouched |
| Non-GNOME DEs | **None** — `standaloneMenu()` path is identical |
| KDE widget | **None** — completely separate code |
| Cache files | New unique name `devtoolbox-cheats-combined.idx` — no collision |
| Front-matter parsing | **None** — shared code is copied verbatim |
| Clipboard | **None** — shared code is copied verbatim |
| `DEVTOOLBOX_DE` override | **Works** — inherited from shared code |
| `install.sh` (production) | **None** — only `install-dev.sh` is modified |

---

## 5. New Config Variable

| Variable | Default | Description |
|----------|---------|-------------|
| `DEVTOOLBOX_LAYOUT` | `standard` | Argos layout mode (`standard`/`zenity`/`drilldown`). Read from `~/.config/devtoolbox-cheats/layout.conf`. Can also be set as an environment variable override. |

---

## 6. Verification Plan

### Automated Tests
```bash
bash -n devtoolbox-cheats-combined.30s.sh    # Syntax check
shellcheck devtoolbox-cheats-combined.30s.sh # Linting
bash -n install-dev.sh                       # Syntax check after modification
```

### Manual Verification
- `DEVTOOLBOX_DE=gnome ./devtoolbox-cheats-combined.30s.sh` → verify Argos stdout in all 3 layouts
- `DEVTOOLBOX_DE=terminal ./devtoolbox-cheats-combined.30s.sh` → verify standaloneMenu works
- Switch layout from menu → verify `~/.config/devtoolbox-cheats/layout.conf` is written
- Verify drill-down state file uses the `-combined` suffix (no collision with script 3)
- Run `install-dev.sh`, select option 5 → verify install to `~/.config/argos/`

---

## Open Questions

> [!IMPORTANT]
> **Q1**: Config file location — `~/.config/devtoolbox-cheats/layout.conf` (persistent, XDG-compliant)? Or would you prefer a different mechanism (e.g., environment variable only)?

> [!IMPORTANT]
> **Q2**: For `install-dev.sh`, the "Install all" option currently says "Install all 3" — should it become "Install all 4" to include the combined script, or keep "Install all 3" and add the combined as a standalone option 5 only?

> [!IMPORTANT]
> **Q3**: Should the panel icon text change to indicate the active layout? E.g. `🗒️ Cheatsheets [D]` for drill-down mode? Or keep `🗒️ Cheatsheets` always (drill-down already changes the icon to the selected category name)?
