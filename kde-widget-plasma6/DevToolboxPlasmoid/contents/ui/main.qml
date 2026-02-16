/*
 * Main UI entry point for DevToolbox Cheats Plasmoid
 */

import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0

Item {
    id: root

    // Plasmoid preferred representation (Compact/Full)
    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    // Define representations
    Plasmoid.compactRepresentation: CompactRepresentation {}
    Plasmoid.fullRepresentation: FullRepresentation {}

    // Configuration properties shortcut
    property string cheatsDir: plasmoid.configuration.cheatsDir
    property string cacheFile: plasmoid.configuration.cacheFile
    property string preferredEditor: plasmoid.configuration.preferredEditor

    Component.onCompleted: {
        console.log("DevToolbox Cheats widget loaded");
    }
}
