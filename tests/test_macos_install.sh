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

# pass records a successful test assertion and increments the passed-test count.
pass() {
    echo "OK:   $1"
    ((passed++))
}

# fail records a failed test assertion, prints its message, and marks the test suite as failed.
fail() {
    echo "FAIL: $1"
    failed=1
}

# assert_eq compares expected and actual values and records the assertion result with its description.
assert_eq() {
    local description="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass "$description"
    else
        fail "$description (expected: [$expected], actual: [$actual])"
    fi
}

# assert_contains records whether output contains the expected substring.
assert_contains() {
    local description="$1" output="$2" expected="$3"
    if [[ "$output" == *"$expected"* ]]; then
        pass "$description"
    else
        fail "$description (expected output to contain: [$expected])"
    fi
}

# assert_file_exists verifies that the specified path is an existing regular file and records the assertion result.
assert_file_exists() {
    local description="$1" path="$2"
    if [[ -f "$path" ]]; then
        pass "$description"
    else
        fail "$description (file not found: $path)"
    fi
}

# assert_path_missing verifies that a path does not exist, including dangling symbolic links.
assert_path_missing() {
    local description="$1" path="$2"
    if [[ ! -e "$path" && ! -L "$path" ]]; then
        pass "$description"
    else
        fail "$description (path still exists: $path)"
    fi
}

# make_workspace creates and outputs a temporary workspace with a normalized temporary-directory path.
make_workspace() {
    local workspace
    # macOS TMPDIR carries a trailing slash; strip it so path comparisons in
    # assertions match the installer's normalized output.
    local tmpbase="${TMPDIR:-/tmp}"
    tmpbase="${tmpbase%/}"
    workspace="$(mktemp -d "${tmpbase}/devtoolbox-macos-install-test-XXXXXX")" || {
        echo "Error: failed to create temporary workspace" >&2
        exit 1
    }
    echo "$workspace"
}

# write_stub creates an executable Bash command stub at the specified path with the provided body.
write_stub() {
    local path="$1" body="$2"
    printf '%s\n' '#!/usr/bin/env bash' "$body" > "$path"
    chmod +x "$path"
}

# prepare_fixture creates a minimal repository fixture and isolated home and binary directories within the workspace.
prepare_fixture() {
    local workspace="$1"
    local fixture_root="$workspace/repo"

    mkdir -p "$fixture_root/macOS-beta" "$fixture_root/cheats.d/sample" \
        "$fixture_root/tools" "$workspace/home" "$workspace/bin"
    cp "$REPO_ROOT/macOS-beta/"*.sh "$fixture_root/macOS-beta/"
    printf 'Title: Test Cheat\n' > "$fixture_root/cheats.d/sample/test.md"
    printf '# test tool\n' > "$fixture_root/tools/manage-tocs.py"
}

# setup_stubs configures stubbed system and package-manager commands for an isolated installer test workspace.
setup_stubs() {
    local workspace="$1" managers="$2"
    local bin_dir="$workspace/bin"

    write_stub "$bin_dir/uname" 'echo Darwin'
    write_stub "$bin_dir/fc-list" 'exit 1'
    # Provide a bash 4+ stub so the installer's version check passes.
    # On macOS the system bash is 3.2; this wrapper passes the version probe
    # and delegates all other invocations to the real bash.
    cat > "$bin_dir/bash" << 'BASHSTUB'
#!/bin/bash
if [[ "${1:-}" == "-c" && "${2:-}" == *'BASH_VERSINFO'* ]]; then
    exit 0
fi
exec /bin/bash "$@"
BASHSTUB
    chmod +x "$bin_dir/bash"
    write_stub "$bin_dir/sw_vers" '
case "${1:-}" in
    -productVersion) echo "10.15.7" ;;
    -productName) echo "Mac OS X" ;;
    -buildVersion) echo "19H15" ;;
    *) exit 1 ;;
esac'
    write_stub "$bin_dir/defaults" '
case "${1:-}" in
    read) exit 1 ;;
    *) exit 0 ;;
esac'
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
    installed)
        # Match real `port installed <pkg>` output, including the marker
        # that install_pkg greps for.
        echo "The following ports are currently installed:"
        echo "  $2 @1.0_0 (active)" ;;
    *) exit 0 ;;
