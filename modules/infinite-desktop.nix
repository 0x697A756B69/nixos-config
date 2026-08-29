{ config, lib, pkgs, ... }:

let
  pythonEnv = pkgs.python3.withPackages (ps: [ ps.evdev ]);
  bindScripts = [
    "floating_tile_toggle"
    "navigate_windows"
    "move_window"
    "move_window_tiled"
    "resize_window"
  ];
  pkg = pkgs.stdenv.mkDerivation {
    pname = "hyprland-infinite-desktop";
    version = "2.0";
    src = ./infinite-scripts;
    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/hyprland-infinite $out/bin

      cp discover_hyprland_api.sh floating_tile_toggle.py hypr_ipc.py \
         infinite_desktop_core.py infinite-desktop.sh move_window.py \
         move_window_tiled.py navigate_windows.py resize_window.py \
         $out/lib/hyprland-infinite/

      chmod +x $out/lib/hyprland-infinite/*.py $out/lib/hyprland-infinite/*.sh

      ${lib.concatMapStringsSep "\n" (s: ''
        makeWrapper ${pythonEnv}/bin/python $out/bin/${s} \
          --add-flags "$out/lib/hyprland-infinite/${s}.py"
      '') bindScripts}
      runHook postInstall
    '';
  };
in
{
  options.programs.hyprland-infinite.package = lib.mkOption {
    type = lib.types.package;
    description = "Paquet des scripts hyprland-infinite-desktop-v2";
  };

  config = {
    programs.hyprland-infinite.package = pkg;
    home.packages = [ pkg ];
  };
}