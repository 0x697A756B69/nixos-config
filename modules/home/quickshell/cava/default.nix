# Cava "underbar": HakuSpace pairs Waybar with a Cava-driven strip of bars
# under the bar (upstream needs the waybar-cava AUR fork for that). Here it's
# a small standalone Quickshell layer-shell window instead, fed by cava's own
# raw/ascii output over stdout -- no waybar patch needed.
{ config, pkgs, lib, self, ... }:

let
  barCount = 48;

  cavaConfig = pkgs.writeText "cava-underbar.conf" ''
    [general]
    bars = ${toString barCount}
    framerate = 60
    autosens = 1
    sensitivity = 100

    [output]
    method = raw
    raw_target = /dev/stdout
    data_format = ascii
    ascii_max_range = 100
    bar_delimiter = 59
    frame_delimiter = 10
  '';

  # Same Colors.qml singleton as the power menu (same palette dir, same shape).
  colorsQml = pkgs.writeText "cava-colors.qml" ''
    pragma Singleton
    import QtQuick
    import Quickshell
    import Quickshell.Io

    Singleton {
        id: root
        property alias c: colorsAdapter

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

  cavaUnderbarQml = pkgs.replaceVars ./CavaUnderbar.qml.in {
    cava = "${pkgs.cava}/bin/cava";
    cavaConfig = "${cavaConfig}";
  };

  cavaSrc = pkgs.runCommand "quickshell-cava-src" { } ''
    mkdir -p $out
    cp ${./shell.qml} $out/shell.qml
    cp ${cavaUnderbarQml} $out/CavaUnderbar.qml
    cp ${colorsQml} $out/Colors.qml
  '';
in
{
  config = {
    systemd.user.services.quickshell-cava = {
      Unit = {
        After = [ "graphical-session.target" ];
        Wants = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.quickshell}/bin/quickshell -p ${cavaSrc}";
        Restart = "on-failure";
        RestartSec = 3;
        StartLimitIntervalSec = 0;
      };
    };

    home.packages = [
      (pkgs.writeShellScriptBin "wb-cava" ''
        #!/usr/bin/env bash
        exec systemctl --user start quickshell-cava.service
      '')
    ];
  };
}
