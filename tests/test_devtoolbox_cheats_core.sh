#!/usr/bin/env bash
# tests/test_devtoolbox_cheats_core.sh
#
# Tests core functions from devtoolbox-cheats.30s.sh:
#   detect_de, meta_val, strip_front_matter, compose_label,
#   strip_leading_icon_if_same, b64enc, b64dec, get_layout, setLayout,
#   argos_set_category, argos_get_category, argos_clear_category
#
# Run directly:  bash tests/test_devtoolbox_cheats_core.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET_SCRIPT="$REPO_ROOT/devtoolbox-cheats.30s.sh"

failed=0
pass() { echo "OK:   $1"; }
fail() { echo "FAIL: $1"; failed=1; }

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass "$desc"
    else
        fail "$desc (expected: [$expected], actual: [$actual])"
    fi
}

assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        pass "$desc"
    else
        fail "$desc (expected to contain [$needle], got: [$haystack])"
    fi
}

extract_func() {
    local name="$1"
    awk -v name="$name" '
        $0 ~ "^" name "\\(\\) \\{" { flag=1 }
        flag { print }
        flag && /^}/ { exit }
    ' "$TARGET_SCRIPT"
}

make_workspace() {
    local ws
    ws="$(mktemp -d "${TMPDIR:-/tmp}/devtoolbox-core-test-XXXXXX")" || {
        echo "Error: failed to create workspace" >&2
        exit 1
    }
    echo "$ws"
}

# Sanity check
for fn in detect_de meta_val strip_front_matter compose_label strip_leading_icon_if_same get_layout setLayout argos_set_category argos_get_category argos_clear_category; do
    if [[ -z "$(extract_func "$fn")" ]]; then
        fail "extract_func: could not find function '$fn' in $TARGET_SCRIPT"
    fi
done

# Also extract b64enc/b64dec (they depend on _B64ENC_FLAG which is set at top level)
B64ENC_FUNC="$(extract_func b64enc)"
B64DEC_FUNC="$(extract_func b64dec)"

# ---------------------------------------------------------------------------
# detect_de
# ---------------------------------------------------------------------------

test_detect_de_override_returns_configured_value() {
    local out
    out="$(DEVTOOLBOX_DE=kde bash -c "$(extract_func detect_de); detect_de")"
    assert_eq "detect_de: DEVTOOLBOX_DE=kde returns kde" "kde" "$out"
}

test_detect_de_override_gnome() {
    local out
    out="$(DEVTOOLBOX_DE=gnome bash -c "$(extract_func detect_de); detect_de")"
    assert_eq "detect_de: DEVTOOLBOX_DE=gnome returns gnome" "gnome" "$out"
}

test_detect_de_override_terminal() {
    local out
    out="$(DEVTOOLBOX_DE=terminal bash -c "$(extract_func detect_de); detect_de")"
    assert_eq "detect_de: DEVTOOLBOX_DE=terminal returns terminal" "terminal" "$out"
}

test_detect_de_xdg_gnome() {
    local ws out
    ws="$(make_workspace)"
    out="$(
        DEVTOOLBOX_DE=auto \
        XDG_CURRENT_DESKTOP=GNOME \
        DE_CACHE_FILE="$ws/de.cache" \
        bash -c "$(extract_func detect_de); detect_de"
    )"
    assert_eq "detect_de: XDG_CURRENT_DESKTOP=GNOME returns gnome" "gnome" "$out"
    rm -rf "$ws"
}

test_detect_de_xdg_kde() {
    local ws out
    ws="$(make_workspace)"
    out="$(
        DEVTOOLBOX_DE=auto \
        XDG_CURRENT_DESKTOP=KDE \
        DE_CACHE_FILE="$ws/de.cache" \
        bash -c "$(extract_func detect_de); detect_de"
    )"
    assert_eq "detect_de: XDG_CURRENT_DESKTOP=KDE returns kde" "kde" "$out"
    rm -rf "$ws"
}

test_detect_de_xdg_xfce() {
    local ws out
    ws="$(make_workspace)"
    out="$(
        DEVTOOLBOX_DE=auto \
        XDG_CURRENT_DESKTOP=XFCE \
        DE_CACHE_FILE="$ws/de.cache" \
        bash -c "$(extract_func detect_de); detect_de"
    )"
    assert_eq "detect_de: XDG_CURRENT_DESKTOP=XFCE returns xfce" "xfce" "$out"
    rm -rf "$ws"
}