esac'
    fi
}

# run_installer executes the installer with isolated workspace settings, optional input, and captured output.
run_installer() {
    local workspace="$1" input="${2:-}"
    local installer="$workspace/repo/macOS-beta/install.sh"

    printf '%s' "$input" | \
        HOME="$workspace/home" \
        PATH="$workspace/bin:/usr/bin:/bin" \
        DEVTOOLBOX_TEST_LOG="$workspace/command.log" \
        DEVTOOLBOX_PKG_MGR_PATH="$workspace/bin" \
        bash "$installer" > "$workspace/stdout.log" 2> "$workspace/stderr.log"
}

# test_homebrew_installation verifies successful Homebrew-based installation, including dependency setup and deployment of cheatsheets, tools, plugins, the updater, and LaunchAgent.
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
    assert_file_exists "Homebrew-only: installs generate-tldr" \
        "$workspace/home/.local/bin/generate-tldr"
    assert_eq "Homebrew-only: dedicated macOS TLDR generator source is copied" \
        "$(<"$workspace/repo/macOS-beta/generate-tldr.sh")" \
        "$(<"$workspace/home/.local/bin/generate-tldr")"
    assert_file_exists "Homebrew-only: installs xbar main plugin" \
        "$workspace/home/Library/Application Support/xbar/plugins/devtoolbox-cheats.30s.sh"
    assert_file_exists "Homebrew-only: installs xbar tools plugin" \
        "$workspace/home/Library/Application Support/xbar/plugins/devtools.1m.sh"
    assert_file_exists "Homebrew-only: creates LaunchAgent plist" "$plist"
    assert_contains "Homebrew-only: plist uses absolute installed updater path" \
        "$(<"$plist")" "<string>${expected_updater}</string>"
    assert_contains "Homebrew-only: plist runs update" "$(<"$plist")" "<string>update</string>"
    assert_contains "Homebrew-only: launchctl loads the generated plist" \
        "$(<"$workspace/command.log")" "load ${plist}"

    rm -rf "$workspace"
}

# test_macports_installation verifies successful installer execution with MacPorts and confirms updater deployment.
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

# test_dual_manager_selection verifies that selecting MacPorts succeeds when both package managers are available.
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

# test_missing_manager_error verifies that the installer reports an error and creates no xbar plugin directory when neither supported package manager is available.
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

# test_xbar_cleanup_preserves_unrelated_plugins verifies stale DevToolbox xbar links are removed or replaced while unrelated plugins are preserved.
test_xbar_cleanup_preserves_unrelated_plugins() {
    local workspace plugins_dir output status main_link
    workspace="$(make_workspace)"
    prepare_fixture "$workspace"
    setup_stubs "$workspace" "brew"
    plugins_dir="$workspace/home/Library/Application Support/xbar/plugins"
    mkdir -p "$plugins_dir"
    ln -s "$workspace/repo/macOS-beta/devtools.1m.sh" "$plugins_dir/devtools.1m.sh"
    ln -s /tmp/unrelated-plugin "$plugins_dir/unrelated.1m.sh"
    printf '# unrelated regular plugin\n' > "$plugins_dir/cheats-updater.sh"

    run_installer "$workspace"
    status=$?
    output="$(<"$workspace/stdout.log")"
    main_link="$plugins_dir/devtoolbox-cheats.30s.sh"

    assert_eq "xbar cleanup: installer exits successfully" "0" "$status"
    assert_file_exists "xbar cleanup: preserves unrelated regular plugin" "$plugins_dir/cheats-updater.sh"
    assert_eq "xbar cleanup: preserves unrelated plugin symlink" "/tmp/unrelated-plugin" \
        "$(readlink "$plugins_dir/unrelated.1m.sh")"
    assert_file_exists "xbar cleanup: installs main plugin" "$main_link"
    assert_file_exists "xbar cleanup: devtools plugin installed" "$plugins_dir/devtools.1m.sh"
    assert_contains "xbar cleanup: reports stale-link cleanup" "$output" "Removed old plugin file/link: devtools.1m.sh"

    rm -rf "$workspace"
}

