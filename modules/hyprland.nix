{ config, pkgs, lib, ... }:

let
  mainMod = "SUPER";
  terminal = "kitty";
  menu = "wofi --show drun";
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    package = pkgs.hyprland;

    settings = {
      monitor = [
        ", preferred, auto, auto"
      ];

      exec-once = [
        "kitty"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        layout = "dwindle";
        "col.active_border" = "rgba(89b4faee)";
        "col.inactive_border" = "rgba(45475aaa)";
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

      bind = [
        "${mainMod} + Return, exec, ${terminal}"
        "${mainMod} + R, exec, ${menu}"
        "${mainMod} + Q, killactive"
        "${mainMod} + M, exit"
        "${mainMod} + V, togglefloating"
        "${mainMod} + F, fullscreen"
        "${mainMod} + left,  movefocus, l"
        "${mainMod} + right, movefocus, r"
        "${mainMod} + up,    movefocus, u"
        "${mainMod} + down,  movefocus, d"
        "${mainMod} + 1, workspace, 1"
        "${mainMod} + 2, workspace, 2"
        "${mainMod} + 3, workspace, 3"
        "${mainMod} + 4, workspace, 4"
        "${mainMod} + SHIFT + 1, movetoworkspace, 1"
        "${mainMod} + SHIFT + 2, movetoworkspace, 2"
        "${mainMod} + SHIFT + 3, movetoworkspace, 3"
        "${mainMod} + SHIFT + 4, movetoworkspace, 4"
      ];
    };
  };
}