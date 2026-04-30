#!/usr/bin/env bash
# generate-tldr.sh - Generate native TLDR pages from DevToolbox Markdown cheatsheets
set -euo pipefail

readonly VERSION="2.0.0"

SOURCE_DIR="${SOURCE_DIR:-$HOME/cheats.d}"
OUTPUT_DIR="${OUTPUT_DIR:-$HOME/cheats.d-gen/tldr}"
CACHE_DIR="${TLDR_CACHE_DIR:-$HOME/.cache/tldr/pages}"
PLATFORM_DIR="${TLDR_PLATFORM_DIR:-common}"
DRY_RUN=0
CHECK_ONLY=0
VERBOSE=0
INSTALL_CACHE=1
MERGE_EXISTING=1

files_scanned=0
files_written=0
files_installed=0
examples_extracted=0
skipped_pairs=0
stale_files=0

usage() {
    cat <<EOF
generate-tldr.sh v${VERSION}

USAGE
    generate-tldr.sh [options]

OPTIONS
    --source-dir <path>      Source cheats directory (default: ~/cheats.d)
    --output-dir <path>      Staging directory root (default: ~/cheats.d-gen/tldr)
    --cache-dir <path>       TLDR cache pages root (default: ~/.cache/tldr/pages)
    --platform <name>        TLDR platform directory (default: common)
    --dry-run                Show planned actions without writing files
    --check                  Exit non-zero if staging or cache pages are missing or stale
    --verbose                Print per-file generation details
    --no-cache-install       Do not copy generated pages into the TLDR cache
    --overwrite-existing     Replace existing TLDR pages instead of merging into them
    -h, --help               Show this help
    --version                Show version

NOTES
    - Generates native TLDR pages under <output-dir>/pages/<platform>/
    - Merges generated examples into <cache-dir>/<platform>/ by default
    - Never modifies source Markdown files
EOF
}

log_info() {
    printf '[INFO] %s\n' "$*" >&2
}

log_warn() {
    printf '[WARN] %s\n' "$*" >&2
}

log_error() {
    printf '[ERROR] %s\n' "$*" >&2
}

meta_val() {
    local file="$1" key="$2"
    sed '1s/^\xEF\xBB\xBF//' "$file" | head -n 80 \
        | tr -d '\r' \
        | grep -i -m1 "^[[:space:]]*${key}[[:space:]]*:" \
        | sed -E 's/^[[:space:]]*[^:]+:[[:space:]]*//'
}

relative_path() {
    local path="$1"
    printf '%s\n' "${path#"$SOURCE_DIR"/}"
}

page_name_from_source() {
    local src="$1"
    local name
    name="$(basename "$src" .md)"
    name="${name%cheatsheet}"
    name="${name%_cheatsheet}"
    name="${name%-cheatsheet}"
    name="${name%_}"
    name="${name%-}"
    printf '%s\n' "${name,,}"
}

staging_page_path() {
    local page_name="$1"
    printf '%s/pages/%s/%s.md\n' "$OUTPUT_DIR" "$PLATFORM_DIR" "$page_name"
}

cache_page_path() {
    local page_name="$1"
    printf '%s/%s/%s.md\n' "$CACHE_DIR" "$PLATFORM_DIR" "$page_name"
}

print_summary() {
    printf 'Scanned: %d file(s)\n' "$files_scanned"
    printf 'Written: %d page(s)\n' "$files_written"
    printf 'Installed: %d page(s)\n' "$files_installed"
    printf 'Extracted: %d example(s)\n' "$examples_extracted"
    printf 'Skipped: %d malformed entr(y/ies)\n' "$skipped_pairs"
    if (( CHECK_ONLY )); then
        printf 'Stale/Missing: %d file(s)\n' "$stale_files"
    fi
}

