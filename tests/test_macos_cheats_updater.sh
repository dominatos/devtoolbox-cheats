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

# pass records a successful test result and increments the passed-test count.
pass() {
    echo "OK:   $1"
    ((passed++))
}

# fail records a failed test with the provided message and marks the test suite as unsuccessful.
fail() {
    echo "FAIL: $1"
    failed=1
}

# assert_eq compares expected and actual values and records the test result with the given description.
assert_eq() {
    local description="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass "$description"
    else
        fail "$description (expected: [$expected], actual: [$actual])"
    fi
}

# assert_contains checks whether output contains the expected text and records the assertion result.
assert_contains() {
    local description="$1" output="$2" expected="$3"
    if [[ "$output" == *"$expected"* ]]; then
        pass "$description"
    else
        fail "$description (expected output to contain: [$expected])"
    fi
}

# make_workspace creates and prints a temporary directory for updater tests.
make_workspace() {
    local workspace
    # macOS TMPDIR carries a trailing slash; strip it for consistent paths.
    local tmpbase="${TMPDIR:-/tmp}"
    tmpbase="${tmpbase%/}"
    workspace="$(mktemp -d "${tmpbase}/devtoolbox-macos-updater-test-XXXXXX")" || {
        echo "Error: failed to create temporary workspace" >&2
        exit 1
    }
    echo "$workspace"
}

# prepare_installed_updater prepares an isolated workspace with an installed updater, upstream cheatsheet, and mock Git executable.
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

# run_updater executes the installed cheats updater with an isolated environment and captures its standard output and error.
run_updater() {
    local workspace="$1" command="$2"
    # Do not let a caller-provided Bash startup file replace the fixture PATH;
    # the updater must use the hermetic git stub prepared above.
    BASH_ENV= \
    HOME="$workspace/home" \
    CHEATS_DIR="$workspace/home/cheats.d" \
    PATH="$workspace/bin:/usr/bin:/bin" \
        bash "$workspace/home/.local/bin/cheats-updater" "$command" \
        > "$workspace/stdout.log" 2> "$workspace/stderr.log"
}

# test_installed_command_has_no_sibling_runtime_dependency verifies that the installed updater displays help successfully without its sibling runtime file.
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

# test_check_clones_and_compares_upstream verifies that the updater clones the upstream cheatsheets and reports new files with an update recommendation.
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

# test_list_uses_cloned_upstream verifies that the updater lists cheatsheets from the cloned upstream repository.
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

test_update_backs_up_and_preserves_custom_files() {
    local workspace status output backup_dir
    workspace="$(make_workspace)"
    prepare_installed_updater "$workspace"

    # Pre-existing custom file that must survive the update.
    mkdir -p "$workspace/home/cheats.d/mine"
    printf 'Title: My Custom\n' > "$workspace/home/cheats.d/mine/custom.md"
    # Stub manage-tocs.py so TOC integration can be observed.
    mkdir -p "$workspace/home/.local/share/devtoolbox-cheats/tools"
    cat > "$workspace/home/.local/share/devtoolbox-cheats/tools/manage-tocs.py" <<'PY'
#!/usr/bin/env python3
import sys
print("TOCS-APPLIED:" + ",".join(sys.argv[2:]))
PY
    chmod +x "$workspace/home/.local/share/devtoolbox-cheats/tools/manage-tocs.py"

    run_updater "$workspace" "update"
    status=$?
    output="$(<"$workspace/stdout.log")"

    assert_eq "update: exits successfully" "0" "$status"
    assert_contains "update: copies upstream file into CHEATS_DIR" \
        "$(cat "$workspace/home/cheats.d/network/test.md")" "Title: Network Test"
    assert_contains "update: preserves custom file" \
        "$(cat "$workspace/home/cheats.d/mine/custom.md")" "My Custom"

    backup_dir="$(ls -d "$workspace/home/.local/share/devtoolbox-cheats/backups/"* 2>/dev/null | head -n1)"
    assert_contains "update: creates timestamped backup of prior state" \
        "$(cat "$backup_dir/mine/custom.md")" "My Custom"
    # log_info writes to stderr.
    assert_contains "update: invokes manage-tocs.py for official files" \
        "$(<"$workspace/stderr.log")" "TOC formatting applied"

    rm -rf "$workspace"
}

echo "=== macOS updater tests ==="
test_installed_command_has_no_sibling_runtime_dependency
test_check_clones_and_compares_upstream
test_list_uses_cloned_upstream
test_update_backs_up_and_preserves_custom_files
echo "Results: $passed passed, $failed failed"

exit "$failed"
