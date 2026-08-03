#!/usr/bin/env bash
# tests/test_bump_version.sh
#
# Tests for bump-version.sh:
#   - Missing version.txt error
#   - Updates VERSION= in .sh files
#   - Updates "Version": in KDE metadata.json
#   - Handles sed special characters in version
#
# Run directly:  bash tests/test_bump_version.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET_SCRIPT="$REPO_ROOT/bump-version.sh"

# Source shared test helpers
# shellcheck source=tests/test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

test_missing_version_txt_exits_with_error() {
    local ws rc output
    ws="$(make_workspace)"
    cp "$TARGET_SCRIPT" "$ws/bump-version.sh"
    chmod +x "$ws/bump-version.sh"
    output="$(bash "$ws/bump-version.sh" 2>&1; echo "EXITCODE:$?")"
    rc="${output##*EXITCODE:}"
    output="${output%EXITCODE:*}"
    assert_eq "missing version.txt: exits non-zero" "1" "$rc"
    assert_contains "missing version.txt: reports error" "$output" "Error"
    rm -rf "$ws"
}

test_updates_version_in_bash_scripts() {
    local ws
    ws="$(make_workspace)"
    cp "$TARGET_SCRIPT" "$ws/bump-version.sh"
    chmod +x "$ws/bump-version.sh"
    printf '1.2.3\n' > "$ws/version.txt"
    # shellcheck disable=SC2016
    printf '#!/bin/bash\nVERSION="v1.0.0"\necho "$VERSION"\n' > "$ws/test-script.sh"

    bash "$ws/bump-version.sh"

    local content
    content="$(cat "$ws/test-script.sh")"
    assert_contains "bump .sh: updates VERSION" "$content" 'VERSION="v1.2.3"'
    assert_contains "bump .sh: preserves script structure" "$content" "#!/bin/bash"
    rm -rf "$ws"
}

test_updates_version_in_metadata_json() {
    local ws
    ws="$(make_workspace)"
    cp "$TARGET_SCRIPT" "$ws/bump-version.sh"
    chmod +x "$ws/bump-version.sh"
    printf '2.0.0\n' > "$ws/version.txt"
    mkdir -p "$ws/kde-widget-plasma6/DevToolboxPlasmoid"
    printf '{"Name": "Test", "Version": "1.0.0"}\n' > "$ws/kde-widget-plasma6/DevToolboxPlasmoid/metadata.json"

    bash "$ws/bump-version.sh"

    local content
    content="$(cat "$ws/kde-widget-plasma6/DevToolboxPlasmoid/metadata.json")"
    assert_contains "bump metadata: updates Version" "$content" '"Version": "2.0.0"'
    rm -rf "$ws"
}

test_preserves_readonly_prefix() {
    local ws
    ws="$(make_workspace)"
    cp "$TARGET_SCRIPT" "$ws/bump-version.sh"
    chmod +x "$ws/bump-version.sh"
    printf '3.0.0\n' > "$ws/version.txt"
    printf '#!/bin/bash\nreadonly VERSION="v1.0.0"\n' > "$ws/test-script.sh"

    bash "$ws/bump-version.sh"

    local content
    content="$(cat "$ws/test-script.sh")"
    assert_contains "bump readonly: preserves readonly prefix" "$content" 'readonly VERSION="v3.0.0"'
    rm -rf "$ws"
}

test_version_with_special_chars() {
    local ws
    ws="$(make_workspace)"
    cp "$TARGET_SCRIPT" "$ws/bump-version.sh"
    chmod +x "$ws/bump-version.sh"
    printf '1.0.0-beta/1\n' > "$ws/version.txt"
    printf '#!/bin/bash\nVERSION="v1.0.0"\n' > "$ws/test-script.sh"

    bash "$ws/bump-version.sh"

    local content
    content="$(cat "$ws/test-script.sh")"
    assert_contains "bump special chars: handles slash in version" "$content" 'VERSION="v1.0.0-beta/1"'
    rm -rf "$ws"
}

test_version_with_ampersand() {
    local ws
    ws="$(make_workspace)"
    cp "$TARGET_SCRIPT" "$ws/bump-version.sh"
    chmod +x "$ws/bump-version.sh"
    printf '1.0.0&beta\n' > "$ws/version.txt"
    printf '#!/bin/bash\nVERSION="v1.0.0"\n' > "$ws/test-script.sh"

    bash "$ws/bump-version.sh"

    local content
    content="$(cat "$ws/test-script.sh")"
    assert_contains "bump special chars: handles ampersand in version" "$content" 'VERSION="v1.0.0&beta"'
    rm -rf "$ws"
}

test_no_version_txt_no_changes() {
    local ws rc output
    ws="$(make_workspace)"
    cp "$TARGET_SCRIPT" "$ws/bump-version.sh"
    chmod +x "$ws/bump-version.sh"
    printf '#!/bin/bash\nVERSION="v1.0.0"\n' > "$ws/test-script.sh"
    local before
    before="$(cat "$ws/test-script.sh")"

    # Should fail because version.txt is missing from the workspace
    output="$(bash "$ws/bump-version.sh" 2>&1; echo "EXITCODE:$?")"
    rc="${output##*EXITCODE:}"

    assert_eq "no version.txt: exits non-zero" "1" "$rc"
    local after
    after="$(cat "$ws/test-script.sh")"
    assert_eq "no version.txt: no changes to script" "$before" "$after"
    rm -rf "$ws"
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------

test_missing_version_txt_exits_with_error
test_updates_version_in_bash_scripts
test_updates_version_in_metadata_json
test_preserves_readonly_prefix
test_version_with_special_chars
test_version_with_ampersand
test_no_version_txt_no_changes

# shellcheck disable=SC2154
exit $failed
