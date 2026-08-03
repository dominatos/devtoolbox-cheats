#!/usr/bin/env bash
# tests/test_argos_renderers.sh
#
# Tests Argos layout renderers by sourcing the script functions directly.
# Uses a mock cache file and pre-cached screen dims.
#
# Run:  bash tests/test_argos_renderers.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET_SCRIPT="$REPO_ROOT/devtoolbox-cheats.30s.sh"

# Source shared test helpers
# shellcheck source=tests/test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

# Create mock cache file
make_mock_cache() {
    local dir="$1"
    local cache="$dir/cheats.cache"
    cat > "$cache" <<'CACHEEOF'
/home/user/cheats.d/DevTools/Git.md	Git Basics	Dev & Tools	git	10
/home/user/cheats.d/DevTools/Docker.md	Docker Intro	Dev & Tools	docker	20
/home/user/cheats.d/Network/Curl.md	Curl Guide	Network	wifi	5
/home/user/cheats.d/Network/Wget.md	Wget Guide	Network	wifi	15
/home/user/cheats.d/Basics/Grep.md	Grep Tutorial	Basics	text-editor	10
CACHEEOF
    echo "$cache"
}

echo "=== Argos renderer tests ==="
echo ""

# --- _render_functions_submenu ---

echo "_render_functions_submenu:"

test_functions_submenu_standard() {
    local ws cache out
    ws="$(mktemp -d "${TMPDIR:-/tmp}/devtoolbox-argos-test-XXXXXX")"
    cache="$(make_mock_cache "$ws")"
    
    out="$(_SCREEN_DIMS_CACHED=1920x1080 DEVTOOLBOX_DE=terminal \
        CHEATS_CACHE="$cache" DEVTOOLBOX_LAYOUT_CONF="$ws/layout.conf" \
        TOC_FORMAT_CONF="$ws/toc.conf" \
        SCRIPT_PATH="/test/script.sh" \
        bash -c "
            $(extract_func get_toc_format)
            $(extract_func _render_functions_submenu)
            _render_functions_submenu standard
        " 2>/dev/null)"
    
    assert_contains "standard: has header" "$out" "DevToolbox Functions"
    assert_contains "standard: has search" "$out" "Search cheats"
    assert_contains "standard: has layout" "$out" "Layout Options"
    assert_contains "standard: has TOC" "$out" "TOC Formatting"
    
    rm -rf "$ws"
}
test_functions_submenu_standard

test_functions_submenu_zenity() {
    local ws cache out
    ws="$(mktemp -d "${TMPDIR:-/tmp}/devtoolbox-argos-test-XXXXXX")"
    cache="$(make_mock_cache "$ws")"
    
    out="$(_SCREEN_DIMS_CACHED=1920x1080 DEVTOOLBOX_DE=terminal \
        CHEATS_CACHE="$cache" DEVTOOLBOX_LAYOUT_CONF="$ws/layout.conf" \
        TOC_FORMAT_CONF="$ws/toc.conf" \
        SCRIPT_PATH="/test/script.sh" \
        bash -c "
            $(extract_func get_toc_format)
            $(extract_func _render_functions_submenu)
            _render_functions_submenu zenity
        " 2>/dev/null)"
    
    assert_contains "zenity: has zenity checked" "$out" "✅ Zenity"
    
    rm -rf "$ws"
}
test_functions_submenu_zenity

test_functions_submenu_drilldown() {
    local ws cache out
    ws="$(mktemp -d "${TMPDIR:-/tmp}/devtoolbox-argos-test-XXXXXX")"
    cache="$(make_mock_cache "$ws")"
    
    out="$(_SCREEN_DIMS_CACHED=1920x1080 DEVTOOLBOX_DE=terminal \
        CHEATS_CACHE="$cache" DEVTOOLBOX_LAYOUT_CONF="$ws/layout.conf" \
        TOC_FORMAT_CONF="$ws/toc.conf" \
        SCRIPT_PATH="/test/script.sh" \
        bash -c "
            $(extract_func get_toc_format)
            $(extract_func _render_functions_submenu)
            _render_functions_submenu drilldown
        " 2>/dev/null)"
    
    assert_contains "drilldown: has drilldown checked" "$out" "✅ Drill-down"
    
    rm -rf "$ws"
}
test_functions_submenu_drilldown

# --- render_argos_zenity (simpler than standard/drilldown) ---

echo ""
echo "render_argos_zenity:"

test_zenity_renders_categories() {
    local ws cache out
    ws="$(mktemp -d "${TMPDIR:-/tmp}/devtoolbox-argos-test-XXXXXX")"
    cache="$(make_mock_cache "$ws")"
    
    out="$(_SCREEN_DIMS_CACHED=1920x1080 DEVTOOLBOX_DE=terminal \
        CHEATS_CACHE="$cache" DEVTOOLBOX_LAYOUT_CONF="$ws/layout.conf" \
        TOC_FORMAT_CONF="$ws/toc.conf" \
        ARGOS_RUNTIME_DIR="$ws/run" ARGOS_CAT_TTL=60 \
        SCRIPT_PATH="/test/script.sh" \
        bash -c "
            mkdir -p '$ws/run'
            $(extract_func detect_de)
            $(extract_func is_small_screen)
            $(extract_func get_screen_dims)
            $(extract_func get_layout)
            $(extract_func get_toc_format)
            $(extract_func setTocFormat)
            $(extract_func strip_leading_icon_if_same)
            $(extract_func compose_label)
            $(extract_func b64enc)
            $(extract_func _render_functions_submenu)
            $(extract_func _render_small_screen_header)
            $(extract_func render_argos_zenity)
            declare -A GROUP_ICON=([\"Dev & Tools\"]=\"d\" [\"Network\"]=\"n\" [\"Basics\"]=\"b\")
            render_argos_zenity zenity
        " 2>/dev/null)"
    
    assert_contains "zenity: has title" "$out" "Cheatsheets"
    assert_contains "zenity: has Dev & Tools" "$out" "Dev & Tools"
    assert_contains "zenity: has browseDeep" "$out" "browseDeep_Cheats"
    
    rm -rf "$ws"
}
test_zenity_renders_categories

echo ""
echo "=== All Argos renderer tests complete ==="
echo ""
# shellcheck disable=SC2154
exit "$failed"
