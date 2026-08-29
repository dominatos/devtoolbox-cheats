#!/usr/bin/env bash
# macOS-beta/debug.sh — Universal debug info collector for DevToolbox Cheats
# On macOS: runs diagnostic checks directly.
# On Linux: SSHes to macOS host, runs checks remotely, saves output locally.
#
# Usage:
#   bash macOS-beta/debug.sh                   # detect platform automatically
#   bash macOS-beta/debug.sh --host mymac       # custom SSH host (Linux only)
#   bash macOS-beta/debug.sh --compact          # essential checks only (macOS only)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ============= macOS Mode: run directly =============
if [[ "$(uname -s)" == "Darwin" ]]; then
    exec bash "$SCRIPT_DIR/debug-sysinfo.sh" "$@"
fi

# ============= Linux Mode: SSH to macOS =============
HOST="${DEVTOOLBOX_MAC_HOST:-macos}"
OUTPUT_DIR="$SCRIPT_DIR/debug-output"
SYSINFO_ARGS=()

while (($#)); do
    case "$1" in
        --host)     HOST="$2"; shift 2 ;;
        --output)   OUTPUT_DIR="$2"; shift 2 ;;
        --compact)  SYSINFO_ARGS+=("--compact"); shift ;;
        -h|--help)
            sed -n '2,13p' "${BASH_SOURCE[0]}"
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# log prints a debug message with a standard prefix.
log() { printf '[debug] %s\n' "$*"; }

# Connectivity check
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$HOST" true 2>/dev/null; then
    echo "ERROR: Cannot reach SSH host '$HOST' (passwordless login required)." >&2
    exit 1
fi
log "Connected to $HOST"

# Sync script to remote
log "Syncing scripts to $HOST ..."
scp -q "$SCRIPT_DIR/debug-sysinfo.sh" "$HOST":~/devtool/macOS-beta/debug-sysinfo.sh 2>/dev/null || true

# Run debug script on remote
mkdir -p "$OUTPUT_DIR"
timestamp="$(date +%Y-%m-%d-%H%M%S)"
outfile="$OUTPUT_DIR/${timestamp}-sysinfo.txt"

log "Running debug-sysinfo.sh on $HOST ..."
# shellcheck disable=SC2029  # SYSINFO_ARGS expands on client side intentionally
ssh "$HOST" "bash ~/devtool/macOS-beta/debug-sysinfo.sh ${SYSINFO_ARGS[*]}" > "$outfile" 2>&1

log "Output saved to $outfile"
log "Done"
