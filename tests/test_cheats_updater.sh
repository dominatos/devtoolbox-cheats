#!/usr/bin/env bash
# tests/test_cheats_updater.sh
#
# Integration test for cheats-updater.sh's cmd_update, focused on the
# behavior introduced in this change: TOC auto-formatting is applied only
# to official files that were actually written to CHEATS_DIR, and custom
# user files are never passed to manage-tocs.py.
#
# Network access (git clone) and python3 are stubbed out via a temporary
# PATH so the test is hermetic and fast.
#
# Run directly:  bash tests/test_cheats_updater.sh
#
# NOTE: cmd_update relies on process substitution (`< <(...)`) internally,
# which requires a working /dev/fd on the host. This is standard on Linux
# CI runners; some minimal/sandboxed containers do not provide it.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET_SCRIPT="$REPO_ROOT/cheats-updater.sh"

failed=0
# pass reports a successful test result with the provided message.
pass() { echo "OK:   $1"; }
# fail reports a test failure and marks the test suite as failed.
fail() { echo "FAIL: $1"; failed=1; }

# assert_eq compares expected and actual values and records a passing or failing assertion with the supplied description.
assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        pass "$desc"
    else
        fail "$desc (expected: [$expected], actual: [$actual])"
    fi
}

# assert_contains checks whether a string contains the expected substring and records the assertion result.
assert_contains() {
    local desc="$1" haystack="$2" needle="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        pass "$desc"
    else
        fail "$desc (expected to find [$needle] in output)"
    fi
}

# assert_file_exists verifies that a file exists at the specified path and records the result using the provided description.
assert_file_exists() {
    local desc="$1" path="$2"
    if [[ -f "$path" ]]; then
        pass "$desc"
    else
        fail "$desc (file not found: $path)"
    fi
}

# assert_file_missing verifies that a specified file does not exist.
assert_file_missing() {
    local desc="$1" path="$2"
    if [[ ! -f "$path" ]]; then
        pass "$desc"
    else
        fail "$desc (file unexpectedly exists: $path)"
    fi
}

# make_workspace creates and outputs a temporary workspace directory, exiting with an error if creation fails.
make_workspace() {
    local ws
    ws="$(mktemp -d "${TMPDIR:-/tmp}/devtoolbox-test-XXXXXX")" || {
        echo "Error: failed to create workspace" >&2
        exit 1
    }
    echo "$ws"
}

# Builds a hermetic test environment:
#   $ws/home                 -> $HOME for the run
#   $ws/home/cheats.d        -> $CHEATS_DIR (pre-populated by the caller)
#   $ws/home/bin             -> stubbed `git` and `python3` on PATH
# setup_env creates an isolated test environment with fake upstream content and stubbed external commands.
setup_env() {
    local ws="$1"
    mkdir -p "$ws/home/bin" "$ws/fixture/cheats.d/network" \
        "$ws/home/.local/share/devtoolbox-cheats/tools"

    # Fake upstream content: one file, used to populate the local dir.
    printf '# Foo\n\nofficial content v1\n' > "$ws/fixture/cheats.d/network/foo.md"

    # Stub git: only understands `git clone ... <dest>`, copies the fixture.
    cat > "$ws/home/bin/git" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "clone" ]]; then
    dest="\${@: -1}"
    mkdir -p "\$dest"
    cp -r "$ws/fixture/cheats.d" "\$dest/"
    exit 0
fi
exit 1
EOF
    chmod +x "$ws/home/bin/git"

    cat > "$ws/home/bin/realpath" <<'PYEOF'
#!/usr/bin/env bash
echo "/fake/path/cheats-updater.sh"
exit 0
PYEOF
    chmod +x "$ws/home/bin/realpath"

    # Stub python3: logs its invocation for later assertions.
    cat > "$ws/home/bin/python3" <<EOF
#!/usr/bin/env bash
echo "\$@" >> "$ws/python3-invocations.log"
exit 0
EOF
    chmod +x "$ws/home/bin/python3"

    # manage-tocs.py just needs to exist at the first candidate path found
    # by cmd_update; its content is irrelevant since python3 is stubbed.
    printf '# stub\n' > "$ws/home/.local/share/devtoolbox-cheats/tools/manage-tocs.py"
}

# run_update executes the updater in an isolated workspace and echoes its exit status.
run_update() {
    local ws="$1"
    HOME="$ws/home" \
    CHEATS_DIR="$ws/home/cheats.d" \
    PATH="$ws/home/bin:$PATH" \
        bash "$TARGET_SCRIPT" update >"$ws/stdout.log" 2>"$ws/stderr.log"
    echo $?
}

# test_update_writes_official_file_and_creates_backup verifies that update copies the upstream official file and creates a backup directory.
test_update_writes_official_file_and_creates_backup() {
    local ws rc
    ws="$(make_workspace)"
    setup_env "$ws"

    mkdir -p "$ws/home/cheats.d"
    rc="$(run_update "$ws")"
    assert_eq "update: exits 0" "0" "$rc"
    assert_file_exists "update: writes new official file" "$ws/home/cheats.d/network/foo.md"
    assert_eq "update: official file content matches upstream" \
        "$(cat "$ws/fixture/cheats.d/network/foo.md")" \
        "$(cat "$ws/home/cheats.d/network/foo.md")"

    if compgen -G "$ws/home/.local/share/devtoolbox-cheats/backups/*" > /dev/null; then
        pass "update: creates a backup directory"
    else
        fail "update: no backup directory created"
    fi

    rm -rf "$ws"
}

