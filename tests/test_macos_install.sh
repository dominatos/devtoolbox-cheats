#!/usr/bin/env bash
# tests/test_macos_install.sh
#
# Hermetic integration tests for macOS-beta/install.sh. Each case runs a
# minimal copied installer with a temporary HOME and stubbed macOS commands.
# No real package manager, launchd service, or user configuration is touched.
#
# Run: bash tests/test_macos_install.sh
# shellcheck disable=SC2016
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

failed=0
passed=0

pass() {
    echo "OK:   $1"
    ((passed++))
}

fail() {
    echo "FAIL: $1"
    failed=1
}

assert_eq() {
    local description="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass "$description"
    else
        fail "$description (expected: [$expected], actual: [$actual])"
    fi
}

assert_contains() {
    local description="$1" output="$2" expected="$3"
    if [[ "$output" == *"$expected"* ]]; then
        pass "$description"
    else
        fail "$description (expected output to contain: [$expected])"
    fi
}

assert_file_exists() {
    local description="$1" path="$2"
    if [[ -f "$path" ]]; then
        pass "$description"
    else
        fail "$description (file not found: $path)"
    fi
}

assert_path_missing() {
    local description="$1" path="$2"
    if [[ ! -e "$path" && ! -L "$path" ]]; then
        pass "$description"
    else
        fail "$description (path still exists: $path)"
    fi
}

make_workspace() {
    local workspace
    workspace="$(mktemp -d "${TMPDIR:-/tmp}/devtoolbox-macos-install-test-XXXXXX")" || {
        echo "Error: failed to create temporary workspace" >&2
        exit 1
    }
    echo "$workspace"
}

write_stub() {
    local path="$1" body="$2"
    printf '%s\n' '#!/usr/bin/env bash' "$body" > "$path"
    chmod +x "$path"
}

prepare_fixture() {
    local workspace="$1"
    local fixture_root="$workspace/repo"

    mkdir -p "$fixture_root/macOS-beta" "$fixture_root/cheats.d/sample" \
        "$fixture_root/tools" "$workspace/home" "$workspace/bin"
    cp "$REPO_ROOT/macOS-beta/"*.sh "$fixture_root/macOS-beta/"
    cp "$REPO_ROOT/cheats-updater.sh" "$fixture_root/cheats-updater.sh"
    printf 'Title: Test Cheat\n' > "$fixture_root/cheats.d/sample/test.md"
    printf '# test tool\n' > "$fixture_root/tools/manage-tocs.py"
}

setup_stubs() {
    local workspace="$1" managers="$2"
    local bin_dir="$workspace/bin"

    write_stub "$bin_dir/uname" 'echo Darwin'
    write_stub "$bin_dir/fc-list" 'exit 1'
    write_stub "$bin_dir/launchctl" '
printf "%s\\n" "$*" >> "${DEVTOOLBOX_TEST_LOG:?}"
if [[ "${1:-}" == "list" ]]; then
    exit 1
fi
exit 0'
    write_stub "$bin_dir/sudo" '
printf "sudo %s\\n" "$*" >> "${DEVTOOLBOX_TEST_LOG:?}"
"$@"'

    if [[ "$managers" == *brew* ]]; then
        write_stub "$bin_dir/brew" '
printf "brew %s\\n" "$*" >> "${DEVTOOLBOX_TEST_LOG:?}"
case "${1:-}" in
    --version) echo "Homebrew 4.0.0" ;;
    list) exit 0 ;;
    *) exit 0 ;;
esac'
    fi

    if [[ "$managers" == *port* ]]; then
        write_stub "$bin_dir/port" '
printf "port %s\\n" "$*" >> "${DEVTOOLBOX_TEST_LOG:?}"
case "${1:-}" in
    version) echo "Version: 2.9.0" ;;
    installed) echo "  $2 @1.0_0 (active)" ;;
    *) exit 0 ;;
esac'
    fi
}

run_installer() {
    local workspace="$1" input="${2:-}"
    local installer="$workspace/repo/macOS-beta/install.sh"

    printf '%s' "$input" | \
        HOME="$workspace/home" \
        PATH="$workspace/bin:/usr/bin:/bin" \
        DEVTOOLBOX_TEST_LOG="$workspace/command.log" \
        bash "$installer" > "$workspace/stdout.log" 2> "$workspace/stderr.log"
}

