#!/usr/bin/env bash
# cheats-updater.sh - Update manager for devtoolbox-cheats
set -euo pipefail

readonly VERSION="1.0.0"
readonly UPSTREAM_URL="https://github.com/dominatos/devtoolbox-cheats.git"
readonly BRANCH="main"
readonly CHEATS_DIR="${CHEATS_DIR:-$HOME/cheats.d}"
readonly TEMP_DIR="/tmp/devtoolbox-cheats-$$"

# Colors
if [[ -t 1 ]]; then
    C_RESET=$'\033[0m' C_RED=$'\033[0;31m' C_GREEN=$'\033[0;32m'
    C_YELLOW=$'\033[0;33m' C_BLUE=$'\033[0;34m' C_CYAN=$'\033[0;36m'
    C_BOLD=$'\033[1m' C_DIM=$'\033[2m'
else
    C_RESET="" C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_CYAN="" C_BOLD="" C_DIM=""
fi

log_info()  { echo -e "${C_GREEN}[INFO]${C_RESET} $*" >&2; }
log_warn()  { echo -e "${C_YELLOW}[WARN]${C_RESET} $*" >&2; }
log_error() { echo -e "${C_RED}[ERROR]${C_RESET} $*" >&2; }

cleanup() {
    [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Clone repo to temp location
clone_repo() {
    log_info "Cloning ${C_CYAN}${UPSTREAM_URL}${C_RESET} (${BRANCH})..."
    
    if ! git clone --branch "$BRANCH" --depth 1 --quiet "$UPSTREAM_URL" "$TEMP_DIR" 2>&1; then
        log_error "Failed to clone repository"
        exit 1
    fi
    
    if [[ ! -d "$TEMP_DIR/cheats.d" ]]; then
        log_error "Repository cloned but cheats.d directory not found"
        exit 1
    fi
    
    log_info "Clone complete"
}

# Check for updates
cmd_check() {
    clone_repo
    
    log_info "Comparing with ${C_CYAN}${CHEATS_DIR}${C_RESET}..."
    echo
    
    local new=0 modified=0 unchanged=0 custom=0
    
    if [[ ! -d "$CHEATS_DIR" ]]; then
        local total
        total=$(find "$TEMP_DIR/cheats.d" -type f -name "*.md" | wc -l)
        echo "  ${C_GREEN}All ${total} files are new${C_RESET}"
        echo
        echo "  Run ${C_CYAN}cheats-updater.sh update${C_RESET} to download"
        return 0
    fi
    
    # Build list of official files
    declare -A official_files
    while IFS= read -r rel_path; do
        [[ -n "$rel_path" ]] && official_files["$rel_path"]=1
    done < <(find "$TEMP_DIR/cheats.d" -type f -name "*.md" -printf "%P\n" 2>/dev/null)
    
    # Check official files for updates (process substitution to avoid subshell)
    while IFS= read -r remote_file; do
        local rel_path="${remote_file#${TEMP_DIR}/cheats.d/}"
        local local_file="${CHEATS_DIR}/${rel_path}"
        
        if [[ ! -f "$local_file" ]]; then
            echo "  ${C_GREEN}+ ${rel_path}${C_RESET}"
            ((new++)) || true
        elif ! cmp -s "$remote_file" "$local_file"; then
            echo "  ${C_YELLOW}~ ${rel_path}${C_RESET}"
            ((modified++)) || true
        else
            ((unchanged++)) || true
        fi
    done < <(find "$TEMP_DIR/cheats.d" -type f -name "*.md" | sort)
    
    # Check for custom user files (process substitution to avoid subshell)
    while IFS= read -r local_file; do
        local rel_path="${local_file#${CHEATS_DIR}/}"
        if [[ ! -v official_files["$rel_path"] ]]; then
            echo "  ${C_BLUE}? ${rel_path}${C_RESET} (custom)"
            ((custom++)) || true
        fi
    done < <(find "$CHEATS_DIR" -type f -name "*.md" | sort)
    
    echo
    echo "  ${C_BOLD}Summary:${C_RESET}"
    echo "    ${C_GREEN}+${new}${C_RESET} new  ${C_YELLOW}~${modified}${C_RESET} modified  ${C_DIM}=${unchanged}${C_RESET} unchanged  ${C_BLUE}?${custom}${C_RESET} custom"
    echo
    if (( new + modified > 0 )); then
        echo "  Run ${C_CYAN}cheats-updater.sh update${C_RESET} to apply changes"
    else
        echo "  ${C_GREEN}Everything is up to date${C_RESET}"
    fi
}

# List all files
cmd_list() {
    clone_repo
    
    log_info "Listing all files..."
    echo
    
    echo "  ${C_BOLD}Official cheatsheets:${C_RESET}"
    find "$TEMP_DIR/cheats.d" -type f -name "*.md" -printf "    %P\n" | sort
    
    echo
}

# Update files - preserve custom cheats
cmd_update() {
    clone_repo
    
    # Create backup
    local backup_dir="${HOME}/.local/share/devtoolbox-cheats/backups/$(date +%Y-%m-%d-%H%M%S)"
    if [[ -d "$CHEATS_DIR" ]]; then
        log_info "Creating backup..."
        mkdir -p "$backup_dir"
        cp -a "$CHEATS_DIR/." "$backup_dir/"
        log_info "Backup saved to: ${backup_dir}"
    fi
    
    mkdir -p "$CHEATS_DIR"
    
    log_info "Updating official cheats to ${C_CYAN}${CHEATS_DIR}${C_RESET}..."
    echo
    
    local added=0 modified=0 unchanged=0
    
    # Get list of all remote files
    mapfile -t remote_files < <(find "$TEMP_DIR/cheats.d" -type f -name "*.md" | sort)
    
    # Process each file
    for remote_file in "${remote_files[@]}"; do
        local rel_path="${remote_file#${TEMP_DIR}/cheats.d/}"
        local local_file="${CHEATS_DIR}/${rel_path}"
        local local_dir
        local_dir="$(dirname "$local_file")"
        
        mkdir -p "$local_dir"
        
        if [[ ! -f "$local_file" ]]; then
            cp "$remote_file" "$local_file"
            echo "  ${C_GREEN}+ ${rel_path}${C_RESET}"
            ((added++)) || true
        elif ! cmp -s "$remote_file" "$local_file"; then
            cp "$remote_file" "$local_file"
            echo "  ${C_YELLOW}~ ${rel_path}${C_RESET}"
            ((modified++)) || true
        else
            ((unchanged++)) || true
        fi
    done
    
    echo
    echo "  ${C_BOLD}Results:${C_RESET}"
    echo "    ${C_GREEN}+${added}${C_RESET} new  ${C_YELLOW}~${modified}${C_RESET} modified  ${C_DIM}=${unchanged}${C_RESET} unchanged"
    echo
    echo "  ${C_GREEN}Update complete — Total: $((added + modified)) changed, ${unchanged} unchanged${C_RESET}"
    
    # Notification
    if command -v notify-send &>/dev/null; then
        notify-send "DevToolbox Cheats" "Updated: +${added} new, ~${modified} modified" 2>/dev/null || true
    fi
}

show_help() {
    cat <<EOF
${C_BOLD}cheats-updater.sh${C_RESET} v${VERSION}

${C_BOLD}USAGE${C_RESET}
    cheats-updater.sh <command>

${C_BOLD}COMMANDS${C_RESET}
    ${C_GREEN}check${C_RESET}       Check for updates
    ${C_GREEN}list${C_RESET}        List all official cheatsheets
    ${C_GREEN}update${C_RESET}      Update all official cheatsheets

${C_BOLD}ENVIRONMENT${C_RESET}
    CHEATS_DIR     Target directory (default: ~/cheats.d)

${C_BOLD}EXAMPLES${C_RESET}
    cheats-updater.sh check
    cheats-updater.sh update
    
    CHEATS_DIR=/custom/path cheats-updater.sh update

${C_BOLD}BACKUP${C_RESET}
    Automatic backup is created before every update:
    ~/.local/share/devtoolbox-cheats/backups/YYYY-MM-DD-HHMMSS/

EOF
}

# Check dependencies
for cmd in git find cp; do
    if ! command -v "$cmd" &>/dev/null; then
        log_error "Required command: ${cmd}"
        exit 1
    fi
done

case "${1:-}" in
    check)  cmd_check ;;
    list)   cmd_list ;;
    update) cmd_update ;;
    -h|--help) show_help ;;
    --version) echo "v${VERSION}"; exit 0 ;;
    *) show_help; exit 1 ;;
esac
