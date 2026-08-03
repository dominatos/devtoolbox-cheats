#!/usr/bin/env bash
# tests/test_uninstall.sh
#
# Tests uninstall.sh helper functions: remove_file, remove_dir
# Uses isolated workspace to avoid touching real system files.
#
# Run:  bash tests/test_uninstall.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
UNINSTALL_SCRIPT="$REPO_ROOT/uninstall.sh"

# Source shared test helpers
# shellcheck source=tests/test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass "$desc"
    else
        fail "$desc (expected: [$expected], actual: [$actual])"
    fi
}

assert_file_exists() {
    local desc="$1" f="$2"
    if [[ -f "$f" ]]; then
        pass "$desc"
    else
        fail "$desc (file not found: $f)"
    fi
}

assert_file_not_exists() {
    local desc="$1" f="$2"
    if [[ ! -f "$f" ]]; then
        pass "$desc"
    else
        fail "$desc (file should not exist: $f)"
    fi
}

assert_dir_not_exists() {
    local desc="$1" d="$2"
    if [[ ! -d "$d" ]]; then
        pass "$desc"
    else
        fail "$desc (dir should not exist: $d)"
    fi
}

# Extract helper functions from uninstall.sh
extract_func() {
    local name="$1"
    awk -v name="$name" '
        $0 ~ "^" name "\\(\\) \\{" { flag=1 }
        flag { print }
        flag && /^}/ { exit }
    ' "$UNINSTALL_SCRIPT"
}

# Sanity check
echo "=== Checking function existence ==="
for fn in remove_file remove_dir; do
    if [[ -z "$(extract_func "$fn")" ]]; then
        fail "extract_func: could not find function '$fn' in $UNINSTALL_SCRIPT"
    fi
done

echo ""
echo "=== uninstall.sh tests ==="
echo ""

# --- remove_file ---

echo "remove_file:"

test_remove_file_existing() {
    local ws
    ws="$(make_workspace)"
    touch "$ws/testfile.txt"
    
    local out
    out="$(bash -c "$(extract_func remove_file); remove_file '$ws/testfile.txt'")"
    assert_file_not_exists "remove_file: removes existing file" "$ws/testfile.txt"
    assert_eq "remove_file: outputs success" "1" "$(echo "$out" | grep -c "✓")"
    
    rm -rf "$ws"
}
test_remove_file_existing

test_remove_file_nonexistent() {
    local ws
    ws="$(make_workspace)"
    
    # Should not fail on non-existent file
    bash -c "$(extract_func remove_file); remove_file '$ws/nonexistent.txt'" 2>/dev/null
    assert_eq "remove_file: no error for missing file" "0" "$?"
    
    rm -rf "$ws"
}
test_remove_file_nonexistent

test_remove_file_symlink() {
    local ws
    ws="$(make_workspace)"
    touch "$ws/target.txt"
    ln -s "$ws/target.txt" "$ws/link.txt"
    
    bash -c "$(extract_func remove_file); remove_file '$ws/link.txt'" 2>/dev/null
    assert_file_not_exists "remove_file: removes symlink" "$ws/link.txt"
    assert_file_exists "remove_file: preserves target" "$ws/target.txt"
    
    rm -rf "$ws"
}
test_remove_file_symlink

test_remove_file_readonly() {
    local ws
    ws="$(make_workspace)"
    touch "$ws/readonly.txt"
    chmod 444 "$ws/readonly.txt"
    
    # Note: Non-root users can still rm -f files they own, even if readonly.
    # The readonly permission only prevents content modification, not deletion.
    # This test verifies remove_file handles the operation without crashing.
    local out
    out="$(bash -c "$(extract_func remove_file); remove_file '$ws/readonly.txt'" 2>&1)"
    # Verify it didn't crash and produced output
    assert_contains "remove_file: handles readonly gracefully" "$out" "✓"
    assert_file_not_exists "remove_file: readonly file removed" "$ws/readonly.txt"
    
    rm -rf "$ws"
}
test_remove_file_readonly

# --- remove_dir ---

echo ""
echo "remove_dir:"

test_remove_dir_existing() {
    local ws
    ws="$(make_workspace)"
    mkdir -p "$ws/testdir"
    touch "$ws/testdir/file.txt"
    
    local out
    out="$(bash -c "$(extract_func remove_dir); remove_dir '$ws/testdir'")"
    assert_dir_not_exists "remove_dir: removes existing directory" "$ws/testdir"
    assert_eq "remove_dir: outputs success" "1" "$(echo "$out" | grep -c "✓")"
    
    rm -rf "$ws"
}
test_remove_dir_existing

test_remove_dir_nonexistent() {
    local ws
    ws="$(make_workspace)"
    
    bash -c "$(extract_func remove_dir); remove_dir '$ws/nonexistent'" 2>/dev/null
    assert_eq "remove_dir: no error for missing dir" "0" "$?"
    
    rm -rf "$ws"
}
test_remove_dir_nonexistent

