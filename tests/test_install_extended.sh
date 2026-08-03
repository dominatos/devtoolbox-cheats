#!/usr/bin/env bash
# tests/test_install_extended.sh
#
# Tests additional install.sh functions:
#   is_argos_present, install_argos, install_generic_app,
#   install_desktop_entry, print_de_instructions
#
# Run:  bash tests/test_install_extended.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
INSTALL_SCRIPT="$REPO_ROOT/install.sh"

failed=0
pass() { echo "OK:   $1"; }
fail() { echo "FAIL: $1"; failed=1; }

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass "$desc"
    else
        fail "$desc (expected: [$expected], actual: [$actual])"
    fi
}

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        pass "$desc"
    else
        fail "$desc (expected to contain [$needle], got: [$haystack])"
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

extract_func() {
    local name="$1"
    awk -v name="$name" '
        $0 ~ "^" name "\\(\\) \\{" { flag=1 }
        flag { print }
        flag && /^}/ { exit }
    ' "$INSTALL_SCRIPT"
}

make_workspace() {
    local ws
    ws="$(mktemp -d "${TMPDIR:-/tmp}/devtoolbox-install-ext-test-XXXXXX")" || {
        echo "Error: failed to create workspace" >&2
        exit 1
    }
    echo "$ws"
}

echo "=== Checking function existence ==="
for fn in is_argos_present install_argos install_generic_app install_desktop_entry print_de_instructions; do
    if [[ -z "$(extract_func "$fn")" ]]; then
        fail "extract_func: could not find function '$fn' in $INSTALL_SCRIPT"
    fi
done

echo ""
echo "=== install.sh extended tests ==="
echo ""

# --- is_argos_present ---

echo "is_argos_present:"

test_is_argos_present_true_when_dir_exists() {
    local ws
    ws="$(make_workspace)"
    mkdir -p "$ws/home/.config/argos"
    
    local rc=0
    HOME="$ws/home" bash -c "$(extract_func is_argos_present); is_argos_present" || rc=$?
    assert_eq "is_argos_present: returns 0 when dir exists" "0" "$rc"
    
    rm -rf "$ws"
}
test_is_argos_present_true_when_dir_exists

test_is_argos_present_false_when_no_dir() {
    local ws
    ws="$(make_workspace)"
    mkdir -p "$ws/home"
    
    local rc=0
    HOME="$ws/home" bash -c "$(extract_func is_argos_present); is_argos_present" || rc=$?
    assert_eq "is_argos_present: returns 1 when no dir" "1" "$rc"
    
    rm -rf "$ws"
}
test_is_argos_present_false_when_no_dir

# --- install_argos ---

echo ""
echo "install_argos:"

test_install_argos_copies_scripts() {
    local ws repo_copy func_file out
    ws="$(make_workspace)"
    repo_copy="$ws/repo"
    mkdir -p "$repo_copy"
    echo "#!/bin/bash" > "$repo_copy/devtoolbox-cheats.30s.sh"
    echo "#!/bin/bash" > "$repo_copy/devtools.1m.sh"
    
    func_file="$ws/func.sh"
    extract_func install_argos > "$func_file"
    
    out="$(HOME="$ws/home" bash -c "
        SCRIPT_DIR='$repo_copy'
        source '$func_file'
        install_argos
    " 2>&1)"
    
    assert_contains "install_argos: output mentions argos" "$out" "Installing Argos"
    assert_file_exists "install_argos: copies main script" "$ws/home/.config/argos/devtoolbox-cheats.30s.sh"
    assert_file_exists "install_argos: copies devtools script" "$ws/home/.config/argos/devtools.1m.sh"
    
    rm -rf "$ws"
}
test_install_argos_copies_scripts

test_install_argos_handles_missing_scripts() {
    local ws repo_copy func_file out
    ws="$(make_workspace)"
    repo_copy="$ws/repo"
    mkdir -p "$repo_copy"  # No scripts
    
    func_file="$ws/func.sh"
    extract_func install_argos > "$func_file"
    
    out="$(HOME="$ws/home" bash -c "
        SCRIPT_DIR='$repo_copy'
        source '$func_file'
        install_argos
    " 2>&1)"
    assert_contains "install_argos: warns on missing script" "$out" "not found"
    
    rm -rf "$ws"
}
test_install_argos_handles_missing_scripts

# --- install_generic_app ---

echo ""
echo "install_generic_app:"

test_install_generic_app_copies_script() {
    local ws repo_copy func_file
    ws="$(make_workspace)"
    repo_copy="$ws/repo"
    mkdir -p "$repo_copy"
    echo "#!/bin/bash" > "$repo_copy/devtoolbox-cheats.30s.sh"
    mkdir -p "$repo_copy/docs/img"
    touch "$repo_copy/docs/img/icons8-test-cheating-48.png"
    
    func_file="$ws/func.sh"
    extract_func install_generic_app > "$func_file"
    
    HOME="$ws/home" bash -c "
        SCRIPT_DIR='$repo_copy'
        source '$func_file'
        install_generic_app
    " 2>&1 >/dev/null
    assert_file_exists "install_generic_app: installs script" "$ws/home/.local/bin/devtoolbox-cheats-menu"
    
    rm -rf "$ws"
}
test_install_generic_app_copies_script

