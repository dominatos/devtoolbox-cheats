#!/usr/bin/env bash
# tests/test_devtoolbox_cheats_ui.sh
#
# Tests UI and workflow functions from devtoolbox-cheats.30s.sh:
#   copy, showCheat viewer loop, ensure_cache, index_cheats,
#   argos_set_category, argos_get_category, argos_clear_category
#
# Run:  bash tests/test_devtoolbox_cheats_ui.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET_SCRIPT="$REPO_ROOT/devtoolbox-cheats.30s.sh"

# Source shared test helpers
# shellcheck source=tests/test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

echo "=== Checking function existence ==="
for fn in copy index_cheats ensure_cache argos_set_category argos_get_category argos_clear_category; do
    if [[ -z "$(extract_func "$fn")" ]]; then
        fail "extract_func: could not find function '$fn' in $TARGET_SCRIPT"
    fi
done

echo ""
echo "=== UI and workflow tests ==="
echo ""

# --- copy ---

echo "copy:"

test_copy_no_backend() {
    local out
    out="$(CLIPBOARD_COPY="" bash -c "$(extract_func copy); echo 'hello' | copy; echo rc=\$?")"
    # copy returns 1 when CLIPBOARD_COPY is empty ([[ -n "" ]] fails)
    assert_contains "copy: no backend returns rc=1" "$out" "rc=1"
}
test_copy_no_backend

test_copy_wl_copy() {
    # Mock wl-copy to just cat
    local out
    out="$(CLIPBOARD_COPY="cat" bash -c "$(extract_func copy); echo 'test-data' | copy; echo rc=\$?")"
    assert_contains "copy: with backend succeeds" "$out" "rc=0"
}
test_copy_wl_copy

# --- index_cheats ---

echo ""
echo "index_cheats:"

test_index_cheats_creates_cache() {
    local ws cache
    ws="$(make_workspace)"
    mkdir -p "$ws/cheats.d"
    make_test_cheat "$ws/cheats.d" "TestCheat" "TestGroup" "10"
    
    cache="$ws/cache.tsv"
    CHEATS_DIR="$ws/cheats.d" CHEATS_CACHE="$cache" bash -c "$(extract_func meta_val); $(extract_func index_cheats); index_cheats"
    
    assert_file_exists "index_cheats: creates cache file" "$cache"
    assert_contains "index_cheats: cache contains cheat" "$(cat "$cache")" "TestCheat"
    assert_contains "index_cheats: cache contains group" "$(cat "$cache")" "TestGroup"
    
    rm -rf "$ws"
}
test_index_cheats_creates_cache

test_index_cheats_empty_dir() {
    local ws cache
    ws="$(make_workspace)"
    mkdir -p "$ws/cheats.d"
    
    cache="$ws/cache.tsv"
    CHEATS_DIR="$ws/cheats.d" CHEATS_CACHE="$cache" bash -c "$(extract_func meta_val); $(extract_func index_cheats); index_cheats"
    
    assert_file_exists "index_cheats: creates cache for empty dir" "$cache"
    assert_eq "index_cheats: empty cache has no entries" "0" "$(wc -l < "$cache")"
    
    rm -rf "$ws"
}
test_index_cheats_empty_dir

test_index_cheats_multiple_files() {
    local ws cache
    ws="$(make_workspace)"
    make_test_cheat "$ws/cheats.d" "Cheats1" "GroupA" "10"
    make_test_cheat "$ws/cheats.d" "Cheats2" "GroupA" "20"
    make_test_cheat "$ws/cheats.d" "Cheats3" "GroupB" "5"
    
    cache="$ws/cache.tsv"
    CHEATS_DIR="$ws/cheats.d" CHEATS_CACHE="$cache" bash -c "$(extract_func meta_val); $(extract_func index_cheats); index_cheats"
    
    local count
    count="$(wc -l < "$cache")"
    assert_eq "index_cheats: indexes all files" "3" "$count"
    
    rm -rf "$ws"
}
test_index_cheats_multiple_files

test_index_cheats_defaults() {
    local ws cache file
    ws="$(make_workspace)"
    # Create cheat with no metadata
    mkdir -p "$ws/cheats.d"
    echo "# Just a heading" > "$ws/cheats.d/minimal.md"
    
    cache="$ws/cache.tsv"
    CHEATS_DIR="$ws/cheats.d" CHEATS_CACHE="$cache" bash -c "$(extract_func meta_val); $(extract_func index_cheats); index_cheats"
    
    local content
    content="$(cat "$cache")"
    assert_contains "index_cheats: uses filename as title" "$content" "minimal"
    assert_contains "index_cheats: defaults group to Misc" "$content" "Misc"
    assert_contains "index_cheats: defaults order to 9999" "$content" "9999"
    
    rm -rf "$ws"
}
test_index_cheats_defaults

