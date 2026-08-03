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

---

## 13. Trap expands $tmp_cache at definition time, not on signal [MAJOR]

**Status:** Fixed
**Affected components:** devtoolbox-cheats.30s.sh:770

**Description:**
The `trap "rm -f '$tmp_cache' 2>/dev/null" EXIT` uses double quotes, causing `$tmp_cache` to expand immediately when the trap is set rather than when the EXIT signal fires.

**Impact:**
If `$tmp_cache` is reassigned or the variable scope changes before exit, the trap will delete the wrong file or fail silently, leaving orphaned temp files.

**Resolution:**
Used a scope-safe global variable (`_ARGOS_TMP_CACHE`) to hold the temp file path, so the EXIT trap can always find it after the function returns. The global is cleared after successful `mv`. Preserves any existing EXIT trap.

---

## 14. Declare and assign separately masks return values (SC2155) [MINOR]

**Status:** Fixed
**Affected components:** devtoolbox-cheats.30s.sh:163,199,218,231,247,300,316,370

**Description:**
Pattern `local var="$(cmd)"` in 8 locations. The `local` declaration always succeeds (exit code 0), masking the return value of the subshell.

**Impact:**
Functions that rely on the return code of `detect_de`, `detect_dialog_tool`, or `default_terminal` may silently succeed when they should fail.

**Resolution:**
Split into declaration and assignment at all 8 locations (e.g. `local de; de="$(detect_de)"`).

---

## 15. Redundant single-item for loops (SC2043) [TRIVIAL]

**Status:** Fixed
**Affected components:** devtoolbox-cheats.30s.sh:331,341,351

**Description:**
Three `for t in <single-item>` loops iterate only once. These should be direct `command -v` checks instead.

**Impact:**
No functional impact, but misleading code structure suggests more terminals were intended.

**Resolution:**
Replaced single-item loops with direct `command -v` checks for xfce4-terminal, mate-terminal, and lxterminal.

---

## 17. A && B || C is not if-then-else (SC2015) [TRIVIAL]

**Status:** Fixed
**Affected components:** devtoolbox-cheats.30s.sh:102

**Description:**
`copy()` uses `[[ -n "$CLIPBOARD_COPY" ]] && eval "$CLIPBOARD_COPY" || true`. If `eval` succeeds but returns non-zero, the `|| true` masks it.

**Impact:**
Clipboard copy failures are silently swallowed.

**Resolution:**
Removed `|| true` so clipboard errors propagate: `copy() { [[ -n "$CLIPBOARD_COPY" ]] && eval "$CLIPBOARD_COPY"; }`

---

## 20. Unquoted variables in test expressions (SC2086) [MINOR]

**Status:** Fixed
**Affected components:** kde-widget-plasma6/debug-widget.sh:26,79,88

**Description:**
`[ $CHEAT_COUNT -eq 0 ]`, `[ $EXIT_CODE -eq 0 ]`, and `[ $PIPE_COUNT -gt 0 ]` use unquoted variables.

**Impact:**
If the variables are empty or contain spaces, the test will fail with a syntax error.

**Resolution:**
Quoted all three variables (e.g. `[ "$CHEAT_COUNT" -eq 0 ]`).

---

## 22. Useless cat in version file read (SC2002) [TRIVIAL]

**Status:** Fixed
**Affected components:** bump-version.sh:16; devtoolbox-cheats.30s.sh:621

**Description:**
`cat "$FILE" | tr ...` can be replaced with `tr ... < "$FILE"`.

**Impact:**
Minor inefficiency; spawns an unnecessary `cat` process.

**Resolution:**
Replaced pipe with input redirection at both locations.

---

## 37. Backup recovery block lacks per-command error handling [MINOR]

**Status:** Fixed
**Affected components:** cheats-updater.sh:208-213

**Description:**
The backup recovery block performs `rm -rf` and `cp -a` as independent statements with no exit-status checks, and logs "Backup restored" unconditionally.

**Impact:**
A failed removal followed by a partial copy can corrupt the cheats directory. A successful removal followed by a failed copy leaves the user with no cheats directory at all.

**Resolution:**
Implemented transactional recovery: validates CHEATS_DIR exists, stages current dir to a rollback location via `mv`, copies backup to target with `--` for safe paths, and only logs success after the swap completes. Automatic rollback if copy fails.

---

## 38. mkdir -p failure for debug-log directory is silently swallowed [MINOR]

**Status:** Fixed
**Affected components:** kde-widget-plasma6/DevToolboxPlasmoid/contents/code/indexer.sh:17-18

**Description:**
`mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null` discards all errors. If the directory cannot be created, subsequent writes to `$DEBUG_LOG` fail silently.

**Impact:**
Debug logging is silently disabled with no diagnostic, making troubleshooting impossible.

**Resolution:**
Added exit-status check on `mkdir -p` — emits a warning on failure and redirects debug logging to `/dev/null`.

---

## 39. Atomic-write flow discards original file permissions [MINOR]

**Status:** Fixed
**Affected components:** tools/manage-tocs.py:163-169

**Description:**
`tempfile.mkstemp()` creates the temporary file with default umask permissions. After `os.replace()`, the rewritten file inherits those defaults instead of the original file's mode bits.

**Impact:**
Files that were executable, group-readable, or had other non-default permissions lose them after a TOC update.

**Resolution:**
Capture `os.stat(filepath).st_mode` before write, apply to temp file with `os.chmod()` after creation, and restore after replacement.

---

## 40. tmp_fd double-close risk on write failure [MINOR]

**Status:** Fixed
**Affected components:** tools/manage-tocs.py:166-183

**Description:**
`tmp_fd` was set to `None` after the `with os.fdopen(...)` block exited. If `write()` raised, `finally` would try to close an already-closed fd.

**Impact:**
Double-closing a file descriptor can close an unrelated file that reuses the same descriptor number.

**Resolution:**
Moved `tmp_fd = None` immediately after `os.fdopen()` returns, before `write()` can fail. Ownership transfers to the file object before any I/O.

---