test_install_generic_app_installs_icon() {
    local ws repo_copy func_file
    ws="$(make_workspace)"
    repo_copy="$ws/repo"
    mkdir -p "$repo_copy"
    touch "$repo_copy/devtoolbox-cheats.30s.sh"
    mkdir -p "$repo_copy/docs/img"
    touch "$repo_copy/docs/img/icons8-test-cheating-48.png"
    
    func_file="$ws/func.sh"
    extract_func install_generic_app > "$func_file"
    
    HOME="$ws/home" bash -c "
        SCRIPT_DIR='$repo_copy'
        source '$func_file'
        install_generic_app
    " 2>&1 >/dev/null
    assert_file_exists "install_generic_app: installs icon" "$ws/home/.local/share/icons/devtoolbox-cheats.png"
    
    rm -rf "$ws"
}
test_install_generic_app_installs_icon

# --- install_desktop_entry ---

echo ""
echo "install_desktop_entry:"

test_install_desktop_entry_creates_file() {
    local ws
    ws="$(make_workspace)"
    mkdir -p "$ws/home/.local/bin" "$ws/home/.local/share/icons"
    touch "$ws/home/.local/bin/devtoolbox-cheats-menu"
    touch "$ws/home/.local/share/icons/devtoolbox-cheats.png"
    
    HOME="$ws/home" bash -c "$(extract_func install_desktop_entry); install_desktop_entry" 2>&1 >/dev/null
    assert_file_exists "install_desktop_entry: creates .desktop file" "$ws/home/.local/share/applications/devtoolbox-cheats.desktop"
    
    rm -rf "$ws"
}
test_install_desktop_entry_creates_file

test_install_desktop_entry_has_correct_content() {
    local ws
    ws="$(make_workspace)"
    mkdir -p "$ws/home/.local/bin" "$ws/home/.local/share/icons"
    touch "$ws/home/.local/bin/devtoolbox-cheats-menu"
    touch "$ws/home/.local/share/icons/devtoolbox-cheats.png"
    
    HOME="$ws/home" bash -c "$(extract_func install_desktop_entry); install_desktop_entry" 2>&1 >/dev/null
    local content
    content="$(cat "$ws/home/.local/share/applications/devtoolbox-cheats.desktop")"
    assert_contains "install_desktop_entry: has Name" "$content" "Name=DevToolbox Cheats"
    assert_contains "install_desktop_entry: has Type" "$content" "Type=Application"
    assert_contains "install_desktop_entry: has Exec" "$content" "Exec="
    assert_contains "install_desktop_entry: has Icon" "$content" "Icon="
    
    rm -rf "$ws"
}
test_install_desktop_entry_has_correct_content

# --- print_de_instructions ---

echo ""
echo "print_de_instructions:"

test_print_de_instructions_xfce() {
    local out
    out="$(HOME="/tmp" bash -c "$(extract_func print_de_instructions); print_de_instructions xfce")"
    assert_contains "print_de_instructions: xfce mentions genmon" "$out" "Genmon"
    assert_contains "print_de_instructions: xfce mentions panel" "$out" "panel"
}
test_print_de_instructions_xfce

test_print_de_instructions_kde() {
    local out
    out="$(HOME="/tmp" bash -c "$(extract_func print_de_instructions); print_de_instructions kde")"
    # KDE has no specific case — falls through to default (*)
    assert_contains "print_de_instructions: kde shows generic instructions" "$out" "Unknown desktop"
}
test_print_de_instructions_kde

test_print_de_instructions_gnome() {
    local out
    out="$(HOME="/tmp" bash -c "$(extract_func print_de_instructions); print_de_instructions gnome")"
    assert_contains "print_de_instructions: gnome mentions Argos" "$out" "Argos"
}
test_print_de_instructions_gnome

test_print_de_instructions_tiling() {
    local out
    out="$(HOME="/tmp" bash -c "$(extract_func print_de_instructions); print_de_instructions tiling")"
    assert_contains "print_de_instructions: tiling mentions i3" "$out" "i3"
    assert_contains "print_de_instructions: tiling mentions sway" "$out" "sway"
    assert_contains "print_de_instructions: tiling mentions hyprland" "$out" "hyprland"
}
test_print_de_instructions_tiling

test_print_de_instructions_unknown() {
    local out
    out="$(HOME="/tmp" bash -c "$(extract_func print_de_instructions); print_de_instructions unknown_de")"
    assert_contains "print_de_instructions: unknown shows generic instructions" "$out" "Unknown desktop"
}
test_print_de_instructions_unknown

test_print_de_instructions_contains_script_path() {
    local out
    out="$(HOME="/tmp" bash -c "$(extract_func print_de_instructions); print_de_instructions kde")"
    assert_contains "print_de_instructions: contains script path" "$out" "devtoolbox-cheats-menu"
}
test_print_de_instructions_contains_script_path

echo ""
echo "=== All install.sh extended tests complete ==="
echo ""
exit "$failed"
