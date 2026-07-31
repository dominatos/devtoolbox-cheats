#!/usr/bin/env python3
"""Manage Table of Contents formatting for DevToolbox Cheatsheets.

This script unifies TOC generation for different markdown viewers.
It will:
  1. Parse the markdown file.
  2. Clean main `##` headers (remove trailing `/ translations` but keep emojis).
  3. Rebuild the TOC block from scratch using the chosen formatting style.

Usage:
  python3 tools/manage-tocs.py --style obsidian
  python3 tools/manage-tocs.py --style github
"""

import argparse
import re
import sys
import os
from pathlib import Path

def heading_to_github_slug(heading_text: str) -> str:
    """Convert heading text to a GitHub-compatible anchor slug."""
    slug = heading_text.lower()
    # Remove emojis
    slug = re.sub(r'[\U0001F600-\U0001FAFF]', '', slug)
    slug = re.sub(r'[\U00002702-\U000027B0]', '', slug)
    slug = re.sub(r'[\U000025A0-\U00002B55]', '', slug)
    # Remove non-alphanumeric except spaces, hyphens, and underscores
    slug = re.sub(r'[^\w\s\-]', '', slug)
    # Collapse multiple spaces into one
    slug = re.sub(r'\s+', ' ', slug).strip()
    # Replace spaces with hyphens
    slug = slug.replace(' ', '-')
    slug = slug.strip('-')
    return slug

def clean_header(header_line: str) -> tuple:
    """Clean the header line by removing trailing translations."""
    content = header_line[3:]
    if " / " in content:
        content = content.split(" / ")[0]
    content = content.strip()
    return f"## {content}", content

def process_file(filepath: Path, style: str):
    try:
        content = filepath.read_text(encoding='utf-8')
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return False
        
    lines = content.splitlines()
    in_toc = False
    toc_start_idx = -1
    toc_end_idx = -1
    headers = []
    
    # Pass 1: Find TOC bounds and headers
    for i, line in enumerate(lines):
        if re.match(r'^##\s+.*Table of Contents', line, re.IGNORECASE):
            in_toc = True
            toc_start_idx = i
            continue
            
        if in_toc:
            if line.startswith('---') or (line.startswith('## ') and i > toc_start_idx):
                toc_end_idx = i
                in_toc = False
                
        # Detect main headers (skip the TOC header itself)
        if line.startswith('## ') and not re.match(r'^##\s+.*Table of Contents', line, re.IGNORECASE):
            new_header_line, header_text = clean_header(line)
            headers.append((i, new_header_line, header_text))

    if toc_start_idx != -1 and toc_end_idx == -1:
        toc_end_idx = len(lines)

    # Rebuild TOC
    new_toc_lines = []
    for _, _, header_text in headers:
        if style == 'obsidian':
            anchor = header_text.replace(" ", "%20")
        elif style == 'github':
            anchor = heading_to_github_slug(header_text)
        else:
            anchor = header_text.replace(" ", "%20") # fallback
            
        new_toc_lines.append(f"- [{header_text}](#{anchor})")
        
    # Replace headers in lines
    for idx, new_header_line, _ in headers:
        lines[idx] = new_header_line
        
    # Replace TOC block
    if toc_start_idx != -1 and toc_end_idx != -1:
        final_lines = lines[:toc_start_idx+1] + [""] + new_toc_lines + [""] + lines[toc_end_idx:]
    else:
        final_lines = lines
    
    new_content = "\n".join(final_lines) + "\n"
    if new_content != content:
        filepath.write_text(new_content, encoding='utf-8')
        return True
    return False

def main():
    parser = argparse.ArgumentParser(description='Format Table of Contents for DevToolbox Cheatsheets.')
    parser.add_argument('--style', choices=['obsidian', 'github'], default='obsidian',
                        help='Formatting style to use for TOC links (default: obsidian)')
    parser.add_argument('--dir', type=Path, default=None,
                        help='Directory containing .md files (default: ~/cheats.d)')
    args = parser.parse_args()

    if args.dir:
        cheats_dir = args.dir
    else:
        cheats_dir = Path.home() / 'cheats.d'

    if not cheats_dir.is_dir():
        print(f"Error: Directory {cheats_dir} not found.", file=sys.stderr)
        sys.exit(1)

    print(f"Starting TOC rebuild. Mode: {args.style.upper()}")
    modified_count = 0
    total_count = 0
    
    for md_file in sorted(cheats_dir.rglob('*.md')):
        total_count += 1
        if process_file(md_file, args.style):
            modified_count += 1
            print(f"  [UPDATED] {md_file.name}")

    print("-" * 40)
    print(f"Done. Updated {modified_count} out of {total_count} files to {args.style.upper()} formatting.")

if __name__ == '__main__':
    main()
