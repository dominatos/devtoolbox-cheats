## FIXED ISSUES

## 1. Ignore the generated Windows binary at its actual output path [MINOR]

**Status:** Fixed
**Affected components:** .gitignore:7

**Description:**
The `.gitignore` entry "Windows/cheats.exe" doesn't match the actual build output.

**Impact:**
The generated executable could be committed accidentally.

**Resolution:**
Updated `.gitignore` to correctly ignore `Windows-beta/cheats.exe`.

---

## 2. Add a top-level # Changelog heading [TRIVIAL]

**Status:** Fixed
**Affected components:** CHANGELOG.md:1

**Description:**
The changelog lacks a top-level heading before the release entries.

**Impact:**
Fails markdownlint and affects document structure.

**Resolution:**
Inserted `# Changelog` at the very start of CHANGELOG.md.

---

## 3. Windows install instructions must not say "run as Administrator" [MAJOR]

**Status:** Fixed
**Affected components:** README.md:96-105

**Description:**
The Quick Automated Install section instructs users to "Open PowerShell as Administrator".

**Impact:**
Causes shortcuts and `cheats.d` to be installed into the wrong (Administrator) profile instead of the user's profile.

**Resolution:**
Updated the instructions to tell users to open a regular (non-elevated) PowerShell and run the installer without Administrator privileges.

---

## 4. The updater/systemd docs don't match the shipped unit contract [MINOR]

**Status:** Fixed
**Affected components:** README.md:764-793

**Description:**
The README updater/systemd docs don't match the actual updater contract or systemd unit.

**Impact:**
Users will be confused when trying to manually configure or understand the updater.

**Resolution:**
Documented that the systemd unit runs `%h/.local/bin/cheats-updater`, and updated the manual setup steps to correctly symlink the executable to `~/.local/bin`.

---

## 5. Fix the mojibake in the included-cheats list [MINOR]

**Status:** Fixed
**Affected components:** README.md:1084-1085

**Description:**
The README contains mojibake replacement characters () in the included-cheats list.

**Impact:**
Unstable rendering and copy-paste reliability.

**Resolution:**
Replaced the replacement characters with intended emojis (`🛠️ Jenkins CI/CD` and `🟢 Node`).

---

## 6. Manual install skips the compile step [MINOR]

**Status:** Fixed
**Affected components:** Windows-beta/README-windows.md:69-75

**Description:**
The manual installation steps skip the actual compile step for AutoHotkey.

**Impact:**
Users will not obtain the `cheats.exe` and installation will fail.

**Resolution:**
Explicitly instructed users to run the AutoHotkey script compiler (`Ahk2Exe`) to compile it, or to run `cheats.ahk` directly.

---

## 7. Don't key lookups by the rendered label [MAJOR]

**Status:** Fixed
**Affected components:** Windows-beta/cheats.ahk:131-137

**Description:**
The menu mapping keys entries by their rendered label, which can collide.

**Impact:**
If multiple cheats have the same label, the entries will be overwritten, causing the wrong file to open.

**Resolution:**
Changed `MENU_MAP` to key by `A_ThisMenuItemPos` (position index) instead of the label, ensuring uniqueness even if labels collide.

---

## 8. Abort when the installer is run elevated [MAJOR]

**Status:** Fixed
**Affected components:** Windows-beta/install-devtoolbox.ps1:10-15

**Description:**
The script uses `$env:USERPROFILE` which causes installation into the Administrator profile when run elevated.

**Impact:**
Installs to the wrong directory, making the app unavailable to the normal user.

**Resolution:**
Added an elevation check at the top of the PowerShell script using `WindowsPrincipal` to abort and warn the user if running as Administrator.

---

## 9. Registering both startup entries guarantees duplicate tray instances [MAJOR]

**Status:** Fixed
**Affected components:** Windows-beta/install-devtoolbox.ps1:81-93

**Description:**
The script copies both `cheats.exe` and `cheats.ahk` to the Startup folder.

**Impact:**
Both artifacts will launch on boot, producing duplicate tray icons and background instances.

**Resolution:**
Changed the strategy to only copy `cheats.exe` to the Startup folder on successful compilation, eliminating duplicates.

---

## 10. Install the `.ahk` fallback when Ahk2Exe is unavailable [MAJOR]

**Status:** Fixed
**Affected components:** Windows-beta/install-devtoolbox.ps1:100-102

**Description:**
When `Ahk2Exe` is missing, the script only writes a warning but fails to install the fallback `.ahk`.

**Impact:**
The application will not launch at login if the compiler is missing.

**Resolution:**
Added logic to copy `cheats.ahk` to the Startup folder and launch it directly when `Ahk2Exe` is unavailable.

---

## 11. Use mktemp -d for the working directory [MAJOR]

**Status:** Fixed
**Affected components:** cheats-updater.sh:9-27

**Description:**
The script uses a hardcoded, predictable `TEMP_DIR` path in `/tmp`.