## 27. CI bash-syntax step always exits 0 due to piped subshell [MAJOR]

**Status:** Fixed
**Affected components:** .github/workflows/ci.yml:37-45

**Description:**
The bash-syntax step uses a piped `find ... | while` loop. The `while` runs in a subshell, so `failed=1` set inside it never reaches the outer `exit $failed`. The step always succeeds regardless of syntax errors.

**Impact:**
Bash syntax errors in shell scripts go undetected in CI, allowing broken code to merge.

**Resolution:**
Replaced the piped `find ... | while` with process substitution `while ... done < <(find ... -print0)`. The `while` loop now runs in the current shell, so `failed=1` propagates correctly.

---

## 28. CI ShellCheck step always exits 0 due to piped subshell [MAJOR]

**Status:** Fixed
**Affected components:** .github/workflows/ci.yml:62-70

**Description:**
Same subshell issue as #27. The ShellCheck step pipes `find` into `while`, causing `failed=1` to be lost in the subshell.

**Impact:**
ShellCheck linting results are silently ignored; the step always reports success.

**Resolution:**
Same fix as #27 — replaced pipe with process substitution `< <(find ... -print0)`.

---

## 29. CI QML lint step always exits 0 due to piped subshell [MAJOR]

**Status:** Fixed
**Affected components:** .github/workflows/ci.yml:99-108

**Description:**
Same subshell issue as #27 and #28. The QML validation step pipes `find` into `while`, so `failed=1` is lost.

**Impact:**
QML syntax errors go undetected in CI.

**Resolution:**
Same fix — replaced pipe with process substitution `< <(find ... -print0)`.

---

## 32. CI integrity step uses word-splitting find loop [MINOR]

**Status:** Fixed
**Affected components:** .github/workflows/ci.yml:225-229

**Description:**
The large-file check uses `find ... | while read f; do` without `-print0` or `-d ''`. Filenames with spaces or special characters will be split incorrectly.

**Impact:**
Files with spaces in names are silently skipped or misreported.

**Resolution:**
Added `-print0` to `find` and changed `while read f` to `while IFS= read -r -d '' f`.

---

## 16. mkdir -m only applies to deepest directory with -p (SC2174) [MINOR]

**Status:** Fixed
**Affected components:** devtoolbox-cheats.30s.sh:715

**Description:**
`mkdir -m 0700 -p "$ARGOS_RUNTIME_DIR"` sets permissions only on the final directory, not intermediate parent directories.

**Impact:**
Parent directories may have overly permissive defaults, exposing the runtime directory path to other users.

**Resolution:**
Removed `-m 0700` from `mkdir` (the `chmod 0700` on the next line already sets the correct permissions).

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

## 41. Plasma 5 debugLog passed to shell without escaping [MINOR]

**Status:** Fixed
**Affected components:** kde-widget-plasma5/DevToolboxPlasmoid/contents/ui/main.qml:93-103

**Description:**
`debugLog` (and `cheatsDir`, `normalizedCacheFile`) are interpolated into the shell command string without shell escaping. Plasma 6 wraps these with `Cheats.bashSafePath()` and `Cheats.escapeShell()` before interpolation. Plasma 5's `cheats.js` already defines `bashSafePath()` (line 196) but `getIndexCommand` doesn't use it for its arguments, and `main.qml` doesn't call it either.

**Impact:**
Paths containing spaces, single quotes, double quotes, or other shell metacharacters produce a syntactically broken shell command, causing the indexer to fail or behave unexpectedly.

**Resolution:**
Fixed by resolving issue #48 — `getIndexCommand()` now applies `escapeBashDoubleQuoted()` to all interpolated path values before embedding them in the inner script's double-quoted strings. The outer `cmd` wraps everything in `bash -c '...'`, so the command is safe at both levels.

---

## 42. Plasma 5 debugLog parent directory not ensured before command [MINOR]

**Status:** Fixed
**Affected components:** kde-widget-plasma5/DevToolboxPlasmoid/contents/ui/main.qml:93-103

**Description:**
`main.qml` computes `debugLog` from `rawCacheDir` but never verifies the parent directory exists before passing the path into `getIndexCommand`. The shell command then writes to a path whose directory may not exist, failing silently. Plasma 6's `indexer.sh` includes a `mkdir -p` for this purpose (line 18), but the Plasma 5 path (via `cheats.js` inline script) has no equivalent.

**Impact:**
If the user's cache directory doesn't exist yet (e.g. first run, custom path), the debug log write fails and all diagnostic output is lost. The indexer continues but with no way to troubleshoot issues.

**Resolution:**
Added `mkdir -p "$(dirname "<debugLog>")" 2>/dev/null` at the beginning of the shell script constructed by `getIndexCommand()` in `cheats.js`, ensuring the debug log's parent directory exists before any writes.

---

## 43. CHANGELOG.md rollback claim is inaccurate — mechanism is broken [MINOR]

**Status:** Fixed
**Affected components:** CHANGELOG.md:13

**Description:**
CHANGELOG.md line 13 claims "transactional staging — moves current dir to rollback location before copy, with automatic rollback on failure." The rollback mechanism was broken: `mktemp -d` created the rollback directory before `mv` could rename `CHEATS_DIR` to it, so the rename always failed (destination already exists).

**Impact:**
Users reading the changelog were led to believe automatic rollback protects them during failed updates. In reality, if the backup copy failed, the user lost their cheats directory with no recovery path.

**Resolution:**
Fixed by resolving issue #44 — the rollback mechanism now uses a staging parent directory so both `mv` operations perform true renames. The CHANGELOG claim is now accurate.

---

## 44. Rollback mktemp creates directory before mv, preventing true rename [MAJOR]

**Status:** Fixed
**Affected components:** cheats-updater.sh:213-215

