{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 38;
        margin-top = 0;
        spacing = 10;

        # Gauche : logo + menu + musique
        modules-left = [
          "custom/logo"
          "custom/settings"
          "custom/prev"
          "custom/playpause"
          "custom/next"
          "custom/music"
        ];
        # Centre : 3 ronds workspaces (événementiel)
        modules-center = [ "custom/ws1" "custom/ws2" "custom/ws3" ];
        # Droite : cpu + ram + volume + wifi + ethernet + bt + HDR + heure + power
        modules-right = [
          "cpu"
          "memory"
          "pulseaudio"
          "network#wifi"
          "network#ethernet"
          "custom/bt"
          "custom/hdr"
          "clock"
          "custom/power"
        ];
        "custom/logo" = {
          format = "";
          tooltip = false;
        };
        "custom/settings" = {
          format = "󰀘";
          on-click = "rofi -show drun";
          tooltip = false;
        };
        "custom/prev" = {
          format = "󰓕";
          on-click = "playerctl previous";
          tooltip = false;
        };
        "custom/playpause" = {
          exec = "${pkgs.bash}/bin/bash ${pkgs.writeScript "wp" ''#!/usr/bin/env bash
status=$(playerctl status 2>/dev/null)
if [ "$status" = "Playing" ]; then echo "󰏤"; else echo "󰐊"; fi''}";
          interval = 2;
          on-click = "${pkgs.bash}/bin/bash ${pkgs.writeScript "wp2" ''#!/usr/bin/env bash
playerctl play-pause 2>/dev/null
sleep 0.2
status=$(playerctl status 2>/dev/null)
if [ "$status" = "Playing" ]; then echo "󰏤"; else echo "󰐊"; fi
pkill -RTMIN+1 waybar''}";
          signal = 1;
          tooltip = false;
        };
        "custom/next" = {
          format = "󰓗";
          on-click = "playerctl next";
          tooltip = false;
        };
        "custom/music" = {
          exec = "wb-music";
          interval = 1;
          return-type = "json";
        };
        "custom/ws1" = {
          exec = "wb-wsreader 1";
          signal = 4;
          interval = 10;
          return-type = "json";
          tooltip = false;
        };
        "custom/ws2" = {
          exec = "wb-wsreader 2";
          signal = 4;
          interval = 10;
          return-type = "json";
          tooltip = false;
        };
        "custom/ws3" = {
          exec = "wb-wsreader 3";
          signal = 4;
          interval = 10;
          return-type = "json";
          tooltip = false;
        };
        cpu = {
          interval = 3;
          format = "{icon} {usage}%";
          format-icons = [ "󰍛" ];
          tooltip = false;
        };
        memory = {
          interval = 5;
          format = "{icon} {percentage}%";
          format-icons = [ "󰟜" ];
          tooltip = false;
        };
        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰝟 {volume}%";
          format-icons = [ "󰕿" "󰖀" "󰕾" ];
          on-click = "pamixer -t";
          on-scroll-up = "pamixer -i 5";
          on-scroll-down = "pamixer -d 5";
          on-click-right = "pavucontrol";
        };
        "custom/bt" = {
          exec = "wb-bt";
          on-click = "rofi-bluetooth -theme $HOME/.config/rofi/catppuccin-mocha.rasi";
          signal = 3;
          interval = 30;
          return-type = "json";
          tooltip = false;
        };
        clock = {
          format = "{:%H:%M}";
          tooltip-format = "{: %A %d %B %Y}";
        };
        "custom/power" = {
          format = "⏻";
          on-click = "power-menu";
          tooltip = false;
        };
        "network#wifi" = {
          # Wifi : l'icône varie selon la puissance du signal
          interface = "wlp*";
          format-wifi = "{icon}";
          format-icons = [ "󰤯" "󰤟" "󰤢" "󰤨" ];
          format-disconnected = "";
          tooltip = false;
        };
        "network#ethernet" = {
          # Ethernet : le câble branché supplante l'icône wifi
          interface = "en*";
          format-ethernet = "󰈀";
          format-disconnected = "";
          tooltip = false;
        };
        "custom/hdr" = {
          exec = "wb-hdr";
          return-type = "json";
          on-click = "wb-hdr toggle";
          signal = 10;
          tooltip = false;
        };
      };
    };

    style = ''
      @import "${config.styling.palette}/colors.css";

      * {
        font-family: "JetBrains Mono Nerd Font";
        font-size: 16px;
        border: none;
        border-radius: 0;
        min-height: 0;
        padding: 0;
      }

      tooltip {
        background: @base;
        border: 1px solid @base_alt;
        border-radius: 8px;
        color: @text;
      }

      window#waybar {
        background: transparent;
        color: @text;
      }

      /* --- Encoches : opaque (contrairement aux apps translucides + flou) --- */
      #waybar .modules-left {
        padding: 0 12px;
        background: @base;
        border-radius: 0 0 16px 16px;
      }
      #waybar .modules-center {
        padding: 0 4px;
        margin: 0 8px;
        background: @base;
        border-radius: 0 0 16px 16px;
      }
      #waybar .modules-right {
        padding: 0 14px;
        background: @base;
        border-radius: 0 0 16px 16px;
      }

      /* --- Gauche : compact, logo NixOS grand et aéré --- */
      #custom-logo {
        padding: 0 6px;
        margin-right: 16px;
        font-size: 22px;
        color: @text;
      }
      #custom-settings, #custom-prev, #custom-playpause, #custom-next {
        padding: 0 7px;
        font-size: 14px;
        color: @text;
      }
      #custom-music { padding: 0 5px; font-size: 13px; color: @text_alt; }

      /* --- Centre : encoche serrée, rectangle actif sobre, points tassés --- */
      #custom-ws1, #custom-ws2, #custom-ws3 {
        margin: 8px 2px;
        font-size: 14px;
        color: @text;
        background: transparent;
        border-radius: 9px;
        min-width: 22px;
        min-height: 22px;
      }
      #custom-ws1.active, #custom-ws2.active, #custom-ws3.active {
        margin: 8px 2px;
        color: @on_accent;
        background: @accent;
        min-width: 48px;
        min-height: 22px;
      }

      /* --- Droite : compact, palette --- */
      #cpu { padding: 0 7px; font-size: 13px; color: @text; }
      #memory { padding: 0 7px; font-size: 13px; color: @text; }
      #pulseaudio { padding: 0 7px; font-size: 13px; color: @text; }
      #pulseaudio.muted { color: @disabled; }
      #custom-bt { padding: 0 7px; font-size: 13px; color: @text; }
      #custom-bt.bt-off { color: @disabled; }
      #clock { padding: 0 7px; font-size: 13px; color: @text; }
      #custom-power {
        padding: 0 7px;
        color: @error;
        font-size: 13px;
      }

      /* --- Réseau + HDR --- */
      #network.wifi, #network.ethernet { padding: 0 6px; font-size: 13px; color: @text; }
      #custom-hdr {
        padding: 0 7px;
        font-size: 12px;
        font-weight: bold;
      }
      #custom-hdr.hdr-on { color: @text; }
      #custom-hdr.hdr-off { color: @disabled; }
    '';

    systemd = {
      enable = true;
    };
  };
}
