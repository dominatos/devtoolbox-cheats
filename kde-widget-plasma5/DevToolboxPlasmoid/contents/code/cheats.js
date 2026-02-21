/*
 * Cheatsheet logic for DevToolbox Cheats Plasmoid
 */

.pragma library
    .import "utils.js" as Utils

// Groups configuration (default icons)
var GROUP_ICONS = {
    "Basics": "help-contents",
    "Network": "network-wired",
    "Storage & FS": "drive-harddisk",
    "Backups & S3": "document-save-all",
    "Files & Archives": "package-x-generic",
    "Text & Parsing": "text-field",
    "Kubernetes & Containers": "kubernetes-pod", // Fallback if not found
    "System & Logs": "utilities-system-monitor",
    "Web Servers": "network-server",
    "Databases": "data-database",
    "Package Managers": "system-software-install",
    "Security & Crypto": "security-high",
    "Dev & Tools": "applications-development",
    "Misc": "preferences-other",
    "Diagnostics": "utilities-log-viewer",
    "Cloud": "cloud-shape",
    "Monitoring": "utilities-energy-monitor"
};


// ... (existing code) ...

if (!groupsMap[group]) {
    groupsMap[group] = {
        name: group,
        icon: icon || GROUP_ICONS[group] || "🧩",
        cheats: [],
        expanded: false // Default to collapsed
    };
}

// Parse Front Matter from Markdown content
function parseFrontMatter(content) {
    var lines = content.split('\n');
    var metadata = {
        title: "",
        group: "Misc",
        icon: "",
        order: 9999
    };

    // Read first 80 lines max
    for (var i = 0; i < Math.min(lines.length, 80); i++) {
        var line = lines[i].trim();
        if (line.match(/^Title:/i)) metadata.title = line.replace(/^Title:\s*/i, '').trim();
        if (line.match(/^Group:/i)) metadata.group = line.replace(/^Group:\s*/i, '').trim();
        if (line.match(/^Icon:/i)) metadata.icon = line.replace(/^Icon:\s*/i, '').trim();
        if (line.match(/^Order:/i)) metadata.order = parseInt(line.replace(/^Order:\s*/i, '').trim()) || 9999;
    }

    return metadata;
}

// Remove Front Matter from content for viewing/copying
function stripFrontMatter(content) {
    // Simply remove lines starting with metadata keys in the first 80 lines
    // This is a simplified regex approach
    var lines = content.split('\n');
    var output = [];
    var inHeader = true;

    for (var i = 0; i < lines.length; i++) {
        if (i < 80 && inHeader) {
            if (lines[i].match(/^(Title|Group|Icon|Order):/i)) {
                continue;
            }
            // First empty line usually ends the header block if we want to be strict,
            // or just skip known keys. The bash script skips specific keys.
        }
        output.push(lines[i]);
    }

    // Trim leading empty lines
    while (output.length > 0 && output[0].trim() === "") {
        output.shift();
    }

    return output.join('\n');
}