test_detect_de_xdg_cinnamon() {
    local ws out
    ws="$(make_workspace)"
    out="$(
        DEVTOOLBOX_DE=auto \
        XDG_CURRENT_DESKTOP=X-Cinnamon \
        DE_CACHE_FILE="$ws/de.cache" \
        bash -c "$(extract_func detect_de); detect_de"
    )"
    assert_eq "detect_de: XDG_CURRENT_DESKTOP=X-Cinnamon returns cinnamon" "cinnamon" "$out"
    rm -rf "$ws"
}

test_detect_de_xdg_mate() {
    local ws out
    ws="$(make_workspace)"
    out="$(
        DEVTOOLBOX_DE=auto \
        XDG_CURRENT_DESKTOP=MATE \
        DE_CACHE_FILE="$ws/de.cache" \
        bash -c "$(extract_func detect_de); detect_de"
    )"
    assert_eq "detect_de: XDG_CURRENT_DESKTOP=MATE returns mate" "mate" "$out"
    rm -rf "$ws"
}

test_detect_de_xdg_lxqt() {
    local ws out
    ws="$(make_workspace)"
    out="$(
        DEVTOOLBOX_DE=auto \
        XDG_CURRENT_DESKTOP=LXQt \
        DE_CACHE_FILE="$ws/de.cache" \
        bash -c "$(extract_func detect_de); detect_de"
    )"
    assert_eq "detect_de: XDG_CURRENT_DESKTOP=LXQt returns lxqt" "lxqt" "$out"
    rm -rf "$ws"
}

test_detect_de_no_xdg_returns_terminal() {
    local ws out
    ws="$(make_workspace)"
    # Stub pgrep to always fail (no DE processes running)
    mkdir -p "$ws/bin"
    cat > "$ws/bin/pgrep" <<'STUBEOF'
#!/usr/bin/env bash
exit 1
STUBEOF
    chmod +x "$ws/bin/pgrep"
    out="$(
        DEVTOOLBOX_DE=auto \
        XDG_CURRENT_DESKTOP="" \
        DE_CACHE_FILE="$ws/de.cache" \
        PATH="$ws/bin:/usr/bin:/bin" \
        bash -c "$(extract_func detect_de); detect_de"
    )"
    assert_eq "detect_de: no XDG, no pgrep returns terminal" "terminal" "$out"
    rm -rf "$ws"
}

test_detect_de_caches_result() {
    local ws out1 out2
    ws="$(make_workspace)"
    out1="$(
        DEVTOOLBOX_DE=auto \
        XDG_CURRENT_DESKTOP=GNOME \
        DE_CACHE_FILE="$ws/de.cache" \
        bash -c "$(extract_func detect_de); detect_de"
    )"
    out2="$(cat "$ws/de.cache")"
    assert_eq "detect_de: caches result to DE_CACHE_FILE" "gnome" "$out2"
    rm -rf "$ws"
}

test_detect_de_uses_cache_on_subsequent_calls() {
    local ws out
    ws="$(make_workspace)"
    printf 'kde\n' > "$ws/de.cache"
    out="$(
        DEVTOOLBOX_DE=auto \
        XDG_CURRENT_DESKTOP=GNOME \
        DE_CACHE_FILE="$ws/de.cache" \
        bash -c "$(extract_func detect_de); detect_de"
    )"
    assert_eq "detect_de: uses cached value (kde) even though XDG says GNOME" "kde" "$out"
    rm -rf "$ws"
}

test_detect_de_partial_xdg_match() {
    local ws out
    ws="$(make_workspace)"
    out="$(
        DEVTOOLBOX_DE=auto \
        XDG_CURRENT_DESKTOP="ubuntu:GNOME" \
        DE_CACHE_FILE="$ws/de.cache" \
        bash -c "$(extract_func detect_de); detect_de"
    )"
    assert_eq "detect_de: partial XDG match *GNOME* returns gnome" "gnome" "$out"
    rm -rf "$ws"
}

test_detect_de_unity_match() {
    local ws out
    ws="$(make_workspace)"
    out="$(
        DEVTOOLBOX_DE=auto \
        XDG_CURRENT_DESKTOP="Unity" \
        DE_CACHE_FILE="$ws/de.cache" \
        bash -c "$(extract_func detect_de); detect_de"
    )"
    assert_eq "detect_de: XDG_CURRENT_DESKTOP=Unity returns gnome" "gnome" "$out"
    rm -rf "$ws"
}

