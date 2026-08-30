{ pkgs, ... }:

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
      * {
        font-family: "JetBrains Mono Nerd Font";
        font-size: 16px;
        border: none;
        border-radius: 0;
        min-height: 0;
        padding: 0;
      }

      tooltip {
        background: #11111b;
        border: 1px solid #313244;
        border-radius: 8px;
        color: #cdd6f4;
      }

      window#waybar {
        background: transparent;
        color: #cdd6f4;
      }

      /* --- Encoches : fond plein sombre --- */
      #waybar .modules-left {
        padding: 0 12px;
        background: #11111b;
        border-radius: 0 0 16px 16px;
      }
      #waybar .modules-center {
        padding: 0 4px;
        margin: 0 8px;
        background: #11111b;
        border-radius: 0 0 16px 16px;
      }
      #waybar .modules-right {
        padding: 0 14px;
        background: #11111b;
        border-radius: 0 0 16px 16px;
      }

      /* --- Gauche : compact, logo NixOS grand et aéré, mono-clair --- */
      #custom-logo {
        padding: 0 6px;
        margin-right: 16px;
        font-size: 22px;
        color: #cdd6f4;
      }
      #custom-settings, #custom-prev, #custom-playpause, #custom-next {
        padding: 0 7px;
        font-size: 14px;
        color: #cdd6f4;
      }
      #custom-music { padding: 0 5px; font-size: 13px; color: #a6adc8; }

      /* --- Centre : encoche serrée, rectangle actif sobre, points tassés --- */
      #custom-ws1, #custom-ws2, #custom-ws3 {
        margin: 8px 2px;
        font-size: 14px;
        color: #cdd6f4;
        background: transparent;
        border-radius: 9px;
        min-width: 22px;
        min-height: 22px;
      }
      #custom-ws1.active, #custom-ws2.active, #custom-ws3.active {
        margin: 8px 2px;
        color: #1e1e2e;
        background: #cdd6f4;
        min-width: 48px;
        min-height: 22px;
      }

      /* --- Droite : compact, mono-clair --- */
      #cpu { padding: 0 7px; font-size: 13px; color: #cdd6f4; }
      #memory { padding: 0 7px; font-size: 13px; color: #cdd6f4; }
      #pulseaudio { padding: 0 7px; font-size: 13px; color: #cdd6f4; }
      #pulseaudio.muted { color: #6c7086; }
      #custom-bt { padding: 0 7px; font-size: 13px; color: #cdd6f4; }
      #custom-bt.bt-off { color: #6c7086; }
      #clock { padding: 0 7px; font-size: 13px; color: #cdd6f4; }
      #custom-power {
        padding: 0 7px;
        color: #cdd6f4;
        font-size: 13px;
      }

      /* --- Réseau + HDR --- */
      #network.wifi, #network.ethernet { padding: 0 6px; font-size: 13px; color: #cdd6f4; }
      #custom-hdr {
        padding: 0 7px;
        font-size: 12px;
        font-weight: bold;
      }
      #custom-hdr.hdr-on { color: #cdd6f4; }
      #custom-hdr.hdr-off { color: #6c7086; }
    '';

    systemd = {
      enable = true;
    };
  };
}
