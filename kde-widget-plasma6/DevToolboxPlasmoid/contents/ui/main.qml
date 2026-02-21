/*
 * Main UI entry point for DevToolbox Cheats Plasmoid
 */

import QtQuick
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    // Show compact (icon) in panel; clicking expands to full popup
    preferredRepresentation: compactRepresentation

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    toolTipMainText: "DevToolbox Cheats"
    toolTipSubText: "Click to search and copy cheatsheets"

    Component.onCompleted: {
        console.log("DevToolbox Cheats widget loaded");
    }
}
