#!/usr/bin/env bash
# tests/test_helpers.sh
#
# Shared test helpers for all test scripts.
# Source this file at the top of each test script.
#
# Provides:
#   - pass, fail: test result reporters
#   - assert_eq, assert_contains, assert_file_exists: assertions
#   - extract_func: function extraction from shell scripts
#   - make_workspace, make_test_cheat: test setup utilities

# Test result tracking
failed=0

# Test result reporters
pass() { echo "OK:   $1"; }
fail() { echo "FAIL: $1"; failed=1; }

# Assertions
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

assert_file_exists() {
    local desc="$1" f="$2"
    if [[ -f "$f" ]]; then
        pass "$desc"
    else
        fail "$desc (file not found: $f)"
    fi
}

# Function extraction from shell scripts
# Usage: extract_func <function_name> [script_path]
# If script_path is not provided, uses TARGET_SCRIPT variable
extract_func() {
    local name="$1"
    local script="${2:-$TARGET_SCRIPT}"
    awk -v name="$name" '
        $0 ~ "^" name "\\(\\) \\{" { flag=1 }
        flag { print }
        flag && /^}/ { exit }
    ' "$script"
}

# Test workspace creation
make_workspace() {
    local prefix="${1:-devtoolbox-test}"
    local ws
    ws="$(mktemp -d "${TMPDIR:-/tmp}/${prefix}-XXXXXX")" || {
        echo "Error: failed to create workspace" >&2
        exit 1
    }
    echo "$ws"
}

# Create a test cheat file
# Usage: make_test_cheat <directory> <name> [group] [order]
make_test_cheat() {
    local dir="$1" name="$2" group="${3:-TestGroup}" order="${4:-10}"
    mkdir -p "$dir/$group"
    cat > "$dir/$group/$name.md" <<EOF
Title: $name
Group: $group
Icon: test-icon
Order: $order

## Content

Some test content for $name.
EOF
    echo "$dir/$group/$name.md"
}
