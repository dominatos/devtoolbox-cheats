#!/usr/bin/env python3
"""Fix broken TOC anchors in markdown cheatsheets.

Reads each .md file, extracts headings and their auto-generated slugs,
compares against TOC anchor links, and fixes mismatches.

GitHub slug algorithm (simplified):
  1. Lowercase
  2. Strip markdown heading markers (## )
  3. Remove emojis
  4. Remove non-alphanumeric except spaces and hyphens
  5. Replace spaces with hyphens
  6. Strip leading/trailing hyphens
  NOTE: Multiple consecutive hyphens are PRESERVED (not collapsed).
        E.g. "A & B" → "a---b" (& removed, spaces→hyphens)

Usage:
  python3 fix-toc-anchors.py                    # dry-run (default)
  python3 fix-toc-anchors.py --apply            # apply fixes
  python3 fix-toc-anchors.py --dir /path/to/md  # custom directory
"""

import argparse
import re
import sys
from pathlib import Path


def heading_to_slug(heading_text: str) -> str:
    """Convert heading text to a GitHub-compatible anchor slug.

    IMPORTANT: Does NOT collapse consecutive hyphens, matching GitHub's behavior.
    E.g. "## Install & Configure" → "install---configure"
    """
    slug = heading_text.lower()
    # Remove heading markers
    slug = re.sub(r'^#+\s*', '', slug)
    # Remove emojis (broad Unicode ranges)
    slug = re.sub(r'[\U0001F600-\U0001F64F]', '', slug)  # emoticons
    slug = re.sub(r'[\U0001F300-\U0001F5FF]', '', slug)  # symbols & pictographs
    slug = re.sub(r'[\U0001F680-\U0001F6FF]', '', slug)  # transport & map
    slug = re.sub(r'[\U0001F1E0-\U0001F1FF]', '', slug)  # flags
    slug = re.sub(r'[\U0001F900-\U0001F9FF]', '', slug)  # supplemental
    slug = re.sub(r'[\U0001FA00-\U0001FA6F]', '', slug)  # chess symbols
    slug = re.sub(r'[\U0001FA70-\U0001FAFF]', '', slug)  # symbols extended
    slug = re.sub(r'[\U00002702-\U000027B0]', '', slug)  # dingbats
    slug = re.sub(r'[\U0000FE00-\U0000FE0F]', '', slug)  # variation selectors
    slug = re.sub(r'[\U0000200D]', '', slug)  # ZWJ
    slug = re.sub(r'[\U000025A0-\U000025FF]', '', slug)  # geometric shapes
    slug = re.sub(r'[\U00002600-\U000026FF]', '', slug)  # misc symbols
    slug = re.sub(r'[\U00002B50-\U00002B55]', '', slug)  # stars
    # Remove non-alphanumeric except spaces, hyphens, and underscores
    slug = re.sub(r'[^\w\s\-]', '', slug)
    # Collapse multiple spaces into one
    slug = re.sub(r'\s+', ' ', slug).strip()
    # Replace spaces with hyphens
    slug = slug.replace(' ', '-')
    # Strip leading/trailing hyphens
    slug = slug.strip('-')
    # DO NOT collapse multiple consecutive hyphens (GitHub preserves them)
    return slug


def extract_headings_and_slugs(content: str) -> dict:
    """Extract all H1-H3 headings and their generated slugs."""
    headings = {}
    for line in content.splitlines():
        m = re.match(r'^(#{1,3})\s+(.+)$', line)
        if m:
            full_heading = m.group(0)
            slug = heading_to_slug(full_heading)
            if slug:
                headings[slug] = m.group(2).strip()
    return headings


def extract_toc_links(content: str) -> list:
    """Extract TOC entries as (line_number, original_line, link_text, anchor)."""
    toc_entries = []
    in_toc = False
    for i, line in enumerate(content.splitlines(), 1):
        if re.match(r'^##\s+.*[Tt]able\s+of\s+[Cc]ontents', line):
            in_toc = True
            continue
        if in_toc:
            if re.match(r'^---\s*$', line) or re.match(r'^##\s+', line):
                in_toc = False
                continue
            m = re.match(r'^(\s*[-*]?\s*\d*\.?\s*\[([^\]]+)\]\((#[^)]+)\)\s*)$', line)
            if m:
                toc_entries.append((i, m.group(0), m.group(2), m.group(3).strip()))
    return toc_entries


