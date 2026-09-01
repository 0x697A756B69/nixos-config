# Unified settings app (Wi-Fi / Bluetooth / Display). AGS v2 + Astal
# (AstalNetwork/AstalBluetooth/AstalHyprland). Opened via right-click on
# the matching waybar modules (see modules/home/waybar).
#
# - No `ags bundle`: TS/TSX source is copied as-is into the store, run via
#   `ags run app.ts` (package.json points "astal" at the store path).
# - Matugen colors are inlined into the CSS (readFile), not @import: Astal's
#   GTK4 CSS doesn't propagate @define-color from an imported file.
# - GI_TYPELIB_PATH must be set explicitly (the ags package doesn't set it).
{ config, pkgs, lib, ... }:

let
  astalGjs = pkgs.astal.io;

  styleCss = pkgs.writeText "ags-style.css" ''
    ${builtins.readFile "${config.styling.palette}/colors.css"}

    * {
      font-family: "JetBrains Mono Nerd Font";
    }

    /* Transparent window: translucent background + rounded corners are
       carried by .panel-box. Real blur via Hyprland layer_rule (modules/home/hyprland). */
    window.Panel {
      background: transparent;
    }

    .panel-box {
      background: @base_glass;
      color: @text;
      border-radius: 20px;
    }

    .sidebar {
      padding: 8px;
      min-width: 140px;
      border-radius: 20px 0 0 20px;
    }
    .sidebar-btn {
      border-radius: 12px;
      color: @text;
      background: transparent;
      font-size: 14px;
      font-weight: bold;
    }
    .sidebar-btn:hover {
      background: alpha(@base_alt, 0.4);
    }
    .sidebar-btn.active {
      background: alpha(@accent, 0.28);
      color: @accent;
    }

    .content {
      padding: 16px;
      min-width: 340px;
    }
    .tab-content {
      color: @text;
    }
    .tab-title {
      font-size: 15px;
      font-weight: bold;
      color: @text;
    }
    .display-row {
      padding: 6px 4px;
      color: @text;
    }
    .display-row button {
      min-width: 0;
      padding: 4px 10px;
      color: @text;
      background: @base_alt;
      border-radius: 8px;
    }
    .display-row button:hover {
      background: @accent;
      color: @on_accent;
    }
    .display-row button:disabled {
      color: @disabled;
      background: transparent;
    }

    /* Icon button (widget/IconToggle.tsx) in place of the GTK <switch>. */
    .icon-toggle {
      padding: 6px 10px;
      border-radius: 10px;
      color: @text_alt;
      background: transparent;
      font-size: 16px;
      min-width: 0;
    }
    .icon-toggle:hover {
      background: alpha(@base_alt, 0.4);
    }
    .icon-toggle.active {
      color: @accent;
      background: alpha(@accent, 0.18);
    }

    .list-row {
      padding: 8px 8px;
      border-radius: 10px;
      color: @text;
      background: transparent;
    }
    .list-row:hover {
      background: @base_alt;
    }
    .list-row:disabled {
      color: @disabled;
    }

    .muted {
      color: @text_alt;
      font-size: 12px;
    }

    .empty {
      color: @text_alt;
      padding: 12px 14px;
    }
  '';

  packageJson = pkgs.writeText "ags-package.json" (builtins.toJSON {
    name = "settings-app";
    dependencies.astal = "${astalGjs}/share/astal/gjs";
  });

  # Directory run directly by `ags run`.
  agsShellSrc = pkgs.runCommand "ags-shell-src" { } ''
    mkdir -p $out/widget
    cp ${./app.ts} $out/app.ts
    cp ${./widget/SettingsWindow.tsx} $out/widget/SettingsWindow.tsx
    cp ${./widget/WifiTab.tsx} $out/widget/WifiTab.tsx
    cp ${./widget/BluetoothTab.tsx} $out/widget/BluetoothTab.tsx
    cp ${./widget/DisplayTab.tsx} $out/widget/DisplayTab.tsx
    cp ${./widget/IconToggle.tsx} $out/widget/IconToggle.tsx
    cp ${styleCss} $out/style.css
    cp ${packageJson} $out/package.json
  '';

  giTypelibPath = lib.makeSearchPath "lib/girepository-1.0" [
    pkgs.glib.out
    pkgs.gtk4
    pkgs.graphene
    pkgs.networkmanager
    astalGjs
    pkgs.astal.astal4
    pkgs.astal.network
    pkgs.astal.bluetooth
    pkgs.astal.hyprland
  ];
in
{
  options.programs.ags-shell.package = lib.mkOption {
    type = lib.types.package;
    description = ''
      Source directory of the AGS/Astal settings app (app.ts + widget/).
      Launched by wb-dropdown (with GI_TYPELIB_PATH set) at session
      startup (see modules/home/hyprland).
    '';
  };

  config = {
    programs.ags-shell.package = agsShellSrc;

    home.packages = [
      pkgs.ags
      (pkgs.writeShellScriptBin "wb-dropdown" ''
        #!/usr/bin/env bash
        export GI_TYPELIB_PATH="${giTypelibPath}''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"
        exec ${pkgs.ags}/bin/ags run ${agsShellSrc}/app.ts --gtk4
      '')
    ];
  };
}