test_homebrew_installation() {
    local workspace output status plist expected_updater
    workspace="$(make_workspace)"
    prepare_fixture "$workspace"
    setup_stubs "$workspace" "brew"

    run_installer "$workspace"
    status=$?
    output="$(<"$workspace/stdout.log")"
    plist="$workspace/home/Library/LaunchAgents/com.devtoolbox-cheats.updater.plist"
    expected_updater="$workspace/home/.local/bin/cheats-updater"

    assert_eq "Homebrew-only: installer exits successfully" "0" "$status"
    assert_contains "Homebrew-only: selects Homebrew" "$output" "Selected package manager: brew"
    assert_file_exists "Homebrew-only: deploys cheatsheets" "$workspace/home/cheats.d/sample/test.md"
    assert_file_exists "Homebrew-only: deploys tools" "$workspace/home/.local/share/devtoolbox-cheats/tools/manage-tocs.py"
    assert_file_exists "Homebrew-only: installs updater" "$expected_updater"
    assert_eq "Homebrew-only: dedicated macOS updater source is copied" \
        "$(<"$workspace/repo/macOS-beta/cheats-updater.sh")" "$(<"$expected_updater")"
    assert_file_exists "Homebrew-only: creates LaunchAgent plist" "$plist"
    assert_contains "Homebrew-only: plist uses absolute installed updater path" \
        "$(<"$plist")" "<string>${expected_updater}</string>"
    assert_contains "Homebrew-only: plist runs update" "$(<"$plist")" "<string>update</string>"
    assert_contains "Homebrew-only: launchctl loads the generated plist" \
        "$(<"$workspace/command.log")" "load ${plist}"

    rm -rf "$workspace"
}

test_macports_installation() {
    local workspace output status
    workspace="$(make_workspace)"
    prepare_fixture "$workspace"
    setup_stubs "$workspace" "port"

    run_installer "$workspace"
    status=$?
    output="$(<"$workspace/stdout.log")"

    assert_eq "MacPorts-only: installer exits successfully" "0" "$status"
    assert_contains "MacPorts-only: selects MacPorts" "$output" "Selected package manager: port"
    assert_file_exists "MacPorts-only: installs updater" "$workspace/home/.local/bin/cheats-updater"

    rm -rf "$workspace"
}

test_dual_manager_selection() {
    local workspace output status
    workspace="$(make_workspace)"
    prepare_fixture "$workspace"
    setup_stubs "$workspace" "brew port"

    run_installer "$workspace" $'2\n'
    status=$?
    output="$(<"$workspace/stdout.log")"

    assert_eq "Dual-manager: installer exits successfully" "0" "$status"
    assert_contains "Dual-manager: accepts MacPorts selection" "$output" "Selected package manager: port"

    rm -rf "$workspace"
}

test_missing_manager_error() {
    local workspace output status
    workspace="$(make_workspace)"
    prepare_fixture "$workspace"
    setup_stubs "$workspace" ""

    run_installer "$workspace"
    status=$?
    output="$(<"$workspace/stdout.log")"

    assert_eq "No manager: installer exits with an error" "1" "$status"
    assert_contains "No manager: reports the supported managers" "$output" \
        "No package manager found (Homebrew or MacPorts required)."
    assert_path_missing "No manager: does not create xbar plugin directory" \
        "$workspace/home/Library/Application Support/xbar/plugins"

    rm -rf "$workspace"
}

test_xbar_cleanup_preserves_unrelated_plugins() {
    local workspace plugins_dir output status main_link
    workspace="$(make_workspace)"
    prepare_fixture "$workspace"
    setup_stubs "$workspace" "brew"
    plugins_dir="$workspace/home/Library/Application Support/xbar/plugins"
    mkdir -p "$plugins_dir"
    ln -s /tmp/old-devtoolbox-plugin "$plugins_dir/compat.sh"
    ln -s /tmp/old-devtoolbox-plugin "$plugins_dir/devtools.1m.sh"
    ln -s /tmp/unrelated-plugin "$plugins_dir/unrelated.1m.sh"
    printf '# unrelated regular plugin\n' > "$plugins_dir/cheats-updater.sh"

    run_installer "$workspace"
    status=$?
    output="$(<"$workspace/stdout.log")"
    main_link="$plugins_dir/devtoolbox-cheats.30s.sh"

    assert_eq "xbar cleanup: installer exits successfully" "0" "$status"
    assert_path_missing "xbar cleanup: removes stale compat symlink" "$plugins_dir/compat.sh"
    assert_path_missing "xbar cleanup: removes stale devtools symlink" "$plugins_dir/devtools.1m.sh"
    assert_file_exists "xbar cleanup: preserves unrelated regular plugin" "$plugins_dir/cheats-updater.sh"
    assert_eq "xbar cleanup: preserves unrelated plugin symlink" "/tmp/unrelated-plugin" \
        "$(readlink "$plugins_dir/unrelated.1m.sh")"
    assert_eq "xbar cleanup: main symlink targets the dedicated script" \
        "$workspace/repo/macOS-beta/devtoolbox-cheats.30s.sh" "$(readlink "$main_link")"
    assert_contains "xbar cleanup: reports stale-link cleanup" "$output" "Removed stale xbar link: compat.sh"

    rm -rf "$workspace"
}

echo "=== macOS installer tests ==="
test_homebrew_installation
test_macports_installation
test_dual_manager_selection
test_missing_manager_error
test_xbar_cleanup_preserves_unrelated_plugins
echo "Results: $passed passed, $failed failed"

exit "$failed"
