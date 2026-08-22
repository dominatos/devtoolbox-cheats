#!/usr/bin/env bash
# tests/test_macos_cheats_updater.sh
#
# Focused, hermetic tests for the standalone macOS updater's command setup and
# upstream repository cloning. The tests use a copied installed command so no
# sibling macOS source files are available at runtime.
#
# Run: bash tests/test_macos_cheats_updater.sh
# shellcheck disable=SC2016
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
UPDATER_SOURCE="$REPO_ROOT/macOS-beta/cheats-updater.sh"

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

make_workspace() {
    local workspace
    workspace="$(mktemp -d "${TMPDIR:-/tmp}/devtoolbox-macos-updater-test-XXXXXX")" || {
        echo "Error: failed to create temporary workspace" >&2
        exit 1
    }
    echo "$workspace"
}

prepare_installed_updater() {
    local workspace="$1"
    mkdir -p "$workspace/bin" "$workspace/home/.local/bin" \
        "$workspace/upstream/cheats.d/network"
    cp "$UPDATER_SOURCE" "$workspace/home/.local/bin/cheats-updater"
    chmod +x "$workspace/home/.local/bin/cheats-updater"
    printf 'Title: Network Test\n' > "$workspace/upstream/cheats.d/network/test.md"
    printf '%s\n' '#!/usr/bin/env bash' \
        'if [[ "${1:-}" == "clone" ]]; then' \
        '    destination="${@: -1}"' \
        '    mkdir -p "$destination"' \
        "    cp -R \"$workspace/upstream/cheats.d\" \"\$destination/\"" \
        '    exit 0' \
        'fi' \
        'exit 1' > "$workspace/bin/git"
    chmod +x "$workspace/bin/git"
}

run_updater() {
    local workspace="$1" command="$2"
    HOME="$workspace/home" \
    CHEATS_DIR="$workspace/home/cheats.d" \
    PATH="$workspace/bin:/usr/bin:/bin" \
        bash "$workspace/home/.local/bin/cheats-updater" "$command" \
        > "$workspace/stdout.log" 2> "$workspace/stderr.log"
}

test_installed_command_has_no_sibling_runtime_dependency() {
    local workspace output status
    workspace="$(make_workspace)"
    prepare_installed_updater "$workspace"

    run_updater "$workspace" "--help"
    status=$?
    output="$(<"$workspace/stdout.log")"

    assert_eq "installed updater: help exits successfully without compat.sh" "0" "$status"
    assert_contains "installed updater: help identifies macOS" "$output" "(macOS)"
    assert_contains "installed updater: help lists update command" "$output" "update"

    rm -rf "$workspace"
}

test_check_clones_and_compares_upstream() {
    local workspace output status
    workspace="$(make_workspace)"
    prepare_installed_updater "$workspace"

    run_updater "$workspace" "check"
    status=$?
    output="$(<"$workspace/stdout.log")"

    assert_eq "check: exits successfully after clone" "0" "$status"
    assert_contains "check: reports all upstream files as new" "$output" "All 1 files are new"
    assert_contains "check: directs the user to update" "$output" "cheats-updater update"

    rm -rf "$workspace"
}

test_list_uses_cloned_upstream() {
    local workspace output status
    workspace="$(make_workspace)"
    prepare_installed_updater "$workspace"

    run_updater "$workspace" "list"
    status=$?
    output="$(<"$workspace/stdout.log")"

    assert_eq "list: exits successfully after clone" "0" "$status"
    assert_contains "list: prints relative cheatsheet path" "$output" "network/test.md"

    rm -rf "$workspace"
}

echo "=== macOS updater tests ==="
test_installed_command_has_no_sibling_runtime_dependency
test_check_clones_and_compares_upstream
test_list_uses_cloned_upstream
echo "Results: $passed passed, $failed failed"

exit "$failed"