def find_best_match(anchor_slug: str, headings: dict) -> str | None:
    """Find the heading slug that best matches the TOC anchor."""
    if anchor_slug in headings:
        return anchor_slug

    # Strategy 1: Remove leading hyphen (emoji left a dash)
    stripped = anchor_slug.lstrip('-')
    if stripped in headings:
        return stripped

    # Strategy 2: TOC omits number prefix, heading has it
    for slug in headings:
        if re.match(r'^\d+-', slug):
            without_num = re.sub(r'^\d+-', '', slug)
            if without_num == anchor_slug:
                return slug

    # Strategy 3: TOC has number prefix, heading doesn't
    if re.match(r'^\d+-', anchor_slug):
        without_num = re.sub(r'^\d+-', '', anchor_slug)
        if without_num in headings:
            return without_num

    # Strategy 4: TOC omits Russian suffix, heading has it
    for slug in headings:
        if slug.startswith(anchor_slug + '--') or slug.startswith(anchor_slug + '-'):
            # Check if the suffix is Cyrillic
            suffix = slug[len(anchor_slug):]
            if re.search(r'[\u0400-\u04FF]', suffix):
                return slug

    # Strategy 5: TOC has Russian suffix, heading doesn't
    if re.search(r'--[\u0400-\u04FF]', anchor_slug):
        en_part = re.split(r'--', anchor_slug)[0]
        if en_part in headings:
            return en_part

    # Strategy 6: Best overlap by word parts
    best_match = None
    best_score = 0
    anchor_parts = set(anchor_slug.split('-'))
    for slug in headings:
        slug_parts = set(slug.split('-'))
        overlap = len(anchor_parts & slug_parts)
        if overlap > best_score and overlap > 0:
            min_len = min(len(anchor_parts), len(slug_parts))
            if overlap >= min_len * 0.5:
                best_score = overlap
                best_match = slug

    return best_match


def fix_file(filepath: Path, apply: bool = False) -> list:
    """Fix broken TOC anchors in a single file. Returns list of fixes."""
    content = filepath.read_text(encoding='utf-8')
    headings = extract_headings_and_slugs(content)
    toc_entries = extract_toc_links(content)

    fixes = []
    for line_num, original_line, link_text, anchor in toc_entries:
        anchor_slug = anchor.lstrip('#')
        if anchor_slug not in headings:
            best_match = find_best_match(anchor_slug, headings)
            if best_match and best_match != anchor_slug:
                new_anchor = '#' + best_match
                new_line = original_line.replace(anchor, new_anchor)
                content = content.replace(original_line, new_line, 1)
                fixes.append((link_text, anchor, new_anchor))

    if fixes and apply:
        filepath.write_text(content, encoding='utf-8')

    return fixes


def check_remaining(filepath: Path) -> list:
    """Check for any remaining broken anchors after fixing."""
    content = filepath.read_text(encoding='utf-8')
    headings = extract_headings_and_slugs(content)
    toc_entries = extract_toc_links(content)
    remaining = []
    for line_num, original_line, link_text, anchor in toc_entries:
        anchor_slug = anchor.lstrip('#')
        if anchor_slug not in headings:
            remaining.append((link_text, anchor))
    return remaining


def main():
    parser = argparse.ArgumentParser(description='Fix broken TOC anchors in markdown cheatsheets')
    parser.add_argument('--apply', action='store_true', help='Apply fixes (default: dry-run)')
    parser.add_argument('--dir', type=Path, default=None,
                        help='Directory containing .md files (default: ../cheats.d)')
    args = parser.parse_args()

    if args.dir:
        cheats_dir = args.dir
    else:
        cheats_dir = Path(__file__).resolve().parent.parent / 'cheats.d'

    if not cheats_dir.is_dir():
        print(f"Error: {cheats_dir} is not a directory", file=sys.stderr)
        sys.exit(1)

    total_fixes = 0
    files_fixed = 0
    files_with_remaining = 0

    for md_file in sorted(cheats_dir.rglob('*.md')):
        fixes = fix_file(md_file, apply=args.apply)
        if fixes:
            files_fixed += 1
            total_fixes += len(fixes)
            rel = md_file.relative_to(cheats_dir)
            mode = "FIXED" if args.apply else "WOULD FIX"
            print(f"\n{'='*60}")
            print(f"FILE: {rel} ({len(fixes)} {mode})")
            print(f"{'='*60}")
            for link_text, old_anchor, new_anchor in fixes:
                print(f"  [{link_text}] {old_anchor} → {new_anchor}")

        remaining = check_remaining(md_file)
        if remaining:
            files_with_remaining += 1
            rel = md_file.relative_to(cheats_dir)
            print(f"\n  ⚠ REMAINING BROKEN in {rel}:")
            for link_text, anchor in remaining:
                print(f"    [{link_text}] {anchor}")

    mode = "Applied" if args.apply else "Dry-run (no files modified)"
    print(f"\n{'='*60}")
    print(f"SUMMARY: {total_fixes} fixes in {files_fixed} files [{mode}]")
    if files_with_remaining:
        print(f"⚠ {files_with_remaining} files still have broken anchors (manual review needed)")
    print(f"{'='*60}")


if __name__ == '__main__':
    main()
