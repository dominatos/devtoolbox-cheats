#!/bin/bash
# Dev Toolbox for Argos — grouped view with zenity popups

# ========================================
# 🛠 Dependencies (install first):
#
# Ubuntu / Debian:
# sudo apt update && sudo apt install jq xclip wl-clipboard uuid-runtime libnotify-bin pandoc curl zenity openssl coreutils
#
# Fedora / RHEL:
# sudo dnf install jq xclip wl-clipboard util-linux uuidd libnotify pandoc curl zenity openssl coreutils
# sudo systemctl enable --now uuidd
#
# Arch / Manjaro:
# sudo pacman -S jq xclip wl-clipboard libnotify pandoc curl zenity openssl coreutils
#
# openSUSE:
# sudo zypper install jq xclip wl-clipboard libnotify-tools pandoc curl zenity openssl coreutils
# ========================================

export PATH="/usr/local/bin:/usr/bin:$PATH"
SCRIPT_PATH="$(realpath -s "$0")"

# Maintained by bump-version.sh — used for consistency across all project scripts
VERSION="v1.4.19"

# Detect clipboard method
if command -v wl-copy >/dev/null && command -v wl-paste >/dev/null; then
  CLIPBOARD_COPY="wl-copy"
  CLIPBOARD_PASTE="wl-paste"
  CLIPBOARD_MODE="Wayland"
elif command -v xclip >/dev/null; then
  CLIPBOARD_COPY="xclip -selection clipboard"
  CLIPBOARD_PASTE="xclip -o -selection clipboard"
  CLIPBOARD_MODE="X11"
else
  echo "❌ Requires wl-clipboard or xclip"
  exit 1
fi

paste()  { eval "$CLIPBOARD_PASTE"; }
copy()   { eval "$CLIPBOARD_COPY"; }
popup()  { echo -e "$2" | zenity --text-info --title="Dev Toolbox: $1" --width=800 --height=500 --filename=/dev/stdin --no-wrap --ok-label="Close" 2>/dev/null; }
show()   { result="$(cat)"; copy <<<"$result"; notify-send "✅ Dev Toolbox" "$1"; popup "$1" "$result"; }

# JSON
jsonFormat()      { paste | jq .       | show "Formatted JSON"; }
jsonMinify()      { paste | jq -c .    | show "Minified JSON"; }
jsonEscape()      { paste | xargs -0 printf "%s" | jq @json | show "Escaped JSON"; }
jsonUnescape()    { paste | jq -r      | show "Unescaped JSON"; }

# Base64
base64Encode()    { paste | base64     | show "Base64 Encoded"; }
base64Decode()    { paste | base64 -d  | show "Base64 Decoded"; }

# URL
urlEncode()       { paste | jq -sRr @uri | show "URL Encoded"; }
urlDecode()       { paste | sed 's/+/ /g; s/%\([0-9a-fA-F][0-9a-fA-F]\)/\\x\1/g;' | xargs -0 printf "%b\n" | show "URL Decoded"; }

# Date / Timestamp
unixToLocal()     { date -d "@$(paste)" +%Y-%m-%dT%H:%M:%S | show "Local Timestamp"; }
unixToUTC()       { date -u -d "@$(paste)" +%Y-%m-%dT%H:%M:%SZ | show "UTC Timestamp"; }
currentUnix()     { date +%s | show "Current Unix Timestamp"; }

# UUID
uuidGen()         { uuidgen | show "Generated UUID"; }
uuidShort()       { openssl rand -hex 4 | show "Short ID"; }

# JWT
jwtDecode() {
  IFS='.' read -r _ payload _ <<<"$(paste)"
  echo "$payload" | base64 -d 2>/dev/null | jq . | show "JWT Payload Decoded"
}

# Hashing
hashMD5()         { paste | md5sum    | awk '{print $1}' | show "MD5 Hash"; }
hashSHA256()      { paste | sha256sum | awk '{print $1}' | show "SHA256 Hash"; }

# Markdown
mdToHtml()        { paste | pandoc -f markdown -t html | show "Converted HTML"; }

# HTTP
curlHeaders()     { url=$(paste); curl -sI "$url" | show "Headers for $url"; }