test_detect_de_pantheon_match() {
    local ws out
    ws="$(make_workspace)"
    out="$(
        DEVTOOLBOX_DE=auto \
        XDG_CURRENT_DESKTOP="Pantheon" \
        DE_CACHE_FILE="$ws/de.cache" \
        bash -c "$(extract_func detect_de); detect_de"
    )"
    assert_eq "detect_de: XDG_CURRENT_DESKTOP=Pantheon returns gnome" "gnome" "$out"
    rm -rf "$ws"
}

test_detect_de_lxde_match() {
    local ws out
    ws="$(make_workspace)"
    out="$(
        DEVTOOLBOX_DE=auto \
        XDG_CURRENT_DESKTOP="LXDE" \
        DE_CACHE_FILE="$ws/de.cache" \
        bash -c "$(extract_func detect_de); detect_de"
    )"
    assert_eq "detect_de: XDG_CURRENT_DESKTOP=LXDE returns lxde" "lxde" "$out"
    rm -rf "$ws"
}

test_detect_de_kde_plasma_match() {
    local ws out
    ws="$(make_workspace)"
    out="$(
        DEVTOOLBOX_DE=auto \
        XDG_CURRENT_DESKTOP="KDE" \
        DE_CACHE_FILE="$ws/de.cache" \
        bash -c "$(extract_func detect_de); detect_de"
    )"
    assert_eq "detect_de: XDG_CURRENT_DESKTOP=KDE returns kde" "kde" "$out"
    rm -rf "$ws"
}

# ---------------------------------------------------------------------------
# meta_val
# ---------------------------------------------------------------------------

test_meta_val_extracts_title() {
    local ws out
    ws="$(make_workspace)"
    printf 'Title: MySQL Queries\nGroup: Databases\n\n# Content\n' > "$ws/test.md"
    out="$(bash -c "$(extract_func meta_val); meta_val "$ws/test.md" Title")"
    assert_eq "meta_val: extracts Title" "MySQL Queries" "$out"
    rm -rf "$ws"
}

test_meta_val_extracts_group() {
    local ws out
    ws="$(make_workspace)"
    printf 'Title: MySQL Queries\nGroup: Databases\n\n# Content\n' > "$ws/test.md"
    out="$(bash -c "$(extract_func meta_val); meta_val "$ws/test.md" Group")"
    assert_eq "meta_val: extracts Group" "Databases" "$out"
    rm -rf "$ws"
}

test_meta_val_extracts_icon() {
    local ws out
    ws="$(make_workspace)"
    printf 'Title: MySQL\nIcon: 🐬\n\n# Content\n' > "$ws/test.md"
    out="$(bash -c "$(extract_func meta_val); meta_val "$ws/test.md" Icon")"
    assert_eq "meta_val: extracts Icon" "🐬" "$out"
    rm -rf "$ws"
}

test_meta_val_extracts_order() {
    local ws out
    ws="$(make_workspace)"
    printf 'Title: MySQL\nOrder: 5\n\n# Content\n' > "$ws/test.md"
    out="$(bash -c "$(extract_func meta_val); meta_val "$ws/test.md" Order")"
    assert_eq "meta_val: extracts Order" "5" "$out"
    rm -rf "$ws"
}

test_meta_val_returns_empty_for_missing_key() {
    local ws out
    ws="$(make_workspace)"
    printf 'Title: MySQL\n\n# Content\n' > "$ws/test.md"
    out="$(bash -c "$(extract_func meta_val); meta_val "$ws/test.md" Group")"
    assert_eq "meta_val: returns empty for missing key" "" "$out"
    rm -rf "$ws"
}

test_meta_val_case_insensitive() {
    local ws out
    ws="$(make_workspace)"
    printf 'title: MySQL\n\n# Content\n' > "$ws/test.md"
    out="$(bash -c "$(extract_func meta_val); meta_val "$ws/test.md" Title")"
    assert_eq "meta_val: case-insensitive key match" "MySQL" "$out"
    rm -rf "$ws"
}

