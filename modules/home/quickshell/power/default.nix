# Power menu: standalone Quickshell shell launched by the far-right waybar
# module. Separate from the settings app — small layer-shell overlay anchored
# top-right under the waybar notch, closes on outside click / Escape.
{ config, pkgs, lib, self, ... }:

let
  # Reuse the same Colors.qml singleton from the settings app (same palette
  # directory, same runtime path) so the power menu matches the theme.
  colorsQml = pkgs.writeText "power-colors.qml" ''
    pragma Singleton
    import QtQuick
    import Quickshell
    import Quickshell.Io

    Singleton {
        id: root
        property alias c: colorsAdapter
        readonly property color baseGlassColor: Qt.rgba(
            c.base_glass.r / 255, c.base_glass.g / 255, c.base_glass.b / 255, c.base_glass.a)

        FileView {
            path: "${config.styling.paletteDir}/colors.json"
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
                property string panel: "#f2000000"
            }
        }
    }
  '';

  powerSrc = pkgs.runCommand "quickshell-power-src" { } ''
    mkdir -p $out
    cp ${./shell.qml} $out/shell.qml
    cp ${./PowerMenu.qml} $out/PowerMenu.qml
    cp ${colorsQml} $out/Colors.qml
  '';
in
{
  config = {
    systemd.user.services.quickshell-power = {
      Unit = {
        After = [ "graphical-session.target" ];
        Wants = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.quickshell}/bin/quickshell -p ${powerSrc}";
        Restart = "on-failure";
        RestartSec = 3;
        StartLimitIntervalSec = 0;
      };
    };

    home.packages = [
      (pkgs.writeShellScriptBin "wb-power" ''
        #!/usr/bin/env bash
        exec systemctl --user start quickshell-power.service
      '')
      (pkgs.writeShellScriptBin "wb-power-toggle" ''
        #!/usr/bin/env bash
        exec ${pkgs.quickshell}/bin/quickshell ipc -p ${powerSrc} call power toggle
      '')
    ];
  };
}
