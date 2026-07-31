import re
import os
import sys

def clean_header(header_line):
    # E.g. "## 🔀 Basic Substitution / Базовая замена" -> "## 🔀 Basic Substitution"
    # Remove the "## " prefix
    content = header_line[3:]
    
    # Split by "/" and take the first part (English part + emoji)
    if " / " in content:
        content = content.split(" / ")[0]
        
    content = content.strip()
    return f"## {content}", content

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    in_toc = False
    toc_start_idx = -1
    toc_end_idx = -1
    
    headers = []
    
    # First pass: find headers and TOC bounds
    for i, line in enumerate(lines):
        if re.match(r'^##\s+.*Table of Contents', line, re.IGNORECASE):
            in_toc = True
            toc_start_idx = i
            continue
            
        if in_toc:
            # TOC ends when we hit a rule "---"
            if line.startswith('---'):
                toc_end_idx = i
                in_toc = False
                continue
            # Some cheatsheets might not have "---" immediately, handle "##"
            if line.startswith('## '):
                toc_end_idx = i
                in_toc = False
                # Fall through to process this header
                
        # Detect main headers (ignore TOC itself)
        if line.startswith('## ') and not re.match(r'^##\s+.*Table of Contents', line, re.IGNORECASE):
            new_header_line, header_text = clean_header(line)
            headers.append((i, new_header_line, header_text))

    # If no TOC found, we just replace headers but don't generate a TOC.
    if toc_start_idx != -1 and toc_end_idx == -1:
        # If TOC reached EOF without "---" or "##"
        toc_end_idx = len(lines)

    # Build new TOC
    new_toc_lines = []
    for _, _, header_text in headers:
        # Generate Obsidian compatible URL-encoded anchor
        anchor = header_text.replace(" ", "%20")
        new_toc_lines.append(f"- [{header_text}](#{anchor})\n")
        
    # Replace headers in lines
    for idx, new_header_line, _ in headers:
        lines[idx] = new_header_line + "\n"
        
    # Replace TOC if it exists
    if toc_start_idx != -1 and toc_end_idx != -1:
        final_lines = lines[:toc_start_idx+1] + ["\n"] + new_toc_lines + ["\n"] + lines[toc_end_idx:]
    else:
        final_lines = lines
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(final_lines)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        for f in sys.argv[1:]:
            process_file(f)
    else:
        # Walk directory
        target_dir = '/home/sviatoslav/scripts/repo/devtoolbox-cheats/cheats.d'
        for root, dirs, files in os.walk(target_dir):
            for file in files:
                if file.endswith('.md'):
                    process_file(os.path.join(root, file))
