#!/usr/bin/env bash
cheats_dir="../cheats.d"
readme="../README.md"

missing=0

while IFS= read -r cheat; do
    rel_path="${cheat#../}"  # strip leading ../
    if ! grep -qF "$rel_path" "$readme"; then
        echo "Missing in README: $rel_path"
        missing=$((missing+1))
    fi
done < <(find "$cheats_dir" -type f -name '*.md')

if [[ $missing -eq 0 ]]; then
    echo "All cheatsheets are referenced in README.md"
else
    echo "$missing cheatsheets missing"
fi