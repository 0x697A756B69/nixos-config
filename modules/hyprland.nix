{ config, pkgs, lib, ... }:

let
  mainMod = "SUPER";
  terminal = "kitty";
  menu = "wofi --show drun";
  inline = lib.generators.mkLuaInline;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    package = pkgs.hyprland;

    systemd = {
      enable = true;
      enableXdgAutostart = true;
    };

    settings = {
      monitor = {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = 1;
      };

      bind = [
        {
          _args = [
            "${mainMod} + Return"
            (inline "hl.dsp.exec_cmd(\"${terminal}\")")
          ];
        }
        {
          _args = [
            "${mainMod} + R"
            (inline "hl.dsp.exec_cmd(\"${menu}\")")
          ];
        }
        {
          _args = [
            "${mainMod} + Q"
            (inline "hl.dsp.window.close()")
          ];
        }
        {
          _args = [
            "${mainMod} + M"
            (inline "hl.dsp.exec_cmd(\"hyprshutdown\")")
          ];
        }
        {
          _args = [
            "${mainMod} + V"
            (inline "hl.dsp.window.float({ action = \"toggle\" })")
          ];
        }
        {
          _args = [
            "${mainMod} + F"
            (inline "hl.dsp.window.fullscreen({ action = \"toggle\" })")
          ];
        }
        {
          _args = [
            "${mainMod} + left"
            (inline "hl.dsp.focus({ direction = \"left\" })")
          ];
        }
        {
          _args = [
            "${mainMod} + right"
            (inline "hl.dsp.focus({ direction = \"right\" })")
          ];
        }
        {
          _args = [
            "${mainMod} + up"
            (inline "hl.dsp.focus({ direction = \"up\" })")
          ];
        }
        {
          _args = [
            "${mainMod} + down"
            (inline "hl.dsp.focus({ direction = \"down\" })")
          ];
        }
        {
          _args = [
            "${mainMod} + 1"
            (inline "hl.dsp.focus({ workspace = 1 })")
          ];
        }
        {
          _args = [
            "${mainMod} + 2"
            (inline "hl.dsp.focus({ workspace = 2 })")
          ];
        }
        {
          _args = [
            "${mainMod} + 3"
            (inline "hl.dsp.focus({ workspace = 3 })")
          ];
        }
        {
          _args = [
            "${mainMod} + 4"
            (inline "hl.dsp.focus({ workspace = 4 })")
          ];
        }
        {
          _args = [
            "${mainMod} + SHIFT + 1"
            (inline "hl.dsp.window.move({ workspace = 1 })")
          ];
        }
        {
          _args = [
            "${mainMod} + SHIFT + 2"
            (inline "hl.dsp.window.move({ workspace = 2 })")
          ];
        }
        {
          _args = [
            "${mainMod} + SHIFT + 3"
            (inline "hl.dsp.window.move({ workspace = 3 })")
          ];
        }
        {
          _args = [
            "${mainMod} + SHIFT + 4"
            (inline "hl.dsp.window.move({ workspace = 4 })")
          ];
        }
      ];

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