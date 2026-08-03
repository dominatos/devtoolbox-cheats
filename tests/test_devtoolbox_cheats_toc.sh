#!/usr/bin/env bash
# tests/test_devtoolbox_cheats_toc.sh
#
# Tests the TOC-format helper functions in devtoolbox-cheats.30s.sh:
#   get_toc_format, setTocFormat, applyTocFormat
#
# The parent script uses `set -Eeuo pipefail` with a top-level argument
# dispatcher, so we don't source the whole file. Instead we extract just
# the function definitions we need (they are simple, side-effect-contained
# functions with no nested top-level '}' inside their bodies) and load
# them into an isolated bash environment for testing. This avoids
# triggering the script's Argos/menu-rendering code paths, which require a
# desktop environment and UI dialog tools that aren't available in a test
# sandbox.
#
# Run directly:  bash tests/test_devtoolbox_cheats_toc.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET_SCRIPT="$REPO_ROOT/devtoolbox-cheats.30s.sh"

failed=0
# pass reports a successful test result with the provided message.
pass() { echo "OK:   $1"; }
# fail reports a test failure message and marks the test suite as failed.
fail() { echo "FAIL: $1"; failed=1; }

# assert_eq compares the expected and actual values, recording a pass or failure with the specified description.
assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass "$desc"
    else
        fail "$desc (expected: [$expected], actual: [$actual])"
    fi
}

# extract_func extracts a named Bash function definition from the target script and prints it.
extract_func() {
    local name="$1"
    awk -v name="$name" '
        $0 ~ "^" name "\\(\\) \\{" { flag=1 }
        flag { print }
        flag && /^}/ { exit }
    ' "$TARGET_SCRIPT"
}

# Sanity check: fail loudly (instead of silently testing nothing) if the
# expected functions ever disappear or get renamed in the source script.
for fn in get_toc_format setTocFormat applyTocFormat; do
    if [[ -z "$(extract_func "$fn")" ]]; then
        fail "extract_func: could not find function '$fn' in $TARGET_SCRIPT"
    fi
done

# make_workspace creates a temporary workspace directory and echoes its path.
make_workspace() {
    local ws
    ws="$(mktemp -d "${TMPDIR:-/tmp}/devtoolbox-toc-test-XXXXXX")" || {
        echo "Error: failed to create workspace" >&2
        exit 1
    }
    echo "$ws"
}

# ---------------------------------------------------------------------------
# get_toc_format
# ---------------------------------------------------------------------------

test_get_toc_format_defaults_to_obsidian() {
    local ws out
    ws="$(make_workspace)"
    out="$(
        DEVTOOLBOX_TOC_FORMAT_CONF="$ws/toc_format.conf" \
        bash -c "$(extract_func get_toc_format); get_toc_format"
    )"
    assert_eq "get_toc_format: defaults to obsidian when unset" "obsidian" "$out"
    rm -rf "$ws"
}

# test_get_toc_format_reads_persisted_config verifies that get_toc_format reads the persisted TOC format configuration.
test_get_toc_format_reads_persisted_config() {
    local ws out
    ws="$(make_workspace)"
    printf 'github\n' > "$ws/toc_format.conf"
    out="$(
        DEVTOOLBOX_TOC_FORMAT_CONF="$ws/toc_format.conf" \
        bash -c "$(extract_func get_toc_format); get_toc_format"
    )"
    assert_eq "get_toc_format: reads persisted config" "github" "$out"
    rm -rf "$ws"
}

test_get_toc_format_env_override_takes_priority() {
    local ws out
    ws="$(make_workspace)"
    printf 'obsidian\n' > "$ws/toc_format.conf"
    out="$(
        DEVTOOLBOX_TOC_FORMAT_CONF="$ws/toc_format.conf" \
        DEVTOOLBOX_TOC_FORMAT="github" \
        bash -c "$(extract_func get_toc_format); get_toc_format"
    )"
    assert_eq "get_toc_format: valid env override wins over persisted config" "github" "$out"
    rm -rf "$ws"
}

