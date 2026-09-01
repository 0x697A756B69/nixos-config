import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"

// Ported from caelestia-dots/shell: modules/nexus/pages/wallandstyle/
// WallpaperSelect.qml (page layout) + modules/nexus/common/WallItem.qml
// (tile). Spacing/rounding values below are their real Tokens values
// (plugin/src/Caelestia/Config/tokens.hpp: rounding.largeIncreased=20,
// spacing.small=8, spacing.medium=12, spacing.large=16), not approximations.
// Two things are simplified rather than ported 1:1: their WallItem uses a
// custom Material-3 ripple (Shape + RadialGradient expanding-circle) for
// press feedback -- a generic design-system primitive used across their
// whole shell, not wallpaper-specific -- replaced here with a plain hover
// tint at the same 0.08 opacity their StateLayer uses at rest. Their
// LoadingIndicator spinner is skipped too: it covers network/slow image
// loads, and our thumbnails are local files that decode near-instantly.
Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Text {
            text: "Fond d'écran"
            font.bold: true
            font.pixelSize: 15
            color: Colors.c.text
            Layout.fillWidth: true
            Layout.bottomMargin: 16
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            columns: 2
            rowSpacing: 12
            columnSpacing: 16

            Repeater {
                model: Wallpapers.list

                delegate: ColumnLayout {
                    id: tile
                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        id: imgWrapper
                        Layout.fillWidth: true
                        Layout.preferredHeight: width
                        radius: 20
                        color: Colors.c.base_alt
                        clip: true

                        Image {
                            id: img
                            anchors.fill: parent
                            source: "file://" + tile.modelData.thumbnail
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            opacity: status === Image.Ready ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Colors.c.text
                            opacity: tileMouse.containsMouse ? 0.08 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Wallpapers.setWallpaper(tile.modelData.path)
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 8
                        text: tile.modelData.name
                        color: Colors.c.text_alt
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
