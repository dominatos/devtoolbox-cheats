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
        log_error "Check your internet connection and try again"
        exit 1
    fi
    
    if [[ ! -d "$TEMP_DIR/cheats.d" ]]; then
        log_error "Repository cloned but cheats.d directory not found"
        exit 1
    fi
    
    log_info "Clone complete"
}

# Compare and show differences using diff
cmd_check() {
    clone_repo
    
    log_info "Comparing with ${C_CYAN}${CHEATS_DIR}${C_RESET}..."
    echo
    
    local new=0 modified=0 unchanged=0
    
    # Find files only in remote (new files)
    while IFS= read -r -d '' remote_file; do
        local rel_path="${remote_file#${TEMP_DIR}/cheats.d/}"
        local local_file="${CHEATS_DIR}/${rel_path}"
        
        if [[ ! -f "$local_file" ]]; then
            echo "  ${C_GREEN}+ ${rel_path}${C_RESET} (new)"
            ((new++))
        fi
    done < <(find "$TEMP_DIR/cheats.d" -type f -name "*.md" -print0)
    
    # Compare existing files using diff
    if [[ -d "$CHEATS_DIR" ]]; then
        while IFS= read -r line; do
            # diff output: "Files <path1> and <path2> differ"
            if [[ "$line" =~ Files\ (.*)\ and\ (.*)\ differ ]]; then
                local file1="${BASH_REMATCH[1]}"
                local rel_path="${file1#${TEMP_DIR}/cheats.d/}"
                echo "  ${C_YELLOW}~ ${rel_path}${C_RESET} (modified)"
                ((modified++))
            fi
        done < <(diff -qr "$TEMP_DIR/cheats.d" "$CHEATS_DIR" 2>/dev/null | grep "^Files.*differ" || true)
        
        # Count unchanged files
        unchanged=$(find "$TEMP_DIR/cheats.d" -type f -name "*.md" | wc -l)
        unchanged=$((unchanged - new - modified))
    else
        # If CHEATS_DIR doesn't exist, all files are new
        new=$(find "$TEMP_DIR/cheats.d" -type f -name "*.md" | wc -l)
        unchanged=0
    fi
    
    echo
    echo "  ${C_BOLD}Summary:${C_RESET} ${C_GREEN}+${new} new${C_RESET} | ${C_YELLOW}~${modified} modified${C_RESET} | ${unchanged} unchanged"
    echo
    
    if ((new + modified > 0)); then
        echo "  Run ${C_CYAN}cheats-updater.sh update${C_RESET} to apply changes"
        return 1
    else
        echo "  ${C_GREEN}? Already up to date${C_RESET}"
        return 0
    fi
}

# List detailed changes using diff
cmd_list() {
    clone_repo
    
    log_info "Listing changes..."
    echo
    
    # Find new files
    while IFS= read -r -d '' remote_file; do
        local rel_path="${remote_file#${TEMP_DIR}/cheats.d/}"
        local local_file="${CHEATS_DIR}/${rel_path}"
        
        if [[ ! -f "$local_file" ]]; then
            echo "${C_GREEN}+++ NEW: ${rel_path}${C_RESET}"
            echo "    $(head -1 "$remote_file" | sed 's/^[#* ]*//')"
            
            local file_size=$(wc -c < "$remote_file")
            echo "    Size: ${file_size} bytes"
            echo
        fi
    done < <(find "$TEMP_DIR/cheats.d" -type f -name "*.md" -print0)
    
    # Find modified files and show diffs
    if [[ -d "$CHEATS_DIR" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ Files\ (.*)\ and\ (.*)\ differ ]]; then
                local remote_file="${BASH_REMATCH[1]}"
                local local_file="${BASH_REMATCH[2]}"
                local rel_path="${remote_file#${TEMP_DIR}/cheats.d/}"
                
                echo "${C_YELLOW}=== MODIFIED: ${rel_path}${C_RESET}"
                
                # Show size difference
                local local_size=$(wc -c < "$local_file")
                local remote_size=$(wc -c < "$remote_file")
                local size_diff=$((remote_size - local_size))
                
                if ((size_diff > 0)); then
                    echo "    Size: ${local_size} > ${remote_size} bytes (${C_GREEN}+${size_diff}${C_RESET})"
                elif ((size_diff < 0)); then
                    echo "    Size: ${local_size} > ${remote_size} bytes (${C_RED}${size_diff}${C_RESET})"
                else
                    echo "    Size: ${local_size} bytes (content changed)"
                fi
                
                # Show diff snippet
                echo "    ${C_DIM}Diff preview:${C_RESET}"
                diff -u "$local_file" "$remote_file" 2>/dev/null | head -25 | tail -n +3 | sed 's/^/      /' || echo "      (binary or large diff)"
                echo
            fi
        done < <(diff -qr "$TEMP_DIR/cheats.d" "$CHEATS_DIR" 2>/dev/null | grep "^Files.*differ" || true)
    fi
}

