#!/usr/bin/env bash
# tests/test_macos_devtoolbox_cheats.sh
#
# Hermetic regression tests for the macOS menu script's viewer selection,
# terminal launching, and cache rebuild behavior. macOS commands are stubbed,
# so this suite is safe to run on both macOS and Linux CI workers.
#
# Run: bash tests/test_macos_devtoolbox_cheats.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET_SCRIPT="$REPO_ROOT/macOS-beta/devtoolbox-cheats.30s.sh"

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

assert_not_contains() {
    local description="$1" output="$2" unexpected="$3"
    if [[ "$output" != *"$unexpected"* ]]; then
        pass "$description"
    else
        fail "$description (did not expect output to contain: [$unexpected])"
    fi
}

file_mode() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        stat -f '%Lp' "$1"
    else
        stat -c '%a' "$1"
    fi
}

make_workspace() {
    local workspace tmpbase="${TMPDIR:-/tmp}"
    tmpbase="${tmpbase%/}"
    workspace="$(mktemp -d "${tmpbase}/devtoolbox-macos-menu-test-XXXXXX")" || {
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

prepare_workspace() {
    local workspace="$1"
    mkdir -p "$workspace/bin" "$workspace/home/cheats.d/Test Group"
    : > "$workspace/command.log"

    cat > "$workspace/home/cheats.d/Test Group/cheat with spaces.md" <<'CHEAT'
Title: Viewer Test
Group: Test Group
Icon: 🧪
Order: 7

# Commands

echo safe
CHEAT

    # shellcheck disable=SC2016
    write_stub "$workspace/bin/base64" '
if [[ "${1:-}" == "-D" ]]; then
    if /usr/bin/base64 -D </dev/null >/dev/null 2>&1; then
        exec /usr/bin/base64 -D
    fi
    exec /usr/bin/base64 -d
fi
exec /usr/bin/base64 "$@"'

    # shellcheck disable=SC2016
    write_stub "$workspace/bin/pbcopy" '
cat > "${DEVTOOLBOX_TEST_WORKSPACE:?}/clipboard.log"'

    # shellcheck disable=SC2016
    write_stub "$workspace/bin/osascript" '
{
    printf "osascript"
    printf " <%s>" "$@"
    printf "\n"
} >> "${DEVTOOLBOX_TEST_LOG:?}"
cat >/dev/null
exit "${OSASCRIPT_STATUS:-0}"'

    # shellcheck disable=SC2016
    write_stub "$workspace/bin/open" '
{
    printf "open"
    printf " <%s>" "$@"
    printf "\n"
} >> "${DEVTOOLBOX_TEST_LOG:?}"
exit "${OPEN_STATUS:-0}"'
}

run_script() {
    local workspace="$1" viewers="$2" osascript_status="$3"
    shift 3
    if [[ -n "$viewers" ]]; then
        mkdir -p "$workspace/home/.config/devtoolbox-cheats"
        printf '%s\n' "$viewers" > "$workspace/home/.config/devtoolbox-cheats/viewer.conf"
    fi
    # A runtime BASH_ENV may prepend real commands ahead of our stubs.
    BASH_ENV='' \
    HOME="$workspace/home" \
    CHEATS_DIR="$workspace/home/cheats.d" \
    CHEATS_CACHE="$workspace/home/.cache/cheats.idx" \
    CHEAT_VIEWERS='' \
    PATH="$workspace/bin:/usr/bin:/bin" \
    DEVTOOLBOX_TEST_WORKSPACE="$workspace" \
    DEVTOOLBOX_TEST_LOG="$workspace/command.log" \
    OSASCRIPT_STATUS="$osascript_status" \
        bash "$TARGET_SCRIPT" "$@" \
        > "$workspace/stdout.log" 2> "$workspace/stderr.log"
}

cheat_payload() {
    local workspace="$1"
    printf '%s' "$workspace/home/cheats.d/Test Group/cheat with spaces.md" \
        | /usr/bin/base64 | tr -d '\n'
}

test_viewer_configuration_round_trips() {
    local workspace status
    workspace="$(make_workspace)"
    prepare_workspace "$workspace"

    run_script "$workspace" "" 0 setCheatViewer "helix cat"
    status=$?

    assert_eq "viewer config: command succeeds" "0" "$status"
    assert_eq "viewer config: preserves ordered viewer list" "helix cat" \
        "$(<"$workspace/home/.config/devtoolbox-cheats/viewer.conf")"

    run_script "$workspace" "" 0 setCheatViewer ""
    assert_contains "viewer config: empty value restores built-in defaults" \
        "$(<"$workspace/home/.config/devtoolbox-cheats/viewer.conf")" "default code codium"

    rm -rf "$workspace"
}

test_detects_mapped_application_bundle_name() {
    local workspace log
    workspace="$(make_workspace)"
    prepare_workspace "$workspace"
    mkdir -p "$workspace/home/Applications/Visual Studio Code.app"

    run_script "$workspace" "" 0 settingsViewer
    log="$(<"$workspace/command.log")"

    assert_contains "viewer detection: recognizes VS Code's actual bundle name" \
        "$log" "<✅ VS Code (code)>"
    assert_not_contains "viewer detection: does not mark mapped VS Code bundle missing" \
        "$log" "<❌ VS Code (code) — not installed>"

    rm -rf "$workspace"
}

test_helix_viewer_opens_terminal_with_escaped_path() {
    local workspace payload log clipboard
    workspace="$(make_workspace)"
    prepare_workspace "$workspace"
    payload="$(cheat_payload "$workspace")"

    run_script "$workspace" "helix" 0 showCheat "$payload"
    log="$(<"$workspace/command.log")"
    clipboard="$(<"$workspace/clipboard.log")"

    assert_contains "helix viewer: launches the configured terminal command" \
        "$log" "<helix $workspace/home/cheats.d/Test\\ Group/cheat\\ with\\ spaces.md>"
    assert_contains "helix viewer: uses metadata-derived terminal title" \
        "$log" "<🧪 Viewer Test>"
    assert_contains "show cheat: copies Markdown body" "$clipboard" "# Commands"
    assert_not_contains "show cheat: strips metadata before copying" "$clipboard" "Title: Viewer Test"

    rm -rf "$workspace"
}

test_terminal_failure_continues_to_next_viewer() {
    local workspace payload log
    workspace="$(make_workspace)"
    prepare_workspace "$workspace"
    payload="$(cheat_payload "$workspace")"

    run_script "$workspace" "helix default" 23 showCheat "$payload"
    log="$(<"$workspace/command.log")"

    assert_contains "terminal failure: attempted terminal viewer first" "$log" "<helix "
    assert_contains "terminal failure: propagates failure and tries next viewer" \
        "$log" "open <$workspace/home/cheats.d/Test Group/cheat with spaces.md>"

    rm -rf "$workspace"
}

test_unknown_viewer_uses_terminal_fallback_without_generic_open() {
    local workspace payload log
    workspace="$(make_workspace)"
    prepare_workspace "$workspace"
    payload="$(cheat_payload "$workspace")"

    run_script "$workspace" "viewer-that-does-not-exist" 0 showCheat "$payload"
    log="$(<"$workspace/command.log")"

    assert_not_contains "unknown viewer: does not silently use system default opener" \
        "$log" "open <"

    rm -rf "$workspace"
}

test_cache_rebuild_indexes_metadata_with_private_permissions() {
    local workspace status cache
    workspace="$(make_workspace)"
    prepare_workspace "$workspace"
    cache="$workspace/home/.cache/cheats.idx"

    CHEATS_REBUILD=1 run_script "$workspace" "default" 0
    status=$?

    assert_eq "cache rebuild: menu rendering succeeds" "0" "$status"
    assert_contains "cache rebuild: indexes cheatsheet metadata" "$(<"$cache")" \
        $'Viewer Test\tTest Group\t🧪\t7'
    assert_eq "cache rebuild: restricts cache permissions" "600" "$(file_mode "$cache")"

    rm -rf "$workspace"
}

test_successful_empty_rebuild_clears_stale_cache() {
    local workspace cache
    workspace="$(make_workspace)"
    prepare_workspace "$workspace"
    rm -f "$workspace/home/cheats.d/Test Group/cheat with spaces.md"
    cache="$workspace/home/.cache/cheats.idx"
    mkdir -p "$(dirname "$cache")"
    printf 'stale cache entry\n' > "$cache"

    CHEATS_REBUILD=1 run_script "$workspace" "default" 0

    assert_eq "empty rebuild: replaces stale cache after successful indexing" \
        "0" "$(wc -c < "$cache" | tr -d ' ')"

    rm -rf "$workspace"
}

echo "=== macOS menu and viewer tests ==="
test_viewer_configuration_round_trips
test_detects_mapped_application_bundle_name
test_helix_viewer_opens_terminal_with_escaped_path
test_terminal_failure_continues_to_next_viewer
test_unknown_viewer_uses_terminal_fallback_without_generic_open
test_cache_rebuild_indexes_metadata_with_private_permissions
test_successful_empty_rebuild_clears_stale_cache
echo "Results: $passed passed, $failed failed"

exit "$failed"
