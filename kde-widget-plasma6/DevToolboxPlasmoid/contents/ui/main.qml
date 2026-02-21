/*
 * Main UI entry point for DevToolbox Cheats Plasmoid (Plasma 6)
 */

import QtQuick
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    // Clicking the compact icon toggles the full popup
    activationTogglesExpanded: true

    // Show compact (icon) in panel; clicking expands to full popup
    preferredRepresentation: compactRepresentation

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    toolTipMainText: "DevToolbox Cheats"
    toolTipSubText: "Click to search and copy cheatsheets"

    Component.onCompleted: {
        console.log("[DevToolbox] main.qml loaded successfully");
        console.log("[DevToolbox] Plasmoid.title =", Plasmoid.title);
        console.log("[DevToolbox] Plasmoid.icon =", Plasmoid.icon);
    }
}
