import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"
import "../components"

Item {
    id: root

    property var monitor: null
    property var availableModes: []
    property string currentModeString: ""
    // availableModes entries look like "2560x1440@279.96Hz"; keep only the
    // ones matching the current resolution (resolution itself is read-only here).
    readonly property var freqModes: monitor
        ? availableModes.filter(m => m.startsWith(monitor.width + "x" + monitor.height + "@"))
        : []

    function refresh() {
        listProc.running = false
        listProc.running = true
    }

    // hyprctl failures otherwise show up as a silently blank page (see
    // the empty catch below) with no indication anything went wrong.
    function reportError(text) {
        if (!text.trim().length) return
        Quickshell.execDetached(["notify-send", "-u", "critical", "-t", "4000", "Écran", text.trim()])
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
                        root.currentModeString = root.monitor.width + "x" + root.monitor.height
                            + "@" + root.monitor.refreshRate.toFixed(2) + "Hz"
                    }
                } catch (e) { root.reportError("hyprctl a renvoyé une réponse invalide : " + e.message) }
                if (root.pendingOverrides) {
                    const next = root.pendingOverrides
                    root.pendingOverrides = null
                    root._dispatchMonitor(next)
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: root.reportError(text)
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

    FrequencyModal {
        id: freqModal
        modes: root.freqModes
        currentMode: root.currentModeString
        onSelected: (mode) => root.applyMonitor({ mode: mode.replace("Hz", "") })
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
            onClicked: freqModal.open()
            Text {
                text: root.monitor ? root.monitor.refreshRate.toFixed(2) + " Hz" : ""
                color: Colors.c.text_alt
            }
            Text {
                text: "󰅀"
                color: Colors.c.text_alt
            }
        }
    }
}
