#!/usr/bin/env bash
# tests/test_cheats_updater_extended.sh
#
# Extended tests for cheats-updater.sh:
#   - Backup recovery (transactional staging with rollback)
#   - cmd_check (new/modified/unchanged/custom file detection)
#
# Run directly:  bash tests/test_cheats_updater_extended.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET_SCRIPT="$REPO_ROOT/cheats-updater.sh"

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
        fail "$desc (expected to find [$needle] in output)"
    fi
}

assert_file_exists() {
    local desc="$1" path="$2"
    if [[ -f "$path" ]]; then
        pass "$desc"
    else
        fail "$desc (file not found: $path)"
    fi
}

make_workspace() {
    local ws
    ws="$(mktemp -d "${TMPDIR:-/tmp}/devtoolbox-updater-ext-test-XXXXXX")" || {
        echo "Error: failed to create workspace" >&2
        exit 1
    }
    echo "$ws"
}

setup_env() {
    local ws="$1"
    mkdir -p "$ws/home/bin" "$ws/fixture/cheats.d/network" \
        "$ws/fixture/cheats.d/basics" \
        "$ws/home/.local/share/devtoolbox-cheats/tools"

    # Fake upstream content: multiple files
    printf '# Foo\n\nofficial content v1\n' > "$ws/fixture/cheats.d/network/foo.md"
    printf '# Bar\n\nbasics content v1\n' > "$ws/fixture/cheats.d/basics/bar.md"

    # Stub git — must use single-quoted heredoc to avoid expanding $ws at define time
    cat > "$ws/home/bin/git" <<GITEOF
#!/usr/bin/env bash
if [[ "\$1" == "clone" ]]; then
    dest="\${@: -1}"
    mkdir -p "\$dest"
    cp -r "$ws/fixture/cheats.d" "\$dest/"
    exit 0
fi
exit 1
GITEOF
    chmod +x "$ws/home/bin/git"

    cat > "$ws/home/bin/realpath" <<'PYEOF'
#!/usr/bin/env bash
echo "/fake/path/cheats-updater.sh"
exit 0
PYEOF
    chmod +x "$ws/home/bin/realpath"

    # Stub python3 that always fails (for backup recovery tests)
    cat > "$ws/home/bin/python3" <<PYEOF
#!/usr/bin/env bash
echo "Simulated TOC formatting failure" >&2
exit 1
PYEOF
    chmod +x "$ws/home/bin/python3"

    # manage-tocs.py stub
    printf '# stub\n' > "$ws/home/.local/share/devtoolbox-cheats/tools/manage-tocs.py"
}

# ---------------------------------------------------------------------------
# Backup recovery tests
# ---------------------------------------------------------------------------

test_backup_recovery_restores_on_toc_failure() {
    local ws rc output
    ws="$(make_workspace)"
    setup_env "$ws"

    # Pre-populate CHEATS_DIR with existing content
    mkdir -p "$ws/home/cheats.d/network"
    printf 'original content\n' > "$ws/home/cheats.d/network/foo.md"

    output="$(HOME="$ws/home" CHEATS_DIR="$ws/home/cheats.d" PATH="$ws/home/bin:$PATH" \
        bash "$TARGET_SCRIPT" update 2>&1)"
    rc=$?

    # Update should fail because python3 stub returns 1
    assert_eq "backup recovery: exit code is 1 on TOC failure" "1" "$rc"
    # The original content should be restored
    assert_eq "backup recovery: restores original content" \
        "original content" "$(cat "$ws/home/cheats.d/network/foo.md")"
    assert_contains "backup recovery: logs backup restored" "$output" "Backup restored"

    rm -rf "$ws"
}

