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

/**
 * Plasma 6 Shield: Backslash-escape every non-alphanumeric character (except space)
 * to survive the DataSource whitelist stripping in Plasma 6.
 * The DataSource strips characters like / | $ _ = ; & [ ] before execution.
 * By escaping them, they survive the stripping AND the shell then interprets them correctly.
 */
function plasmaShield(str) {
    if (!str) return "";
    return str.replace(/([^a-zA-Z0-9 ])/g, "\\$1");
}

// Build command to index cheats (using shell for performance)
// We retain the bash logic for indexing because it's faster and reliable on Linux
function getIndexCommand(cheatsDir, cacheFile) {
    // Simple debug log path to avoid complex stripping issues
    var debugLog = "/tmp/devtoolbox-debug.log";

    // Build the script block
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

    // Escape for bash -c "..."
    var escapedScript = script.replace(/\\/g, "\\\\").replace(/"/g, "\\\"").replace(/\$/g, "\\$");

    // Construct the full command
    var finalCmd = "env LC_ALL=C.UTF-8 bash -c \"" + escapedScript + "\"";

    // Apply the Plasma 6 Shield
    return plasmaShield(finalCmd);
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


        if (!groupsMap[group]) {
            groupsMap[group] = {
                name: group,
                icon: icon || GROUP_ICONS[group] || "🧩", // Use specific icon or fallback
                cheats: [],
                expanded: false // Default to collapsed
            };
        }

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
    return /^[a-zA-Z0-9\.\-_+]+$/.test(str);
}

function getExportMarkdownCommand(cheatsDir, outputFile) {
    var script = "rm -f \"" + outputFile + "\"; " +
        "echo \"# Dev Toolbox Cheatsheet\" > \"" + outputFile + "\"; " +
        "find \"" + cheatsDir + "\" -type f -name '*.md' | sort | while read f; do " +
        "  echo '' >> \"" + outputFile + "\"; " +
        "  sed '1,80{/^Title:/d; /^Group:/d; /^Icon:/d; /^Order:/d}' \"$f\" >> \"" + outputFile + "\"; " +
        "done";

    var escapedScript = script.replace(/\\/g, "\\\\").replace(/"/g, "\\\"").replace(/\$/g, "\\$");
    return plasmaShield("bash -c \"" + escapedScript + "\"");
}

// Export a single cheatsheet (front-matter stripped) to outputFile
function getExportCheatCommand(cheatPath, outputFile) {
    var script = "sed '1,80{/^[Tt]itle:/d; /^[Gg]roup:/d; /^[Ii]con:/d; /^[Oo]rder:/d}' " +
        "\"" + cheatPath + "\" > \"" + outputFile + "\" && " +
        "notify-send 'DevToolbox' 'Exported to " + outputFile + "'";

    var escapedScript = script.replace(/\\/g, "\\\\").replace(/"/g, "\\\"").replace(/\$/g, "\\$");
    return plasmaShield("bash -c \"" + escapedScript + "\"");
}

// Build command to launch fzf search in a terminal.
function getFzfSearchCommand(cheatsDir, editor) {
    var safeEditor = editor || "code";
    var inner =
        "if ! command -v fzf >/dev/null 2>&1; then " +
        "echo 'ERROR: fzf not installed. Install via apt/dnf/pacman.'; " +
        "read -rp 'Press enter to exit...'; exit 1; fi; " +
        "selected=$(grep -rnH --include='*.md' . \"" + cheatsDir + "\" 2>/dev/null | " +
        "fzf --delimiter : " +
        "--preview 'if command -v bat >/dev/null 2>&1; then bat --style=numbers --color=always --highlight-line {2} {1}; else cat {1}; fi' " +
        "--preview-window 'right:60%' " +
        "--header 'Type to search all cheats... Enter to open.' " +
        "--bind 'enter:accept') || exit 0; " +
        "[ -z \"$selected\" ] && exit 0; " +
        "file=$(echo \"$selected\" | cut -d: -f1); " +
        "line=$(echo \"$selected\" | cut -d: -f2); " +
        "if command -v \"" + safeEditor + "\" >/dev/null 2>&1; then " +
        "\"" + safeEditor + "\" -g \"$file:$line\"; " +
        "else " +
        "${EDITOR:-nano} +\"$line\" \"$file\"; " +
        "fi";

    var escapedScript = inner.replace(/\\/g, "\\\\").replace(/"/g, "\\\"").replace(/\$/g, "\\$");
    return plasmaShield("bash -c \"" + escapedScript + "\"");
}
