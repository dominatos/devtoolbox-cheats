/*
 * Main UI entry point for DevToolbox Cheats Plasmoid
 */

import QtQuick
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    // Plasmoid preferred representation (Compact/Full)
    preferredRepresentation: compactRepresentation

    // Define representations
    compactRepresentation: Component {
        CompactRepresentation {}
    }
    fullRepresentation: Component {
        FullRepresentation {}
    }

    // Configuration properties shortcut
    property string cheatsDir: plasmoid.configuration.cheatsDir
    property string cacheFile: plasmoid.configuration.cacheFile
    property string preferredEditor: plasmoid.configuration.preferredEditor

    toolTipMainText: "DevToolbox Cheats"
    toolTipSubText: "Click to search and copy cheatsheets"

    Component.onCompleted: {
        console.log("DevToolbox Cheats widget loaded");
    }
}
