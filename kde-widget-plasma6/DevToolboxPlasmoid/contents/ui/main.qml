/*
 * Main UI entry point for DevToolbox Cheats Plasmoid (Plasma 6)
 */

import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    Plasmoid.status: PlasmaCore.Types.ActiveStatus

    // Show compact (icon) in panel; clicking expands to full popup
    preferredRepresentation: compactRepresentation

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    toolTipMainText: "DevToolbox Cheats"
    toolTipSubText: "Click to search and copy cheatsheets"

    // Toggle popup on click — uses PlasmoidItem's built-in 'expanded' property
    Plasmoid.onActivated: {
        console.log("[DevToolbox] Plasmoid.onActivated fired, expanded was:", expanded);
        expanded = !expanded
        console.log("[DevToolbox] expanded is now:", expanded);
    }

    Component.onCompleted: {
        console.log("[DevToolbox] main.qml loaded successfully");
        console.log("[DevToolbox] Plasmoid.title =", Plasmoid.title);
        console.log("[DevToolbox] Plasmoid.icon =", Plasmoid.icon);
    }
}
