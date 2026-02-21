/*
 * Main UI entry point for DevToolbox Cheats Plasmoid (Plasma 6)
 */

import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    // Clicking the compact icon toggles the full popup
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    
    // Show compact (icon) in panel; clicking expands to full popup
    preferredRepresentation: compactRepresentation

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    toolTipMainText: "DevToolbox Cheats"
    toolTipSubText: "Click to search and copy cheatsheets"
    
    // This property controls popup behavior
    property bool expanded: false
    
    Plasmoid.onActivated: {
        expanded = !expanded
    }

    Component.onCompleted: {
        console.log("[DevToolbox] main.qml loaded successfully");
        console.log("[DevToolbox] Plasmoid.title =", Plasmoid.title);
        console.log("[DevToolbox] Plasmoid.icon =", Plasmoid.icon);
    }
}