parse_args() {
    while (($#)); do
        case "$1" in
            --source-dir)
                [[ $# -ge 2 ]] || { log_error "Missing value for --source-dir"; exit 1; }
                SOURCE_DIR="$2"
                shift 2
                ;;
            --output-dir)
                [[ $# -ge 2 ]] || { log_error "Missing value for --output-dir"; exit 1; }
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --cache-dir)
                [[ $# -ge 2 ]] || { log_error "Missing value for --cache-dir"; exit 1; }
                CACHE_DIR="$2"
                shift 2
                ;;
            --platform)
                [[ $# -ge 2 ]] || { log_error "Missing value for --platform"; exit 1; }
                PLATFORM_DIR="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --check)
                CHECK_ONLY=1
                shift
                ;;
            --verbose)
                VERBOSE=1
                shift
                ;;
            --no-cache-install)
                INSTALL_CACHE=0
                shift
                ;;
            --overwrite-existing)
                MERGE_EXISTING=0
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            --version)
                printf 'v%s\n' "$VERSION"
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                usage
                exit 1
                ;;
        esac
    done
}

validate_paths() {
    [[ -d "$SOURCE_DIR" ]] || { log_error "Source directory not found: $SOURCE_DIR"; exit 1; }
    [[ -r "$SOURCE_DIR" ]] || { log_error "Source directory is not readable: $SOURCE_DIR"; exit 1; }

    local output_parent
    output_parent="$(dirname "$OUTPUT_DIR")"
    [[ -d "$output_parent" ]] || mkdir -p "$output_parent"
    [[ -w "$output_parent" ]] || { log_error "Output parent directory is not writable: $output_parent"; exit 1; }

    if (( INSTALL_CACHE )); then
        local cache_parent
        cache_parent="$(dirname "$CACHE_DIR")"
        [[ -d "$cache_parent" ]] || mkdir -p "$cache_parent"
        [[ -w "$cache_parent" ]] || { log_error "Cache parent directory is not writable: $cache_parent"; exit 1; }
    fi
}

generate_file_content() {
    local src="$1" page_name="$2"
    local title source_uri
    title="$(meta_val "$src" 'Title' | tr -d '\r')"
    [[ -n "$title" ]] || title="$(basename "$src" .md)"
    source_uri="file://${src}"

    awk -v page_name="$page_name" -v source_title="$title" -v source_uri="$source_uri" '
        function trim(s) {
            sub(/^[[:space:]]+/, "", s)
            sub(/[[:space:]]+$/, "", s)
            return s
        }

        function first_language(s) {
            s = trim(s)
            sub(/^[#>![:space:]-]+/, "", s)
            split(s, parts, /[[:space:]]+\/[[:space:]]+/)
            return trim(parts[1])
        }

        function normalize_placeholders(cmd,   before, placeholder, after, inside) {
            cmd = trim(cmd)
            while (match(cmd, /<[^>]+>/)) {
                before = substr(cmd, 1, RSTART - 1)
                placeholder = substr(cmd, RSTART, RLENGTH)
                after = substr(cmd, RSTART + RLENGTH)
                inside = placeholder
                gsub(/^</, "", inside)
                gsub(/>$/, "", inside)
                cmd = before "{{" inside "}}" after
            }
            return trim(cmd)
        }

        function emit_example(desc, cmd) {
            desc = first_language(desc)
            cmd = normalize_placeholders(cmd)

            if (desc == "" || cmd == "") {
                skipped++
                return
            }

            print "- " desc
            print ""
            print "`" cmd "`"
            print ""
            examples++
        }

        BEGIN {
            print "# " page_name
            print ""
            print "> Generated from DevToolbox cheatsheet: " source_title "."
            print "> More information: <" source_uri ">."
            print ""

            examples = 0
            skipped = 0
            in_code = 0
            pending_desc = ""
            pending_cmd = ""
        }

        {
            gsub(/\r/, "", $0)

            if (NR <= 80 && $0 ~ /^[[:space:]]*(Title|Group|Icon|Order)[[:space:]]*:/) {
                next
            }

            line = $0

            if (line ~ /^```/) {
                if (in_code) {
                    if (pending_desc != "") {
                        skipped++
                        pending_desc = ""
                    }
                    in_code = 0
                } else {
                    in_code = 1
                }
                next
            }

            if (in_code) {
                if (trim(line) == "") {
                    next
                }

                if (line ~ /^[[:space:]]*#/) {
                    pending_desc = line
                    next
                }

                inline_desc = ""
                cmd = line

                if (match(line, /^[[:space:]]*(.*[^[:space:]])[[:space:]]+#(.*)$/, parts)) {
                    cmd = parts[1]
                    inline_desc = parts[2]
                }

                cmd = trim(cmd)
                if (cmd == "") {
                    next
                }

                if (inline_desc != "") {
                    emit_example(inline_desc, cmd)
                    pending_desc = ""
                } else if (pending_desc != "") {
                    emit_example(pending_desc, cmd)
                    pending_desc = ""
                } else {
                    skipped++
                }
                next
            }

            if (trim(line) == "") {
                pending_cmd = ""
                next
            }

            if (line ~ /^[[:space:]]*#/) {
                if (pending_cmd != "") {
                    emit_example(line, pending_cmd)
                    pending_cmd = ""
                }
                next
            }

            if (line ~ /^[[:space:]]*[>|-]/ || line ~ /^[[:space:]]*\|/ || line ~ /^[[:space:]]*##/) {
                pending_cmd = ""
                next
            }

            pending_cmd = trim(line)
        }

        END {
            if (pending_desc != "") {
                skipped++
            }
            if (pending_cmd != "") {
                skipped++
            }

            print "__SUMMARY__\t" examples "\t" skipped > "/dev/stderr"
        }
    ' "$src"
}

merge_page_content() {
    local existing_path="$1" generated_content="$2"

    if [[ ! -f "$existing_path" ]]; then
        printf '%s\n' "$generated_content"
        return
    fi

    awk '
        function flush_block(    cmd) {
            if (block == "") {
                return
            }

            cmd = ""
            if (match(block, /`[^`\n]+`/)) {
                cmd = substr(block, RSTART + 1, RLENGTH - 2)
            }

            if (cmd != "" && !(cmd in seen)) {
                appended[++append_count] = block
                seen[cmd] = 1
            }
            block = ""
        }

        FNR == NR {
            existing = existing $0 ORS
            if (match($0, /^`[^`\n]+`$/)) {
                cmd = substr($0, 2, length($0) - 2)
                seen[cmd] = 1
            }
            next
        }

        /^- / {
            flush_block()
            in_examples = 1
            block = $0 ORS
            next
        }

        {
            if (in_examples) {
                block = block $0 ORS
            }
        }

        END {
            flush_block()
            printf "%s", existing
            if (append_count > 0) {
                if (existing !~ /\n$/) {
                    printf "\n"
                }
                printf "\n<!-- Appended from DevToolbox -->\n\n"
                for (i = 1; i <= append_count; i++) {
                    printf "%s", appended[i]
                }
            }
        }
    ' "$existing_path" <(printf '%s\n' "$generated_content")
}

compare_content() {
    local expected="$1" actual_path="$2" label="$3"
    if [[ ! -f "$actual_path" ]]; then
        log_warn "Missing ${label}: $actual_path"
        stale_files=$((stale_files + 1))
        return
    fi

    if ! diff -u "$actual_path" <(printf '%s\n' "$expected") >/dev/null 2>&1; then
        log_warn "Stale ${label}: $actual_path"
        stale_files=$((stale_files + 1))
    elif (( VERBOSE )); then
        log_info "Up to date ${label}: $actual_path"
    fi
}

write_output_file() {
    local src="$1" page_name="$2" staging_dest="$3" cache_dest="$4"
    local tmp_file generated final_staging final_cache summary_line examples skipped
    tmp_file="$(mktemp)"

    if ! generated="$(generate_file_content "$src" "$page_name" 2> "$tmp_file")"; then
        rm -f "$tmp_file"
        log_error "Failed to generate content for $(relative_path "$src")"
        exit 1
    fi

    summary_line="$(grep '^__SUMMARY__' "$tmp_file" | tail -n1 || true)"
    if [[ -z "$summary_line" ]]; then
        rm -f "$tmp_file"
        log_error "Internal summary missing for $(relative_path "$src")"
        exit 1
    fi

    examples="$(printf '%s\n' "$summary_line" | cut -f2)"
    skipped="$(printf '%s\n' "$summary_line" | cut -f3)"
    examples_extracted=$((examples_extracted + examples))
    skipped_pairs=$((skipped_pairs + skipped))

    if (( VERBOSE )); then
        log_info "Generated $(relative_path "$src") -> ${page_name}.md (${examples} examples)"
        if (( skipped > 0 )); then
            log_warn "$(relative_path "$src"): skipped ${skipped} malformed entr(y/ies)"
        fi
    fi

    if (( DRY_RUN )); then
        if (( MERGE_EXISTING )); then
            printf 'DRY-RUN merge %s\n' "$staging_dest"
        else
            printf 'DRY-RUN write %s\n' "$staging_dest"
        fi
        files_written=$((files_written + 1))
        if (( INSTALL_CACHE )); then
            if (( MERGE_EXISTING )); then
                printf 'DRY-RUN merge-install %s\n' "$cache_dest"
            else
                printf 'DRY-RUN install %s\n' "$cache_dest"
            fi
            files_installed=$((files_installed + 1))
        fi
        rm -f "$tmp_file"
        return
    fi

    mkdir -p "$(dirname "$staging_dest")"
    if (( MERGE_EXISTING )); then
        final_staging="$(merge_page_content "$staging_dest" "$generated")"
    else
        final_staging="$generated"
    fi

    printf '%s\n' "$final_staging" > "$staging_dest"
    files_written=$((files_written + 1))

    if (( INSTALL_CACHE )); then
        mkdir -p "$(dirname "$cache_dest")"
        if (( MERGE_EXISTING )); then
            final_cache="$(merge_page_content "$cache_dest" "$generated")"
            printf '%s\n' "$final_cache" > "$cache_dest"
        else
            cp "$staging_dest" "$cache_dest"
        fi
        files_installed=$((files_installed + 1))
    fi

    rm -f "$tmp_file"
}

check_output_file() {
    local src="$1" page_name="$2" staging_dest="$3" cache_dest="$4"
    local tmp_file generated expected_staging expected_cache summary_line examples skipped
    tmp_file="$(mktemp)"

    if ! generated="$(generate_file_content "$src" "$page_name" 2> "$tmp_file")"; then
        rm -f "$tmp_file"
        log_error "Failed to generate comparison content for $(relative_path "$src")"
        exit 1
    fi

    summary_line="$(grep '^__SUMMARY__' "$tmp_file" | tail -n1 || true)"
    examples="$(printf '%s\n' "$summary_line" | cut -f2)"
    skipped="$(printf '%s\n' "$summary_line" | cut -f3)"
    examples_extracted=$((examples_extracted + examples))
    skipped_pairs=$((skipped_pairs + skipped))

    if (( MERGE_EXISTING )); then
        expected_staging="$(merge_page_content "$staging_dest" "$generated")"
    else
        expected_staging="$generated"
    fi

    compare_content "$expected_staging" "$staging_dest" "staging page"

    if (( INSTALL_CACHE )); then
        if (( MERGE_EXISTING )); then
            expected_cache="$(merge_page_content "$cache_dest" "$generated")"
        else
            expected_cache="$generated"
        fi
        compare_content "$expected_cache" "$cache_dest" "cache page"
    fi

    rm -f "$tmp_file"
}

main() {
    parse_args "$@"
    validate_paths

    mapfile -t source_files < <(find -L "$SOURCE_DIR" -type f -name '*.md' | sort -f)
    files_scanned="${#source_files[@]}"

    local staging_platform_dir
    staging_platform_dir="$OUTPUT_DIR/pages/$PLATFORM_DIR"

    if (( CHECK_ONLY == 0 && DRY_RUN == 0 )); then
        rm -rf "$staging_platform_dir"
        mkdir -p "$staging_platform_dir"
    fi

    local src page_name staging_dest cache_dest
    for src in "${source_files[@]}"; do
        page_name="$(page_name_from_source "$src")"
        staging_dest="$(staging_page_path "$page_name")"
        cache_dest="$(cache_page_path "$page_name")"

        if (( CHECK_ONLY )); then
            check_output_file "$src" "$page_name" "$staging_dest" "$cache_dest"
        else
            write_output_file "$src" "$page_name" "$staging_dest" "$cache_dest"
        fi
    done

    print_summary

    if (( CHECK_ONLY )) && (( stale_files > 0 )); then
        exit 1
    fi
}

main "$@"
