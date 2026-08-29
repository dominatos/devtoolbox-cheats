#!/usr/bin/env bash
# macOS-beta/debug-remote.sh — run debug-sysinfo.sh on a remote macOS host via SSH
# Requires passwordless SSH access (ssh key auth).
#
# Usage:
#   bash macOS-beta/debug-remote.sh                   # default host: "macos"
#   bash macOS-beta/debug-remote.sh --host mymac       # custom SSH host
#   bash macOS-beta/debug-remote.sh --output /tmp/out  # custom output dir
#
# Output is saved to macOS-beta/debug-output/YYYY-MM-DD-HHMMSS-sysinfo.txt

set -euo pipefail

HOST="${DEVTOOLBOX_MAC_HOST:-macos}"
OUTPUT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/debug-output"

while (($#)); do
    case "$1" in
        --host)   HOST="$2"; shift 2 ;;
        --output) OUTPUT_DIR="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,12p' "${BASH_SOURCE[0]}"
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# log writes a prefixed message to standard output.
log() { printf '[debug-remote] %s\n' "$*"; }

# Connectivity check
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$HOST" true 2>/dev/null; then
    echo "ERROR: Cannot reach SSH host '$HOST' (passwordless login required)." >&2
    exit 1
fi
log "Connected to $HOST"

# Run debug script on remote host
log "Running debug-sysinfo.sh on $HOST ..."
timestamp="$(date +%Y-%m-%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"

ssh "$HOST" "bash ~/devtool/macOS-beta/debug-sysinfo.sh" > "$OUTPUT_DIR/${timestamp}-sysinfo.txt" 2>&1

log "Output saved to $OUTPUT_DIR/${timestamp}-sysinfo.txt"
log "Done"
