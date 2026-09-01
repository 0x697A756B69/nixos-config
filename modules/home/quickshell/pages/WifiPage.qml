import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../"

// Same data source as wb-net (nmcli): no native Quickshell.Networking here,
// its plugin isn't compiled in this nixpkgs build (see plan doc).
Item {
    id: root

    property bool wifiEnabled: false
    property var accessPoints: []

    function refresh() {
        radioProc.running = false
        radioProc.running = true
        listProc.running = false
        listProc.running = true
    }

    Component.onCompleted: refresh()

    Process {
        id: radioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }

    Process {
        id: toggleProc
    }

    function setEnabled(on) {
        if (toggleProc.running) return
        toggleProc.exec(["nmcli", "radio", "wifi", on ? "on" : "off"])
        refreshTimer.restart()
    }

    Timer {
        id: refreshTimer
        interval: 700
        onTriggered: root.refresh()
    }

    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "SSID,SECURITY,SIGNAL,IN-USE", "dev", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().length ? text.trim().split("\n") : []
                const seen = new Set()
                const aps = []
                for (const line of lines) {
                    const parts = line.split(":")
                    if (parts.length < 4) continue
                    const inUse = parts.pop() === "*"
                    const signal = parseInt(parts.pop()) || 0
                    const security = parts.pop()
                    const ssid = parts.join(":")
                    if (!ssid || seen.has(ssid)) continue
                    seen.add(ssid)
                    aps.push({ ssid, signal, inUse, open: security === "" || security === "--" })
                }
                aps.sort((a, b) => b.signal - a.signal)
                root.accessPoints = aps
            }
        }
    }

    Process {
        id: connectProc
    }
    function connectTo(ssid) {
        if (connectProc.running) return
        connectProc.exec(["nmcli", "dev", "wifi", "connect", ssid])
        refreshTimer.restart()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Text {
            text: "Wi-Fi"
            font.bold: true
            font.pixelSize: 15
            color: Colors.c.text
            Layout.fillWidth: true
            Layout.bottomMargin: 8
        }

        SettingRow {
            icon: "󰖩"
            label: "Réseau"
            IconToggle {
                active: root.wifiEnabled
                onIcon: "󰖩"
                offIcon: "󰖪"
                tooltip: "Activer/désactiver le Wi-Fi"
                onToggled: root.setEnabled(!root.wifiEnabled)
            }
        }
        SettingRow {
            icon: ""
            label: "Rechercher des réseaux"
            clickable: true
            onClicked: root.refresh()
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 4
            clip: true
            spacing: 0
            model: root.accessPoints

            delegate: Item {
                id: apDelegate
                required property var modelData
                width: ListView.view.width
                height: 40

                Rectangle {
                    anchors.fill: parent
                    color: apMouse.containsMouse && modelData.open ? Colors.baseGlassColor : "transparent"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 10

                    Text {
                        text: apDelegate.modelData.signal > 80 ? "󰤨"
                            : apDelegate.modelData.signal > 60 ? "󰤥"
                            : apDelegate.modelData.signal > 40 ? "󰤢"
                            : apDelegate.modelData.signal > 20 ? "󰤟"
                            : "󰤯"
                        font.pixelSize: 15
                        color: Colors.c.text_alt
                    }
                    Text {
                        text: apDelegate.modelData.ssid
                        color: Colors.c.text
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    Text {
                        visible: !apDelegate.modelData.open
                        text: "󰌾"
                        color: Colors.c.text_alt
                    }
                    Text {
                        text: apDelegate.modelData.signal + "%"
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
                    id: apMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: apDelegate.modelData.open && !connectProc.running
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.connectTo(apDelegate.modelData.ssid)
                }
            }
        }
    }
}
