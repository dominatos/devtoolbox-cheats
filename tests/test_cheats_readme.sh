#!/usr/bin/env bash
# tests/test_cheats_readme.sh
#
# Functional tests for docs/cheats-readme.sh, exercising the CHEATS_DIR /
# README_FILE overrides and directory/file existence checks introduced in
# this change.
#
# Run directly:  bash tests/test_cheats_readme.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET_SCRIPT="$REPO_ROOT/docs/cheats-readme.sh"

# Source shared test helpers
# shellcheck source=tests/test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

# test_missing_cheats_dir verifies that the target script reports a missing cheats directory and exits with status 1.
test_missing_cheats_dir() {
    local ws readme output rc
    ws="$(make_workspace)"
    readme="$ws/README.md"
    printf 'placeholder\n' > "$readme"

    output="$(CHEATS_DIR="$ws/does-not-exist" README_FILE="$readme" bash "$TARGET_SCRIPT" 2>&1)"
    rc=$?
    assert_eq "missing cheats dir: exit code" "1" "$rc"
    assert_contains "missing cheats dir: error message" "$output" "Directory not found"

    rm -rf "$ws"
}

# test_missing_readme_file verifies that the target script exits with an error when the README file is missing.
test_missing_readme_file() {
    local ws output rc
    ws="$(make_workspace)"
    mkdir -p "$ws/cheats.d"

    output="$(CHEATS_DIR="$ws/cheats.d" README_FILE="$ws/README.md" bash "$TARGET_SCRIPT" 2>&1)"
    rc=$?
    assert_eq "missing README: exit code" "1" "$rc"
    assert_contains "missing README: error message" "$output" "File not found"

    rm -rf "$ws"
}

# test_all_referenced verifies that a README referencing every cheatsheet produces a success message and exits successfully.
test_all_referenced() {
    local ws output rc
    ws="$(make_workspace)"
    mkdir -p "$ws/cheats.d/network"
    printf '# Foo\n' > "$ws/cheats.d/network/foo.md"
    printf '[foo](network/foo.md)\n' > "$ws/README.md"

    output="$(CHEATS_DIR="$ws/cheats.d" README_FILE="$ws/README.md" bash "$TARGET_SCRIPT" 2>&1)"
    rc=$?
    assert_eq "all referenced: exit code" "0" "$rc"
    assert_contains "all referenced: success message" "$output" "All cheatsheets are referenced in README.md"

    rm -rf "$ws"
}

# test_missing_reference_reported verifies that an unreferenced cheatsheet is reported by relative path and count.
test_missing_reference_reported() {
    local ws output rc
    ws="$(make_workspace)"
    mkdir -p "$ws/cheats.d/network"
    printf '# Foo\n' > "$ws/cheats.d/network/foo.md"
    printf 'no links here\n' > "$ws/README.md"

    output="$(CHEATS_DIR="$ws/cheats.d" README_FILE="$ws/README.md" bash "$TARGET_SCRIPT" 2>&1)"
    rc=$?
    assert_eq "missing reference: exit code" "0" "$rc"
    assert_contains "missing reference: reports relative path" "$output" "Missing in README: network/foo.md"
    assert_contains "missing reference: reports count" "$output" "1 cheatsheets missing"

    rm -rf "$ws"
}

# --- Test 5: with no overrides, paths default to REPO_ROOT/cheats.d and
# REPO_ROOT/README.md, where REPO_ROOT is derived from the script's own
# location (not the caller's cwd or the real project checkout). ---
test_defaults_resolve_relative_to_script_location() {
    local ws output rc
    ws="$(make_workspace)"
    mkdir -p "$ws/fake-repo/docs" "$ws/fake-repo/cheats.d/basics"
    cp "$TARGET_SCRIPT" "$ws/fake-repo/docs/cheats-readme.sh"
    printf '# Foo\n' > "$ws/fake-repo/cheats.d/basics/foo.md"
    printf '[foo](basics/foo.md)\n' > "$ws/fake-repo/README.md"

    output="$(cd /tmp && bash "$ws/fake-repo/docs/cheats-readme.sh" 2>&1)"
    rc=$?
    assert_eq "defaults: exit code" "0" "$rc"
    assert_contains "defaults: resolves cheats.d/README.md next to script's repo root" \
        "$output" "All cheatsheets are referenced in README.md"

    rm -rf "$ws"
}

test_missing_cheats_dir
test_missing_readme_file
test_all_referenced
test_missing_reference_reported
test_defaults_resolve_relative_to_script_location

# shellcheck disable=SC2154
exit $failed