**Impact:**
Creates a race condition or security vulnerability due to predictable temporary paths.

**Resolution:**
Replaced the hardcoded path with a safe `mktemp -d` call and separated declaration from assignment to fix a ShellCheck warning. Updated `cleanup` to handle empty or invalid temp dir values safely.

---

## 12. Check for cmp before using it [MINOR]

**Status:** Fixed
**Affected components:** cheats-updater.sh:205-210

**Description:**
The dependency check loop verifies `git`, `find`, and `cp` but misses `cmp`.

**Impact:**
The script will fail later during `cmd_check()` or `cmd_update()` if `cmp` is not installed.

**Resolution:**
Added `cmp` to the command-checking loop to fail fast.

## 13. Trap expands $tmp_cache at definition time, not on signal [MAJOR]

**Status:** Open (Code Review Finding)
**Affected components:** devtoolbox-cheats.30s.sh:701

**Description:**
The `trap "rm -f '$tmp_cache' 2>/dev/null" EXIT` uses double quotes, causing `$tmp_cache` to expand immediately when the trap is set rather than when the EXIT signal fires.

**Impact:**
If `$tmp_cache` is reassigned or the variable scope changes before exit, the trap will delete the wrong file or fail silently, leaving orphaned temp files.

**Fix:**
Use single quotes so the variable expands at signal time:
```bash
trap 'rm -f "$tmp_cache" 2>/dev/null' EXIT
```

---

## 14. Declare and assign separately masks return values (SC2155) [MINOR]

**Status:** Open (Code Review Finding)
**Affected components:** devtoolbox-cheats.30s.sh:163,199,218,231,247,300,316,370

**Description:**
Pattern `local var="$(cmd)"` in 8 locations. The `local` declaration always succeeds (exit code 0), masking the return value of the subshell.

**Impact:**
Functions that rely on the return code of `detect_de`, `detect_dialog_tool`, or `default_terminal` may silently succeed when they should fail.

**Fix:**
Split into declaration and assignment:
```bash
local de
de="$(detect_de)"
```

---

## 15. Redundant single-item for loops (SC2043) [TRIVIAL]

**Status:** Open (Code Review Finding)
**Affected components:** devtoolbox-cheats.30s.sh:331,341,351

**Description:**
Three `for t in <single-item>` loops iterate only once. These should be direct `command -v` checks instead.

**Impact:**
No functional impact, but misleading code structure suggests more terminals were intended.

**Fix:**
Replace loops with direct checks:
```bash
xfce)
  command -v xfce4-terminal >/dev/null 2>&1 && { echo "xfce4-terminal"; return; }
  ;;
```

---

## 16. mkdir -m only applies to deepest directory with -p (SC2174) [MINOR]

**Status:** Open (Code Review Finding)
**Affected components:** devtoolbox-cheats.30s.sh:649

**Description:**
`mkdir -m 0700 -p "$ARGOS_RUNTIME_DIR"` sets permissions only on the final directory, not intermediate parent directories.

**Impact:**
Parent directories may have overly permissive defaults, exposing the runtime directory path to other users.

**Fix:**
Create parents without `-m`, then set permissions on the final directory:
```bash
mkdir -p "$ARGOS_RUNTIME_DIR" 2>/dev/null || true
chmod 0700 "$ARGOS_RUNTIME_DIR" 2>/dev/null || true
```

---

## 17. A && B || C is not if-then-else (SC2015) [TRIVIAL]

**Status:** Open (Code Review Finding)
**Affected components:** devtoolbox-cheats.30s.sh:101

**Description:**
`copy()` uses `[[ -n "$CLIPBOARD_COPY" ]] && eval "$CLIPBOARD_COPY" || true`. If `eval` succeeds but returns non-zero, the `|| true` masks it.

**Impact:**
Clipboard copy failures are silently swallowed.

**Fix:**
Use proper if-then:
```bash
copy() { if [[ -n "$CLIPBOARD_COPY" ]]; then eval "$CLIPBOARD_COPY"; fi; }
```

---

## 18. Unused variables VERSION and CLIPBOARD_MODE [TRIVIAL]

**Status:** Fixed
**Affected components:** devtools.1m.sh:25,35; install.sh:4

**Description:**
`VERSION` is defined but never referenced in devtools.1m.sh and install.sh. `CLIPBOARD_MODE` in devtools.1m.sh is also unused.

**Impact:**
Dead code; minor maintenance burden.

**Resolution:**
Surfaced the `$VERSION` variable in the printed header banners of both `install.sh` and `devtools.1m.sh` so it provides value to the user.

---

## 19. read without -r mangles backslashes (SC2162) [TRIVIAL]

**Status:** Fixed
**Affected components:** kde-widget-plasma6/install.sh:132; kde-widget-plasma6/uninstall.sh:61; kde-widget-plasma5/install.sh:89

**Description:**
`read -p` without `-r` interprets backslashes as escape characters.