test_backup_recovery_rollback_on_cp_failure() {
    local ws rc output
    ws="$(make_workspace)"
    setup_env "$ws"

    # Pre-populate CHEATS_DIR
    mkdir -p "$ws/home/cheats.d/network"
    printf 'original content\n' > "$ws/home/cheats.d/network/foo.md"

    # cp stub: fail when copying FROM a backup dir (recovery step only)
    mv "$ws/home/bin/git" "$ws/home/bin/git.real"
    cat > "$ws/home/bin/cp" <<CPEOF
#!/usr/bin/env bash
# Fail when source (any arg except the last) contains a backup path
# Recovery step: cp -a \$backup_dir \$CHEATS_DIR — source is the backup dir
local args=( "\$@" )
for (( i=0; i < \${#args[@]}-1; i++ )); do
    if [[ "\${args[\$i]}" == *"/backups/"* ]]; then
        echo "Simulated cp failure during recovery" >&2
        exit 1
    fi
done
exec /usr/bin/cp "\$@"
CPEOF
    chmod +x "$ws/home/bin/cp"

    output="$(HOME="$ws/home" CHEATS_DIR="$ws/home/cheats.d" PATH="$ws/home/bin:$PATH" \
        bash "$TARGET_SCRIPT" update 2>&1)"
    rc=$?

    # Restore
    mv "$ws/home/bin/git.real" "$ws/home/bin/git" 2>/dev/null || true
    rm -f "$ws/home/bin/cp"

    assert_eq "backup rollback: exit code is 1" "1" "$rc"
    assert_contains "backup rollback: reports recovery failure" "$output" "Backup recovery failed"

    rm -rf "$ws"
}

test_backup_recovery_no_backup_dir_skips_restore() {
    local ws rc output
    ws="$(make_workspace)"
    setup_env "$ws"

    # No pre-existing CHEATS_DIR — no backup should be created
    output="$(HOME="$ws/home" CHEATS_DIR="$ws/home/cheats-new.d" PATH="$ws/home/bin:$PATH" \
        bash "$TARGET_SCRIPT" update 2>&1)"
    rc=$?

    # Should still fail (python3 returns 1), but no backup restore attempted
    assert_eq "no backup dir: exit code is 1" "1" "$rc"
    assert_file_exists "no backup dir: new file still written" "$ws/home/cheats-new.d/network/foo.md"

    rm -rf "$ws"
}

test_backup_recovery_preserves_custom_files_in_backup() {
    local ws rc
    ws="$(make_workspace)"
    setup_env "$ws"

    # Pre-populate with both official and custom files
    mkdir -p "$ws/home/cheats.d/network" "$ws/home/cheats.d/myspace"
    printf 'official\n' > "$ws/home/cheats.d/network/foo.md"
    printf 'custom notes\n' > "$ws/home/cheats.d/myspace/my-custom.md"

    rc="$(HOME="$ws/home" CHEATS_DIR="$ws/home/cheats.d" PATH="$ws/home/bin:$PATH" \
        bash "$TARGET_SCRIPT" update 2>&1)"
    rc=$?

    # Find the backup directory
    local backup_dir
    backup_dir="$(find "$ws/home/.local/share/devtoolbox-cheats/backups" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)"

    if [[ -n "$backup_dir" ]]; then
        assert_file_exists "backup preserves custom file" "$backup_dir/myspace/my-custom.md"
        assert_file_exists "backup preserves official file" "$backup_dir/network/foo.md"
    else
        fail "backup: no backup directory created"
    fi

    rm -rf "$ws"
}

# ---------------------------------------------------------------------------
# cmd_check tests
# ---------------------------------------------------------------------------

run_check() {
    local ws="$1"
    HOME="$ws/home" \
    CHEATS_DIR="$ws/home/cheats.d" \
    PATH="$ws/home/bin:$PATH" \
        bash "$TARGET_SCRIPT" check >"$ws/stdout.log" 2>"$ws/stderr.log"
    echo $?
}

test_check_reports_new_files() {
    local ws rc output
    ws="$(make_workspace)"
    setup_env "$ws"
    # Create CHEATS_DIR but leave it empty — per-file [+] lines require the dir to exist
    mkdir -p "$ws/home/cheats.d"

    rc="$(run_check "$ws")"
    output="$(cat "$ws/stdout.log")"
    assert_eq "check new files: exit code 0" "0" "$rc"
    assert_contains "check new files: reports + for new file" "$output" "+ network/foo.md"
    assert_contains "check new files: reports + for new file" "$output" "+ basics/bar.md"
    assert_contains "check new files: suggests update" "$output" "update"

    rm -rf "$ws"
}

test_check_reports_unchanged_files() {
    local ws rc output
    ws="$(make_workspace)"
    setup_env "$ws"
    # Pre-populate local with same content as upstream
    mkdir -p "$ws/home/cheats.d/network" "$ws/home/cheats.d/basics"
    cp "$ws/fixture/cheats.d/network/foo.md" "$ws/home/cheats.d/network/foo.md"
    cp "$ws/fixture/cheats.d/basics/bar.md" "$ws/home/cheats.d/basics/bar.md"

    rc="$(run_check "$ws")"
    output="$(cat "$ws/stdout.log")"
    assert_eq "check unchanged: exit code 0" "0" "$rc"
    assert_contains "check unchanged: reports up to date" "$output" "up to date"

    rm -rf "$ws"
}

test_check_reports_modified_files() {
    local ws rc output
    ws="$(make_workspace)"
    setup_env "$ws"
    # Pre-populate local with DIFFERENT content
    mkdir -p "$ws/home/cheats.d/network"
    printf 'modified local content\n' > "$ws/home/cheats.d/network/foo.md"

    rc="$(run_check "$ws")"
    output="$(cat "$ws/stdout.log")"
    assert_eq "check modified: exit code 0" "0" "$rc"
    assert_contains "check modified: reports ~ for modified file" "$output" "~ network/foo.md"

    rm -rf "$ws"
}

test_check_reports_custom_files() {
    local ws rc output
    ws="$(make_workspace)"
    setup_env "$ws"
    # Pre-populate with a custom file not in upstream
    mkdir -p "$ws/home/cheats.d/myspace"
    printf 'my custom notes\n' > "$ws/home/cheats.d/myspace/custom.md"

    rc="$(run_check "$ws")"
    output="$(cat "$ws/stdout.log")"
    assert_eq "check custom: exit code 0" "0" "$rc"
    assert_contains "check custom: reports ? for custom file" "$output" "? myspace/custom.md (custom)"

    rm -rf "$ws"
}

test_check_mixed_scenario() {
    local ws rc output
    ws="$(make_workspace)"
    setup_env "$ws"
    # Mix: one unchanged, one modified, one custom
    mkdir -p "$ws/home/cheats.d/network" "$ws/home/cheats.d/myspace"
    cp "$ws/fixture/cheats.d/network/foo.md" "$ws/home/cheats.d/network/foo.md"  # unchanged
    printf 'different\n' > "$ws/home/cheats.d/myspace/custom.md"  # custom

    rc="$(run_check "$ws")"
    output="$(cat "$ws/stdout.log")"
    assert_eq "check mixed: exit code 0" "0" "$rc"
    # Should have unchanged for foo.md, new for bar.md (missing locally), custom for custom.md
    assert_contains "check mixed: reports custom" "$output" "custom"

    rm -rf "$ws"
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------

# Backup recovery
test_backup_recovery_restores_on_toc_failure
test_backup_recovery_rollback_on_cp_failure
test_backup_recovery_no_backup_dir_skips_restore
test_backup_recovery_preserves_custom_files_in_backup

# cmd_check
test_check_reports_new_files
test_check_reports_unchanged_files
test_check_reports_modified_files
test_check_reports_custom_files
test_check_mixed_scenario

exit $failed
