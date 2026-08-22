#!/bin/bash
# macOS-beta/cheats-updater.sh — standalone macOS cheatsheet updater
# This script intentionally contains its own update flow so the installed
# ~/.local/bin/cheats-updater command has no runtime dependency on Linux files.
#
# Requires: Bash 4+ (macOS ships with 3.2)
# This script auto-detects and re-executes with Homebrew Bash if needed.

# --- Auto-detect Bash 4+ and re-exec if needed ---
if [[ "${BASH_VERSINFO[0]:-0}" -lt 4 ]]; then
    for bash_path in /opt/homebrew/bin/bash /usr/local/bin/bash /opt/local/bin/bash; do
        if [[ -x "$bash_path" ]]; then
            exec "$bash_path" "$0" "$@"
        fi
    done
    echo "ERROR: Bash 4+ required. Install with: brew install bash" >&2
    exit 1
fi

set -euo pipefail

readonly VERSION="v1.5.5"
SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
readonly UPSTREAM_URL="https://github.com/dominatos/devtoolbox-cheats.git"
readonly BRANCH="main"
readonly CHEATS_DIR="${CHEATS_DIR:-$HOME/cheats.d}"
TEMP_DIR="$(mktemp -d /tmp/devtoolbox-cheats-XXXXXX)"
readonly TEMP_DIR
readonly PLATFORM="macos"

# ============= Colors =============
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

# Clone the upstream repository into the per-invocation temporary directory.
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

# ============= Override: find -printf =============
# macOS find doesn't support -printf; use sed to strip leading ./
find_relative_paths() {
  local base_dir="$1"
  if [[ "$PLATFORM" == "macos" ]]; then
    (cd "$base_dir" && find . -type f -name "*.md" | sed 's|^\./||' | sort)
  else
    find "$base_dir" -type f -name "*.md" -printf "%P\n" 2>/dev/null | sort
  fi
}

find_full_paths() {
  local base_dir="$1"
  find "$base_dir" -type f -name "*.md" 2>/dev/null | sort
}

# ============= Override: declare -A official_files =============
# Use indexed array with helper function for lookup
_official_files_paths=()

is_not_official_file() {
  local rel_path="$1"
  local found=0
  for path in "${_official_files_paths[@]}"; do
    if [[ "$path" == "$rel_path" ]]; then
      found=1
      break
    fi
  done
  (( ! found ))
}

# ============= Override: cp -a =============
compat_cp_archive() {
  if [[ "$PLATFORM" == "macos" ]]; then
    cp -rp "$@"
  else
    cp -a "$@"
  fi
}

# ============= Override: realpath =============
compat_realpath_s() {
  local path="$1"
  if [[ "$PLATFORM" == "macos" ]]; then
    if command -v grealpath >/dev/null 2>&1; then
      grealpath -s "$path" 2>/dev/null || echo "$path"
    elif command -v python3 >/dev/null 2>&1; then
      python3 -c "import os; print(os.path.realpath('$path'))" 2>/dev/null || echo "$path"
    else
      echo "$path"
    fi
  else
    realpath -s "$path" 2>/dev/null || echo "$path"
  fi
}

# ============= Override: notify-send =============
compat_notify_send() {
  local title="$1" msg="$2"
  if [[ "$PLATFORM" == "macos" ]]; then
    if command -v osascript >/dev/null 2>&1; then
      osascript -e "display notification \"$msg\" with title \"$title\"" 2>/dev/null || true
    fi
  else
    notify-send "$title" "$msg" 2>/dev/null || true
  fi
}

# ============= Override: cmd_check() =============
cmd_check() {
    clone_repo

    log_info "Comparing with ${C_CYAN}${CHEATS_DIR}${C_RESET}..."
    echo

    local new=0 modified=0 unchanged=0 custom=0

    if [[ ! -d "$CHEATS_DIR" ]]; then
        local total
        total=$(find_full_paths "$TEMP_DIR/cheats.d" | wc -l)
        echo "  ${C_GREEN}All ${total} files are new${C_RESET}"
        echo
        echo "  Run ${C_CYAN}${SCRIPT_NAME} update${C_RESET} to download"
        return 0
    fi

    _official_files_paths=()
    while IFS= read -r rel_path; do
        [[ -n "$rel_path" ]] && _official_files_paths+=("$rel_path")
    done < <(find_relative_paths "$TEMP_DIR/cheats.d")

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
    done < <(find_full_paths "$TEMP_DIR/cheats.d" | sort)

    while IFS= read -r local_file; do
        local rel_path="${local_file#"${CHEATS_DIR}"/}"
        if is_not_official_file "$rel_path"; then
            echo "  ${C_BLUE}? ${rel_path}${C_RESET} (custom)"
            ((custom++)) || true
        fi
    done < <(find_full_paths "$CHEATS_DIR" | sort)

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

# ============= Override: cmd_list() =============
cmd_list() {
    clone_repo

    log_info "Listing all files..."
    echo

    echo "  ${C_BOLD}Official cheatsheets:${C_RESET}"
    find_relative_paths "$TEMP_DIR/cheats.d" | while read -r rel_path; do
        echo "    $rel_path"
    done

    echo
}

# ============= Override: cmd_update() =============
cmd_update() {
    clone_repo

    local backup_dir
    backup_dir="${HOME}/.local/share/devtoolbox-cheats/backups/$(date +%Y-%m-%d-%H%M%S)"
    if [[ -d "$CHEATS_DIR" ]]; then
        log_info "Creating backup..."
        mkdir -p "$backup_dir"
        compat_cp_archive "$CHEATS_DIR/." "$backup_dir/"
        log_info "Backup saved to: ${backup_dir}"
    fi

    mkdir -p "$CHEATS_DIR"

    log_info "Updating official cheats to ${C_CYAN}${CHEATS_DIR}${C_RESET}..."
    echo

    local added=0 modified=0 unchanged=0
    local official_local_files=()

    local remote_files=()
    while IFS= read -r file; do
        remote_files+=("$file")
    done < <(find_full_paths "$TEMP_DIR/cheats.d" | sort)

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
    compat_notify_send "DevToolbox Cheats" "Updated: +${added} new, ~${modified} modified"

    # Auto-apply TOC formatting
    local toc_conf="${HOME}/.config/devtoolbox-cheats/toc_format.conf"
    local toc_format="obsidian"
    if [[ -s "$toc_conf" ]]; then
        local _fmt
        _fmt="$(tr -d '[:space:]' < "$toc_conf")"
        case "$_fmt" in
            obsidian|github) toc_format="$_fmt" ;;
        esac
    fi

    # Search for manage-tocs.py
    local manage_tocs=""
    for candidate in \
        "$HOME/.local/share/devtoolbox-cheats/tools/manage-tocs.py" \
        "$HOME/devtoolbox-cheats/tools/manage-tocs.py" \
        "$(dirname "$(compat_realpath_s "$0")")/tools/manage-tocs.py"; do
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
                exit 1
            else
                log_info "TOC formatting applied (${toc_format}, ${#official_local_files[@]} official files)"
            fi
        fi
    fi
}

# ============= Show Help =============
show_help() {
    cat <<EOF
${C_BOLD}${SCRIPT_NAME}${C_RESET} ${VERSION} (macOS)

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

# ============= Main Entry Point =============
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