**Description:**
`rollback_dir="$(mktemp -d "${CHEATS_DIR}.rollback.XXXXXX")"` creates the rollback directory on disk. The subsequent `mv -- "$CHEATS_DIR" "$rollback_dir"` does not fail — instead, `mv` moves `CHEATS_DIR` *inside* the pre-existing rollback directory (creating `$rollback_dir/cheats.d/...`), breaking the intended rollback path. The subsequent `cp -a -- "$backup_dir" "$CHEATS_DIR"` then creates a new `CHEATS_DIR`, but if this also fails, the rollback `mv -- "$rollback_dir" "$CHEATS_DIR"` encounters the same nesting problem. Neither mv operation performs a true rename.

**Impact:**
The entire backup recovery block was non-functional. If TOC formatting failed after files were copied, the `else` branch executed but the rollback `mv` also failed, leaving the user with a corrupted or missing `CHEATS_DIR` with no way to recover.

**Resolution:**
Replaced with a staging parent pattern: `mktemp -d "${CHEATS_DIR}.staging.XXXXXX"` creates a temporary parent, and `rollback_dir="${staging_parent}/rollback"` assigns a non-existing child path. Both `mv` operations now perform true renames. Cleanup removes `staging_parent` on both success and failure paths. In the failure branch, any partial `CHEATS_DIR` left by a failed `cp -a` must be removed before moving `rollback_dir` back to prevent nesting.

---

## 45. test_no_version_txt_no_changes runs TARGET_SCRIPT from repo root [MINOR]

**Status:** Fixed
**Affected components:** tests/test_bump_version.sh:152-166

**Description:**
`test_no_version_txt_no_changes` creates a workspace but runs `bash "$TARGET_SCRIPT"` from the repo root where `version.txt` exists. The test does not validate behavior when `version.txt` is actually missing from the script's execution context.

**Impact:**
The test passed regardless of whether the missing-version check worked, because `TARGET_SCRIPT` always found `version.txt` in its own directory. A regression in the version-check guard would go undetected.

**Resolution:**
Copied `TARGET_SCRIPT` into the workspace (which lacks `version.txt`) and executed the copied script from there. The before/after assertion on the unchanged `test-script.sh` fixture remains the same.

---

## 46. Success-path tests duplicate sed logic instead of calling bump-version.sh [MINOR]

**Status:** Fixed
**Affected components:** tests/test_bump_version.sh:61-149

**Description:**
`test_updates_version_in_bash_scripts`, `test_preserves_readonly_prefix`, `test_version_with_special_chars`, and `test_updates_version_in_metadata_json` all manually re-implement the `sed` substitution logic from `bump-version.sh` instead of copying the actual script into the workspace and running it.

**Impact:**
If `bump-version.sh`'s sed pattern changed, these tests would not catch regressions because they used their own sed commands.

**Resolution:**
Replaced duplicated sed logic in all four success-path tests with actual `bump-version.sh` execution. Each test now copies the script into the workspace, sets up `version.txt`, and runs the real script, ensuring regressions in the actual script are caught.

---

## 47. test_compose_label_without_icon redefines functions instead of sourcing real ones [MINOR]

**Status:** Fixed
**Affected components:** tests/test_devtoolbox_cheats_core.sh:486-516

**Description:**
`test_compose_label_without_icon` writes a standalone `run_test.sh` that redefines `strip_leading_icon_if_same` and `compose_label` from scratch instead of sourcing or extracting the real implementations from `devtoolbox-cheats.30s.sh`.

**Impact:**
If the real functions were updated, this test would not catch regressions because it used its own copies.

**Resolution:**
Replaced the standalone script approach with `extract_func` to use the real function implementations, matching the pattern of adjacent tests. The empty-icon case is tested by passing `''` as a positional argument.

---

## 48. Plasma 5 cheats.js interpolates paths into shell without escaping [MAJOR]

**Status:** Fixed
**Affected components:** kde-widget-plasma5/DevToolboxPlasmoid/contents/code/cheats.js:112-131

**Description:**
`getIndexCommand()` constructs a shell script by concatenating `cheatsDir` and `debugLog` directly into double-quoted shell strings. The `safeScript.replace(/'/g, "'\\''")` only escapes single quotes for the outer wrapping — it does not protect the double-quoted variable values inside the script string.

**Impact:**
If `cheatsDir` or `debugLog` contained shell metacharacters (double quotes, backticks, `$()`, spaces), the generated shell command was syntactically broken or allowed arbitrary command execution.

**Resolution:**
Added `escapeBashDoubleQuoted()` helper function in `cheats.js` that escapes `\`, `"`, `$`, and `` ` `` characters. Applied it to `cheatsDir` and `debugLog` before interpolation into the inner script's double-quoted strings. Also added `mkdir -p` for the debug log parent directory at the beginning of the constructed shell script.

---

## 49. Plasma 5 cheats.js mkdir -p exit status not checked [MINOR]

**Status:** Fixed
**Affected components:** kde-widget-plasma5/DevToolboxPlasmoid/contents/code/cheats.js:103

**Description:**
`getIndexCommand()` includes `mkdir -p "$(dirname ...)" 2>/dev/null` at the start of the constructed shell script, but the exit status is discarded (output redirected to `/dev/null`). If directory creation fails (e.g. read-only parent, permission denied), the script continues and subsequent writes to the debug log fail silently with no diagnostic.

**Impact:**
The indexer appears to succeed but produces no debug output, making troubleshooting impossible. The UI reports a successful load even when the debug log was never written.

**Resolution:**
Added a fallback chain: if the initial `mkdir -p` fails, the script falls back to `/tmp/devtoolbox-debug.log`. If that also fails, it emits an actionable error and exits non-zero. All subsequent file operations reference a shell variable `$debugLog` so the fallback path is used consistently throughout the script.

---

## 50. applyTocFormat hides manage-tocs.py failures via backgrounded subshell [MINOR]

**Status:** Fixed
**Affected components:** devtoolbox-cheats.30s.sh:704-711

**Description:**
`applyTocFormat()` runs `python3 "$py_script"` inside a `(...) & disown` block. The `&` backgrounds the subshell and `disown` detaches it, so the function returns immediately with exit code 0 regardless of whether python3 succeeds or fails. The failure notification is sent, but the exit status is never propagated to callers of `setTocFormat` or the CLI `applyTocFormat` command.

