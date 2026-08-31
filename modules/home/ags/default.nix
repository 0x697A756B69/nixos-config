# Dropdown wifi/bluetooth façon macOS, ancré sous l'encoche droite de la
# waybar. AGS v2 (CLI de scaffolding) + Astal (bibliothèques GObject/DBus
# événementielles pour NetworkManager et BlueZ — voir AstalNetwork-0.1.gir /
# AstalBluetooth-0.1.gir : les widgets se lient aux propriétés via bind(),
# qui s'abonne au signal GObject "notify::<prop>" ; ces propriétés changent
# elles-mêmes en réaction aux signaux DBus de NetworkManager/BlueZ côté
# bibliothèque C — aucun polling écrit ici).
#
# Packaging : pas de `ags bundle` (comportement de sortie non vérifiable
# dans cet environnement sans session graphique). À la place, la source
# TS/TSX est copiée telle quelle dans le store (reproductible, aucun accès
# réseau) et lancée via `ags run app.ts` — le mode natif documenté par la
# CLI, qui résout la dépendance "astal" via un chemin de store absolu dans
# package.json (généré ci-dessous), donc pas de téléchargement npm au
# lancement non plus.
{ config, pkgs, lib, ... }:

let
  astalGjs = pkgs.astal.io;

  configTs = pkgs.writeText "ags-config.ts" ''
    // Largeur partagée avec #modules-right (voir modules/home/waybar) :
    // générée ici pour éviter toute valeur dupliquée en dur.
    export const PANEL_WIDTH = ${toString config.styling.modulesRightWidth};
  '';

  styleCss = pkgs.writeText "ags-style.css" ''
    @import url("${config.styling.palette}/colors.css");

    * {
      font-family: "JetBrains Mono Nerd Font";
    }

    /* La fenêtre reste transparente : le fond visuel opaque + les coins
       arrondis sont portés par .panel-box, exactement comme #waybar est
       transparent et laisse ses .modules-* porter le fond (voir
       modules/home/waybar) — continuité visuelle avec l'encoche dont ce
       panneau descend. */
    window.Panel {
      background: transparent;
    }

    .panel-box {
      background: @base;
      color: @text;
      border-radius: 0 0 16px 16px;
      padding: 8px 0 12px 0;
    }

    .panel-header {
      padding: 4px 14px 8px 14px;
    }

    .panel-title {
      font-size: 15px;
      font-weight: bold;
      color: @text;
    }

    .panel-header button {
      min-width: 0;
      padding: 4px 8px;
      color: @text;
      background: transparent;
      border-radius: 8px;
    }
    .panel-header button:hover {
      background: @base_alt;
    }

    .panel-list {
      padding: 0 6px;
    }

    .ap-row, .bt-row {
      padding: 8px 8px;
      border-radius: 10px;
      color: @text;
      background: transparent;
    }
    .ap-row:hover, .bt-row:hover {
      background: @base_alt;
    }
    .ap-row:disabled {
      color: @disabled;
    }

    .lock, .strength, .battery, .state {
      color: @text_alt;
      font-size: 12px;
    }

    .empty {
      color: @text_alt;
      padding: 12px 14px;
    }
  '';

  packageJson = pkgs.writeText "ags-package.json" (builtins.toJSON {
    name = "waybar-dropdown";
    dependencies.astal = "${astalGjs}/share/astal/gjs";
  });

  # Arborescence source assemblée (app.ts + widget/*.tsx statiques du dépôt,
  # config.ts/style.css/package.json générés) : c'est ce répertoire qu'`ags
  # run` exécute directement.
  agsShellSrc = pkgs.runCommand "ags-shell-src" { } ''
    mkdir -p $out/widget
    cp ${./app.ts} $out/app.ts
    cp ${./widget/NetworkPanel.tsx} $out/widget/NetworkPanel.tsx
    cp ${./widget/BluetoothPanel.tsx} $out/widget/BluetoothPanel.tsx
    cp ${configTs} $out/config.ts
    cp ${styleCss} $out/style.css
    cp ${packageJson} $out/package.json
  '';

  # `ags run` seul échoue : le binaire (buildGoModule, pas de wrapper GTK)
  # ne pose pas GI_TYPELIB_PATH. Vérifié en conditions réelles (headless,
  # sans display) : sans ce chemin, gjs échoue à "Requiring Astal/AstalNetwork"
  # (Gdk, Graphene, NM introuvables) ; avec, l'app importe tout, construit
  # les deux panneaux, et n'échoue plus qu'à l'ouverture du display (attendu
  # ici, absence de session Wayland). NM (NetworkManager) vient du paquet
  # networkmanager : AstalNetwork l'utilise en interne.
  giTypelibPath = lib.makeSearchPath "lib/girepository-1.0" [
    pkgs.glib.out
    pkgs.gtk4
    pkgs.graphene
    pkgs.networkmanager
    astalGjs
    pkgs.astal.astal4
    pkgs.astal.network
    pkgs.astal.bluetooth
  ];
in
{
  options.programs.ags-shell.package = lib.mkOption {
    type = lib.types.package;
    description = ''
      Répertoire source du dropdown wifi/bluetooth AGS/Astal (app.ts +
      widget/). Lancé par le script wb-dropdown (GI_TYPELIB_PATH correct),
      exécuté au démarrage de la session (voir modules/home/hyprland).
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
