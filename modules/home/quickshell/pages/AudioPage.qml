import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"
import "../services"

// Audio output device selection + master volume. Backend: AudioService
// (WirePlumber), which lists every sink and lets the user pick the default.
// Volume uses pamixer so the master slider and waybar's pulseaudio module
// (both pamixer) stay in sync.
Item {
    id: root

    property bool pamixerMuted: false
    property real masterVolume: 1

    Component.onCompleted: {
        AudioService.refresh()
        mutedCheck.running = true
        volCheck.running = true
    }

    function setVolume(x, width) {
        if (width <= 0) return
        const v = Math.max(0, Math.min(1, x / width))
        root.masterVolume = v
        pamixerExec.exec(["pamixer", "--set-volume", String(Math.round(v * 100))])
        // waybar pulseaudio will pick the change up itself via PA events.
    }

    Process {
        id: mutedCheck
        command: ["pamixer", "--get-mute"]
        stdout: StdioCollector {
            onStreamFinished: root.pamixerMuted = text.trim() === "true"
        }
    }

    Process {
        id: volCheck
        command: ["pamixer", "--get-volume"]
        stdout: StdioCollector {
            onStreamFinished: root.masterVolume = (parseInt(text) || 0) / 100
        }
    }

    Process {
        id: pamixerExec
    }

    Component {
        id: volumeSlider
        Item {
            implicitWidth: 220
            implicitHeight: 28

            Rectangle {
                id: volTrack
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                height: 4
                radius: 2
                color: Colors.c.base_alt

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * root.masterVolume
                    height: parent.height
                    radius: 2
                    color: Colors.c.accent
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: (mouse) => root.setVolume(mouse.x, width)
                onPositionChanged: if (pressed) root.setVolume(mouse.x, width)
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Text {
            text: "Son"
            font.bold: true
            font.pixelSize: 15
            color: Colors.c.text
            Layout.fillWidth: true
            Layout.bottomMargin: 8
        }

        // --- Master volume sliders ---
        Text {
            text: "Volume"
            font.pixelSize: 12
            color: Colors.c.text_alt
            Layout.topMargin: 4
            Layout.bottomMargin: 2
        }

        Loader {
            sourceComponent: volumeSlider
            Layout.fillWidth: true
        }

        SettingRow {
            icon: "󰝟"
            label: "Muet"
            IconToggle {
                active: root.pamixerMuted
                onIcon: "󰝟"
                offIcon: "󰕾"
                tooltip: "Activer/désactiver le son"
                onToggled: {
                    pamixerExec.exec(["pamixer", "-t"])
                    refreshTimer.restart()
                }
            }
        }

        Text {
            text: "Sortie"
            font.bold: true
            font.pixelSize: 12
            color: Colors.c.text_alt
            Layout.fillWidth: true
            Layout.topMargin: 12
            Layout.bottomMargin: 4
        }

        // --- Sink list (devices) ---
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 0
            model: AudioService.sinks

            delegate: Item {
                id: sinkDelegate
                required property var modelData
                property bool isDefault: modelData.name === AudioService.defaultSinkId

                width: ListView.view.width
                height: 44

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 10
                    color: sinkMouse.containsMouse || sinkDelegate.isDefault
                        ? Colors.baseGlassColor : "transparent"

                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: sinkDelegate.isDefault ? "󰓃" : "󰓄"
                        font.pixelSize: 15
                        color: sinkDelegate.isDefault ? Colors.c.accent : Colors.c.text_alt
                    }

                    Text {
                        text: AudioService.describe(sinkDelegate.modelData.name)
                        Layout.fillWidth: true
                        font.pixelSize: 13
                        color: Colors.c.text
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        visible: sinkDelegate.isDefault
                        width: 52
                        height: 20
                        radius: 10
                        color: Colors.c.accent
                        Text {
                            anchors.centerIn: parent
                            text: "défaut"
                            font.pixelSize: 10
                            color: Colors.c.on_accent
                        }
                    }
                }

                MouseArea {
                    id: sinkMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !sinkDelegate.isDefault
                    cursorShape: sinkDelegate.isDefault ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: AudioService.setDefaultSink(sinkDelegate.modelData.id)
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 400
        onTriggered: {
            AudioService.refresh()
            mutedCheck.running = false
            mutedCheck.running = true
            volCheck.running = false
            volCheck.running = true
        }
    }
}