**Impact:**
CLI commands `setTocFormat` and `applyTocFormat` always report success even when `manage-tocs.py` fails. Users receive no indication that TOC formatting failed, and CI/CD pipelines that rely on the exit code will not detect failures.

**Resolution:**
Removed `& disown` so the subshell runs synchronously. Added `exit 1` in the failure branch so the exit status propagates to callers. The function now blocks until `manage-tocs.py` finishes, and the exit code accurately reflects success or failure.

---

## 51. EXIT trap for _ARGOS_TMP_CACHE does not guard against empty variable [TRIVIAL]

**Status:** Fixed
**Affected components:** devtoolbox-cheats.30s.sh:775

**Description:**
The EXIT trap `trap 'rm -f "$_ARGOS_TMP_CACHE" 2>/dev/null' EXIT` always executes, even when `_ARGOS_TMP_CACHE` is empty (set to `""` on line 789 after successful `mv`). `rm -f ""` returns exit code 1 on GNU coreutils (the `-f` flag does not suppress the "cannot remove empty string" error). Since this is an EXIT trap, the non-zero exit code can override the script's intended exit status.

**Impact:**
A successful script run can appear to fail if the EXIT trap fires with an empty `_ARGOS_TMP_CACHE`, because `rm -f ""` returns 1. The `2>/dev/null` suppresses the error message but not the exit code.

**Resolution:**
Added a guard to skip cleanup when the variable is empty: `[[ -n "$_ARGOS_TMP_CACHE" ]] && rm -f "$_ARGOS_TMP_CACHE" 2>/dev/null; true`. The trailing `true` ensures the trap always returns success. Also wrapped `mv -f` in an `if` block so `_ARGOS_TMP_CACHE` is only cleared after the move succeeds — failed moves leave the variable set so the EXIT trap can clean up the temporary file.

---

## 52. Plasma 5 cheats.js initial echo write to debugLog not verified [MINOR]

**Status:** Fixed
**Affected components:** kde-widget-plasma5/DevToolboxPlasmoid/contents/code/cheats.js:109

**Description:**
`getIndexCommand()` writes `echo "Search Dir: ..." > "$debugLog"` without checking if the write succeeds. If the file is not writable (permissions, read-only filesystem), the redirection fails silently and the script continues as if logging succeeded.

**Impact:**
The indexer appears to succeed but produces no debug output, making troubleshooting impossible.

**Resolution:**
Added a write-check with fallback: if the initial `echo > "$debugLog"` fails, falls back to `/tmp/devtoolbox-debug.log` and retries. If that also fails, emits an error and exits non-zero.

---

## 54. applyTocFormat returns success when manage-tocs.py is missing [MINOR]

**Status:** Fixed
**Affected components:** devtoolbox-cheats.30s.sh:713-715

**Description:**
The `else` branch in `applyTocFormat()` when `manage-tocs.py` is not found sends a notification but does not `return 1`. The function exits with the exit code of `notify-send ... || true` (always 0), so callers see success even though no formatting was applied.

**Impact:**
CLI commands `setTocFormat` and `applyTocFormat` report success when the formatter script is missing, misleading users and CI/CD pipelines.

**Resolution:**
Added `return 1` after the notification in the missing-script branch.

---

## 55. test_no_version_txt_no_changes masks exit status with || true [MINOR]

**Status:** Fixed
**Affected components:** tests/test_bump_version.sh:136-141

**Description:**
`test_no_version_txt_no_changes` runs `bash "$ws/bump-version.sh" 2>/dev/null || true`, which masks the exit status. The test verifies no side effects occurred but does not assert that the script exited non-zero. A regression in the version-check guard would go undetected.

**Impact:**
The test passes even if the script incorrectly exits 0 on a missing `version.txt`, because `|| true` swallows the exit code.

**Resolution:**
Captured the exit status using `echo "EXITCODE:$?"` pattern and added an assertion that the exit code is 1 before verifying no files changed.

---

## 23. Duplicated DE detection logic across scripts [MINOR]

**Status:** ⏭️ Skipped (deferred — requires architectural approval)

**Affected components:** devtoolbox-cheats.30s.sh:118-158; install.sh:117-169

**Description:**
`detect_de()` is implemented independently in the main script and install.sh with different implementations. The main script uses `XDG_CURRENT_DESKTOP` with process fallback and caches results. install.sh uses `XDG_CURRENT_DESKTOP`, `DESKTOP_SESSION`, and process checks without caching.

**Impact:**
Maintenance burden — any new DE must be added in two places. The implementations may diverge silently, causing inconsistent behavior between runtime and install-time detection.

**Resolution (Deferred):**
Extract `detect_de()` into a shared sourced file (e.g. `lib/detect-de.sh`) and source it from both scripts. Alternatively, consolidate into the main script and have install.sh call it. Requires architectural approval to proceed.

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

---

## 31. Hardcoded developer-local debug path in Plasma 5 cheats.js [MINOR]

**Status:** Fixed
**Affected components:** kde-widget-plasma5/DevToolboxPlasmoid/contents/code/cheats.js:104; kde-widget-plasma5/DevToolboxPlasmoid/contents/ui/main.qml:93; kde-widget-plasma6/DevToolboxPlasmoid/contents/ui/main.qml:112

**Description:**
`getIndexCommand()` contained a hardcoded path `/home/sviatoslav/Downloads/devtoolbox-kde/devtoolbox-cheats-beta/kde-widget-plasma5/debug.log` as the debug log destination.

**Impact:**
Debug logs were written to a non-existent path on any other user's system, failing silently. On the developer's machine, it may have leaked data to a stale directory.

**Resolution:**
Removed the hardcoded `debugLog` variable from both Plasma 5 and Plasma 6 `cheats.js`. Both `main.qml` variants now derive the debug log path by stripping the filename from `plasmoid.configuration.cacheFile` (with a `/tmp` fallback for bare filenames) and pass the resolved path into `getIndexCommand` as a parameter. The function retains `|| "/tmp/devtoolbox-debug.log"` as a safety fallback.