# test_update_toc_formatting_excludes_custom_files verifies that updates format official files with the default style while excluding and preserving custom files.
test_update_toc_formatting_excludes_custom_files() {
    local ws rc log
    ws="$(make_workspace)"
    setup_env "$ws"

    # Pre-populate CHEATS_DIR with a custom, non-official file.
    mkdir -p "$ws/home/cheats.d/network"
    printf 'my own notes\n' > "$ws/home/cheats.d/network/my-custom.md"

    rc="$(run_update "$ws")"
    log="$ws/python3-invocations.log"

    assert_eq "update+toc: exits 0" "0" "$rc"
    assert_file_exists "update+toc: python3 (manage-tocs.py) was invoked" "$log"

    if [[ -f "$log" ]]; then
        local invocation
        invocation="$(cat "$log")"
        if [[ "$invocation" == *"network/foo.md"* ]]; then
            pass "update+toc: official file included in --files list"
        else
            fail "update+toc: official file missing from invocation ($invocation)"
        fi
        if [[ "$invocation" == *"my-custom.md"* ]]; then
            fail "update+toc: custom file leaked into --files list ($invocation)"
        else
            pass "update+toc: custom file correctly excluded from --files list"
        fi
        if [[ "$invocation" == *"--style obsidian"* ]]; then
            pass "update+toc: default style (obsidian) passed to manage-tocs.py"
        else
            fail "update+toc: expected --style obsidian in invocation ($invocation)"
        fi
    fi

    # Custom file must be left completely untouched by the update.
    assert_eq "update+toc: custom file content is unmodified" \
        "my own notes" "$(cat "$ws/home/cheats.d/network/my-custom.md")"

    rm -rf "$ws"
}

# test_update_honors_persisted_toc_format verifies that update succeeds and passes the configured TOC format to the formatter.
test_update_honors_persisted_toc_format() {
    local ws rc log invocation
    ws="$(make_workspace)"
    setup_env "$ws"
    mkdir -p "$ws/home/.config/devtoolbox-cheats"
    printf 'github\n' > "$ws/home/.config/devtoolbox-cheats/toc_format.conf"

    rc="$(run_update "$ws")"
    log="$ws/python3-invocations.log"

    assert_eq "update+persisted-format: exits 0" "0" "$rc"
    assert_file_exists "update+persisted-format: python3 invoked" "$log"
    invocation="$(cat "$log" 2>/dev/null || true)"
    if [[ "$invocation" == *"--style github"* ]]; then
        pass "update+persisted-format: uses persisted github style"
    else
        fail "update+persisted-format: expected --style github in invocation ($invocation)"
    fi

    rm -rf "$ws"
}

# test_update_skips_toc_formatting_when_manage_tocs_missing verifies that an update succeeds and writes official files when the TOC formatter is unavailable.
test_update_skips_toc_formatting_when_manage_tocs_missing() {
    local ws rc log
    ws="$(make_workspace)"
    setup_env "$ws"
    rm -f "$ws/home/.local/share/devtoolbox-cheats/tools/manage-tocs.py"

    rc="$(run_update "$ws")"
    log="$ws/python3-invocations.log"

    assert_eq "update without manage-tocs.py: still exits 0" "0" "$rc"
    assert_file_missing "update without manage-tocs.py: python3 never invoked" "$log"
    assert_file_exists "update without manage-tocs.py: official file still written" \
        "$ws/home/cheats.d/network/foo.md"

    rm -rf "$ws"
}

test_update_writes_official_file_and_creates_backup
test_update_toc_formatting_excludes_custom_files
test_update_honors_persisted_toc_format
test_update_skips_toc_formatting_when_manage_tocs_missing

test_update_toc_formatting_failure_reported() {
    local ws rc output
    ws="$(make_workspace)"
    setup_env "$ws"
    
    # Pre-populate CHEATS_DIR so it has something to format
    mkdir -p "$ws/home/cheats.d/network"
    printf '# Foo
' > "$ws/home/cheats.d/network/foo.md"
    
    # Override the python3 stub to fail
    cat > "$ws/home/bin/python3" <<'PYEOF'
#!/usr/bin/env bash
echo "Fake error from formatter" >&2
exit 1
PYEOF
    
    # We need to capture both stdout and stderr and check exit code
    output="$(HOME="$ws/home" CHEATS_DIR="$ws/home/cheats.d" PATH="$ws/home/bin:$PATH" bash "$TARGET_SCRIPT" update 2>&1)"
    rc=$?
    
    assert_eq "update+toc fails if formatter fails: exit code" "1" "$rc"
    assert_contains "update+toc fails if formatter fails: reports formatter error message" "$output" "Fake error from formatter"
    
    rm -rf "$ws"
}

test_update_toc_formatting_failure_reported

exit $failed