# test_get_toc_format_invalid_env_override_falls_through verifies that an invalid environment override falls back to the persisted TOC format.
test_get_toc_format_invalid_env_override_falls_through() {
    local ws out
    ws="$(make_workspace)"
    printf 'github\n' > "$ws/toc_format.conf"
    out="$(
        DEVTOOLBOX_TOC_FORMAT_CONF="$ws/toc_format.conf" \
        DEVTOOLBOX_TOC_FORMAT="not-a-real-format" \
        bash -c "$(extract_func get_toc_format); get_toc_format"
    )"
    assert_eq "get_toc_format: invalid env override falls back to persisted config" "github" "$out"
    rm -rf "$ws"
}

# test_get_toc_format_invalid_env_override_no_config_falls_to_default verifies that an invalid environment override falls back to the default format when no configuration exists.
test_get_toc_format_invalid_env_override_no_config_falls_to_default() {
    local ws out
    ws="$(make_workspace)"
    out="$(
        DEVTOOLBOX_TOC_FORMAT_CONF="$ws/toc_format.conf" \
        DEVTOOLBOX_TOC_FORMAT="bogus" \
        bash -c "$(extract_func get_toc_format); get_toc_format"
    )"
    assert_eq "get_toc_format: invalid env override + no config -> default" "obsidian" "$out"
    rm -rf "$ws"
}

test_get_toc_format_ignores_whitespace_in_config() {
    local ws out
    ws="$(make_workspace)"
    printf '  github  \n' > "$ws/toc_format.conf"
    out="$(
        DEVTOOLBOX_TOC_FORMAT_CONF="$ws/toc_format.conf" \
        bash -c "$(extract_func get_toc_format); get_toc_format"
    )"
    assert_eq "get_toc_format: strips whitespace from config file" "github" "$out"
    rm -rf "$ws"
}

# test_get_toc_format_invalid_persisted_value_falls_to_default verifies that an invalid persisted TOC format falls back to the default `obsidian` format.
test_get_toc_format_invalid_persisted_value_falls_to_default() {
    local ws out
    ws="$(make_workspace)"
    printf 'nonsense\n' > "$ws/toc_format.conf"
    out="$(
        DEVTOOLBOX_TOC_FORMAT_CONF="$ws/toc_format.conf" \
        bash -c "$(extract_func get_toc_format); get_toc_format"
    )"
    assert_eq "get_toc_format: invalid persisted value falls back to default" "obsidian" "$out"
    rm -rf "$ws"
}

# ---------------------------------------------------------------------------
# setTocFormat
# ---------------------------------------------------------------------------

test_set_toc_format_persists_valid_value() {
    local ws
    ws="$(make_workspace)"
    DEVTOOLBOX_TOC_FORMAT_CONF="$ws/nested/toc_format.conf" \
        bash -c "$(extract_func setTocFormat); setTocFormat github"
    assert_eq "setTocFormat: persists valid value" "github" "$(cat "$ws/nested/toc_format.conf")"
    rm -rf "$ws"
}

# test_set_toc_format_rejects_invalid_value verifies that setTocFormat persists obsidian when given an invalid value.
test_set_toc_format_rejects_invalid_value() {
    local ws
    ws="$(make_workspace)"
    DEVTOOLBOX_TOC_FORMAT_CONF="$ws/toc_format.conf" \
        bash -c "$(extract_func setTocFormat); setTocFormat not-valid"
    assert_eq "setTocFormat: falls back to obsidian for invalid value" "obsidian" "$(cat "$ws/toc_format.conf")"
    rm -rf "$ws"
}

