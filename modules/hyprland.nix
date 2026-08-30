{ config, pkgs, lib, self, ... }:

let
  mainMod = "SUPER";
  terminal = "kitty";
  menu = "wofi --show drun";
  inline = lib.generators.mkLuaInline;
  infinite = config.programs.hyprland-infinite.package;
  core = "${infinite}/lib/hyprland-infinite/infinite_desktop_core.py";
  py = (pkgs.python3.withPackages (ps: [ ps.evdev ]));
  wallpaper = "${self}/modules/wallpapers/wallpaper_upscaled_2k.mp4";
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    package = pkgs.hyprland;

    settings = {
      monitor = {
        output = "";
        mode = "2560x1440@280";
        position = "auto";
        scale = 1;
      };

      bind = [
        { _args = [ "${mainMod} + Return" (inline "hl.dsp.exec_cmd(\"${terminal}\")") ]; }
        { _args = [ "${mainMod} + R"      (inline "hl.dsp.exec_cmd(\"${menu}\")") ]; }
        { _args = [ "${mainMod} + Q"      (inline "hl.dsp.window.close()") ]; }
        { _args = [ "${mainMod} + M"      (inline "hl.dsp.exit()") ]; }
        { _args = [ "${mainMod} + V"      (inline "hl.dsp.window.float({ action = \"toggle\" })") ]; }
        { _args = [ "${mainMod} + F"      (inline "hl.dsp.window.fullscreen({ action = \"toggle\" })") ]; }

        # --- Workspaces (dépôt) ---
        { _args = [ "${mainMod} + Z" (inline "hl.dsp.focus({ workspace = \"-1\" })") ]; }
        { _args = [ "${mainMod} + X" (inline "hl.dsp.focus({ workspace = \"+1\" })") ]; }
        { _args = [ "${mainMod} + SHIFT + Z" (inline "hl.dsp.window.move({ workspace = \"-1\" })") ]; }
        { _args = [ "${mainMod} + SHIFT + X" (inline "hl.dsp.window.move({ workspace = \"+1\" })") ]; }

        # --- Toggle flottant toutes fenêtres ---
        { _args = [ "${mainMod} + D" (inline "hl.dsp.exec_cmd(\"floating_tile_toggle\")") ]; }

        # --- Navigation ---
        { _args = [ "${mainMod} + left"  (inline "hl.dsp.exec_cmd(\"navigate_windows left\")") ]; }
        { _args = [ "${mainMod} + right" (inline "hl.dsp.exec_cmd(\"navigate_windows right\")") ]; }
        { _args = [ "${mainMod} + up"    (inline "hl.dsp.exec_cmd(\"navigate_windows up\")") ]; }
        { _args = [ "${mainMod} + down"  (inline "hl.dsp.exec_cmd(\"navigate_windows down\")") ]; }

        # --- Move tiled ---
        { _args = [ "${mainMod} + ALT + left"  (inline "hl.dsp.exec_cmd(\"move_window_tiled left\")") ]; }
        { _args = [ "${mainMod} + ALT + right" (inline "hl.dsp.exec_cmd(\"move_window_tiled right\")") ]; }
        { _args = [ "${mainMod} + ALT + up"    (inline "hl.dsp.exec_cmd(\"move_window_tiled up\")") ]; }
        { _args = [ "${mainMod} + ALT + down"  (inline "hl.dsp.exec_cmd(\"move_window_tiled down\")") ]; }

        # --- Move floating (repeating) ---
        { _args = [ "${mainMod} + SHIFT + left"  (inline "hl.dsp.exec_cmd(\"move_window left\")")  { repeating = true; } ]; }
        { _args = [ "${mainMod} + SHIFT + right" (inline "hl.dsp.exec_cmd(\"move_window right\")") { repeating = true; } ]; }
        { _args = [ "${mainMod} + SHIFT + up"    (inline "hl.dsp.exec_cmd(\"move_window up\")")    { repeating = true; } ]; }
        { _args = [ "${mainMod} + SHIFT + down"  (inline "hl.dsp.exec_cmd(\"move_window down\")")  { repeating = true; } ]; }

        # --- Resize (repeating) ---
        { _args = [ "${mainMod} + CTRL + left"  (inline "hl.dsp.exec_cmd(\"resize_window left\")")  { repeating = true; } ]; }
        { _args = [ "${mainMod} + CTRL + right" (inline "hl.dsp.exec_cmd(\"resize_window right\")") { repeating = true; } ]; }
        { _args = [ "${mainMod} + CTRL + up"    (inline "hl.dsp.exec_cmd(\"resize_window up\")")    { repeating = true; } ]; }
        { _args = [ "${mainMod} + CTRL + down"  (inline "hl.dsp.exec_cmd(\"resize_window down\")")  { repeating = true; } ]; }
        # --- Wallpaper animé: restart mpvpaper ---
        { _args = [ "${mainMod} + B"      (inline "hl.dsp.exec_cmd(\"pkill mpvpaper; sleep 0.2; mpvpaper -o 'no-audio loop' DP-4 ${wallpaper}\")") ]; }
      ];

      on = {
        _args = [
          "hyprland.start"
          (inline ''
            function()
            hl.exec_cmd("${py}/bin/python ${core} 1.6 > /tmp/infinite-desktop.log 2>&1")
            hl.exec_cmd("mpvpaper -o 'no-audio loop' DP-4 ${wallpaper}")
	    end
          '')
        ];
      };

      config = {
        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          col = {
            active_border = "rgba(89b4faee)";
            inactive_border = "rgba(45475aaa)";
          };
          layout = "dwindle";
        };
        decoration = {
          rounding = 8;
        };
        animations = {
          enabled = true;
        };
        input = {
          kb_layout = "fr";
        };
      };
    };
  };
}