test_meta_val_strips_surrounding_double_quotes() {
    local ws out
    ws="$(make_workspace)"
    printf 'Title: "MySQL Queries"\n\n# Content\n' > "$ws/test.md"
    out="$(bash -c "$(extract_func meta_val); meta_val "$ws/test.md" Title")"
    assert_eq "meta_val: strips surrounding double quotes" "MySQL Queries" "$out"
    rm -rf "$ws"
}

test_meta_val_strips_surrounding_single_quotes() {
    local ws out
    ws="$(make_workspace)"
    printf "Title: 'MySQL Queries'\n\n# Content\n" > "$ws/test.md"
    out="$(bash -c "$(extract_func meta_val); meta_val "$ws/test.md" Title")"
    assert_eq "meta_val: strips surrounding single quotes" "MySQL Queries" "$out"
    rm -rf "$ws"
}

test_meta_val_handles_bom() {
    local ws out
    ws="$(make_workspace)"
    printf '\xEF\xBB\xBFTitle: BOM File\n\n# Content\n' > "$ws/test.md"
    out="$(bash -c "$(extract_func meta_val); meta_val "$ws/test.md" Title")"
    assert_eq "meta_val: handles BOM" "BOM File" "$out"
    rm -rf "$ws"
}

test_meta_val_handles_crlf() {
    local ws out
    ws="$(make_workspace)"
    printf 'Title: CRLF File\r\nGroup: Test\r\n\r\n# Content\r\n' > "$ws/test.md"
    out="$(bash -c "$(extract_func meta_val); meta_val "$ws/test.md" Title")"
    assert_eq "meta_val: handles CRLF line endings" "CRLF File" "$out"
    rm -rf "$ws"
}

test_meta_val_only_reads_first_80_lines() {
    local ws out
    ws="$(make_workspace)"
    {
        printf '# Header\n\n'
        printf 'Group: EarlyGroup\n'
        # Fill lines 4-80 with noise
        for i in $(seq 1 77); do echo "noise line $i"; done
        # Put a late Group on line 81 — should NOT be picked up
        printf 'Group: LateGroup\n'
    } > "$ws/test.md"
    out="$(bash -c "$(extract_func meta_val); meta_val "$ws/test.md" Group")"
    assert_eq "meta_val: only reads first 80 lines" "EarlyGroup" "$out"
    rm -rf "$ws"
}

test_meta_val_handles_whitespace_around_key() {
    local ws out
    ws="$(make_workspace)"
    printf '  Title:  Spaced Title\n\n# Content\n' > "$ws/test.md"
    out="$(bash -c "$(extract_func meta_val); meta_val "$ws/test.md" Title")"
    assert_eq "meta_val: handles whitespace around key" "Spaced Title" "$out"
    rm -rf "$ws"
}

# ---------------------------------------------------------------------------
# strip_front_matter
# ---------------------------------------------------------------------------

test_strip_front_matter_removes_title_group_icon_order() {
    local ws out
    ws="$(make_workspace)"
    printf 'Title: MySQL\nGroup: Databases\nIcon: 🐬\nOrder: 5\n\n# MySQL Commands\nContent here\n' > "$ws/test.md"
    out="$(bash -c "$(extract_func strip_front_matter); strip_front_matter" < "$ws/test.md")"
    assert_contains "strip_front_matter: removes Title" "$out" "# MySQL Commands"
    assert_contains "strip_front_matter: removes Group" "$out" "Content here"
    # Verify front-matter keys are NOT in output
    if [[ "$out" == *"Title:"* ]]; then
        fail "strip_front_matter: Title line should be removed"
    else
        pass "strip_front_matter: Title line removed"
    fi
    if [[ "$out" == *"Group:"* ]]; then
        fail "strip_front_matter: Group line should be removed"
    else
        pass "strip_front_matter: Group line removed"
    fi
    rm -rf "$ws"
}

test_strip_front_matter_preserves_content_after_80_lines() {
    local ws out
    ws="$(make_workspace)"
    {
        printf 'Title: Test\nGroup: Test\n\n'
        for i in $(seq 1 77); do echo "line $i"; done
        printf 'Title: LateTitle\nGroup: LateGroup\n'
    } > "$ws/test.md"
    out="$(bash -c "$(extract_func strip_front_matter); strip_front_matter" < "$ws/test.md")"
    assert_contains "strip_front_matter: preserves content after line 80" "$out" "Title: LateTitle"
    rm -rf "$ws"
}