// Build command to index cheats (using shell for performance)
// We retain the bash logic for indexing because it's faster and reliable on Linux
function getIndexCommand(cheatsDir, cacheFile) {
    // We will construct a shell command that finds files, parses them, and outputs JSON
    // Note: Writing complex JSON generator in one-liner bash is tricky.
    // Instead, we might want to just output TSV like before, or a simple format 
    // that we can easily parse in QML.

    // Let's stick to the existing TSV format output by the bash script command,
    // and we will parse that TSV in QML/JS to build our model.
    // This avoids needing to rewrite the robust bash indexing logic in pure JS/QML
    // which might run into permission or performance issues.

    // Robust indexing command wrapped in bash
    // We iterate over files and extract metadata one by one.
    // The command string uses double quotes internally for bash variables, so we need to be careful with escaping.
    // We construct the inner command first, then wrap it.

    // Robust indexing command wrapped in bash with single quotes to prevent expansion
    // We construct the script content first.

    // Check directory existence and list it for debug
    var debugLog = "/home/sviatoslav/Downloads/devtoolbox-kde/devtoolbox-cheats-beta/kde-widget-plasma5/debug.log";

    var script = "{ " +
        "searchDir=\"" + cheatsDir + "\"; " +
        "echo \"Search Dir: $searchDir\" > " + debugLog + "; " +
        "[ -d \"$searchDir\" ] || echo 'Directory not found!' >> " + debugLog + "; " +
        "find -L \"$searchDir\" -type f -name '*.md' | while read -r f; do " +
        "  title=$(grep -i -m1 '^Title:' \"$f\" | sed -E 's/^[Tt][Ii][Tt][Ll][Ee]:[[:space:]]*//; s/[[:space:]]*$//' | tr -d '\\r'); " +
        "  group=$(grep -i -m1 '^Group:' \"$f\" | sed -E 's/^[Gg][Rr][Oo][Uu][Pp]:[[:space:]]*//; s/[[:space:]]*$//' | tr -d '\\r'); " +
        "  icon=$(grep -i -m1 '^Icon:' \"$f\" | sed -E 's/^[Ii][Cc][Oo][Nn]:[[:space:]]*//; s/[[:space:]]*$//' | tr -d '\\r'); " +
        "  order=$(grep -i -m1 '^Order:' \"$f\" | sed -E 's/^[Oo][Rr][Dd][Ee][Rr]:[[:space:]]*//; s/[[:space:]]*$//' | tr -d '\\r'); " +
        "  [ -z \"$title\" ] && title=$(basename \"$f\" .md); " +
        "  [ -z \"$group\" ] && group=\"Misc\"; " +
        "  [ -z \"$order\" ] && order=9999; " +
        "  res=\"$f|$title|$group|$icon|$order\"; " +
        "  echo \"$res\"; " +
        "  echo \"$res\" >> " + debugLog + "; " +
        "done; }";

    var safeScript = script.replace(/'/g, "'\\''");
    // Force UTF-8 locale to ensure emojis are output correctly
    return "env LC_ALL=C.UTF-8 bash -c '" + safeScript + "'";
}

// Parse the output of the index command
// Format: path|title|group|icon|order
function parseIndexOutput(output) {
    var lines = output.trim().split('\n');
    var groupsMap = {};
    var seenPaths = {};

    for (var i = 0; i < lines.length; i++) {
        var parts = lines[i].split('|');
        if (parts.length < 5) continue;

        var path = parts[0];
        if (seenPaths[path]) continue;
        seenPaths[path] = true;

        var title = parts[1];
        var group = parts[2];
        var icon = parts[3];
        var order = parseInt(parts[4]) || 9999;

        // console.log("Parsed cheat:", path, title, group); // verbose logging

        if (!groupsMap[group]) {
            groupsMap[group] = {
                name: group,
                icon: icon || GROUP_ICONS[group] || "🧩", // Use specific icon or fallback
                cheats: [],
                expanded: false // Default to collapsed
            };
        }

        // If the group itself doesn't have an icon yet, but the cheat has one, 
        // valid mainly if index provides group icon separately, but here we just use defaults.

        groupsMap[group].cheats.push({
            path: path,
            title: title,
            icon: icon,
            order: order,
            group: group
        });
    }

    console.log("Parsed " + lines.length + " lines. Found groups:", Object.keys(groupsMap));

    // Sort cheats within groups
    var sortedGroups = [];
    var groupNames = Object.keys(groupsMap).sort();

    for (var j = 0; j < groupNames.length; j++) {
        var g = groupsMap[groupNames[j]];
        g.cheats.sort(function (a, b) { return a.order - b.order; });
        sortedGroups.push(g);
    }

    return sortedGroups;
}

// Check if a string is likely a system icon name (alphanumeric + separators)
// vs an emoji or other text.
function isIconName(str) {
    if (!str) return false;
    // Allow standard icon names: "git", "network-wired", "go-next", "c++" (escaped as needed)
    // Rejects spaces, emojis (multibyte), etc.
    // Note: '+' is used in some icons like 'c++' or 'zoom-in+'
    return /^[a-zA-Z0-9\.\-_+]+$/.test(str);
}

function getExportMarkdownCommand(cheatsDir, outputFile) {
    // Generate command to concat all cheats
    // We reuse the logic: iterate, cat, strip frontmatter

    var cmd = "rm -f '" + outputFile + "'; " +
        "echo '# Dev Toolbox Cheatsheet' > '" + outputFile + "'; " +
        "find '" + cheatsDir + "' -type f -name '*.md' | sort | while read f; do " +
        "  echo '' >> '" + outputFile + "'; " +
        "  sed '1,80{/^Title:/d; /^Group:/d; /^Icon:/d; /^Order:/d}' \"$f\" >> '" + outputFile + "'; " +
        "done";

    return cmd;
}

// Export a single cheatsheet (front-matter stripped) to outputFile
function getExportCheatCommand(cheatPath, outputFile) {
    var safePath = cheatPath.replace(/'/g, "'\\''")
    var safeOut = outputFile.replace(/'/g, "'\\''");
    return "bash -c " +
        "\"sed '1,80{/^[Tt]itle:/d; /^[Gg]roup:/d; /^[Ii]con:/d; /^[Oo]rder:/d}' " +
        "'" + safePath + "' > '" + safeOut + "' && " +
        "notify-send 'DevToolbox' 'Exported to " + safeOut + "'\"";
}

// Build command to launch fzf search in a terminal.
// Selected file:line is opened in the preferred editor.
function getFzfSearchCommand(cheatsDir, editor) {
    var safeDir = cheatsDir.replace(/'/g, "'\\''")
    var safeEditor = (editor || "code").replace(/'/g, "'\\''");
    // The inner bash script mirrors the argos fzfSearch() function:
    //   grep -rnH all .md -> fzf with bat/cat preview -> open result in editor
    var inner =
        "if ! command -v fzf >/dev/null 2>&1; then " +
        "echo 'ERROR: fzf not installed. Install via apt/dnf/pacman.'; " +
        "read -rp 'Press enter to exit...'; exit 1; fi; " +
        "selected=\$(grep -rnH --include='*.md' . '" + safeDir + "' 2>/dev/null | " +
        "fzf --delimiter : " +
        "--preview 'if command -v bat >/dev/null 2>&1; then bat --style=numbers --color=always --highlight-line {2} {1}; else cat {1}; fi' " +
        "--preview-window 'right:60%' " +
        "--header 'Type to search all cheats... Enter to open.' " +
        "--bind 'enter:accept') || exit 0; " +
        "[ -z \"\$selected\" ] && exit 0; " +
        "file=\$(echo \"\$selected\" | cut -d: -f1); " +
        "line=\$(echo \"\$selected\" | cut -d: -f2); " +
        "if command -v '" + safeEditor + "' >/dev/null 2>&1; then " +
        "'" + safeEditor + "' -g \"\$file:\$line\"; " +
        "else " +
        "\${EDITOR:-nano} +\"\$line\" \"\$file\"; " +
        "fi";
    // Escape inner for embedding in outer single-quoted bash string
    var safeInner = inner.replace(/'/g, "'\\'' ");
    return "bash -c '" + safeInner + "'";
}
