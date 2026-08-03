#!/usr/bin/env bash
# tests/test_cheats_updater_extended2.sh
#
# Tests additional cheats-updater.sh functions:
#   log_info, log_warn, log_error, show_help, cleanup
#
# Run:  bash tests/test_cheats_updater_extended2.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
UPDATER="$REPO_ROOT/cheats-updater.sh"

# Source shared test helpers
# shellcheck source=tests/test_helpers.sh
source "$SCRIPT_DIR/test_helpers.sh"

# Override extract_func for cheats-updater.sh (one-liner functions)
extract_func() {
    local name="$1"
    # First try multi-line extraction
    local result
    result="$(awk -v name="$name" '
        $0 ~ "^" name "\\(\\) \\{" { flag=1 }
        flag { print }
        flag && /^}/ { exit }
    ' "$UPDATER")"
    if [[ -n "$result" ]]; then
        echo "$result"
        return
    fi
    # Fallback: extract single-line functions
    grep "^${name}() " "$UPDATER" || grep "^${name}()" "$UPDATER"
}

echo "=== Checking function existence ==="
# Note: log functions use color variables defined at top level, so we define them for testing
COLOR_DEFS='C_RESET="" C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_CYAN="" C_BOLD="" C_DIM=""'
for fn in log_info log_warn log_error show_help cleanup; do
    if [[ -z "$(extract_func "$fn")" ]]; then
        fail "extract_func: could not find function '$fn' in $UPDATER"
    fi
done

echo ""
echo "=== cheats-updater.sh extended tests ==="
echo ""

# --- log functions ---

echo "log functions:"

test_log_info_outputs_to_stderr() {
    local out
    out="$(bash -c "$COLOR_DEFS; $(extract_func log_info); log_info 'test message'" 2>&1 >/dev/null)"
    assert_contains "log_info: contains INFO tag" "$out" "[INFO]"
    assert_contains "log_info: contains message" "$out" "test message"
}
test_log_info_outputs_to_stderr

test_log_warn_outputs_to_stderr() {
    local out
    out="$(bash -c "$COLOR_DEFS; $(extract_func log_warn); log_warn 'warning msg'" 2>&1 >/dev/null)"
    assert_contains "log_warn: contains WARN tag" "$out" "[WARN]"
    assert_contains "log_warn: contains message" "$out" "warning msg"
}
test_log_warn_outputs_to_stderr

test_log_error_outputs_to_stderr() {
    local out
    out="$(bash -c "$COLOR_DEFS; $(extract_func log_error); log_error 'error msg'" 2>&1 >/dev/null)"
    assert_contains "log_error: contains ERROR tag" "$out" "[ERROR]"
    assert_contains "log_error: contains message" "$out" "error msg"
}
test_log_error_outputs_to_stderr

test_log_functions_handle_multiple_args() {
    local out
    out="$(bash -c "$COLOR_DEFS; $(extract_func log_info); log_info 'arg1' 'arg2' 'arg3'" 2>&1 >/dev/null)"
    assert_contains "log_info: handles multiple args" "$out" "arg1 arg2 arg3"
}
test_log_functions_handle_multiple_args

# --- show_help ---

echo ""
echo "show_help:"

test_show_help_contains_usage() {
    local out
    out="$(bash -c "$(extract_func show_help); show_help")"
    assert_contains "show_help: contains USAGE section" "$out" "USAGE"
}
test_show_help_contains_usage

test_show_help_contains_commands() {
    local out
    out="$(bash -c "$(extract_func show_help); show_help")"
    assert_contains "show_help: contains COMMANDS section" "$out" "COMMANDS"
    assert_contains "show_help: mentions check" "$out" "check"
    assert_contains "show_help: mentions update" "$out" "update"
    assert_contains "show_help: mentions list" "$out" "list"
}
test_show_help_contains_commands

test_show_help_contains_environment() {
    local out
    out="$(bash -c "$(extract_func show_help); show_help")"
    assert_contains "show_help: contains ENVIRONMENT section" "$out" "ENVIRONMENT"
    assert_contains "show_help: mentions CHEATS_DIR" "$out" "CHEATS_DIR"
}
test_show_help_contains_environment

test_show_help_contains_examples() {
    local out
    out="$(bash -c "$(extract_func show_help); show_help")"
    assert_contains "show_help: contains EXAMPLES section" "$out" "EXAMPLES"
}
test_show_help_contains_examples

test_show_help_contains_backup_info() {
    local out
    out="$(bash -c "$(extract_func show_help); show_help")"
    assert_contains "show_help: contains BACKUP section" "$out" "BACKUP"
}
test_show_help_contains_backup_info

# --- cleanup ---

echo ""
echo "cleanup:"

test_cleanup_removes_existing_temp_dir() {
    local ws tmp_dir
    ws="$(mktemp -d "${TMPDIR:-/tmp}/devtoolbox-updater-test-XXXXXX")"
    tmp_dir="$ws/temp_to_remove"
    mkdir -p "$tmp_dir"
    
    bash -c "
        TEMP_DIR='$tmp_dir'
        $(extract_func cleanup)
        cleanup
    "
    
    if [[ ! -d "$tmp_dir" ]]; then
        pass "cleanup: removes existing temp dir"
    else
        fail "cleanup: temp dir still exists"
    fi
    
    rm -rf "$ws"
}
test_cleanup_removes_existing_temp_dir

test_cleanup_handles_missing_temp_dir() {
    local ws
    ws="$(mktemp -d "${TMPDIR:-/tmp}/devtoolbox-updater-test-XXXXXX")"
    
    # cleanup returns non-zero when TEMP_DIR doesn't exist (condition fails)
    # but it should not crash or produce errors
    local out
    out="$(bash -c "
        TEMP_DIR='$ws/nonexistent'
        $(extract_func cleanup)
        cleanup
    " 2>&1)" || true
    # No error output means it handled the case gracefully
    assert_eq "cleanup: no error output for missing dir" "" "$out"
    
    rm -rf "$ws"
}
test_cleanup_handles_missing_temp_dir

test_cleanup_handles_empty_temp_dir() {
    # cleanup returns non-zero when TEMP_DIR is empty (condition fails)
    # but it should not crash or produce errors
    local out
    out="$(bash -c "
        TEMP_DIR=''
        $(extract_func cleanup)
        cleanup
    " 2>&1)" || true
    assert_eq "cleanup: no error output for empty TEMP_DIR" "" "$out"
}
test_cleanup_handles_empty_temp_dir

echo ""
echo "=== All cheats-updater extended tests complete ==="
echo ""
# shellcheck disable=SC2154
exit "$failed"