test_strip_front_matter_case_insensitive() {
    local ws out
    ws="$(make_workspace)"
    printf 'title: Test\ngroup: Test\n\n# Content\n' > "$ws/test.md"
    out="$(bash -c "$(extract_func strip_front_matter); strip_front_matter" < "$ws/test.md")"
    if [[ "$out" == *"title:"* ]] || [[ "$out" == *"group:"* ]]; then
        fail "strip_front_matter: case-insensitive removal"
    else
        pass "strip_front_matter: case-insensitive removal"
    fi
    rm -rf "$ws"
}

test_strip_front_matter_handles_crlf() {
    local ws out
    ws="$(make_workspace)"
    printf 'Title: Test\r\nGroup: Test\r\n\r\n# Content\r\n' > "$ws/test.md"
    out="$(bash -c "$(extract_func strip_front_matter); strip_front_matter" < "$ws/test.md")"
    assert_contains "strip_front_matter: handles CRLF" "$out" "# Content"
    if [[ "$out" == *"Title:"* ]]; then
        fail "strip_front_matter: CRLF Title removed"
    else
        pass "strip_front_matter: CRLF Title removed"
    fi
    rm -rf "$ws"
}

test_strip_front_matter_no_front_matter_passthrough() {
    local ws out
    ws="$(make_workspace)"
    printf '# Just A Header\n\nSome content\n' > "$ws/test.md"
    out="$(bash -c "$(extract_func strip_front_matter); strip_front_matter" < "$ws/test.md")"
    assert_eq "strip_front_matter: passes through when no front-matter" "# Just A Header

Some content" "$out"
    rm -rf "$ws"
}

# ---------------------------------------------------------------------------
# compose_label / strip_leading_icon_if_same
# ---------------------------------------------------------------------------

test_compose_label_with_icon() {
    local out
    out="$(bash -c "$(extract_func strip_leading_icon_if_same); $(extract_func compose_label); compose_label 'MySQL Queries' 'Tool'" )"
    assert_eq "compose_label: with icon prepends icon" "Tool MySQL Queries" "$out"
}

test_compose_label_without_icon() {
    local out
    out="$(bash -c "$(extract_func strip_leading_icon_if_same); $(extract_func compose_label); compose_label 'MySQL Queries' ''")"
    assert_eq "compose_label: without icon returns title" "MySQL Queries" "$out"
}

test_compose_label_deduplicates_icon() {
    local out
    out="$(bash -c "$(extract_func strip_leading_icon_if_same); $(extract_func compose_label); compose_label 'Tool MySQL Queries' 'Tool'" )"
    assert_eq "compose_label: deduplicates leading icon" "Tool MySQL Queries" "$out"
}

test_strip_leading_icon_removes_if_same() {
    local out
    out="$(bash -c "$(extract_func strip_leading_icon_if_same); strip_leading_icon_if_same 'Tool MySQL' 'Tool'" )"
    assert_eq "strip_leading_icon_if_same: removes leading icon" "MySQL" "$out"
}

test_strip_leading_icon_keeps_if_different() {
    local out
    out="$(bash -c "$(extract_func strip_leading_icon_if_same); strip_leading_icon_if_same 'Chart MySQL' 'Tool'" )"
    assert_eq "strip_leading_icon_if_same: keeps title when icon differs" "Chart MySQL" "$out"
}

test_strip_leading_icon_empty_icon_passthrough() {
    local out
    out="$(bash -c "$(extract_func strip_leading_icon_if_same); strip_leading_icon_if_same 'MySQL' '"'"''"'"'" )"
    assert_eq "strip_leading_icon_if_same: empty icon passes through" "MySQL" "$out"
}

# ---------------------------------------------------------------------------
# get_layout / setLayout
# ---------------------------------------------------------------------------

test_get_layout_defaults_to_standard() {
    local ws out
    ws="$(make_workspace)"
    out="$(
        DEVTOOLBOX_LAYOUT_CONF="$ws/layout.conf" \
        ARGOS_CAT_STATE="$ws/state" \
        bash -c "$(extract_func get_layout); get_layout"
    )"
    assert_eq "get_layout: defaults to standard" "standard" "$out"
    rm -rf "$ws"
}