---

## 34. Issue #31 not marked Fixed despite fix being applied [TRIVIAL]

**Status:** Fixed
**Affected components:** tofix.md:514-528

**Description:**
The diff removed the hardcoded developer path from `cheats.js` and passed `debugLog` as a parameter from `main.qml` in both Plasma 5 and 6 — which is exactly what issue #31 prescribes. However, the `tofix.md` diff only updated the **Fix:** description; the **Status** field still read `Open (Code Review Finding)` and the entry had not been moved to `## FIXED ISSUES`.

**Impact:**
\#31 was being counted as unresolved in tooling and dashboards even though the code was already fixed, causing noise in triaging.

**Resolution:**
Updated issue #31's **Status** to `Fixed`, replaced its **Fix:** section with a **Resolution:** block describing the change.

---

## 35. Plasma 5 `debugLog` embedded in shell script without quoting or sanitization [MINOR]

**Status:** Fixed
**Affected components:** kde-widget-plasma5/DevToolboxPlasmoid/contents/ui/main.qml (new lines); kde-widget-plasma5/DevToolboxPlasmoid/contents/code/cheats.js:108-120

**Description:**
`main.qml` computed `debugLog` from `cacheFile` but did not run it through any sanitization function before passing it to `getIndexCommand`. Inside `cheats.js` the value was concatenated bare into a one-liner shell script. No surrounding shell quotes wrapped the path. By contrast, Plasma 6's `main.qml` wraps the equivalent path with `Cheats.bashSafePath(...)` and passes it as a quoted argument to `bash`.

**Impact:**
If the user's cache directory path contained spaces or shell metacharacters (e.g. `~/.cache/my files/`), the generated shell command was syntactically broken.

**Resolution:**
All three redirect occurrences of `debugLog` in `cheats.js` are now wrapped in double quotes within the shell script string (e.g. `"> \"" + debugLog + "\";"`).
Note: applying `bashSafePath` from QML would have been incorrect here — the single quotes it generates would be mangled by the `safeScript.replace(/'/g, "'\\''")` escaping that wraps the whole script. Double-quoting inside the script string is the right approach for this architecture.

---

## 36. Regex dirname extraction fails for bare-filename `cacheFile` [TRIVIAL]

**Status:** Fixed
**Affected components:** kde-widget-plasma5/DevToolboxPlasmoid/contents/ui/main.qml (new lines); kde-widget-plasma6/DevToolboxPlasmoid/contents/ui/main.qml (new lines)

**Description:**
Both Plasma variants extracted the directory from `cacheFile` using `.replace(/\/[^\/]*$/, "")`. If `cacheFile` contained no `/` (e.g. a bare filename), the regex stripped the entire string, yielding `""`. The concatenated `debugLog` became `"/devtoolbox-debug.log"` — a root-level path the widget process cannot write to.

**Impact:**
The debug log would be silently dropped; a root-level path also causes a permission error on any non-root system.

**Resolution:**
Added `if (!rawCacheDir) rawCacheDir = "/tmp"` immediately after the regex in both Plasma 5 and Plasma 6 `main.qml`, ensuring `debugLog` always resolves to a writable path.

---

## 56. Staging parent derivation does not validate unsafe root target [MINOR]

**Status:** Fixed
**Affected components:** cheats-updater.sh:213-215

**Description:**
`staging_parent="$(mktemp -d "${CHEATS_DIR}.staging.XXXXXX")"` creates the staging directory as a sibling of `CHEATS_DIR`. If `CHEATS_DIR` is `/`, this creates `/.staging.XXXXXX` in root, which is unsafe and likely to fail silently.

**Impact:**
On a system where `CHEATS_DIR` is set to `/`, the recovery path creates files in the root filesystem, risking data corruption or permission errors.

**Resolution:**
Changed to derive staging location from `dirname -- "$CHEATS_DIR"` and added validation: rejects root or empty parent targets before invoking `mktemp`.

---

## 57. Backup recovery does not clean up partial CHEATS_DIR on failure [MINOR]

**Status:** Fixed
**Affected components:** cheats-updater.sh:216-222

**Description:**
If `mv -- "$CHEATS_DIR" "$rollback_dir"` succeeds but `cp -a -- "$backup_dir" "$CHEATS_DIR"` fails, a partial `CHEATS_DIR` may be left behind. The rollback `mv -- "$rollback_dir" "$CHEATS_DIR"` then encounters the existing partial directory, causing nesting or failure.

**Impact:**
A failed recovery attempt leaves the user with a corrupted or partially-populated `CHEATS_DIR` and no clean rollback path.

**Resolution:**
Added `rm -rf -- "$CHEATS_DIR"` before the rollback `mv` in the failure branch to ensure a clean target for the restore operation.

---

## 58. Missing test coverage for ampersand in version strings [TRIVIAL]

**Status:** Fixed
**Affected components:** tests/test_bump_version.sh:112-125

**Description:**
`test_version_with_special_chars` only tests `/` in version strings. The `&` character is also significant in bash (command separator) and sed replacement strings, but has no explicit test coverage.

**Impact:**
A regression in `bump-version.sh`'s handling of `&` in sed patterns would go undetected.

**Resolution:**
Added `test_version_with_ampersand` that writes `1.0.0&beta` to `version.txt` and asserts the generated `VERSION` assignment preserves the ampersand literally.

---

## 59. CI version-sync check omits generate-tldr.sh [MINOR]

**Status:** Fixed
**Affected components:** .github/workflows/ci.yml:273

**Description:**
The `version-sync` job iterates over a hardcoded list of shell scripts (`devtoolbox-cheats.30s.sh cheats-updater.sh install.sh devtools.1m.sh`) to verify their `VERSION` variable matches `version.txt`. The script `generate-tldr.sh` also contains a `VERSION` variable but is not included in this list.

**Impact:**
If `generate-tldr.sh`'s `VERSION` drifts out of sync with `version.txt`, the CI will not detect the inconsistency and the mismatch will ship undetected.

