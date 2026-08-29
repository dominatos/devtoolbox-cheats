#!/usr/bin/env bash
# <xbar.title>Dev Toolbox</xbar.title>
# <xbar.version>v1.5.6</xbar.version>
# <xbar.author>Sviatoslav</xbar.author>
# <xbar.author.github>dominatos</xbar.author.github>
# <xbar.abouturl>https://github.com/dominatos/devtoolbox-cheats</xbar.abouturl>

# macOS-beta/devtools.1m.sh — standalone macOS tools menu for SwiftBar
# This script intentionally contains its own platform logic and does not
# source Linux runtime scripts or a compatibility shim.
#
# Requires: Bash 4+ (macOS ships with 3.2)
# This script auto-detects and re-executes with Homebrew/MacPorts Bash if needed.

if [[ "${BASH_VERSINFO[0]:-0}" -lt 4 ]]; then
    # Loop protection: the flag is only meaningful while still on Bash < 4.
    # A successful re-exec inherits it but exits this branch immediately.
    if [[ -n "${_DEVTOOLBOX_BASH_REEXEC:-}" ]]; then
        echo "ERROR: Bash 4+ required but re-exec already attempted." >&2
        echo "Install a modern Bash first: brew install bash" >&2
        exit 1
    fi
    # Verify each candidate really provides Bash 4+ before exec'ing into it.
    for bash_path in /opt/homebrew/bin/bash /usr/local/bin/bash /opt/local/bin/bash; do
        # shellcheck disable=SC2016  # must stay single-quoted: evaluated by the candidate bash
        if [[ -x "$bash_path" ]] && "$bash_path" -c '[[ "${BASH_VERSINFO[0]:-0}" -ge 4 ]]' 2>/dev/null; then
            export _DEVTOOLBOX_BASH_REEXEC=1
            # Ensure the re-exec uses an absolute path in case xbar invoked us with a relative path
            _script_path="$0"
            [[ "$_script_path" != /* ]] && _script_path="$PWD/$_script_path"
            exec "$bash_path" "$_script_path" "$@"
        fi
    done
    echo "ERROR: Bash 4+ required." >&2
    echo "  Install with Homebrew: brew install bash" >&2
    echo "  Or with MacPorts:      sudo port install bash" >&2
    exit 1
fi

set -euo pipefail

# Package-manager tools may live outside xbar's minimal PATH.
export PATH="/opt/homebrew/bin:/opt/local/bin:/usr/local/bin:$PATH"

# Resolve symlink so xbar actions point at the real script location.
SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE" ]]; do
    SCRIPT_DIR="$(cd "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="$SCRIPT_DIR/$SOURCE"
done
SCRIPT_DIR="$(cd "$(dirname "$SOURCE")" && pwd)"

# Maintained by bump-version.sh — used for consistency across all project scripts
VERSION="v1.5.6"

# ============= Dependency Validation =============
# Hard requirements: clipboard (the plugin cannot function without them).
# Everything else is validated per-action so a missing optional tool
# degrades gracefully instead of killing the whole plugin.
missing_deps=()
for dep in pbcopy pbpaste; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        missing_deps+=("$dep")
    fi
done
if (( ${#missing_deps[@]} > 0 )); then
    echo "❌ Missing required tools: ${missing_deps[*]}" >&2
    exit 1
fi

# Per-action dependency guard: reports via notification instead of letting
# require_action_tool verifies that a required command is available and notifies the user when it is missing.
require_action_tool() {
    local cmd="$1" action_label="$2"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        notify "$action_label" "❌ Required tool '$cmd' is not installed"
        return 1
    fi
    return 0
}

# clip_read reads the current clipboard contents and writes them to standard output.
clip_read()  { pbpaste; }
# clip_write writes input to the macOS clipboard.
clip_write() { pbcopy; }

# notify displays a macOS notification with the specified subtitle and message.
notify() {
    osascript - "$1" "$2" <<'APPLESCRIPT' >/dev/null 2>&1 || true
on run argv
    display notification (item 2 of argv) with title "Dev Toolbox" subtitle (item 1 of argv)
end run
APPLESCRIPT
}

# popup displays a macOS dialog with the specified title and body, truncating bodies longer than 4000 characters.
popup() {
    # Truncate the raw body BEFORE escaping so truncation cannot split an
    # escape sequence; pass values through argv, never interpolated source.
    local title="$1" body="$2"
    if (( ${#body} > 4000 )); then
        body="${body:0:4000}"$'\n… (truncated — full result copied to clipboard)'
    fi
    osascript - "$title" "$body" <<'APPLESCRIPT' >/dev/null 2>&1 || true
on run argv
    display dialog (item 2 of argv) with title ("Dev Toolbox: " & (item 1 of argv)) buttons {"Close"} default button 1
end run
APPLESCRIPT
}

# show displays piped input, copies it to the clipboard, and notifies the user of the result.
show() {
  local title="$1"
  local result
  result="$(cat)" || true
  printf '%s\n' "$result" | clip_write
  notify "$title" "Result copied to clipboard"
  popup "$title" "$result"
}

# jsonFormat formats the clipboard's JSON content and displays the result.
jsonFormat()      { clip_read | jq .       | show "Formatted JSON"; }
# jsonMinify minifies the JSON content from the clipboard and displays the result.
jsonMinify()      { clip_read | jq -c .    | show "Minified JSON"; }
# jsonEscape escapes the clipboard contents as a JSON string and displays the result.
jsonEscape()      { clip_read | jq -Rs @json | show "Escaped JSON"; }
# jsonUnescape unescapes JSON content from the clipboard and displays the result.
jsonUnescape()    { clip_read | jq -r .    | show "Unescaped JSON"; }

# base64Encode encodes the clipboard contents as Base64 and displays the result.
base64Encode()    { clip_read | base64     | show "Base64 Encoded"; }

# base64_decode_payload decodes a Base64-encoded payload and writes the decoded value to standard output.
base64_decode_payload() {
  # macOS base64 historically decodes with -D; newer builds accept -d.
  # Success is judged by exit status alone: valid inputs may decode to
  # empty output.
  local payload="$1" out=""
  if out="$(printf '%s' "$payload" | base64 -d 2>/dev/null)"; then
    printf '%s' "$out"
    return 0
  elif out="$(printf '%s' "$payload" | base64 -D 2>/dev/null)"; then
    printf '%s' "$out"
    return 0
  fi
  return 1
}

# base64Decode decodes the clipboard contents from Base64 and displays the result, or notifies the user when the input is invalid.
base64Decode() {
  local input decoded
  input="$(clip_read)"
  if decoded="$(base64_decode_payload "$input")"; then
    printf '%s' "$decoded" | show "Base64 Decoded"
  else
    notify "Base64 Decoded" "❌ Invalid input"
    return 0
  fi
}

# urlEncode encodes the clipboard contents as a URL-safe string and displays the result.
urlEncode()       { clip_read | jq -sRr @uri | show "URL Encoded"; }
# urlDecode decodes percent-encoded clipboard text and displays the result.
urlDecode() {
  # python3 handles %-decoding reliably on macOS (no GNU sed/printf quirks).
  clip_read | python3 -c 'import sys,urllib.parse; sys.stdout.write(urllib.parse.unquote(sys.stdin.read()))' | show "URL Decoded"
}

# unixToLocal converts the Unix timestamp from the clipboard to a local date and time.
unixToLocal()     { date -r "$(clip_read)" +%Y-%m-%dT%H:%M:%S | show "Local Timestamp"; }
# unixToUTC converts the clipboard's Unix timestamp to a UTC timestamp and displays the result.
unixToUTC()       { date -u -r "$(clip_read)" +%Y-%m-%dT%H:%M:%SZ | show "UTC Timestamp"; }
# currentUnix outputs the current Unix timestamp, copies it to the clipboard, and displays it.
currentUnix()     { date +%s | show "Current Unix Timestamp"; }

# uuidGen generates a UUID, copies it to the clipboard, and displays it.
uuidGen()         { uuidgen | show "Generated UUID"; }
# uuidShort generates a short random hexadecimal ID and displays it as “Short ID”.
uuidShort()       { openssl rand -hex 4 | show "Short ID"; }

# jwtDecode decodes the JSON payload from the JWT stored in the clipboard and displays it.
# jwtDecode decodes the JSON payload from a JWT copied to the clipboard and displays it formatted.
jwtDecode() {
  local input segments payload b64 decoded
  input="$(clip_read)"
  IFS='.' read -r -a segments <<<"$input"
  if (( ${#segments[@]} != 3 )) || [[ -z "${segments[1]}" ]]; then
    notify "JWT Decode" "❌ Invalid token shape (expected header.payload.signature)"
    return 0
  fi
  payload="${segments[1]}"
  # Base64url → standard base64, restore padding.
  b64="$(printf '%s' "$payload" | tr '_-' '/+')"
  case $(( ${#b64} % 4 )) in
    2) b64="${b64}==" ;;
    3) b64="${b64}=" ;;
  esac
  if ! decoded="$(base64_decode_payload "$b64")"; then
    notify "JWT Decode" "❌ Payload is not valid base64"
    return 0
  fi
  # A syntactically valid JWT payload is always a JSON object; anything else
  # is reported instead of letting jq fail under set -euo pipefail.
  if ! printf '%s' "$decoded" | jq -e . >/dev/null 2>&1; then
    notify "JWT Decode" "❌ Decoded payload is not valid JSON"
    return 0
  fi
  printf '%s' "$decoded" | jq . | show "JWT Payload Decoded"
}

# hashMD5 computes the MD5 hash of the clipboard contents and displays the result.
hashMD5()         { clip_read | md5 -q     | show "MD5 Hash"; }
# hashSHA256 computes the SHA-256 hash of the clipboard contents and displays the result.
hashSHA256()      { clip_read | shasum -a 256 | awk '{print $1}' | show "SHA256 Hash"; }

# mdToHtml converts clipboard Markdown to HTML and displays the result.
mdToHtml() {
  require_action_tool pandoc "Markdown → HTML" || return 0
  clip_read | pandoc -f markdown -t html | show "Converted HTML"
}

# curlHeaders retrieves HTTP headers for the URL stored in the clipboard and displays the result.
curlHeaders()     { local url; url=$(clip_read); curl -sI --max-time 10 "$url" | show "Headers for $url"; }

# getIP finds the local non-loopback IPv4 address and displays it with the "IP Address" label.
getIP() {
  local ip="" iface
  for iface in en0 en1 en2 en3; do
    ip="$(ipconfig getifaddr "$iface" 2>/dev/null || true)"
    if [[ -n "$ip" ]]; then
      break
    fi
  done
  if [[ -z "$ip" ]]; then
    ip="$({ ifconfig 2>/dev/null || true; } | awk '/inet / && $2 !~ /^127\./ {print $2; exit}')"
  fi
  printf '%s' "$ip" | show "IP Address"
}

# getMAC displays the first detected MAC address and copies it to the clipboard.
getMAC()          { { ifconfig 2>/dev/null || true; } | awk '/ether/ {print $2}' | head -n1 | show "MAC Address"; }

# portCheck reads a host:port value from the clipboard and displays whether the port is reachable.
portCheck() {
  local input host port
  input=$(clip_read)
  if [[ "$input" != *:* || -z "${input%%:*}" || -z "${input##*:}" || "$input" == *$'\n'* ]]; then
    notify "Port Check" "❌ Expected host:port on the clipboard"
    return 0
  fi
  host=${input%%:*}
  port=${input##*:}
  # -G 5: bounded connect timeout (BSD nc).
  nc -zv -G 5 "$host" "$port" 2>&1 | show "Port $host:$port check"
}

# fetchSnippet displays a JavaScript fetch() example with an authorization header.
fetchSnippet() {
cat <<'EOF' | show "JS fetch() Snippet"
fetch("https://api.example.com/data", {
  headers: {
    "Authorization": "Bearer YOUR_TOKEN"
  }
}).then(res => res.json()).then(console.log);
EOF
}

# curlAuthSnippet outputs an authenticated curl command example and copies it to the clipboard.
curlAuthSnippet() {
cat <<'EOF' | show "curl + token Snippet"
curl -H "Authorization: Bearer YOUR_TOKEN" https://api.example.com/data
EOF
}

# ============= Keyboard Layout Convert =============
# LC_ALL is forced so BSD sed handles Cyrillic byte sequences even when
# layoutConvert converts QWERTY keyboard-layout text from the clipboard to Russian characters and displays the result.
layoutConvert() {
  clip_read | LC_ALL=en_US.UTF-8 sed \
    -e 's/q/й/g; s/w/ц/g; s/e/у/g; s/r/к/g; s/t/е/g; s/y/н/g; s/u/г/g; s/i/ш/g; s/o/щ/g; s/p/з/g' \
    -e 's/\[/х/g; s/\]/ъ/g; s/a/ф/g; s/s/ы/g; s/d/в/g; s/f/а/g; s/g/п/g; s/h/р/g; s/j/о/g; s/k/л/g; s/l/д/g; s/;/ж/g' \
    -e 's/z/я/g; s/x/ч/g; s/c/с/g; s/v/м/g; s/b/и/g; s/n/т/g; s/m/ь/g; s/,/б/g; s/\./ю/g' \
    -e 's/Q/Й/g; s/W/Ц/g; s/E/У/g; s/R/К/g; s/T/Е/g; s/Y/Н/g; s/U/Г/g; s/I/Ш/g; s/O/Щ/g; s/P/З/g' \
    -e 's/A/Ф/g; s/S/Ы/g; s/D/В/g; s/F/А/g; s/G/П/g; s/H/Р/g; s/J/О/g; s/K/Л/g; s/L/Д/g; s/:/Ж/g' \
    -e 's/Z/Я/g; s/X/Ч/g; s/C/С/g; s/V/М/g; s/B/И/g; s/N/Т/g; s/M/Ь/g; s/</Б/g; s/>/Ю/g' \
    | show "QWERTY → Russian Layout"
}

# layoutReverse converts Russian keyboard-layout text from the clipboard to QWERTY equivalents and displays the result.
layoutReverse() {
  clip_read | LC_ALL=en_US.UTF-8 sed \
    -e 's/й/q/g; s/ц/w/g; s/у/e/g; s/к/r/g; s/е/t/g; s/н/y/g; s/г/u/g; s/ш/i/g; s/щ/o/g; s/з/p/g' \
    -e 's/х/[/g; s/ъ/]/g; s/ф/a/g; s/ы/s/g; s/в/d/g; s/а/f/g; s/п/g/g; s/р/h/g; s/о/j/g; s/л/k/g; s/д/l/g; s/ж/;/g' \
    -e 's/я/z/g; s/ч/x/g; s/с/c/g; s/м/v/g; s/и/b/g; s/т/n/g; s/ь/m/g; s/б/,/g; s/ю/./g' \
    -e 's/Й/Q/g; s/Ц/W/g; s/У/E/g; s/К/R/g; s/Е/T/g; s/Н/Y/g; s/Г/U/g; s/Ш/I/g; s/Щ/O/g; s/З/P/g' \
    -e 's/Ф/A/g; s/Ы/S/g; s/В/D/g; s/А/F/g; s/П/G/g; s/Р/H/g; s/О/J/g; s/Л/K/g; s/Д/L/g; s/Ж/:/g' \
    -e 's/Я/Z/g; s/Ч/X/g; s/С/C/g; s/М/V/g; s/И/B/g; s/Т/N/g; s/Ь/M/g; s/Б/</g; s/Ю/>/g' \
    | show "Russian → QWERTY Layout"
}

# archiveExamples displays common archive creation, extraction, and listing commands.
archiveExamples() {
cat <<'EOF' | show "🗂 Archive Command Examples"
# 📦 TAR
tar -cvf archive.tar folder/         # Create .tar
tar -xvf archive.tar                 # Extract .tar
tar -tvf archive.tar                 # List contents

# 🗜 TAR.GZ
tar -czvf archive.tar.gz folder/     # Create .tar.gz
tar -xzvf archive.tar.gz             # Extract .tar.gz

# 🗜 TAR.BZ2
tar -cjvf archive.tar.bz2 folder/    # Create .tar.bz2
tar -xjvf archive.tar.bz2            # Extract .tar.bz2

# 🧺 GZIP
gzip file                            # Compress → file.gz
gunzip file.gz                       # Decompress

# 🧺 BZIP2
bzip2 file                           # Compress → file.bz2
bunzip2 file.bz2                     # Decompress

# 🧾 ZIP
zip archive.zip file1 file2          # Create .zip
unzip archive.zip                    # Extract .zip

# 📦 7z (p7zip)
7z a archive.7z file1 dir/           # Create .7z
7z x archive.7z                      # Extract .7z
7z l archive.7z                      # List contents

# 📦 XZ
xz file                              # Compress → file.xz
unxz file.xz                         # Decompress

# 📦 RAR (rar/unrar)
rar a archive.rar file1 dir/         # Create .rar
unrar x archive.rar                  # Extract .rar
unrar l archive.rar                  # List contents
EOF
}

# Run function by param — only whitelisted action names are dispatchable;
# unknown values can never resolve to functions, builtins, or PATH executables.
if [[ $# -ge 1 ]]; then
  case "$1" in
    curlHeaders|portCheck|jsonFormat|jsonMinify|jsonEscape|jsonUnescape| \
    unixToLocal|unixToUTC|currentUnix|archiveExamples|jwtDecode| \
    base64Encode|base64Decode|urlEncode|urlDecode|uuidGen|uuidShort| \
    hashMD5|hashSHA256|mdToHtml|getIP|getMAC|fetchSnippet|curlAuthSnippet| \
    layoutConvert|layoutReverse)
      "$1"
      exit $?
      ;;
    *)
      echo "Unknown action: $1" >&2
      exit 1
      ;;
  esac
fi

# ============= xbar Menu Output ============
SCRIPT_PATH="${SCRIPT_DIR}/$(basename "$SOURCE")"

# Short tray label to save menu-bar space; dialogs/notifications keep the
# full "Dev Toolbox" name.
echo "🛠 DT"
echo "---"

# HTTP
echo "🌐 HTTP: Headers       | bash='$SCRIPT_PATH' param1=curlHeaders terminal=false"
echo "📡 Port check (host:port) | bash='$SCRIPT_PATH' param1=portCheck terminal=false"
echo "---"

# JSON
echo "📦 JSON: Format       | bash='$SCRIPT_PATH' param1=jsonFormat terminal=false"
echo "📦 JSON: Minify       | bash='$SCRIPT_PATH' param1=jsonMinify terminal=false"
echo "📦 JSON: Escape       | bash='$SCRIPT_PATH' param1=jsonEscape terminal=false"
echo "📦 JSON: Unescape     | bash='$SCRIPT_PATH' param1=jsonUnescape terminal=false"
echo "---"

# Timestamp
echo "🕓 Time: Unix → Local | bash='$SCRIPT_PATH' param1=unixToLocal terminal=false"
echo "🕓 Time: Unix → UTC   | bash='$SCRIPT_PATH' param1=unixToUTC terminal=false"
echo "🕓 Time: Now (Unix)   | bash='$SCRIPT_PATH' param1=currentUnix terminal=false"
echo "---"

echo "🗂 Archive CLI Examples | bash='$SCRIPT_PATH' param1=archiveExamples terminal=false"

# --- Advanced Section ---
echo "⚙️ More Tools"
echo "-- 🔐 JWT: Decode        | bash='$SCRIPT_PATH' param1=jwtDecode terminal=false"
echo "-- 📎 Base64: Encode     | bash='$SCRIPT_PATH' param1=base64Encode terminal=false"
echo "-- 📎 Base64: Decode     | bash='$SCRIPT_PATH' param1=base64Decode terminal=false"
echo "-- 🔗 URL: Encode        | bash='$SCRIPT_PATH' param1=urlEncode terminal=false"
echo "-- 🔗 URL: Decode        | bash='$SCRIPT_PATH' param1=urlDecode terminal=false"
echo "-- 🆔 UUID: Generate     | bash='$SCRIPT_PATH' param1=uuidGen terminal=false"
echo "-- 🆔 UUID: Short ID     | bash='$SCRIPT_PATH' param1=uuidShort terminal=false"
echo "-- 🔒 Hash: MD5          | bash='$SCRIPT_PATH' param1=hashMD5 terminal=false"
echo "-- 🔒 Hash: SHA256       | bash='$SCRIPT_PATH' param1=hashSHA256 terminal=false"
echo "-- 📝 Markdown → HTML    | bash='$SCRIPT_PATH' param1=mdToHtml terminal=false"
echo "-- 🌍 IP Address         | bash='$SCRIPT_PATH' param1=getIP terminal=false"
echo "-- 🌍 MAC Address        | bash='$SCRIPT_PATH' param1=getMAC terminal=false"
echo "-- 💡 Snippet: JS fetch  | bash='$SCRIPT_PATH' param1=fetchSnippet terminal=false"
echo "-- 💡 Snippet: curl + JWT | bash='$SCRIPT_PATH' param1=curlAuthSnippet terminal=false"
echo "-- ⌨️ QWERTY → RU | bash='$SCRIPT_PATH' param1=layoutConvert terminal=false"
echo "-- ⌨️ RU → QWERTY     | bash='$SCRIPT_PATH' param1=layoutReverse terminal=false"