test_get_layout_env_override() {
    local ws out
    ws="$(make_workspace)"
    out="$(
        DEVTOOLBOX_LAYOUT_CONF="$ws/layout.conf" \
        DEVTOOLBOX_LAYOUT=drilldown \
        ARGOS_CAT_STATE="$ws/state" \
        bash -c "$(extract_func get_layout); get_layout"
    )"
    assert_eq "get_layout: env override returns drilldown" "drilldown" "$out"
    rm -rf "$ws"
}

test_get_layout_reads_persisted_config() {
    local ws out
    ws="$(make_workspace)"
    printf 'zenity\n' > "$ws/layout.conf"
    out="$(
        DEVTOOLBOX_LAYOUT_CONF="$ws/layout.conf" \
        ARGOS_CAT_STATE="$ws/state" \
        bash -c "$(extract_func get_layout); get_layout"
    )"
    assert_eq "get_layout: reads persisted config" "zenity" "$out"
    rm -rf "$ws"
}

test_get_layout_invalid_config_falls_to_default() {
    local ws out
    ws="$(make_workspace)"
    printf 'bogus\n' > "$ws/layout.conf"
    out="$(
        DEVTOOLBOX_LAYOUT_CONF="$ws/layout.conf" \
        ARGOS_CAT_STATE="$ws/state" \
        bash -c "$(extract_func get_layout); get_layout"
    )"
    assert_eq "get_layout: invalid config falls to default" "standard" "$out"
    rm -rf "$ws"
}

test_setLayout_persists_valid_value() {
    local ws
    ws="$(make_workspace)"
    DEVTOOLBOX_LAYOUT_CONF="$ws/layout.conf" \
        ARGOS_CAT_STATE="$ws/state" \
        bash -c "$(extract_func setLayout); setLayout drilldown"
    assert_eq "setLayout: persists valid value" "drilldown" "$(cat "$ws/layout.conf")"
    rm -rf "$ws"
}

test_setLayout_invalid_falls_to_standard() {
    local ws
    ws="$(make_workspace)"
    DEVTOOLBOX_LAYOUT_CONF="$ws/layout.conf" \
        ARGOS_CAT_STATE="$ws/state" \
        bash -c "$(extract_func setLayout); setLayout bogus"
    assert_eq "setLayout: invalid falls to standard" "standard" "$(cat "$ws/layout.conf")"
    rm -rf "$ws"
}

test_setLayout_clears_argos_state() {
    local ws
    ws="$(make_workspace)"
    printf 'oldcategory' > "$ws/state"
    DEVTOOLBOX_LAYOUT_CONF="$ws/layout.conf" \
        ARGOS_CAT_STATE="$ws/state" \
        bash -c "$(extract_func setLayout); setLayout standard"
    if [[ -f "$ws/state" ]]; then
        fail "setLayout: should clear argos state"
    else
        pass "setLayout: clears argos state"
    fi
    rm -rf "$ws"
}

# ---------------------------------------------------------------------------
# argos_set_category / argos_get_category / argos_clear_category
# ---------------------------------------------------------------------------

test_argos_set_and_get_category() {
    local ws out
    ws="$(make_workspace)"
    mkdir -p "$ws/runtime"
    out="$(
        ARGOS_RUNTIME_DIR="$ws/runtime" \
        ARGOS_CAT_STATE="$ws/runtime/state" \
        ARGOS_CAT_TTL=60 \
        bash -c "
            $(extract_func argos_set_category)
            $(extract_func argos_get_category)
            argos_set_category 'Databases'
            argos_get_category
        "
    )"
    assert_eq "argos: set then get returns category" "Databases" "$out"
    rm -rf "$ws"
}

test_argos_clear_category() {
    local ws out
    ws="$(make_workspace)"
    mkdir -p "$ws/runtime"
    out="$(
        ARGOS_RUNTIME_DIR="$ws/runtime" \
        ARGOS_CAT_STATE="$ws/runtime/state" \
        ARGOS_CAT_TTL=60 \
        bash -c "
            $(extract_func argos_set_category)
            $(extract_func argos_clear_category)
            $(extract_func argos_get_category)
            argos_set_category 'Databases'
            argos_clear_category
            argos_get_category
        "
    )"
    assert_eq "argos: clear returns empty" "" "$out"
    rm -rf "$ws"
}