**Impact:**
User input containing backslashes will be silently corrupted.

**Resolution:**
Replaced `read -p` with `read -rp` across all interactive installer scripts.

---

## 20. Unquoted variables in test expressions (SC2086) [MINOR]

**Status:** Open (Code Review Finding)
**Affected components:** kde-widget-plasma6/debug-widget.sh:26,88

**Description:**
`[ $CHEAT_COUNT -eq 0 ]` and `[ $PIPE_COUNT -gt 0 ]` use unquoted variables.

**Impact:**
If the variables are empty or contain spaces, the test will fail with a syntax error.

**Fix:**
Quote the variables: `[ "$CHEAT_COUNT" -eq 0 ]`

---

## 21. Unquoted expansion inside parameter substitution (SC2295) [TRIVIAL]

**Status:** Open (Code Review Finding)
**Affected components:** docs/cheats-readme.sh:8

**Description:**
`rel_path="${cheat#$cheats_dir/}"` has an unquoted variable inside `${..}`, which is treated as a glob pattern.

**Impact:**
If `$cheats_dir` contains glob characters (`*`, `?`, `[`), the pattern matching will behave unexpectedly.

**Fix:**
Quote separately: `rel_path="${cheat#"$cheats_dir"/}"`

---

## 22. Useless cat in version file read (SC2002) [TRIVIAL]

**Status:** Open (Code Review Finding)
**Affected components:** bump-version.sh:16; devtoolbox-cheats.30s.sh:621

**Description:**
`cat "$FILE" | tr ...` can be replaced with `tr ... < "$FILE"`.

**Impact:**
Minor inefficiency; spawns an unnecessary `cat` process.

**Fix:**
Use input redirection: `RAW_VERSION=$(tr -d '[:space:]' < "$VERSION_FILE")`

---

## 23. Duplicated DE detection logic across scripts [MINOR]

**Status:** Open (Code Review Finding)
**Affected components:** devtoolbox-cheats.30s.sh:118-158; install.sh:117-169

**Description:**
`detect_de()` is implemented independently in the main script and install.sh with different implementations. The main script uses `XDG_CURRENT_DESKTOP` with process fallback and caches results. install.sh uses `XDG_CURRENT_DESKTOP`, `DESKTOP_SESSION`, and process checks without caching.

**Impact:**
Maintenance burden — any new DE must be added in two places. The implementations may diverge silently, causing inconsistent behavior between runtime and install-time detection.

**Fix:**
Extract `detect_de()` into a shared sourced file (e.g. `lib/detect-de.sh`) and source it from both scripts. Alternatively, consolidate into the main script and have install.sh call it.

---

## 24. Remove the copied `.` grep root from all FZF implementations [MAJOR]

**Status:** Fixed
**Affected components:** kde-widget-plasma5/.../cheats.js, kde-widget-plasma6/.../cheats.js, kde-widget-plasma6/.../fzf-search.sh, devtoolbox-cheats.30s.sh

**Description:**
The grep invocation used to build the selected variable included an extra literal "." path. Removing it previously caused `grep` to interpret the directory argument as the pattern, breaking `fzf`.

**Impact:**
Search queries fail entirely and `fzf` displays 0 results because the search path is improperly treated as a regex pattern against the current directory.

**Resolution:**
The `.` pattern was properly restored (as `"."`) to all four grep invocations to ensure the specified directory is actually searched, rather than being treated as a search string.

---

## 25. Guard timer cleanup against the timeout/abort race [MINOR]

**Status:** Fixed
**Affected components:** kde-widget-plasma5/.../main.qml, kde-widget-plasma6/.../main.qml

**Description:**
A race condition exists between the timeout handler and `xhr.onreadystatechange` where both may attempt to call `updateTimer.destroy()` simultaneously if the timeout and the XHR response coincide.

**Impact:**
Can double-destroy the QML Timer, leading to crashes in the Plasma desktop widget due to a C++ use-after-free/double-delete error.

**Resolution:**
Added a `timerDestroyed` boolean flag to both `main.qml` versions. The flag is checked before stopping/destroying the timer, and flipped to `true` **before** any cleanup functions (`xhr.abort()` or `updateTimer.destroy()`) are called, thereby preventing synchronous re-entrancy.

---

## 26. Hardcoded cheats directory in empty-state messages [TRIVIAL]

**Status:** Fixed
**Affected components:** kde-widget-plasma6/.../main.qml

**Description:**
The empty-state UI text hardcoded the `~/cheats.d` path instead of reflecting the user's custom configured `plasmoid.configuration.cheatsDir`.

**Impact:**
Users who configure a custom cheats directory might be confused by error messages pointing them to the default `~/cheats.d` directory when the widget is empty.

**Resolution:**
Updated both `globalStatusMessage` assignments in the Plasma 6 `main.qml` to concatenate `plasmoid.configuration.cheatsDir` (falling back to `"~/cheats.d"` if undefined) so the UI accurately displays the configured directory path.
