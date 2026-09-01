# App de réglages unifiée (Wi-Fi / Bluetooth / Écran), fenêtre unique à
# onglets ouverte via clic droit sur les modules waybar correspondants (voir
# modules/home/waybar). AGS v2 (CLI de scaffolding) + Astal (bibliothèques
# GObject/DBus événementielles) : AstalNetwork/AstalBluetooth pour le
# wifi/bluetooth, AstalHyprland pour l'écran. Reconstruction d'un premier
# prototype (dropdown wifi/bluetooth seul) retiré ensuite ; ce module reprend
# tel quel tout le packaging qui avait été débogué en conditions réelles :
#
# - Pas de `ags bundle` (comportement de sortie non vérifiable sans session
#   graphique) : la source TS/TSX est copiée telle quelle dans le store et
#   lancée via `ags run app.ts`, qui résout "astal" via un chemin de store
#   absolu dans package.json (généré ci-dessous) — aucun accès réseau ni au
#   build ni au lancement.
# - Couleurs matugen INLINÉES dans le CSS (pas de @import) : vérifié en
#   conditions réelles (capture d'écran + échantillonnage de pixel) que le
#   CSS GTK4 d'Astal ne propage PAS les @define-color d'un fichier @import
#   dans la feuille qui l'importe. Même technique que modules/home/zen.nix
#   (builtins.readFile).
# - `ags run` seul échoue sans GI_TYPELIB_PATH (le binaire, buildGoModule,
#   ne le pose pas) : sans lui, gjs échoue à "Requiring Astal/AstalNetwork"
#   (Gdk, Graphene, NM introuvables). Avec, l'app importe tout et construit
#   les fenêtres ; seul reste l'échec attendu à l'ouverture du display en
#   environnement headless.
{ config, pkgs, lib, ... }:

let
  astalGjs = pkgs.astal.io;

  styleCss = pkgs.writeText "ags-style.css" ''
    ${builtins.readFile "${config.styling.palette}/colors.css"}

    * {
      font-family: "JetBrains Mono Nerd Font";
    }

    /* La fenêtre reste transparente : le fond visuel translucide + les
       coins arrondis sont portés par .panel-box. Fenêtre centrée façon
       sélecteur d'app (voir modules/home/rofi/config-layout.rasi, même
       rayon 20px), et thème "app" (translucide + flou, base_glass) plutôt
       que le thème "encoche" (opaque, base) maintenant qu'elle flotte au
       centre au lieu de descendre de la waybar — même famille que kitty/
       zen (voir le commentaire dans modules/home/waybar sur cette
       distinction opaque/translucide). Le flou réel derrière vient du
       layer_rule Hyprland (blur = true, voir modules/home/hyprland). */
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
      background: @base_alt;
    }
    .sidebar-btn.active {
      background: @accent;
      color: @on_accent;
    }
    .close-btn {
      padding: 8px 10px;
      border-radius: 8px;
      color: @text_alt;
      background: transparent;
    }
    .close-btn:hover {
      background: @base_alt;
      color: @error;
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

    /* Interrupteurs (bluetooth power, etc.) : GTK4 les peint en bleu par
       défaut (Adwaita), aucun rapport avec la palette matugen. */
    switch {
      background: @base_alt;
      border-radius: 999px;
    }
    switch:checked {
      background: @accent;
    }
    switch slider {
      background: @text;
      border-radius: 999px;
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

  # Arborescence source assemblée (app.ts + widget/*.tsx statiques du dépôt,
  # style.css/package.json générés) : c'est ce répertoire qu'`ags run`
  # exécute directement.
  agsShellSrc = pkgs.runCommand "ags-shell-src" { } ''
    mkdir -p $out/widget
    cp ${./app.ts} $out/app.ts
    cp ${./widget/SettingsWindow.tsx} $out/widget/SettingsWindow.tsx
    cp ${./widget/WifiTab.tsx} $out/widget/WifiTab.tsx
    cp ${./widget/BluetoothTab.tsx} $out/widget/BluetoothTab.tsx
    cp ${./widget/DisplayTab.tsx} $out/widget/DisplayTab.tsx
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
      Répertoire source de l'app de réglages AGS/Astal (app.ts + widget/).
      Lancé par le script wb-dropdown (GI_TYPELIB_PATH correct), exécuté au
      démarrage de la session (voir modules/home/hyprland).
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