# test_dependency_install_commands_are_logged verifies that the installer logs installation commands for missing required and optional dependencies.
test_dependency_install_commands_are_logged() {
    local workspace output status
    workspace="$(make_workspace)"
    prepare_fixture "$workspace"
    setup_stubs "$workspace" "brew"
    # Make every package report as NOT installed so the installer must run
    # `brew install <pkg>`; the stub logs each invocation.
    write_stub "$workspace/bin/brew" '
printf "brew %s\\n" "$*" >> "${DEVTOOLBOX_TEST_LOG:?}"
case "${1:-}" in
    --version) echo "Homebrew 4.0.0" ;;
    list) exit 1 ;;
    install) exit 0 ;;
    *) exit 0 ;;
esac'

    run_installer "$workspace"
    status=$?
    local log
    log="$(<"$workspace/command.log")"

    assert_eq "dep-install: installer exits successfully" "0" "$status"
    assert_contains "dep-install: installs required bash" "$log" "install bash"
    assert_contains "dep-install: installs required fzf" "$log" "install fzf"
    assert_contains "dep-install: installs required jq" "$log" "install jq"
    assert_contains "dep-install: installs required pandoc" "$log" "install pandoc"
    assert_contains "dep-install: installs bat" "$log" "install bat"
    assert_contains "dep-install: installs coreutils" "$log" "install coreutils"

    rm -rf "$workspace"
}

# test_macports_install_command_is_logged verifies that missing MacPorts dependencies trigger the expected sudo port install commands while the installer completes successfully.
test_macports_install_command_is_logged() {
    local workspace status
    workspace="$(make_workspace)"
    prepare_fixture "$workspace"
    setup_stubs "$workspace" "port"
    # Report packages as NOT installed so `sudo port install` must run.
    write_stub "$workspace/bin/port" '
printf "port %s\\n" "$*" >> "${DEVTOOLBOX_TEST_LOG:?}"
case "${1:-}" in
    version) echo "Version: 2.9.0" ;;
    installed) exit 0 ;;
    *) exit 0 ;;
esac'

    run_installer "$workspace"
    status=$?
    local log
    log="$(<"$workspace/command.log")"

    assert_eq "macports-dep-install: installer exits successfully" "0" "$status"
    assert_contains "macports-dep-install: sudo port install bash is executed" \
        "$log" "sudo port install bash"
    assert_contains "macports-dep-install: sudo port install jq is executed" \
        "$log" "sudo port install jq"

    rm -rf "$workspace"
}

# test_required_dependency_failure_aborts verifies that a failed required dependency installation aborts the installer and prevents deployment of cheats and the updater.
test_required_dependency_failure_aborts() {
    local workspace status output
    workspace="$(make_workspace)"
    prepare_fixture "$workspace"
    setup_stubs "$workspace" "brew"
    # Every required install fails.
    write_stub "$workspace/bin/brew" '
printf "brew %s\\n" "$*" >> "${DEVTOOLBOX_TEST_LOG:?}"
case "${1:-}" in
    --version) echo "Homebrew 4.0.0" ;;
    list) exit 1 ;;
    install) exit 1 ;;
    *) exit 0 ;;
esac'

    run_installer "$workspace"
    status=$?
    output="$(<"$workspace/stdout.log")"

    if [[ "$status" != "0" ]]; then
        pass "required-dep-failure: installer terminates with failure"
    else
        fail "required-dep-failure: installer terminated with failure (got exit 0)"
    fi
    assert_contains "required-dep-failure: reports the failed dependency" \
        "$output" "could not be installed"
    assert_path_missing "required-dep-failure: cheats are NOT deployed" \
        "$workspace/home/cheats.d/sample/test.md"
    assert_path_missing "required-dep-failure: updater is NOT installed" \
        "$workspace/home/.local/bin/cheats-updater"

    rm -rf "$workspace"
}


# test_regular_xbar_file_is_not_overwritten verifies that the installer refuses to overwrite an unrelated regular xbar plugin file and preserves its contents.
test_regular_xbar_file_is_not_overwritten() {
    local workspace status output
    workspace="$(make_workspace)"
    prepare_fixture "$workspace"
    setup_stubs "$workspace" "brew"
    local plugins_dir="$workspace/home/Library/Application Support/xbar/plugins"
    mkdir -p "$plugins_dir"
    printf 'user own plugin\n' > "$plugins_dir/devtools.1m.sh"

    run_installer "$workspace"
    status=$?
    output="$(<"$workspace/stdout.log")"

    if [[ "$status" != "0" ]]; then
        pass "regular-file guard: installer refuses to overwrite"
    else
        fail "regular-file guard: installer refuses to overwrite (got exit 0)"
    fi
    assert_contains "regular-file guard: reports the refusal" "$output" "Refusing to overwrite unknown file"
    assert_contains "regular-file guard: user file content preserved" \
        "$(cat "$plugins_dir/devtools.1m.sh")" "user own plugin"

    rm -rf "$workspace"
}

