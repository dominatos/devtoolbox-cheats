#!/usr/bin/env bash
# cheats-updater.sh - Update manager for devtoolbox-cheats
set -euo pipefail

readonly VERSION="v1.5.2"
SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
readonly UPSTREAM_URL="https://github.com/dominatos/devtoolbox-cheats.git"
readonly BRANCH="main"
readonly CHEATS_DIR="${CHEATS_DIR:-$HOME/cheats.d}"
TEMP_DIR="$(mktemp -d /tmp/devtoolbox-cheats-XXXXXX)"
readonly TEMP_DIR

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
    [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
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
        echo "  Run ${C_CYAN}${SCRIPT_NAME} update${C_RESET} to download"
        return 0
    fi
    
    # Build list of official files
    declare -A official_files
    while IFS= read -r rel_path; do
        [[ -n "$rel_path" ]] && official_files["$rel_path"]=1
    done < <(find "$TEMP_DIR/cheats.d" -type f -name "*.md" -printf "%P\n" 2>/dev/null)
    
    # Check official files for updates (process substitution to avoid subshell)
    while IFS= read -r remote_file; do
        local rel_path="${remote_file#"${TEMP_DIR}"/cheats.d/}"
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
        local rel_path="${local_file#"${CHEATS_DIR}"/}"
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
        echo "  Run ${C_CYAN}${SCRIPT_NAME} update${C_RESET} to apply changes"
    else
        echo "  ${C_GREEN}Everything is up to date${C_RESET}"
    fi
}

# cmd_list lists all official Markdown cheatsheets from the upstream repository, sorted by relative path.
cmd_list() {
    clone_repo
    
    log_info "Listing all files..."
    echo
    
    echo "  ${C_BOLD}Official cheatsheets:${C_RESET}"
    find "$TEMP_DIR/cheats.d" -type f -name "*.md" -printf "    %P\n" | sort
    
    echo
}

# cmd_update updates official cheatsheets while preserving custom files and creating a backup of the existing cheatsheet directory.
cmd_update() {
    clone_repo
    
    # Create backup
    local backup_dir
    backup_dir="${HOME}/.local/share/devtoolbox-cheats/backups/$(date +%Y-%m-%d-%H%M%S)"
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
    local official_local_files=()
    
    # Get list of all remote files
    mapfile -t remote_files < <(find "$TEMP_DIR/cheats.d" -type f -name "*.md" | sort)
    
    # Process each file and accumulate official local paths
    for remote_file in "${remote_files[@]}"; do
        local rel_path="${remote_file#"${TEMP_DIR}"/cheats.d/}"
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
        [[ -f "$local_file" ]] && official_local_files+=("$local_file")
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
    
    # Auto-apply TOC formatting — official files only, never custom user files
    local toc_conf="${HOME}/.config/devtoolbox-cheats/toc_format.conf"
    local toc_format="obsidian"
    if [[ -s "$toc_conf" ]]; then
        local _fmt
        _fmt="$(tr -d '[:space:]' < "$toc_conf")"
        case "$_fmt" in
            obsidian|github) toc_format="$_fmt" ;;
        esac
    fi

    # Search for manage-tocs.py in known install locations
    local manage_tocs=""
    for candidate in \
        "$HOME/.local/share/devtoolbox-cheats/tools/manage-tocs.py" \
        "$HOME/devtoolbox-cheats/tools/manage-tocs.py" \
        "$(dirname "$(realpath -s "$0")")/tools/manage-tocs.py"; do
        if [[ -f "$candidate" ]]; then
            manage_tocs="$candidate"
            break
        fi
    done

    if [[ -n "$manage_tocs" ]] && command -v python3 &>/dev/null; then
        log_info "Applying TOC format (${C_CYAN}${toc_format}${C_RESET}) to official files only..."
        if (( ${#official_local_files[@]} > 0 )); then
            local out
            if ! out="$(python3 "$manage_tocs" --style "$toc_format" --files "${official_local_files[@]}" 2>&1)"; then
                log_error "TOC formatting failed:\n$out"
                if [[ -n "${backup_dir:-}" && -d "$backup_dir" ]]; then
                    log_warn "Restoring backup from ${backup_dir}..."
                    if [[ ! -d "$CHEATS_DIR" ]]; then
                        log_error "Cannot restore: CHEATS_DIR does not exist"
                    else
                        local staging_parent parent_dir
                        parent_dir="$(dirname -- "$CHEATS_DIR")"
                        if [[ "$parent_dir" == "/" ]]; then
                            log_error "Cannot stage recovery: parent of CHEATS_DIR is root"
                        else
                            staging_parent="$(mktemp -d "${parent_dir}/.staging.XXXXXX")" || {
                                log_error "Cannot create staging directory"
                            }
                        fi
                        if [[ -n "${staging_parent:-}" ]]; then
                            rollback_dir="${staging_parent}/rollback"
                            if mv -- "$CHEATS_DIR" "$rollback_dir" && cp -a -- "$backup_dir" "$CHEATS_DIR"; then
                                rm -rf -- "$staging_parent"
                                log_info "Backup restored"
                            else
                                log_error "Backup recovery failed, rolling back..."
                                rm -rf -- "$CHEATS_DIR"
                                mv -- "$rollback_dir" "$CHEATS_DIR" 2>/dev/null || true
                                rm -rf -- "$staging_parent"
                            fi
                        fi
                    fi
                fi
                exit 1
            else
                log_info "TOC formatting applied (${toc_format}, ${#official_local_files[@]} official files)"
            fi
        fi
    fi
}

show_help() {
    cat <<EOF
${C_BOLD}${SCRIPT_NAME}${C_RESET} ${VERSION}

${C_BOLD}USAGE${C_RESET}
    ${SCRIPT_NAME} <command>

${C_BOLD}COMMANDS${C_RESET}
    ${C_GREEN}check${C_RESET}       Check for updates
    ${C_GREEN}list${C_RESET}        List all official cheatsheets
    ${C_GREEN}update${C_RESET}      Update all official cheatsheets

${C_BOLD}ENVIRONMENT${C_RESET}
    CHEATS_DIR     Target directory (default: ~/cheats.d)

${C_BOLD}EXAMPLES${C_RESET}
    ${SCRIPT_NAME} check
    ${SCRIPT_NAME} update
    
    CHEATS_DIR=/custom/path ${SCRIPT_NAME} update

${C_BOLD}BACKUP${C_RESET}
    Automatic backup is created before every update:
    ~/.local/share/devtoolbox-cheats/backups/YYYY-MM-DD-HHMMSS/

EOF
}

# Check dependencies
for cmd in git find cp cmp; do
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
    --version) echo "${VERSION}"; exit 0 ;;
    *) show_help; exit 1 ;;
esac