test_remove_dir_nested() {
    local ws
    ws="$(make_workspace)"
    mkdir -p "$ws/nested/deep/dir"
    touch "$ws/nested/deep/dir/file.txt"
    
    bash -c "$(extract_func remove_dir); remove_dir '$ws/nested'" 2>/dev/null
    assert_dir_not_exists "remove_dir: removes nested directory" "$ws/nested"
    
    rm -rf "$ws"
}
test_remove_dir_nested

# --- Integration: simulate full uninstall with mocked commands ---

echo ""
echo "Integration:"

test_uninstall_removes_known_paths() {
    local ws
    ws="$(make_workspace)"
    
    # Create fake installed paths
    mkdir -p "$ws/home/.config/systemd/user"
    mkdir -p "$ws/home/.local/bin"
    mkdir -p "$ws/home/.local/share/applications"
    mkdir -p "$ws/home/.local/share/icons"
    mkdir -p "$ws/home/.config/argos"
    mkdir -p "$ws/home/.local/share/plasma/plasmoids/com.dominatos.devtoolboxcheats"
    mkdir -p "$ws/home/.local/share/devtoolbox-cheats"
    mkdir -p "$ws/home/.config/devtoolbox-cheats"
    
    # Create user cheat sheet directory and file (should be preserved)
    mkdir -p "$ws/home/cheats.d"
    touch "$ws/home/cheats.d/my-custom-cheats.md"
    
    touch "$ws/home/.config/systemd/user/devtoolbox-cheats-updater.service"
    touch "$ws/home/.config/systemd/user/devtoolbox-cheats-updater.timer"
    touch "$ws/home/.local/bin/devtoolbox-cheats-menu"
    touch "$ws/home/.local/bin/cheats-updater"
    touch "$ws/home/.local/share/applications/devtoolbox-cheats.desktop"
    touch "$ws/home/.local/share/icons/devtoolbox-cheats.png"
    touch "$ws/home/.config/argos/devtoolbox-cheats.30s.sh"
    touch "$ws/home/.config/argos/devtools.1m.sh"
    
    # Source the helper functions and simulate removal
    bash -c "
        $(extract_func remove_file)
        $(extract_func remove_dir)
        HOME='$ws/home'
        remove_file \"\$HOME/.config/systemd/user/devtoolbox-cheats-updater.service\"
        remove_file \"\$HOME/.config/systemd/user/devtoolbox-cheats-updater.timer\"
        remove_file \"\$HOME/.local/bin/devtoolbox-cheats-menu\"
        remove_file \"\$HOME/.local/bin/cheats-updater\"
        remove_file \"\$HOME/.local/share/applications/devtoolbox-cheats.desktop\"
        remove_file \"\$HOME/.local/share/icons/devtoolbox-cheats.png\"
        remove_file \"\$HOME/.config/argos/devtoolbox-cheats.30s.sh\"
        remove_file \"\$HOME/.config/argos/devtools.1m.sh\"
        remove_dir \"\$HOME/.local/share/plasma/plasmoids/com.dominatos.devtoolboxcheats\"
        remove_dir \"\$HOME/.local/share/devtoolbox-cheats\"
        remove_dir \"\$HOME/.config/devtoolbox-cheats\"
    "
    
    assert_file_not_exists "integration: service removed" "$ws/home/.config/systemd/user/devtoolbox-cheats-updater.service"
    assert_file_not_exists "integration: timer removed" "$ws/home/.config/systemd/user/devtoolbox-cheats-updater.timer"
    assert_file_not_exists "integration: menu script removed" "$ws/home/.local/bin/devtoolbox-cheats-menu"
    assert_file_not_exists "integration: updater script removed" "$ws/home/.local/bin/cheats-updater"
    assert_file_not_exists "integration: desktop entry removed" "$ws/home/.local/share/applications/devtoolbox-cheats.desktop"
    assert_file_not_exists "integration: icon removed" "$ws/home/.local/share/icons/devtoolbox-cheats.png"
    assert_file_not_exists "integration: argos script removed" "$ws/home/.config/argos/devtoolbox-cheats.30s.sh"
    assert_file_not_exists "integration: argos updater removed" "$ws/home/.config/argos/devtools.1m.sh"
    assert_dir_not_exists "integration: plasmoid dir removed" "$ws/home/.local/share/plasma/plasmoids/com.dominatos.devtoolboxcheats"
    assert_dir_not_exists "integration: data dir removed" "$ws/home/.local/share/devtoolbox-cheats"
    assert_dir_not_exists "integration: config dir removed" "$ws/home/.config/devtoolbox-cheats"
    assert_file_exists "integration: user cheats preserved" "$ws/home/cheats.d/my-custom-cheats.md"
    
    rm -rf "$ws"
}
test_uninstall_removes_known_paths

echo ""
echo "=== All uninstall.sh tests complete ==="
echo ""
# shellcheck disable=SC2154
exit "$failed"
