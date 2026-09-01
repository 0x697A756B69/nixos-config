import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../"

// Matches the repo's actual Displays page (screenshots/6.png, Hyprland tab):
// plain icon+label rows directly on the page with a thin bottom divider,
// control right-aligned — no colored card/grouped-list segments here, that
// pattern is used elsewhere in their app but not on this page.
Item {
    id: root

    property var monitor: null
    property var availableModes: []
    property bool freqExpanded: false
    // availableModes entries look like "2560x1440@279.96Hz"; keep only the
    // ones matching the current resolution (resolution itself is read-only here).
    readonly property var freqModes: monitor
        ? availableModes.filter(m => m.startsWith(monitor.width + "x" + monitor.height + "@"))
        : []

    function refresh() {
        listProc.running = false
        listProc.running = true
    }

    Component.onCompleted: refresh()

    // Set whenever applyMonitor() is called while a previous call is still
    // in flight; dispatched once the refresh below confirms the real state,
    // instead of racing another hyprctl eval against stale data.
    property var pendingOverrides: null

    Process {
        id: listProc
        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const mons = JSON.parse(text)
                    if (mons.length) {
                        root.monitor = mons[0]
                        root.availableModes = mons[0].availableModes || []
                    }
                } catch (e) { }
                if (root.pendingOverrides) {
                    const next = root.pendingOverrides
                    root.pendingOverrides = null
                    root._dispatchMonitor(next)
                }
            }
        }
    }

    Process {
        id: applyProc
        onExited: root.refresh()
    }

    // Entry point for every control (HDR/VRR/mode): if a previous
    // request hasn't been confirmed by hyprctl yet, merge into it instead of
    // firing a second hyprctl eval computed from the same stale monitor.
    function applyMonitor(overrides) {
        if (!root.monitor) return
        if (applyProc.running) {
            root.pendingOverrides = Object.assign({}, root.pendingOverrides || {}, overrides)
            return
        }
        root._dispatchMonitor(overrides)
    }

    // Single write path: always send the full known state so a partial
    // update doesn't reset the rest (same rule as the AGS/Astal version).
    function _dispatchMonitor(overrides) {
        const m = root.monitor
        const mode = overrides.mode ?? (m.width + "x" + m.height + "@" + m.refreshRate.toFixed(2))
        const scale = overrides.scale !== undefined ? overrides.scale : m.scale
        const vrr = overrides.vrr !== undefined ? overrides.vrr : m.vrr
        const hdrOn = overrides.hdrOn !== undefined
            ? overrides.hdrOn
            : (m.colorManagementPreset === "hdr" || m.colorManagementPreset === "hdredid")
        const cm = hdrOn ? "hdr" : "srgb"
        const bitdepth = hdrOn ? 10 : 8
        applyProc.exec(["hyprctl", "eval",
            `hl.monitor({ output = "${m.name}", mode = "${mode}", position = "${m.x}x${m.y}", scale = ${scale}, cm = "${cm}", bitdepth = ${bitdepth}, vrr = ${vrr} })`])
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        visible: root.monitor !== null

        Text {
            text: "Écran"
            font.bold: true
            font.pixelSize: 15
            color: Colors.c.text
            Layout.fillWidth: true
        }

        Text {
            text: root.monitor ? (root.monitor.description || root.monitor.name) : ""
            font.italic: true
            font.pixelSize: 11
            color: Colors.c.text_alt
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.bottomMargin: 8
        }

        SettingRow {
            icon: "󰵽"
            label: "HDR"
            IconToggle {
                id: hdrToggle
                active: root.monitor
                    ? (root.monitor.colorManagementPreset === "hdr" || root.monitor.colorManagementPreset === "hdredid")
                    : false
                onIcon: "󰵽"
                offIcon: "󰵾"
                tooltip: "Activer/désactiver le HDR"
                onToggled: root.applyMonitor({ hdrOn: !hdrToggle.active })
            }
        }

        SettingRow {
            icon: "󰓦"
            label: "VRR"
            IconToggle {
                id: vrrToggle
                active: root.monitor ? root.monitor.vrr : false
                onIcon: "󰓦"
                offIcon: "󰓨"
                tooltip: "Activer/désactiver le taux de rafraîchissement variable"
                onToggled: root.applyMonitor({ vrr: !vrrToggle.active })
            }
        }

        SettingRow {
            icon: "󰍹"
            label: "Résolution"
            Text {
                text: root.monitor ? (root.monitor.width + "×" + root.monitor.height) : ""
                color: Colors.c.text_alt
            }
        }

        SettingRow {
            icon: "󰓅"
            label: "Fréquence"
            clickable: true
            onClicked: root.freqExpanded = !root.freqExpanded
            Text {
                text: root.monitor ? root.monitor.refreshRate.toFixed(2) + " Hz" : ""
                color: Colors.c.text_alt
            }
            Text {
                text: root.freqExpanded ? "󰅃" : "󰅀"
                color: Colors.c.text_alt
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 4
            visible: root.freqExpanded
            clip: true
            spacing: 0
            model: root.freqModes

            delegate: Item {
                id: freqDelegate
                required property var modelData
                property bool isCurrent: root.monitor
                    && modelData === (root.monitor.width + "x" + root.monitor.height + "@" + root.monitor.refreshRate.toFixed(2) + "Hz")
                width: ListView.view.width
                height: 36

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: freqModeMouse.containsMouse && !freqDelegate.isCurrent ? Colors.baseGlassColor : "transparent"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    Text {
                        text: freqDelegate.modelData.split("@")[1]
                        color: freqDelegate.isCurrent ? Colors.c.disabled : Colors.c.text
                        Layout.fillWidth: true
                    }
                    Text {
                        visible: freqDelegate.isCurrent
                        text: "actuel"
                        color: Colors.c.text_alt
                        font.pixelSize: 11
                    }
                }

                MouseArea {
                    id: freqModeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !freqDelegate.isCurrent
                    cursorShape: !freqDelegate.isCurrent ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.applyMonitor({ mode: freqDelegate.modelData.replace("Hz", "") })
                }
            }
        }
    }
}