# Update files
cmd_update() {
    clone_repo
    
    # Create backup
    local backup_dir="${HOME}/.local/share/devtoolbox-cheats/backups/$(date +%Y-%m-%d-%H%M%S)"
    if [[ -d "$CHEATS_DIR" ]]; then
        log_info "Creating backup to ${C_DIM}${backup_dir}${C_RESET}..."
        mkdir -p "$backup_dir"
        cp -a "$CHEATS_DIR" "$backup_dir/" 2>/dev/null || true
    fi
    
    # Ensure target directory exists
    mkdir -p "$CHEATS_DIR"
    
    local updated=0 added=0 skipped=0
    
    log_info "Updating cheats..."
    echo
    
    # Copy all files from remote
    while IFS= read -r -d '' remote_file; do
        local rel_path="${remote_file#${TEMP_DIR}/cheats.d/}"
        local local_file="${CHEATS_DIR}/${rel_path}"
        local local_dir="$(dirname "$local_file")"
        
        mkdir -p "$local_dir"
        
        if [[ ! -f "$local_file" ]]; then
            cp "$remote_file" "$local_file"
            echo "  ${C_GREEN}+ ${rel_path}${C_RESET}"
            ((added++))
        elif ! diff -q "$remote_file" "$local_file" >/dev/null 2>&1; then
            cp "$remote_file" "$local_file"
            echo "  ${C_YELLOW}~ ${rel_path}${C_RESET}"
            ((updated++))
        else
            ((skipped++))
        fi
    done < <(find "$TEMP_DIR/cheats.d" -type f -name "*.md" -print0 | sort -z)
    
    echo
    echo "  ${C_BOLD}Results:${C_RESET} ${C_GREEN}+${added} added${C_RESET} | ${C_YELLOW}~${updated} modified${C_RESET} | ${skipped} unchanged"
    echo
    echo "  ${C_GREEN}? Update complete${C_RESET}"
    
    # Notification
    if command -v notify-send &>/dev/null; then
        notify-send "DevToolbox Cheats" "? Updated: +${added} new, ~${updated} modified" 2>/dev/null || true
    fi
}

show_help() {
    cat <<EOF
${C_BOLD}cheats-updater.sh${C_RESET} v${VERSION}

${C_BOLD}USAGE${C_RESET}
    cheats-updater.sh <command>

${C_BOLD}COMMANDS${C_RESET}
    ${C_GREEN}check${C_RESET}       Check for updates (shows summary)
    ${C_GREEN}list${C_RESET}        Show detailed changes with diffs
    ${C_GREEN}update${C_RESET}      Apply updates to local cheats

${C_BOLD}ENVIRONMENT${C_RESET}
    CHEATS_DIR     Target directory (default: ~/cheats.d)

${C_BOLD}EXAMPLES${C_RESET}
    cheats-updater.sh check
    cheats-updater.sh list
    cheats-updater.sh update
    
    CHEATS_DIR=/custom/path cheats-updater.sh update

${C_BOLD}REQUIREMENTS${C_RESET}
    git, diff, find

EOF
}

# Check dependencies
for cmd in git diff find; do
    if ! command -v "$cmd" &>/dev/null; then
        log_error "Required command not found: ${cmd}"
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