**Resolution:**
Added `generate-tldr.sh` to the `for script in ...` loop on line 273 of `.github/workflows/ci.yml`.

---

## 60. Viewer loop may continue after `code` invocation fails silently [MINOR]

**Status:** Fixed
**Affected components:** devtoolbox-cheats.30s.sh:845-851

**Description:**
The viewer-selection loop invokes `code --reuse-window "$file" 2>/dev/null && return 0`. If VS Code is installed but the command fails (e.g. no display, corrupted install), the `&&` chain skips `return 0` and the loop falls through to subsequent viewers (`cat`, `less`, `zenity`, `terminal`), potentially opening the same file in multiple applications.

**Impact:**
Users may see the same cheat file opened in both VS Code and a terminal pager simultaneously, causing confusion and wasted screen space.

**Resolution:**
Separated the `code` invocation from `return 0` onto independent lines so `return 0` always executes when `code` is found, regardless of the command's exit status. This prevents silent fallthrough to other viewers.

---

## 61. Startup retry timer disconnects live indexer after fixed delay [MINOR]

**Status:** Fixed
**Affected components:** kde-widget-plasma6/DevToolboxPlasmoid/contents/ui/main.qml:233-251

**Description:**
`startupRetryTimer` fires after a fixed 10-second interval and disconnects all `shSource` connections if `globalDataCompleted` is still false. For large cheats directories, the indexer may legitimately take longer than 10 seconds to complete its first scan. The timer unconditionally disconnects the active indexer, clears loading state, and triggers a retry — which starts a second indexer that may also be disconnected by `retryBoundTimer` after another 10 seconds.

**Impact:**
Large cheats directories cause the widget to report a loading failure even though the indexer is still running. The user sees a "Failed to load cheats" error despite the data eventually becoming available.

**Resolution:**
Increased both `startupRetryTimer` and `retryBoundTimer` intervals from 10 seconds to 30 seconds, giving the indexer adequate time to complete initial scans of large cheats directories. Updated log messages to reflect the new timeout value.

---

## 62. Duplicate test-harness boilerplate [MINOR]

**Status:** Fixed
**Affected components:** tests/test_argos_renderers.sh:14-16

**Description:**
The `pass`, `fail`, `assert_contains`, and `extract_func` helpers are defined locally in `test_argos_renderers.sh` instead of being sourced from a shared test helper file.

**Impact:**
Maintenance burden — any change to helper behavior must be replicated across multiple test files, risking inconsistencies.

**Resolution:**
Created `tests/test_helpers.sh` containing all shared test helpers (`pass`, `fail`, `assert_eq`, `assert_contains`, `assert_file_exists`, `extract_func`, `make_workspace`, `make_test_cheat`). Updated `test_argos_renderers.sh` to source the shared helper and removed duplicated definitions.

---

## 63. Duplicate test-harness boilerplate [MINOR]

**Status:** Fixed
**Affected components:** tests/test_cheats_updater_extended2.sh:14-16

**Description:**
The `pass`, `fail`, `assert_eq`, `assert_contains`, and `extract_func` helpers are defined locally in `test_cheats_updater_extended2.sh` instead of being sourced from a shared test helper file.

**Impact:**
Maintenance burden — any change to helper behavior must be replicated across multiple test files, risking inconsistencies.

**Resolution:**
Updated `test_cheats_updater_extended2.sh` to source `tests/test_helpers.sh` and removed duplicated definitions. Added a custom `extract_func` override for cheats-updater.sh's one-liner functions.

---

## 65. Duplicated test-harness boilerplate across all 5 new shell test files [MINOR]

**Status:** Fixed
**Affected components:** tests/test_devtoolbox_cheats_ui.sh:15-97, tests/test_argos_renderers.sh:14-49, tests/test_cheats_updater_extended2.sh:14-53, tests/test_devtoolbox_cheats_screen.sh:15-53, tests/test_indexer.sh:13-79

**Description:**
The shared `pass`, `fail`, assertion, `extract_func`, `make_workspace`, and `make_test_cheat` helpers are duplicated across all 5 new test files instead of being sourced from a single shared helper.

**Impact:**
High maintenance burden — any change to helper behavior must be replicated across 5 files, risking inconsistencies and bugs.

**Resolution:**
Created `tests/test_helpers.sh` containing all shared helpers. Updated all 5 test files to source the shared helper and removed duplicated definitions. Also updated `test_bump_version.sh` and `test_cheats_readme.sh` to use the shared helper.

---

## 67. Duplicate test-harness boilerplate [MINOR]

**Status:** Fixed
**Affected components:** tests/test_indexer.sh:13-42

**Description:**
The `pass`/`fail` and assertion helpers, along with `make_workspace` and `make_test_cheat`, are defined locally in `test_indexer.sh` instead of being sourced from a shared test helper file.

**Impact:**
Maintenance burden — any change to helper behavior must be replicated across multiple test files.

**Resolution:**
Updated `test_indexer.sh` to source `tests/test_helpers.sh` and removed duplicated definitions.

---

## 64. Assertions never fail: result of `[[ ]]` is discarded [MAJOR]

**Status:** Fixed
**Affected components:** tests/test_devtoolbox_cheats_screen.sh:247-284

**Description:**
Four test functions — `test_default_terminal_prefers_gnome_terminal_on_gnome`, `test_default_terminal_returns_something`, `test_detect_dialog_tool_kde_prefers_kdialog`, and `test_detect_dialog_tool_gnome_prefers_zenity` — use `[[ -n "$out" ]]` but discard the result, always calling `pass` unconditionally.

**Impact:**
Tests pass even when assertions fail, providing false confidence and hiding regressions.

**Resolution:**
Updated all four test functions to conditionally call `pass` only when `[[ -n "$out" ]]` succeeds, and otherwise call `fail` with an appropriate error message.

---

## 66. Mocked `index_cheats` is overridden by the real function, defeating the test [MAJOR]

**Status:** Fixed
**Affected components:** tests/test_devtoolbox_cheats_ui.sh:274-293