# Network
getIP()           { hostname -I | awk '{print $1}' | show "IP Address"; }
getMAC()          { ip link show | awk '/ether/ {print $2}' | head -n1 | show "MAC Address"; }
portCheck() {
  input=$(paste)
  host=${input%%:*}
  port=${input##*:}
  nc -zv "$host" "$port" 2>&1 | show "Port $host:$port check"
}

# Snippets
fetchSnippet() {
cat <<EOF | show "JS fetch() Snippet"
fetch("https://api.example.com/data", {
  headers: {
    "Authorization": "Bearer YOUR_TOKEN"
  }
}).then(res => res.json()).then(console.log);
EOF
}

curlAuthSnippet() {
cat <<EOF | show "curl + token Snippet"
curl -H "Authorization: Bearer YOUR_TOKEN" https://api.example.com/data
EOF
}

# Keyboard Layout Convert
layoutConvert() {
  paste | sed \
    -e 's/q/й/g; s/w/ц/g; s/e/у/g; s/r/к/g; s/t/е/g; s/y/н/g; s/u/г/g; s/i/ш/g; s/o/щ/g; s/p/з/g' \
    -e 's/\[/х/g; s/\]/ъ/g; s/a/ф/g; s/s/ы/g; s/d/в/g; s/f/а/g; s/g/п/g; s/h/р/g; s/j/о/g; s/k/л/g; s/l/д/g; s/;/ж/g' \
    -e 's/z/я/g; s/x/ч/g; s/c/с/g; s/v/м/g; s/b/и/g; s/n/т/g; s/m/ь/g; s/,/б/g; s/\./ю/g' \
    -e 's/Q/Й/g; s/W/Ц/g; s/E/У/g; s/R/К/g; s/T/Е/g; s/Y/Н/g; s/U/Г/g; s/I/Ш/g; s/O/Щ/g; s/P/З/g' \
    -e 's/A/Ф/g; s/S/Ы/g; s/D/В/g; s/F/А/g; s/G/П/g; s/H/Р/g; s/J/О/g; s/K/Л/g; s/L/Д/g; s/:/Ж/g' \
    -e 's/Z/Я/g; s/X/Ч/g; s/C/С/g; s/V/М/g; s/B/И/g; s/N/Т/g; s/M/Ь/g; s/</Б/g; s/>/Ю/g' \
    | show "QWERTY → Russian Layout"
}

layoutReverse() {
  paste | sed \
    -e 's/й/q/g; s/ц/w/g; s/у/e/g; s/к/r/g; s/е/t/g; s/н/y/g; s/г/u/g; s/ш/i/g; s/щ/o/g; s/з/p/g' \
    -e 's/х/[/g; s/ъ/]/g; s/ф/a/g; s/ы/s/g; s/в/d/g; s/а/f/g; s/п/g/g; s/р/h/g; s/о/j/g; s/л/k/g; s/д/l/g; s/ж/;/g' \
    -e 's/я/z/g; s/ч/x/g; s/с/c/g; s/м/v/g; s/и/b/g; s/т/n/g; s/ь/m/g; s/б/,/g; s/ю/./g' \
    -e 's/Й/Q/g; s/Ц/W/g; s/У/E/g; s/К/R/g; s/Е/T/g; s/Н/Y/g; s/Г/U/g; s/Ш/I/g; s/Щ/O/g; s/З/P/g' \
    -e 's/Ф/A/g; s/Ы/S/g; s/В/D/g; s/А/F/g; s/П/G/g; s/Р/H/g; s/О/J/g; s/Л/K/g; s/Д/L/g; s/Ж/:/g' \
    -e 's/Я/Z/g; s/Ч/X/g; s/С/C/g; s/М/V/g; s/И/B/g; s/Т/N/g; s/Ь/M/g; s/Б/</g; s/Ю/>/g' \
    | show "Russian → QWERTY Layout"
}
archiveExamples() {
cat <<EOF | show "🗂 Archive Command Examples"
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

# 📦 7z (p7zip-full)
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


# Run function by param
[ $# -ge 1 ] && { "$1"; exit $?; }

# Argos Menu Output
# echo "🛠 Dev Toolbox ($CLIPBOARD_MODE)"
echo "🛠 Dev Toolbox"
echo "---"

# HTTP
echo "🌐 1HTTP: Headers      | bash='$SCRIPT_PATH' param1=curlHeaders terminal=false"
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

echo "-- 🗂 Archive CLI Examples | bash='$SCRIPT_PATH' param1=archiveExamples terminal=false"

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
