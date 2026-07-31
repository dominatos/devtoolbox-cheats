# DevToolbox Cheatsheets Tools

This directory contains utility scripts to help maintain and format the cheatsheets in the `cheats.d/` directory.

## `manage-tocs.py` (Recommended)

A unified Python script to automatically clean up headers and regenerate the Table of Contents for all cheatsheets. 

When applied, this script will:
1. Strip Russian translations from main `##` headers (while preserving emojis) to keep TOC anchors clean.
2. Completely remove the old, broken TOC section.
3. Regenerate a perfect TOC from scratch, using your preferred markdown formatting style.

### Usage

**Format for Obsidian** (Default)
Generates exact-match anchors with URL-encoded spaces (e.g., `[Heading Name](#Heading%20Name)`). This is required for Obsidian's internal linking to function correctly.
```bash
./manage-tocs.py --style obsidian
```

**Format for GitHub / GitLab**
Generates standard lowercase, hyphenated slugs with emojis stripped (e.g., `[Heading Name](#heading-name)`).
```bash
./manage-tocs.py --style github
```

**Run on a specific file or directory**
By default, the script processes all `.md` files in `~/cheats.d/`. You can override this using `--dir`:
```bash
./manage-tocs.py --dir /path/to/specific/cheatsheet.md
```

---

## Deprecated Scripts

- `fix-toc-github.py`: An older, complex script that attempted to fuzzy-match broken GitHub anchors to existing headers. It has been fully replaced by `manage-tocs.py`, which offers a much cleaner "rebuild from scratch" approach. You can safely delete this script.
- `fix_tocs.py`: A temporary script previously located at the repo root. Replaced by `manage-tocs.py`.
