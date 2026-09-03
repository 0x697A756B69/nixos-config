import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"
import "../services"

// Audio page: master volume + mute for the default sink, then a list of
// every output (sink) and input (source) device, each with its own volume
// slider and the ability to set it as default. Backend: AudioService (wpctl).
Item {
    id: root

    // Shared generic slider used for the master volume.
    Item {
        id: masterSliderHost
        visible: false
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

        // --- Master volume ---
        Text {
            text: "Volume"
            font.pixelSize: 12
            color: Colors.c.text_alt
            Layout.topMargin: 4
            Layout.bottomMargin: 2
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            Layout.bottomMargin: 6
            spacing: 10

            Text {
                text: AudioService.masterMuted ? "󰝟" : "󰕾"
                font.pixelSize: 17
                color: AudioService.masterMuted ? Colors.c.error : Colors.c.accent
            }

            Item {
                Layout.fillWidth: true
                height: 24

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 5
                    radius: 2.5
                    color: Colors.c.base_alt
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * Math.max(0, Math.min(1, AudioService.masterVolume))
                        height: parent.height
                        radius: 2.5
                        color: Colors.c.accent
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: (mouse) => setMaster(mouse.x, width)
                    onPositionChanged: if (pressed) setMaster(mouse.x, width)
                }

                function setMaster(x, w) {
                    if (w <= 0) return
                    const v = Math.max(0, Math.min(1, x / w))
                    AudioService.setSinkVolume(AudioService.defaultSinkDeviceId, v)
                }
            }

            Text {
                text: Math.round(AudioService.masterVolume * 100) + "%"
                font.pixelSize: 12
                color: Colors.c.text_alt
                Layout.preferredWidth: 42
                horizontalAlignment: Text.AlignRight
            }
        }

        // --- Output devices ---
        Text {
            text: "Sortie"
            font.bold: true
            font.pixelSize: 12
            color: Colors.c.text_alt
            Layout.fillWidth: true
            Layout.topMargin: 6
            Layout.bottomMargin: 2
        }

        ListView {
            Layout.fillWidth: true
            implicitHeight: Math.min(contentHeight, 250)
            clip: true
            spacing: 2
            model: AudioService.sinks

            delegate: Item {
                id: sDel
                required property var modelData
                property bool isDefault: modelData.default
                width: ListView.view.width
                height: 58

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 10
                    color: rowMouse.containsMouse || sDel.isDefault
                        ? Colors.baseGlassColor : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 6
                    anchors.bottomMargin: 5
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            text: sDel.isDefault ? "󰓃" : "󰓄"
                            font.pixelSize: 14
                            color: sDel.isDefault ? Colors.c.accent : Colors.c.text_alt
                        }
                        Text {
                            text: AudioService.describe(sDel.modelData.name)
                            Layout.fillWidth: true
                            font.pixelSize: 12
                            color: Colors.c.text
                            elide: Text.ElideRight
                        }
                        Rectangle {
                            visible: sDel.isDefault
                            width: 46
                            height: 18
                            radius: 9
                            color: Colors.c.accent
                            Text {
                                anchors.centerIn: parent
                                text: "défaut"
                                font.pixelSize: 9
                                color: Colors.c.on_accent
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        height: 20

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 4
                            radius: 2
                            color: Colors.c.base_alt
                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * Math.max(0, Math.min(1, AudioService.volumes[sDel.modelData.id] || 0))
                                height: parent.height
                                radius: 2
                                color: Colors.c.accent
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: (mouse) => setVol(mouse.x, width)
                            onPositionChanged: if (pressed) setVol(mouse.x, width)
                            onClicked: if (!sDel.isDefault) AudioService.setDefaultSink(sDel.modelData.id)
                        }

                        function setVol(x, w) {
                            if (w <= 0) return
                            const v = Math.max(0, Math.min(1, x / w))
                            AudioService.setSinkVolume(sDel.modelData.id, v)
                        }
                    }
                }
            }
        }

        // --- Input devices ---
        Text {
            text: "Entrée"
            font.bold: true
            font.pixelSize: 12
            color: Colors.c.text_alt
            Layout.fillWidth: true
            Layout.topMargin: 6
            Layout.bottomMargin: 2
        }

        ListView {
            Layout.fillWidth: true
            implicitHeight: Math.min(contentHeight, 190)
            clip: true
            spacing: 2
            model: AudioService.sources

            delegate: Item {
                id: srcDel
                required property var modelData
                property bool isDefault: modelData.default
                width: ListView.view.width
                height: 50

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 10
                    color: srcRowMouse.containsMouse || srcDel.isDefault
                        ? Colors.baseGlassColor : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: srcDel.isDefault ? "󰎙" : "󰍬"
                        font.pixelSize: 14
                        color: srcDel.isDefault ? Colors.c.accent : Colors.c.text_alt
                    }
                    Text {
                        text: AudioService.describe(srcDel.modelData.name)
                        Layout.fillWidth: true
                        font.pixelSize: 12
                        color: Colors.c.text
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        visible: srcDel.isDefault
                        width: 46
                        height: 18
                        radius: 9
                        color: Colors.c.accent
                        Text {
                            anchors.centerIn: parent
                            text: "défaut"
                            font.pixelSize: 9
                            color: Colors.c.on_accent
                        }
                    }
                }

                MouseArea {
                    id: srcRowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (!srcDel.isDefault) AudioService.setDefaultSource(srcDel.modelData.id)
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    onVisibleChanged: {
        if (visible) AudioService.refresh()
    }

    Component.onCompleted: AudioService.refresh()
}