**Description:**
`test_ensure_cache_rebuilds_on_rebuild_flag` exports an `index_cheats` mock, but the real function is loaded later and overrides it. The test cannot distinguish a rebuild from ordinary cache creation.

**Impact:**
The test provides false confidence — it passes regardless of whether the rebuild logic works correctly.

**Resolution:**
Removed the exported `index_cheats` mock. The test now seeds the cache with old content before enabling `CHEATS_REBUILD=1`, then asserts the content changes to include the new cheat data after `ensure_cache` runs with the real `index_cheats` function.

---

## 68. Test performs no assertion [MAJOR]

**Status:** Fixed
**Affected components:** tests/test_indexer.sh:215-223

**Description:**
`test_indexer_disables_debug_on_bad_dir` masks the indexer exit status with `|| true`, so the test cannot fail regardless of the command's behavior.

**Impact:**
The test provides no value — it always passes even if the indexer fails completely.

**Resolution:**
Updated the test to capture the exit status without masking it, then assert the command succeeds (exit code 0) and produces expected output containing the test cheat data.

---

## 69. Duplicate function-extraction logic within the same file [MINOR]

**Status:** Fixed
**Affected components:** tests/test_install_extended.sh:119-142

**Description:**
The `install_argos` and `install_generic_app` tests use inline awk-based function extraction instead of the existing `extract_func()` helper.

**Impact:**
Code duplication — the same extraction logic is implemented twice in the same file, increasing maintenance burden.

**Resolution:**
Replaced all inline awk-based function extraction with the existing `extract_func()` helper, using it consistently for all tested functions.

---

## 70. Broken "Results" summary line [MINOR]

**Status:** Fixed
**Affected components:** tests/test_install.sh:14-16

**Description:**
The test result tracking uses arithmetic that doesn't correctly count passed and failed tests, producing inaccurate summary output.

**Impact:**
The "Results" line may show incorrect counts, confusing developers about test outcomes.

**Resolution:**
Added a `passed` counter that increments in the `pass()` function. Updated the Results summary to display the correct counts using the counter variables.

---

## 71. Grep result is discarded, not asserted [MAJOR]

**Status:** Fixed
**Affected components:** tests/test_install.sh:101-114

**Description:**
`test_install_cheats_copies_files` runs a grep check but discards the result instead of asserting it, so the test passes even if the grep finds nothing.

**Impact:**
The test provides false confidence — it passes regardless of whether the install pipeline actually copies files correctly.

**Resolution:**
Updated the test to capture the output and use `assert_contains` to verify the output contains "Cheats deployed", while preserving the existing file-copy assertion.

---

## 72. Setup targets the wrong path and mutates the real repository [MAJOR]

**Status:** Fixed
**Affected components:** tests/test_install.sh:174-188

**Description:**
`test_configure_toc_format_default_obsidian` creates a directory at `$REPO_ROOT/tools`, which targets the real repository instead of the isolated test workspace.

**Impact:**
Test isolation is broken — the test modifies the real repository, potentially affecting other tests or leaving artifacts.

**Resolution:**
Removed the `mkdir -p "$REPO_ROOT/tools"` command from the test, restoring proper test isolation.

---

## 73. Assertion too weak to verify the default debug-log relocation [MINOR]

**Status:** Fixed
**Affected components:** tests/test_plasma5_cheats_js.mjs:371-374

**Description:**
The "uses default debug log when not provided" test only matches generic "debug" text instead of verifying the concrete expected default path under the user's home cache directory.

**Impact:**
The test may pass even if the debug log path is incorrect, providing weak coverage.

**Resolution:**
Strengthened the assertion to verify the command contains the exact default path `/tmp/devtoolbox-debug.log`.

---

## 74. Missing error handling on `mktemp -d` risks writing to real filesystem paths [MINOR]

**Status:** Fixed
**Affected components:** tests/test_uninstall.sh:89-101

**Description:**
The test functions use inline `mktemp -d` assignments without error handling. If `mktemp` fails, subsequent filesystem operations target undefined paths.

**Impact:**
Tests may write to real filesystem paths if `mktemp` fails, potentially corrupting user data or system files.

**Resolution:**
Replaced all inline `mktemp -d` assignments with the shared `make_workspace()` helper from `test_helpers.sh`, which includes proper error handling.

---

## 75. Test cannot fail regardless of actual behavior [MAJOR]

**Status:** Fixed
**Affected components:** tests/test_uninstall.sh:129-143

**Description:**
`test_remove_file_readonly` asserts the command exit status, but `remove_file` always returns success after its echo branch, so the test cannot fail.

**Impact:**
The test provides no value — it always passes even if the removal logic is broken.

**Resolution:**
Updated the test to check the output for failure indicators (`✗`) and verify the readonly file still exists, instead of checking the exit status.

---

## FALSE POSITIVE ISSUES

## 21. Unquoted expansion inside parameter substitution (SC2295) [TRIVIAL]

**Status:** ❌ False Positive

**Affected components:** docs/cheats-readme.sh:8

**Description:**
`rel_path="${cheat#$cheats_dir/}"` has an unquoted variable inside `${..}`, which is treated as a glob pattern.

**Resolution (False Positive):**
The code already uses the quoted form: `rel_path="${cheat#"$cheats_dir"/}"`. The issue was resolved in a prior commit before the review was filed. ShellCheck confirms zero SC2295 warnings on the current file.

**CodeRabbit reply:**
The fix described in this issue is already applied in the current codebase. No action needed.

---

## 30. Indexer script missing shebang line [MINOR]

**Status:** ❌ False Positive

**Affected components:** kde-widget-plasma6/DevToolboxPlasmoid/contents/code/indexer.sh:1

**Description:**
`indexer.sh` has no shebang (`#!/bin/bash`). The script begins with a comment.

**Resolution (False Positive):**
The Plasma 6 `indexer.sh` already has `#!/bin/bash` as its first line. Plasma 5 does not have an indexer script. No action needed.

