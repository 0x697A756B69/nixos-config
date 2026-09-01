# Settings app (Wi-Fi / Bluetooth / Display), rebuilt in Quickshell/QML to
# match the visual design of pctrade/end4-pC's Settings app (NavigationRail,
# draggable window, Escape-to-close) — replaces modules/home/ags. Opened via
# right-click on the matching waybar modules (see modules/home/waybar).
{ config, pkgs, lib, ... }:

let
  # Flat JSON color roles (modules/home/theming/matugen) parsed by a
  # JsonAdapter/FileView singleton at runtime — no @import-propagation bug
  # like the GTK4/CSS version had, since QML reads the file directly.
  colorsQml = pkgs.writeText "quickshell-colors.qml" ''
    pragma Singleton
    import QtQuick
    import Quickshell
    import Quickshell.Io

    Singleton {
        id: root
        property alias c: colorsAdapter
        readonly property color baseGlassColor: Qt.rgba(
            c.base_glass.r / 255, c.base_glass.g / 255, c.base_glass.b / 255, c.base_glass.a)
        // Same tint, more opaque: used for the card/rail backgrounds so
        // page content stays legible without blur behind them. baseGlassColor
        // itself stays light — it's also used for hover/active tints.
        readonly property color panelColor: Qt.rgba(
            c.base_glass.r / 255, c.base_glass.g / 255, c.base_glass.b / 255, 0.88)

        FileView {
            path: "${config.styling.palette}/colors.json"
            preload: true
            watchChanges: true
            onFileChanged: reload()

            JsonAdapter {
                id: colorsAdapter
                property string base: "#000000"
                property string base_alt: "#000000"
                property string text: "#ffffff"
                property string text_alt: "#cccccc"
                property string accent: "#ffffff"
                property string on_accent: "#000000"
                property string disabled: "#888888"
                property string error: "#ff0000"
                property string border: "#444444"
                property string warning: "#ffcc00"
                property var base_glass: ({ r: 0, g: 0, b: 0, a: 0.45 })
            }
        }
    }
  '';

  quickshellSrc = pkgs.runCommand "quickshell-settings-src" { } ''
    mkdir -p $out/pages
    cp ${./shell.qml} $out/shell.qml
    cp ${./SettingsWindow.qml} $out/SettingsWindow.qml
    cp ${./IconToggle.qml} $out/IconToggle.qml
    cp ${./SettingRow.qml} $out/SettingRow.qml
    cp ${colorsQml} $out/Colors.qml
    cp ${./pages/WifiPage.qml} $out/pages/WifiPage.qml
    cp ${./pages/BluetoothPage.qml} $out/pages/BluetoothPage.qml
    cp ${./pages/DisplayPage.qml} $out/pages/DisplayPage.qml
  '';
in
{
  options.programs.quickshell-settings.package = lib.mkOption {
    type = lib.types.package;
    description = ''
      Source directory of the Quickshell settings app (shell.qml + *.qml).
      Launched by wb-dropdown at session startup (see modules/home/hyprland).
    '';
  };

  config = {
    programs.quickshell-settings.package = quickshellSrc;

    home.packages = [
      pkgs.quickshell
      (pkgs.writeShellScriptBin "wb-dropdown" ''
        #!/usr/bin/env bash
        exec ${pkgs.quickshell}/bin/quickshell -p ${quickshellSrc}
      '')
      # ipc call needs -p pointing at the exact same path wb-dropdown was
      # launched from; this wrapper bakes it in so waybar can just call
      # `wb-settings open` / `wb-settings openTab wifi` etc.
      (pkgs.writeShellScriptBin "wb-settings" ''
        #!/usr/bin/env bash
        fn="''${1:-toggle}"
        shift || true
        exec ${pkgs.quickshell}/bin/quickshell ipc -p ${quickshellSrc} call settings "$fn" "$@"
      '')
    ];
  };
}
