#!/usr/bin/env bash
# tests/test_indexer.sh
#
# Tests plasma6/indexer.sh: check_cache_valid, cache creation, fallback
#
# Run:  bash tests/test_indexer.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
INDEXER="$REPO_ROOT/kde-widget-plasma6/DevToolboxPlasmoid/contents/code/indexer.sh"

# Source shared test helpers
# shellcheck source=tests/test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

echo "=== indexer.sh tests ==="
echo ""

# --- Basic execution ---

echo "Basic execution:"

test_indexer_requires_cheats_dir() {
    local out
    out="$(bash "$INDEXER" 2>&1)" || true
    assert_contains "indexer: fails without cheatsDir" "$out" "ERROR"
}
test_indexer_requires_cheats_dir

test_indexer_fails_on_missing_dir() {
    local ws
    ws="$(make_workspace)"
    bash "$INDEXER" "$ws/nonexistent" "$ws/debug.log" "$ws/cache.txt" 2>&1 || true
    # "Directory not found" is written to debug log, not stderr
    assert_contains "indexer: fails on missing dir" "$(cat "$ws/debug.log")" "Directory not found"
}
test_indexer_fails_on_missing_dir

test_indexer_indexes_cheats() {
    local ws out
    ws="$(make_workspace)"
    make_test_cheat "$ws/cheats" "GitBasics" "DevTools" "10"
    
    out="$(bash "$INDEXER" "$ws/cheats" "$ws/debug.log" "$ws/cache.txt" 2>&1)"
    assert_contains "indexer: output contains cheat title" "$out" "GitBasics"
    assert_contains "indexer: output contains group" "$out" "DevTools"
    assert_file_exists "indexer: creates cache file" "$ws/cache.txt"
    
    rm -rf "$ws"
}
test_indexer_indexes_cheats

test_indexer_multiple_cheats() {
    local ws out
    ws="$(make_workspace)"
    make_test_cheat "$ws/cheats" "Alpha" "Group1" "10"
    make_test_cheat "$ws/cheats" "Beta" "Group1" "20"
    make_test_cheat "$ws/cheats" "Gamma" "Group2" "5"
    
    out="$(bash "$INDEXER" "$ws/cheats" "$ws/debug.log" "$ws/cache.txt" 2>&1)"
    local count
    count="$(echo "$out" | wc -l)"
    assert_eq "indexer: outputs all cheats" "3" "$count"
    
    rm -rf "$ws"
}
test_indexer_multiple_cheats

# --- Cache ---

echo ""
echo "Cache:"

test_indexer_uses_valid_cache() {
    local ws
    ws="$(make_workspace)"
    make_test_cheat "$ws/cheats" "CachedCheat" "TestGroup" "10"
    
    # Build cache first
    bash "$INDEXER" "$ws/cheats" "$ws/debug.log" "$ws/cache.txt" >/dev/null
    
    # Touch a .md file to make it older than cache
    touch -d "2020-01-01" "$ws/cheats/TestGroup/CachedCheat.md"
    
    # Run again — should use cache
    local out
    out="$(bash "$INDEXER" "$ws/cheats" "$ws/debug.log" "$ws/cache.txt" 2>&1)"
    assert_contains "indexer: uses valid cache" "$out" "CachedCheat"
    assert_contains "indexer: debug says cache valid" "$(cat "$ws/debug.log")" "Using cache"
    
    rm -rf "$ws"
}
test_indexer_uses_valid_cache

test_indexer_rebuilds_stale_cache() {
    local ws
    ws="$(make_workspace)"
    make_test_cheat "$ws/cheats" "OldCheat" "TestGroup" "10"
    
    # Build cache
    bash "$INDEXER" "$ws/cheats" "$ws/debug.log" "$ws/cache.txt" >/dev/null
    
    # Add a new cheat
    make_test_cheat "$ws/cheats" "NewCheat" "TestGroup" "20"
    
    # Run again — should rebuild (cache is stale)
    local out
    out="$(bash "$INDEXER" "$ws/cheats" "$ws/debug.log" "$ws/cache.txt" 2>&1)"
    assert_contains "indexer: rebuilds stale cache" "$out" "NewCheat"
    assert_contains "indexer: debug log has rebuild msg" "$(cat "$ws/debug.log")" "Rebuilding cache"
    
    rm -rf "$ws"
}
test_indexer_rebuilds_stale_cache

test_indexer_handles_symlinks() {
    local ws out
    ws="$(make_workspace)"
    mkdir -p "$ws/real" "$ws/linked"
    make_test_cheat "$ws/real" "LinkedCheat" "TestGroup" "10"
    ln -s "$ws/real/TestGroup/LinkedCheat.md" "$ws/linked/LinkedCheat.md"
    
    out="$(bash "$INDEXER" "$ws/linked" "$ws/debug.log" "$ws/cache.txt" 2>&1)"
    assert_contains "indexer: follows symlinks" "$out" "LinkedCheat"
    
    rm -rf "$ws"
}
test_indexer_handles_symlinks

# --- Debug log ---

echo ""
echo "Debug log:"

test_indexer_writes_debug_log() {
    local ws
    ws="$(make_workspace)"
    make_test_cheat "$ws/cheats" "DebugCheat" "TestGroup" "10"
    
    bash "$INDEXER" "$ws/cheats" "$ws/debug.log" "$ws/cache.txt" >/dev/null
    assert_file_exists "indexer: creates debug log" "$ws/debug.log"
    assert_contains "indexer: debug log has search dir" "$(cat "$ws/debug.log")" "Search Dir"
    assert_contains "indexer: debug log has cache file" "$(cat "$ws/debug.log")" "Cache File"
    assert_contains "indexer: debug log has cheat data" "$(cat "$ws/debug.log")" "DebugCheat"
    
    rm -rf "$ws"
}
test_indexer_writes_debug_log

test_indexer_disables_debug_on_bad_dir() {
    local ws out rc
    ws="$(make_workspace)"
    make_test_cheat "$ws/cheats" "TestCheat" "TestGroup" "10"
    # Use a debug log path in a non-writable location
    out="$(bash "$INDEXER" "$ws/cheats" "/proc/nonexistent/debug.log" "$ws/cache.txt" 2>&1)" || rc=$?
    rc="${rc:-0}"
    # Should still succeed (debug logging disabled) and produce output
    assert_eq "indexer: exits zero on bad debug dir" "0" "$rc"
    assert_contains "indexer: still produces output on bad debug dir" "$out" "TestCheat"
    rm -rf "$ws"
}
test_indexer_disables_debug_on_bad_dir

echo ""
echo "=== All indexer tests complete ==="
echo ""
# shellcheck disable=SC2154
exit "$failed"