**CodeRabbit reply:**
The shebang `#!/bin/bash` is already present at line 1 of the Plasma 6 indexer. Plasma 5 uses a different architecture (cheats.js) and has no indexer.sh. No fix required.

---

## 33. Plasma 5 uninstall references stale cache file path [TRIVIAL]

**Status:** ❌ False Positive

**Affected components:** kde-widget-plasma5/uninstall.sh:33-38

**Description:**
The uninstall script offers to remove `~/.cache/devtoolbox-cheats.json`, but the Plasma 5 widget uses an indexer-based cache at `~/.cache/devtoolbox-cheats-index.cache`.

**Resolution (False Positive):**
The Plasma 5 widget's default cache IS `~/.cache/devtoolbox-cheats.json` (confirmed in `configGeneral.qml:127` and `main.xml:12`). Plasma 5 has no indexer — it uses `cheats.js` directly. The `~/.cache/devtoolbox-cheats-index.cache` path belongs to Plasma 6's indexer only. The uninstall script correctly targets the Plasma 5 cache file.

**CodeRabbit reply:**
The issue incorrectly assumes Plasma 5 uses the same `index.cache` path as Plasma 6. Plasma 5's config defaults to `.json`, which is what the uninstall script removes. No fix required.

---

## CI Workflow Improvements (.github/workflows/ci.yml)
- **File loops**: ~~Replace every command-substitution file loop~~ Done — all loops now use Bash process substitution with null-delimited `find ... -print0` and `while IFS= read -r -d '' f; do` (QML step uses a temp file for `find` exit-status propagation).
- **Branch filters**: ~~Add `dev` to triggers~~ Done — both `push.branches` and `pull_request.branches` include `dev`.
- **Action pinning**: ~~Pin `uses:` to commit SHAs~~ Done — every `uses:` reference is pinned to a full commit SHA with the release tag in an inline comment.
- **QML linting**: ~~Replace brace-counting~~ Done — installs `qtdeclarative5-dev-tools`, detects the Qt5 linter (`/usr/lib/qt5/bin/qmllint`, `qmllint`, or `qml-lint`), and runs it against all `.qml` files **excluding** paths containing `kde-widget-plasma6` (Plasma 6 modules cannot be resolved without a full KDE runtime). Qt6 packages and `qmllint6` are not installed or used.

---

## 76. Missing coverage for user cheat sheet preservation [MINOR]

**Status:** Fixed
**Affected components:** tests/test_uninstall.sh:194-249

**Description:**
`test_uninstall_removes_known_paths()` does not verify that user-created cheat sheets are preserved after removal operations.

**Impact:**
If the uninstall logic accidentally removes user files, this regression would go undetected.

**Resolution:**
Added a fixture file under `$ws/home/cheats.d` in `test_uninstall_removes_known_paths()` and added an assertion to verify it remains after the simulated removal calls.


---

## 77. make_workspace does not propagate failure to the caller [MINOR]

**Status:** Open (Code Review Finding)
**Affected components:** tests/test_helpers.sh:62-69

**Description:**
`make_workspace` calls `mktemp -d ... || { echo "Error" >&2; exit 1; }`. The `exit 1` terminates only the subshell used by `$()` — it does not cause `ws="$(make_workspace)"` assignments in calling test functions to fail or return early. Callers receive an empty `$ws` and continue executing with no path.

**Impact:**
If `mktemp` fails, all subsequent filesystem operations inside the test function (reads, writes, `rm -rf`) target undefined or empty paths — potentially operating on the real filesystem or producing silent false-passes.

**Fix:**
Have `make_workspace` return non-zero on failure and have each caller check `ws="$(make_workspace)" || return 1` (or equivalent) immediately after the assignment. Alternatively, use `|| { fail "make_workspace failed"; return; }` per test function.

---

## 78. Issue #73 resolution references an inconsistent debug-log default path [TRIVIAL]

**Status:** Open (Code Review Finding)
**Affected components:** tofix.md:1099-1105

**Description:**
The **Description** section of issue #73 states the assertion should verify "the concrete expected default path under the user's home cache directory" (implying `$HOME/.cache`), but the **Resolution** section records the fix as strengthening the assertion to verify `/tmp/devtoolbox-debug.log`. The two sections contradict each other within the same issue record.

**Impact:**
Future readers of `tofix.md` get conflicting guidance about what the actual default debug-log path is, making it harder to verify the fix or reproduce the original issue.

**Fix:**
Update issue #73's **Description** to reference `/tmp/devtoolbox-debug.log` as the expected default, removing the conflicting `$HOME/.cache` reference. No code change required.

---

## 79. devtools.1m.sh clipboard helpers use eval [MAJOR]

**Status:** Open (Code Review Finding)
**Affected components:** devtools.1m.sh:41-42

**Description:**
The `paste()` and `copy()` functions execute the configured clipboard command strings using `eval "$CLIPBOARD_PASTE"` and `eval "$CLIPBOARD_COPY"`.

**Impact:**
Shell evaluation of user-controlled or environment-controlled command strings can introduce command injection, quoting errors, and unexpected behavior.

**Fix:**
Avoid `eval` by invoking the clipboard helper directly, e.g. `paste() { $CLIPBOARD_PASTE; }` and `copy() { $CLIPBOARD_COPY; }`, or store the command and arguments in a safe array form before execution.

---

## 80. devtoolbox-cheats.30s.sh terminal wrapper relies on eval [MAJOR]

**Status:** Open (Code Review Finding)
**Affected components:** devtoolbox-cheats.30s.sh:104, 369-394

**Description:**
`run_in_terminal()` escapes the command using `printf '%q'` and then executes it through `bash -c "eval $escaped_cmd"` inside multiple terminal emulator invocations.

**Impact:**
This double-eval pattern increases the risk of command injection and can break quoting, making terminal command execution unsafe for untrusted or complex commands.

**Fix:**
Remove the `eval` wrapper and use a safer shell invocation strategy, such as passing a properly quoted command string to `bash -lc "$cmd"` or using arrays/explicit command execution without intermediate evaluation.

