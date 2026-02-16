/*
 * Utility functions for DevToolbox Cheats Plasmoid
 */

.pragma library

// Check if file exists
function fileExists(path) {
    var xhr = new XMLHttpRequest();
    xhr.open("HEAD", path, false);
    try {
        xhr.send(null);
        return xhr.status !== 404;
    } catch (e) {
        return false;
    }
}

// Read file content
function readFile(path) {
    var xhr = new XMLHttpRequest();
    xhr.open("GET", path, false);
    xhr.send(null);
    return xhr.responseText;
}

// Save text to file
function writeFile(path, content) {
    // Note: Writing files directly from QML/JS in Plasma is restricted for security.
    // We typically rely on a C++ plugin or DataEngine, but for pure QML widgets
    // we might need to use a workaround like `echo ... > file` via command execution
    // or use a dedicated helper executable.
    
    // However, since we are adapting a bash script which had full access,
    // and Plasma widgets usually have some write access to ~/.cache or config,
    // we'll try to use standard logic or fallback to shell command.
    
    // Using simple shell redirection for this prototype as standard JS File API isn't fully available in QML context
    // without C++ backend.
    
    // Escape single quotes for shell
    var safeContent = content.replace(/'/g, "'\\''");
    var cmd = "cat <<EOF > '" + path + "'\n" + content + "\nEOF";
    // executeCommand(cmd, ...); -- this logic will be handled better by the main app logic
    // or we assume we can't easily write from pure JS without an engine.
    
    // ALTERNATIVE: Use the bash helper script concept.
    return false; // Not implemented directly in JS for now, will use shell commands from QML
}

// Strip leading/trailing spaces
function trim(str) {
    return str.replace(/^\s+|\s+$/g, '');
}

// Execute command
function executeCommand(dataSource, cmd, callback) {
    dataSource.connectedSources = [];
    dataSource.connectedSources = [cmd];
    // Output handling would be done via onNewData signal in the main QML
}

// Format date
function formatDate(date) {
    var d = new Date(date),
        month = '' + (d.getMonth() + 1),
        day = '' + d.getDate(),
        year = d.getFullYear(),
        hour = '' + d.getHours(),
        minute = '' + d.getMinutes();

    if (month.length < 2) month = '0' + month;
    if (day.length < 2) day = '0' + day;
    if (hour.length < 2) hour = '0' + hour;
    if (minute.length < 2) minute = '0' + minute;

    return [year, month, day].join('-') + '_' + [hour, minute].join('-');
}