# test_set_toc_format_defaults_when_no_arg verifies that setTocFormat persists obsidian when called without an argument.
test_set_toc_format_defaults_when_no_arg() {
    local ws
    ws="$(make_workspace)"
    DEVTOOLBOX_TOC_FORMAT_CONF="$ws/toc_format.conf" \
        bash -c "$(extract_func setTocFormat); setTocFormat"
    assert_eq "setTocFormat: defaults to obsidian with no argument" "obsidian" "$(cat "$ws/toc_format.conf")"
    rm -rf "$ws"
}

# ---------------------------------------------------------------------------
# applyTocFormat
# test_apply_toc_format_fails_gracefully_without_python3 verifies that applyTocFormat returns a nonzero status when python3 is unavailable.

test_apply_toc_format_fails_gracefully_without_python3() {
    local ws rc
    ws="$(make_workspace)"
    mkdir -p "$ws/bin"
    # A PATH containing only coreutils needed by the function body, with no
    # python3 binary, to exercise the "python3 not found" guard.
    for tool in bash awk mkdir dirname printf cat tr find sort env; do
        real="$(command -v "$tool")"
        [[ -n "$real" ]] && ln -sf "$real" "$ws/bin/$tool"
    done

    PATH="$ws/bin" DEVTOOLBOX_TOC_FORMAT_CONF="$ws/toc_format.conf" \
        SCRIPT_PATH="$TARGET_SCRIPT" CHEATS_DIR="$ws/cheats.d" HOME="$ws" \
        bash -c "$(extract_func get_toc_format); $(extract_func applyTocFormat); applyTocFormat"
    rc=$?
    assert_eq "applyTocFormat: returns non-zero when python3 is missing" "1" "$rc"
    rm -rf "$ws"
}

test_apply_toc_format_invokes_manage_tocs_with_correct_args() {
    local ws rc log
    ws="$(make_workspace)"
    mkdir -p "$ws/bin" "$ws/.local/share/devtoolbox-cheats/tools" "$ws/cheats.d"
    # Fake manage-tocs.py: its content is irrelevant since python3 is stubbed.
    printf '# stub\n' > "$ws/.local/share/devtoolbox-cheats/tools/manage-tocs.py"

    log="$ws/python3-invocation.log"
    cat > "$ws/bin/python3" <<EOF
#!/usr/bin/env bash
echo "\$@" > "$log"
exit 0
EOF
    chmod +x "$ws/bin/python3"

    PATH="$ws/bin:$PATH" DEVTOOLBOX_TOC_FORMAT_CONF="$ws/toc_format.conf" \
        SCRIPT_PATH="$TARGET_SCRIPT" CHEATS_DIR="$ws/cheats.d" HOME="$ws" \
        bash -c "$(extract_func get_toc_format); $(extract_func applyTocFormat); applyTocFormat" \
        >/dev/null 2>&1
    rc=$?

    assert_eq "applyTocFormat: returns 0 on success" "0" "$rc"
    
    local timeout=20
    while [[ ! -f "$log" ]] && (( timeout > 0 )); do
        sleep 0.1
        ((timeout--))
    done

    if [[ -f "$log" ]]; then
        assert_eq "applyTocFormat: invokes manage-tocs.py with correct style/dir" \
            "$ws/.local/share/devtoolbox-cheats/tools/manage-tocs.py --style obsidian --dir $ws/cheats.d" \
            "$(cat "$log")"
    else
        fail "applyTocFormat: python3 stub was never invoked"
    fi
    rm -rf "$ws"
}

test_get_toc_format_defaults_to_obsidian
test_get_toc_format_reads_persisted_config
test_get_toc_format_env_override_takes_priority
test_get_toc_format_invalid_env_override_falls_through
test_get_toc_format_invalid_env_override_no_config_falls_to_default
test_get_toc_format_ignores_whitespace_in_config
test_get_toc_format_invalid_persisted_value_falls_to_default
test_set_toc_format_persists_valid_value
test_set_toc_format_rejects_invalid_value
test_set_toc_format_defaults_when_no_arg
test_apply_toc_format_fails_gracefully_without_python3
test_apply_toc_format_invokes_manage_tocs_with_correct_args

exit $failed