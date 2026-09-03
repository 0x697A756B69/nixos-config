import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root

    property bool btEnabled: false
    property bool scanning: false
    property var devices: []
    property var _paired: ({})
    property var _connected: ({})
    property var _discovered: ({})

    function reportError(text) {
        if (!text.trim().length) return
        Quickshell.execDetached(["notify-send", "-u", "critical", "-t", "4000", "Bluetooth", text.trim()])
    }

    // Merge paired + connected + discovered into one display list.
    function rebuild() {
        const merged = {}
        for (const mac in root._paired) {
            merged[mac] = { mac: mac, name: root._paired[mac], paired: true, connected: !!root._connected[mac], discovered: false }
        }
        for (const mac in root._discovered) {
            if (merged[mac]) {
                merged[mac].name = root._discovered[mac] || merged[mac].name
            } else {
                merged[mac] = { mac: mac, name: root._discovered[mac] || mac, paired: false, connected: !!root._connected[mac], discovered: true }
            }
        }
        const list = Object.values(merged)
        list.sort((a, b) =>
            (b.connected - a.connected) ||
            (b.paired - a.paired) ||
            (b.discovered - a.discovered) ||
            a.name.localeCompare(b.name))
        root.devices = list
    }

    function refresh() {
        powerProc.running = false
        powerProc.running = true
        pairedProc.running = false
        pairedProc.running = true
        connectedProc.running = false
        connectedProc.running = true
    }

    Component.onCompleted: refresh()

    Process {
        id: powerProc
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: root.btEnabled = text.includes("Powered: yes")
        }
        stderr: StdioCollector { onStreamFinished: root.reportError(text) }
    }

    Process {
        id: toggleProc
    }
    function setEnabled(on) {
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
                const p = {}
                if (text.trim().length) {
                    for (const line of text.trim().split("\n")) {
                        const m = line.match(/^Device ([0-9A-Fa-f:]+) (.*)$/)
                        if (m) p[m[1]] = m[2]
                    }
                }
                root._paired = p
                root.rebuild()
            }
        }
        stderr: StdioCollector { onStreamFinished: root.reportError(text) }
    }

    Process {
        id: connectedProc
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                const c = {}
                if (text.trim().length) {
                    for (const line of text.trim().split("\n")) {
                        const m = line.match(/^Device ([0-9A-Fa-f:]+) (.*)$/)
                        if (m) c[m[1]] = m[2]
                    }
                }
                root._connected = c
                root.rebuild()
            }
        }
        stderr: StdioCollector { onStreamFinished: root.reportError(text) }
    }

    // Scan with a timeout so bluetoothctl exits on its own (without --timeout
    // it never emits NEW Device lines when stdout isn't a TTY). All lines are
    // collected and parsed in onStreamFinished.
    Process {
        id: scanProc
        stdout: StdioCollector {
            onStreamFinished: {
                const d = root._discovered
                for (const line of text.split("\n")) {
                    const m = line.match(/\[NEW\] Device ([0-9A-Fa-f:]+)\s*(.*)$/)
                    if (!m) continue
                    const mac = m[1].toUpperCase()
                    const name = (m[2] || "").trim()
                    if (name && !(mac in d)) d[mac] = name
                    else if (!(mac in d)) d[mac] = mac
                }
                root._discovered = d
                root.scanning = false
                root.rebuild()
            }
        }
        onExited: { root.scanning = false; root.refresh() }
    }
    function startScan() {
        root.scanning = true
        root._discovered = {}
        scanProc.exec(["bluetoothctl", "--timeout", "6", "scan", "on"])
    }
    function stopScan() {
        root.scanning = false
        scanProc.kill()
        toggleScanProc.exec(["bluetoothctl", "scan", "off"])
    }

    Process {
        id: toggleScanProc
    }

    Process {
        id: connectProc
    }
    function toggleConnect(dev) {
        if (connectProc.running) return
        if (dev.connected) {
            connectProc.exec(["bluetoothctl", "disconnect", dev.mac])
        } else if (dev.paired) {
            connectProc.exec(["bluetoothctl", "connect", dev.mac])
        } else {
            connectProc.exec(["bluetoothctl", "pair", dev.mac])
        }
        refreshTimer.restart()
    }

    // Reconnect all paired devices.
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
            label: "Bluetooth"
            IconToggle {
                active: root.btEnabled
                onIcon: "󰂯"
                offIcon: "󰂲"
                tooltip: "Activer/désactiver le Bluetooth"
                onToggled: root.setEnabled(!root.btEnabled)
            }
        }
        SettingRow {
            icon: root.scanning ? "󰂯" : "󰂰"
            label: root.scanning ? "Recherche en cours…" : "Rechercher des appareils"
            clickable: true
            onClicked: root.scanning ? root.stopScan() : root.startScan()
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
                height: 46

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 10
                    color: devMouse.containsMouse || devDelegate.modelData.connected
                        ? Colors.baseGlassColor : "transparent"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: devDelegate.modelData.connected ? "󰂯"
                              : (devDelegate.modelData.paired ? "󰂲" : "󰂰")
                        font.pixelSize: 16
                        color: devDelegate.modelData.connected ? Colors.c.accent : Colors.c.text_alt
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: devDelegate.modelData.name || devDelegate.modelData.mac
                            Layout.fillWidth: true
                            font.pixelSize: 13
                            color: Colors.c.text
                            elide: Text.ElideRight
                        }
                        Text {
                            text: devDelegate.modelData.connected ? "Connecté"
                                  : (devDelegate.modelData.paired ? "Appairé" : "À proximité")
                            font.pixelSize: 10
                            color: devDelegate.modelData.connected ? Colors.c.accent : Colors.c.text_alt
                        }
                    }

                    Text {
                        text: devDelegate.modelData.connected ? "Déconnecter"
                              : (devDelegate.modelData.paired ? "Connecter" : "Appairer")
                        font.pixelSize: 11
                        color: Colors.c.accent
                    }
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

            Text {
                anchors.centerIn: parent
                visible: root.devices.length === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.scanning ? "Recherche d'appareils…" : "Aucun appareil"
                font.pixelSize: 12
                color: Colors.c.text_alt
            }
        }
    }
}
