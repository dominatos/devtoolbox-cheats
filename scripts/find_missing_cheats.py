#!/usr/bin/env python3
import os
import re
import sys

# Configuration
README_PATH = 'README.md'
CHEATS_DIR = 'cheats.d'

def main():
    # Ensure we are in the root directory
    if not os.path.exists(README_PATH) or not os.path.exists(CHEATS_DIR):
        print(f"Error: Run this script from the repository root (containing {README_PATH} and {CHEATS_DIR}/)")
        sys.exit(1)

    # 1. Parse README.md for existing links
    print(f"Reading {README_PATH}...")
    try:
        with open(README_PATH, 'r') as f:
            readme_content = f.read()
    except FileNotFoundError:
        print(f"Error: {README_PATH} not found.")
        sys.exit(1)

    existing_links = set()
    # Normalize paths in README links to match os.path.normpath output
    for match in re.finditer(r'\(cheats\.d/([^)]+)\)', readme_content):
        # We strip any anchor tags if present, though usually files don't have them in this repo
        path = match.group(1).split('#')[0]
        existing_links.add(os.path.normpath(path))

    # 2. Find all .md files in cheats.d
    print(f"Scanning {CHEATS_DIR}...")
    all_cheats = set()
    cheat_metadata = {}

    for root, dirs, files in os.walk(CHEATS_DIR):
        for file in files:
            if file.endswith('.md'):
                rel_path = os.path.relpath(os.path.join(root, file), CHEATS_DIR)
                all_cheats.add(os.path.normpath(rel_path))
                
                # Extract metadata
                full_path = os.path.join(root, file)
                title = None
                icon = None
                group = None
                try:
                    with open(full_path, 'r') as f:
                        for _ in range(20): # Check first 20 lines
                            line = f.readline().strip()
                            if line.startswith('Title:'):
                                title = line.split(':', 1)[1].strip()
                            elif line.startswith('Icon:'):
                                icon = line.split(':', 1)[1].strip()
                            elif line.startswith('Group:'):
                                group = line.split(':', 1)[1].strip()
                except Exception as e:
                    print(f"Warning: Could not read metadata from {full_path}: {e}")
                
                # Default values if metadata is missing
                display_title = title if title else file
                display_icon = icon if icon else "📄"
                
                cheat_metadata[os.path.normpath(rel_path)] = {
                    'title': display_title,
                    'icon': display_icon,
                    'group': group,
                    'path': f"cheats.d/{rel_path}" # Path relative to repo root
                }

    # 3. Identify missing cheats
    missing_cheats = all_cheats - existing_links

    if not missing_cheats:
        print("\n✅ All cheatsheets are listed in README.md!")
        return

    # 4. Group by category (directory or Group metadata)
    grouped_missing = {}

    for cheat in missing_cheats:
        meta = cheat_metadata[cheat]
        # Use directory as fallback group if metadata Group is missing/generic
        # os.path.dirname(cheat) returns "category/subdir" or "category"
        # We generally want the top-level directory name as the group if 'Group' isn't set
        directory_parts = os.path.dirname(cheat).split(os.sep)
        directory_category = directory_parts[0].capitalize() if directory_parts else "Misc"

        # Logic: Use 'Group' metadata if available, else derive from directory name
        category = meta.get('group')
        if not category or category.lower() == 'misc':
             category = directory_category
        
        if category not in grouped_missing:
            grouped_missing[category] = []
        
        grouped_missing[category].append(meta)

    # 5. Output results
    print(f"\nFound {len(missing_cheats)} missing cheatsheets. Copy/paste these into {README_PATH}:\n")

    for category, items in sorted(grouped_missing.items()):
        print(f"### {category}")
        for item in sorted(items, key=lambda x: x['title']):
            print(f"- [{item['icon']} {item['title']}]({item['path']})")
        print()

if __name__ == "__main__":
    main()
