#!/usr/bin/env bash
# macOS-beta/debug-remote.sh — gather debug info from a remote macOS host via SSH
# Runs debug-sysinfo.sh on the remote machine (which prompts for install.sh).
# Requires passwordless SSH access (ssh key auth).
#
# Usage:
#   bash macOS-beta/debug-remote.sh                   # default host: "macos"
#   bash macOS-beta/debug-remote.sh --host mymac       # custom SSH host
#   bash macOS-beta/debug-remote.sh --output /tmp/out  # custom output dir
#   bash macOS-beta/debug-remote.sh --no-prompt        # skip install.sh prompt

set -euo pipefail

HOST="${DEVTOOLBOX_MAC_HOST:-macos}"
OUTPUT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/debug-output"
PROMPT_INSTALL=true

while (($#)); do
    case "$1" in
        --host)       HOST="$2"; shift 2 ;;
        --output)     OUTPUT_DIR="$2"; shift 2 ;;
        --no-prompt)  PROMPT_INSTALL=false; shift ;;
        -h|--help)
            sed -n '2,14p' "${BASH_SOURCE[0]}"
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# log prefixes a message with `[debug-remote]` and writes it to standard output.
log() { printf '[debug-remote] %s\n' "$*"; }

# Connectivity check
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$HOST" true 2>/dev/null; then
    echo "ERROR: Cannot reach SSH host '$HOST' (passwordless login required)." >&2
    exit 1
fi
log "Connected to $HOST"

timestamp="$(date +%Y-%m-%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"
outfile="$OUTPUT_DIR/${timestamp}-sysinfo.txt"

# Run debug-sysinfo.sh with -t so the interactive prompt can read input.
log "Running debug-sysinfo.sh on $HOST ..."
if [[ "$PROMPT_INSTALL" == true ]]; then
    # ssh -t allocates a terminal; the script writes to its own output file.
    ssh -t "$HOST" "bash ~/devtool/macOS-beta/debug-sysinfo.sh" > "$outfile" 2>&1
    rc=$?
    if [[ $rc -ne 0 ]]; then
        log "Error: ssh exited with status $rc"
        exit "$rc"
    fi
else
    # No prompt — just capture output directly.
    ssh "$HOST" "bash ~/devtool/macOS-beta/debug-sysinfo.sh" > "$outfile" 2>&1
fi

log "Output saved to $outfile"
log "Done"