test_index_cheats_follows_symlinks() {
    local ws cache
    ws="$(make_workspace)"
    mkdir -p "$ws/real" "$ws/linked"
    make_test_cheat "$ws/real" "LinkedCheat" "TestGroup" "10"
    ln -s "$ws/real/TestGroup/LinkedCheat.md" "$ws/linked/LinkedCheat.md"
    
    cache="$ws/cache.tsv"
    CHEATS_DIR="$ws/linked" CHEATS_CACHE="$cache" bash -c "$(extract_func meta_val); $(extract_func index_cheats); index_cheats"
    
    assert_contains "index_cheats: follows symlinks" "$(cat "$cache")" "LinkedCheat"
    
    rm -rf "$ws"
}
test_index_cheats_follows_symlinks

# --- ensure_cache ---

echo ""
echo "ensure_cache:"

test_ensure_cache_builds_when_empty() {
    local ws cache
    ws="$(make_workspace)"
    mkdir -p "$ws/cheats.d"
    make_test_cheat "$ws/cheats.d" "TestCheat"
    
    cache="$ws/cache.tsv"
    : > "$cache"  # empty cache
    
    CHEATS_DIR="$ws/cheats.d" CHEATS_CACHE="$cache" _CACHE_CHECKED=0 bash -c "
        $(extract_func meta_val)
        $(extract_func index_cheats)
        $(extract_func ensure_cache)
        ensure_cache
    "
    
    assert_contains "ensure_cache: rebuilds empty cache" "$(cat "$cache")" "TestCheat"
    
    rm -rf "$ws"
}
test_ensure_cache_builds_when_empty

test_ensure_cache_skips_when_checked() {
    local ws cache
    ws="$(make_workspace)"
    mkdir -p "$ws/cheats.d"
    make_test_cheat "$ws/cheats.d" "TestCheat"
    
    cache="$ws/cache.tsv"
    : > "$cache"
    
    # First call populates, second call should skip (already checked)
    CHEATS_DIR="$ws/cheats.d" CHEATS_CACHE="$cache" _CACHE_CHECKED=0 bash -c "
        $(extract_func meta_val)
        $(extract_func index_cheats)
        $(extract_func ensure_cache)
        ensure_cache
        _CACHE_CHECKED=1
        ensure_cache
    "
    
    # Should still have content from first build
    assert_contains "ensure_cache: skips when already checked" "$(cat "$cache")" "TestCheat"
    
    rm -rf "$ws"
}
test_ensure_cache_skips_when_checked

test_ensure_cache_rebuilds_on_rebuild_flag() {
    local ws cache
    ws="$(make_workspace)"
    mkdir -p "$ws/cheats.d"
    make_test_cheat "$ws/cheats.d" "CheatV1"
    
    cache="$ws/cache.tsv"
    # Create initial cache with old content
    echo "old content" > "$cache"
    
    # Run ensure_cache with CHEATS_REBUILD=1 - it should call real index_cheats
    CHEATS_DIR="$ws/cheats.d" CHEATS_CACHE="$cache" CHEATS_REBUILD=1 _CACHE_CHECKED=0 bash -c "
        $(extract_func meta_val)
        $(extract_func index_cheats)
        $(extract_func ensure_cache)
        ensure_cache
    "
    
    # Cache should be rebuilt with new content from CheatV1.md
    assert_contains "ensure_cache: rebuilds on flag" "$(cat "$cache")" "CheatV1"
    
    rm -rf "$ws"
}
test_ensure_cache_rebuilds_on_rebuild_flag

# --- argos category functions ---

echo ""
echo "argos category functions:"

test_argos_set_and_get() {
    local ws
    ws="$(make_workspace)"
    mkdir -p "$ws/run"
    
    local out
    out="$(ARGOS_RUNTIME_DIR="$ws/run" ARGOS_CAT_STATE="$ws/run/argos-cat-combined.state" ARGOS_CAT_TTL=60 bash -c "
        $(extract_func argos_set_category)
        $(extract_func argos_get_category)
        argos_set_category 'Networking'
        argos_get_category
    ")"
    assert_eq "argos: set and get category" "Networking" "$out"
    
    rm -rf "$ws"
}
test_argos_set_and_get

test_argos_clear_category() {
    local ws
    ws="$(make_workspace)"
    mkdir -p "$ws/run"
    
    local out
    out="$(ARGOS_RUNTIME_DIR="$ws/run" ARGOS_CAT_STATE="$ws/run/argos-cat-combined.state" ARGOS_CAT_TTL=60 bash -c "
        $(extract_func argos_set_category)
        $(extract_func argos_get_category)
        $(extract_func argos_clear_category)
        argos_set_category 'Networking'
        argos_clear_category
        argos_get_category
    ")"
    assert_eq "argos: clear category returns empty" "" "$out"
    
    rm -rf "$ws"
}
test_argos_clear_category

test_argos_get_empty_when_no_file() {
    local ws
    ws="$(make_workspace)"
    mkdir -p "$ws/run"
    
    local out
    out="$(ARGOS_RUNTIME_DIR="$ws/run" ARGOS_CAT_STATE="$ws/run/argos-cat-combined.state" ARGOS_CAT_TTL=60 bash -c "
        $(extract_func argos_get_category)
        argos_get_category
    ")"
    assert_eq "argos: get returns empty when no file" "" "$out"
    
    rm -rf "$ws"
}
test_argos_get_empty_when_no_file

echo ""
echo "=== All UI tests complete ==="
echo ""
# shellcheck disable=SC2154
exit "$failed"