test_argos_get_category_empty_when_no_state_file() {
    local ws out
    ws="$(make_workspace)"
    mkdir -p "$ws/runtime"
    out="$(
        ARGOS_RUNTIME_DIR="$ws/runtime" \
        ARGOS_CAT_STATE="$ws/runtime/nonexistent" \
        ARGOS_CAT_TTL=60 \
        bash -c "$(extract_func argos_get_category); argos_get_category"
    )"
    assert_eq "argos: get returns empty when no state file" "" "$out"
    rm -rf "$ws"
}

test_argos_get_category_expired_returns_empty() {
    local ws out
    ws="$(make_workspace)"
    mkdir -p "$ws/runtime"
    printf 'Databases' > "$ws/runtime/state"
    # Set mtime to 2 hours ago to exceed TTL
    touch -d "2 hours ago" "$ws/runtime/state"
    out="$(
        ARGOS_RUNTIME_DIR="$ws/runtime" \
        ARGOS_CAT_STATE="$ws/runtime/state" \
        ARGOS_CAT_TTL=60 \
        bash -c "$(extract_func argos_get_category); argos_get_category"
    )"
    assert_eq "argos: get returns empty when TTL expired" "" "$out"
    rm -rf "$ws"
}

# ---------------------------------------------------------------------------
# b64enc / b64dec
# ---------------------------------------------------------------------------

test_b64enc_encodes_string() {
    local out
    out="$(echo -n "hello" | bash -c "$B64ENC_FUNC; b64enc")"
    assert_eq "b64enc: encodes hello" "aGVsbG8=" "$out"
}

test_b64dec_decodes_string() {
    local out
    out="$(echo -n "aGVsbG8=" | bash -c "$B64DEC_FUNC; b64dec")"
    assert_eq "b64dec: decodes aGVsbG8=" "hello" "$out"
}

test_b64_roundtrip() {
    local original encoded decoded
    original="MySQL Queries 🐬 with spaces & special chars!"
    encoded="$(echo -n "$original" | bash -c "$B64ENC_FUNC; b64enc")"
    decoded="$(echo -n "$encoded" | bash -c "$B64DEC_FUNC; b64dec")"
    assert_eq "b64 roundtrip: preserves original string" "$original" "$decoded"
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------

# detect_de
test_detect_de_override_returns_configured_value
test_detect_de_override_gnome
test_detect_de_override_terminal
test_detect_de_xdg_gnome
test_detect_de_xdg_kde
test_detect_de_xdg_xfce
test_detect_de_xdg_cinnamon
test_detect_de_xdg_mate
test_detect_de_xdg_lxqt
test_detect_de_no_xdg_returns_terminal
test_detect_de_caches_result
test_detect_de_uses_cache_on_subsequent_calls
test_detect_de_partial_xdg_match
test_detect_de_unity_match
test_detect_de_pantheon_match
test_detect_de_lxde_match
test_detect_de_kde_plasma_match

# meta_val
test_meta_val_extracts_title
test_meta_val_extracts_group
test_meta_val_extracts_icon
test_meta_val_extracts_order
test_meta_val_returns_empty_for_missing_key
test_meta_val_case_insensitive
test_meta_val_strips_surrounding_double_quotes
test_meta_val_strips_surrounding_single_quotes
test_meta_val_handles_bom
test_meta_val_handles_crlf
test_meta_val_only_reads_first_80_lines
test_meta_val_handles_whitespace_around_key

# strip_front_matter
test_strip_front_matter_removes_title_group_icon_order
test_strip_front_matter_preserves_content_after_80_lines
test_strip_front_matter_case_insensitive
test_strip_front_matter_handles_crlf
test_strip_front_matter_no_front_matter_passthrough

# compose_label / strip_leading_icon_if_same
test_compose_label_with_icon
test_compose_label_without_icon
test_compose_label_deduplicates_icon
test_strip_leading_icon_removes_if_same
test_strip_leading_icon_keeps_if_different
test_strip_leading_icon_empty_icon_passthrough

# get_layout / setLayout
test_get_layout_defaults_to_standard
test_get_layout_env_override
test_get_layout_reads_persisted_config
test_get_layout_invalid_config_falls_to_default
test_setLayout_persists_valid_value
test_setLayout_invalid_falls_to_standard
test_setLayout_clears_argos_state

# argos state helpers
test_argos_set_and_get_category
test_argos_clear_category
test_argos_get_category_empty_when_no_state_file
test_argos_get_category_expired_returns_empty

# b64enc / b64dec
test_b64enc_encodes_string
test_b64dec_decodes_string
test_b64_roundtrip

exit $failed
