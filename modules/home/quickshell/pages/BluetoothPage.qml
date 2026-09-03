import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"

// Same data source as wb-bt (bluetoothctl): no native Quickshell.Bluetooth
// here, its plugin isn't compiled in this nixpkgs build (see plan doc).
Item {
    id: root

    property bool btEnabled: false
    property var devices: []
    property var _paired: ({})
    property var _discoverable: []

    // bluetoothctl failures (bluetoothd down, etc.) otherwise show up as a
    // silently empty list with no indication anything went wrong.
    function reportError(label, text) {
        if (!text.trim().length) return
        Quickshell.execDetached(["notify-send", "-u", "critical", "-t", "4000", label, text.trim()])
    }

    function refresh() {
        powerProc.running = false
        powerProc.running = true
        pairedProc.running = false
        pairedProc.running = true
    }

    Component.onCompleted: refresh()

    Process {
        id: powerProc
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: root.btEnabled = text.includes("Powered: yes")
        }
        stderr: StdioCollector {
            onStreamFinished: root.reportError("Bluetooth", text)
        }
    }

    Process {
        id: toggleProc
    }
    function setEnabled(on) {
        if (toggleProc.running) return
        toggleProc.exec(["bluetoothctl", "power", on ? "on" : "off"])
        refreshTimer.restart()
    }

    Timer {
        id: refreshTimer
        interval: 800
        onTriggered: root.refresh()
    }

    Process {
        id: pairedProc
        command: ["bluetoothctl", "devices", "Paired"]
        stdout: StdioCollector {
            onStreamFinished: {
                const paired = {}
                if (text.trim().length) {
                    for (const line of text.trim().split("\n")) {
                        const m = line.match(/^Device ([0-9A-Fa-f:]+) (.*)$/)
                        if (m) paired[m[1]] = m[2]
                    }
                }
                root._paired = paired
                connectedProc.running = false
                connectedProc.running = true
            }
        }
        stderr: StdioCollector {
            onStreamFinished: root.reportError("Bluetooth", text)
        }
    }

    Process {
        id: connectedProc
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                const connected = new Set()
                if (text.trim().length) {
                    for (const line of text.trim().split("\n")) {
                        const m = line.match(/^Device ([0-9A-Fa-f:]+)/)
                        if (m) connected.add(m[1])
                    }
                }
                const list = []
                for (const mac in root._paired) {
                    list.push({ mac, name: root._paired[mac], connected: connected.has(mac) })
                }
                list.sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
                root.devices = list
            }
        }
        stderr: StdioCollector {
            onStreamFinished: root.reportError("Bluetooth", text)
        }
    }

    Process {
        id: connectProc
    }
    function toggleConnect(dev) {
        if (connectProc.running) return
        connectProc.exec(["bluetoothctl", dev.connected ? "disconnect" : "connect", dev.mac])
        refreshTimer.restart()
    }

    // One-shot timed scan (bluetoothctl blocks for the given duration then exits).
    Process {
        id: scanProc
        command: ["bluetoothctl", "--timeout", "4", "scan", "on"]
        onExited: root.refresh()
    }
    function scan() {
        scanProc.running = false
        scanProc.running = true
    }

    // Reconnect all paired devices (same logic as wb-bt toggle).
    Process {
        id: reconnectProc
        command: ["sh", "-c",
            "sleep 0.5; bluetoothctl devices Paired 2>/dev/null | awk '{print $2}' | while read -r mac; do [ -n \"$mac\" ] && bluetoothctl connect \"$mac\" >/dev/null 2>&1 & done"]
        onExited: refreshTimer.restart()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Text {
            text: "Bluetooth"
            font.bold: true
            font.pixelSize: 15
            color: Colors.c.text
            Layout.fillWidth: true
            Layout.bottomMargin: 8
        }

        SettingRow {
            icon: "󰂯"
            label: "Appareil"
            IconToggle {
                active: root.btEnabled
                onIcon: "󰂯"
                offIcon: "󰂲"
                tooltip: "Activer/désactiver le Bluetooth"
                onToggled: root.setEnabled(!root.btEnabled)
            }
        }
        SettingRow {
            icon: ""
            label: "Rechercher des appareils"
            clickable: true
            onClicked: root.scan()
        }
        SettingRow {
            icon: "󰁻"
            label: "Reconnecter tous"
            clickable: true
            onClicked: {
                reconnectProc.running = false
                reconnectProc.running = true
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 4
            clip: true
            spacing: 0
            model: root.devices

            delegate: Item {
                id: devDelegate
                required property var modelData
                width: ListView.view.width
                height: 40

                Rectangle {
                    anchors.fill: parent
                    color: devMouse.containsMouse ? Colors.baseGlassColor : "transparent"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 10

                    Text {
                        text: "󰂯"
                        font.pixelSize: 15
                        color: Colors.c.text_alt
                    }
                    Text {
                        text: devDelegate.modelData.name
                        color: Colors.c.text
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        text: devDelegate.modelData.connected ? "Connecté" : "Appairé"
                        color: Colors.c.text_alt
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Colors.c.border
                    opacity: 0.25
                }

                MouseArea {
                    id: devMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !connectProc.running
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.toggleConnect(devDelegate.modelData)
                }
            }
        }
    }
}
