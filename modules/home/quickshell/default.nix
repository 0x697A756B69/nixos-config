# Settings app (Wi-Fi / Bluetooth / Display / Wallpaper), rebuilt in
# Quickshell/QML to match the visual design of pctrade/end4-pC's Settings
# app and caelestia-dots/shell's wallpaper picker (NavigationRail,
# draggable window, Escape-to-close, singleton service + grid) — replaces
# modules/home/ags. Opened via right-click on the matching waybar modules
# (see modules/home/waybar).
{ config, pkgs, lib, self, ... }:

let
  # Same source path as the default wallpaper in modules/home/hyprland
  # (both rooted at flake `self`), so "Défaut" here and the persisted
  # startup fallback always refer to the exact same file.
  wallpapersDir = "${self}/modules/home/theming/wallpapers";
  videoWallpaper = "${wallpapersDir}/wallpaper_upscaled_2k.mp4";
  lainWallpaper = "${wallpapersDir}/lain.jpg";
  makimaWallpaper = "${wallpapersDir}/makima1.png";
  wallhavenWallpaper = "${wallpapersDir}/wallhaven-211er6_2560x1440.png";

  # Stills are their own thumbnail; the video needs a single extracted frame.
  videoThumb = pkgs.runCommand "wallpaper-video-thumb.png"
    { nativeBuildInputs = [ pkgs.ffmpeg ]; } ''
      ffmpeg -y -i ${videoWallpaper} -vf 'scale=512:288' -frames:v 1 -loglevel error $out
    '';

  # Mirrors the essential shape of caelestia's services/Wallpapers.qml: a
  # static list + setWallpaper()/setRandom() + an IpcHandler on "wallpaper"
  # (their real one also does FileSystemModel directory scanning and a
  # hover-preview mode backed by their compiled caelestia-cli -- both need
  # infrastructure this shell doesn't have, so they're left out here; the
  # actual apply work is delegated to wb-wallpaper, same as their
  # `caelestia wallpaper -f` call). WallItem (their tile) has no
  # "is this the current wallpaper" indicator, so neither does this list.
  wallpapersQml = pkgs.writeText "quickshell-wallpapers.qml" ''
    pragma Singleton
    import QtQuick
    import Quickshell
    import Quickshell.Io

    Singleton {
        id: root

        readonly property var list: [
            { name: "Défaut", path: "${videoWallpaper}", thumbnail: "${videoThumb}" },
            { name: "Lain", path: "${lainWallpaper}", thumbnail: "${lainWallpaper}" },
            { name: "Makima", path: "${makimaWallpaper}", thumbnail: "${makimaWallpaper}" },
            { name: "Wallhaven", path: "${wallhavenWallpaper}", thumbnail: "${wallhavenWallpaper}" }
        ]

        function setWallpaper(path) {
            Quickshell.execDetached(["wb-wallpaper", path])
        }

        function setRandom() {
            const w = root.list[Math.floor(Math.random() * root.list.length)]
            root.setWallpaper(w.path)
        }

        IpcHandler {
            target: "wallpaper"
            function set(path: string): void { root.setWallpaper(path) }
            function list(): string { return root.list.map(w => w.path).join("\n") }
        }
    }
  '';

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

  quickshellSrc = pkgs.runCommand "quickshell-settings-src" { } ''
    mkdir -p $out/pages
    cp ${./shell.qml} $out/shell.qml
    cp ${./SettingsWindow.qml} $out/SettingsWindow.qml
    cp ${./IconToggle.qml} $out/IconToggle.qml
    cp ${./SettingRow.qml} $out/SettingRow.qml
    cp ${colorsQml} $out/Colors.qml
    cp ${wallpapersQml} $out/Wallpapers.qml
    cp ${./pages/WifiPage.qml} $out/pages/WifiPage.qml
    cp ${./pages/BluetoothPage.qml} $out/pages/BluetoothPage.qml
    cp ${./pages/DisplayPage.qml} $out/pages/DisplayPage.qml
    cp ${./pages/WallpaperPage.qml} $out/pages/WallpaperPage.qml
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