# run_installer_hiding_git runs the installer with an isolated PATH that excludes git and captures its output.
run_installer_hiding_git() {
    # Build a slim PATH that mirrors a bare macOS system (no git), plus the
    # package-manager stubs.
    local workspace="$1" input="${2:-}"
    local slim="$workspace/slimbin"
    mkdir -p "$slim"
    local c resolved
    # NOTE: no `uname` here — the Darwin stub from setup_stubs must win.
    for c in bash dirname basename head grep sed date mkdir cp chmod ln rm \
             mv ls launchctl mktemp touch awk cut tr sleep true find cmp sort \
             tee xargs sw_vers defaults; do
        resolved="$(command -v "$c" 2>/dev/null)" && ln -sf "$resolved" "$slim/$c"
    done
    printf '%s' "$input" | \
        HOME="$workspace/home" \
        PATH="$slim:$workspace/bin" \
        DEVTOOLBOX_TEST_LOG="$workspace/command.log" \
        DEVTOOLBOX_PKG_MGR_PATH="$workspace/bin" \
        bash "$workspace/repo/macOS-beta/install.sh" \
        > "$workspace/stdout.log" 2> "$workspace/stderr.log"
}

# test_git_missing_aborts_with_hint verifies that the installer fails when git is unavailable and reports the xcode-select installation remedy.
test_git_missing_aborts_with_hint() {
    local workspace status combined_output
    workspace="$(make_workspace)"
    prepare_fixture "$workspace"
    setup_stubs "$workspace" "brew"

    run_installer_hiding_git "$workspace"
    status=$?
    combined_output="$(cat "$workspace/stdout.log" "$workspace/stderr.log")"

    if [[ "$status" != "0" ]]; then
        pass "git-missing: installer exits with nonzero status"
    else
        fail "git-missing: installer should exit nonzero (got exit 0)"
    fi
    assert_contains "git-missing: reports git requirement" "$combined_output" "git is required"
    assert_contains "git-missing: suggests xcode-select" "$combined_output" "xcode-select --install"

    rm -rf "$workspace"
}

# test_optional_dependency_failure_does_not_abort verifies that optional dependency installation failures do not prevent successful deployment.
test_optional_dependency_failure_does_not_abort() {
    local workspace status output
    workspace="$(make_workspace)"
    prepare_fixture "$workspace"
    setup_stubs "$workspace" "brew"
    # bash installs fine; every OTHER package fails to install.
    write_stub "$workspace/bin/brew" '
printf "brew %s\\n" "$*" >> "${DEVTOOLBOX_TEST_LOG:?}"
case "${1:-}" in
    --version) echo "Homebrew 4.0.0" ;;
    list) [[ "${2:-}" == "bash" ]] && exit 0 || exit 1 ;;
    install) [[ "${2:-}" == "bash" ]] && exit 0 || exit 1 ;;
    *) exit 0 ;;
esac'

    run_installer "$workspace"
    status=$?
    output="$(<"$workspace/stdout.log")"

    assert_eq "optional-failure: installer still succeeds" "0" "$status"
    assert_file_exists "optional-failure: deployment continues" \
        "$workspace/home/cheats.d/sample/test.md"

    rm -rf "$workspace"
}

echo "=== macOS installer tests ==="
test_homebrew_installation
test_macports_installation
test_dual_manager_selection
test_missing_manager_error
test_xbar_cleanup_preserves_unrelated_plugins
test_dependency_install_commands_are_logged
test_macports_install_command_is_logged
test_required_dependency_failure_aborts
test_regular_xbar_file_is_not_overwritten
test_git_missing_aborts_with_hint
test_optional_dependency_failure_does_not_abort
echo "Results: $passed passed, $failed failed"

exit "$failed"
