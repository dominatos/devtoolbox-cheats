#!/usr/bin/env bash
# macOS-beta/deploy-to-macos-vm.sh — deploy the working tree to the macOS test VM
# vm created with https://github.com/dominatos/macos-virtualbox
# Deploys uncommitted changes without any git operations:
#   1. rsync the repository to ~/Downloads/devtool on the VM
#   2. run ./install.sh there (root installer delegates to macOS-beta/install.sh)
#   3. quit xbar
#   4. relaunch xbar after a short delay (prevents xbar from staying stopped)
#
# Requires passwordless SSH access: ssh macos
#
# Usage:
#   bash macOS-beta/deploy-to-macos-vm.sh [options]
#
# Options:
#   --host <name>        SSH host (default: $DEVTOOLBOX_MAC_HOST or "macos")
#   --remote-dir <path>  Remote directory, relative to home (default:
#                        $DEVTOOLBOX_MAC_DIR or "devtool")
#   --delay <seconds>    Delay before xbar relaunch (default: 30)
#   --no-install         Sync only; skip install.sh
#   --no-restart         Sync only; do not touch xbar
#   -h, --help           Show this help

set -euo pipefail

HOST="${DEVTOOLBOX_MAC_HOST:-macos}"
REMOTE_DIR="${DEVTOOLBOX_MAC_DIR:-devtool}"
DELAY=30
DO_INSTALL=1
DO_RESTART=1

# usage prints the script's command-line usage information.
usage() { sed -n '2,24p' "${BASH_SOURCE[0]}"; }

while (($#)); do
    case "$1" in
        --host)       HOST="$2"; shift 2 ;;
        --remote-dir) REMOTE_DIR="$2"; shift 2 ;;
        --delay)      DELAY="$2"; shift 2 ;;
        --no-install) DO_INSTALL=0; shift ;;
        --no-restart) DO_RESTART=0; shift ;;
        -h|--help)    usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

# Validate --remote-dir before rsync --delete can act on it: only plain
# relative directory names are allowed.
if [[ -z "$REMOTE_DIR" || "$REMOTE_DIR" == /* || "$REMOTE_DIR" == .* || \
      "$REMOTE_DIR" == *..* || "$REMOTE_DIR" =~ [^A-Za-z0-9._/-] ]]; then
    echo "ERROR: invalid --remote-dir '$REMOTE_DIR' (use a simple relative path like 'devtool')" >&2
    exit 1
fi
case "$REMOTE_DIR" in
    */..|/.*|*//*|*./*|*/.)  echo "ERROR: invalid --remote-dir '$REMOTE_DIR'" >&2; exit 1 ;;
esac

# Validate --delay before anything can stop xbar.
if ! [[ "$DELAY" =~ ^[0-9]+$ ]]; then
    echo "ERROR: invalid --delay '$DELAY' (non-negative integer required)" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ ! -d "$REPO_ROOT/macOS-beta" ]]; then
    echo "ERROR: Repository root not found above $SCRIPT_DIR" >&2
    exit 1
fi

# log writes a deployment message with a standard prefix.
log() { printf '[deploy] %s\n' "$*"; }

# ============= 1. Connectivity check =============
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$HOST" true 2>/dev/null; then
    echo "ERROR: Cannot reach SSH host '$HOST' (passwordless login required)." >&2
    exit 1
fi
log "Connected to $HOST"

# ============= 2. Sync working tree (no git involved) =============
log "Syncing $REPO_ROOT → $HOST:~/$REMOTE_DIR ..."
rsync -az --delete \
    --exclude '.git/' \
    --exclude '.github/' \
    --exclude 'Windows-beta/' \
    --exclude 'todelete.txt' \
    --exclude 'uJCulkdr' \
    --exclude 'tofix.md' \
    --exclude 'tofix-helper.md' \
    --exclude 'tofix-helper.py' \
    --exclude 'autofixprompt.md' \
    --exclude 'fixprompt.md' \
    --exclude 'promt.txt' \
    --exclude 'review.md' \
    --exclude 'CHECKLIST.md' \
    --exclude '__pycache__/' \
    "$REPO_ROOT/" "$HOST:$REMOTE_DIR/"
log "Sync complete"

# ============= 3. Run installer on the VM =============
if (( DO_INSTALL )); then
    log "Running install.sh on $HOST ..."
    ssh -t "$HOST" "cd ~/$REMOTE_DIR && ./install.sh"
fi

(( DO_RESTART )) || { log "Done (xbar untouched)"; exit 0; }

# ============= 4. Quit xbar =============
log "Quitting xbar ..."
ssh "$HOST" "pkill -x xbar 2>/dev/null; pkill -ix bitbar 2>/dev/null; true"
log "xbar stopped"

# ============= 5. Relaunch xbar after delay =============
# ssh -f keeps this running on the VM even if this machine disconnects.
log "Relaunching xbar in ${DELAY}s ..."
ssh -f "$HOST" "sleep $DELAY && open -a xbar"
log "Deploy finished — xbar will start in ${DELAY}s"
