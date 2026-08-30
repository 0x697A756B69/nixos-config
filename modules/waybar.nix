{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        margin-top = 0;
        spacing = 4;

        # Gauche : logo + menu + musique + HDR
        modules-left = [
          "custom/logo"
          "custom/settings"
          "custom/prev"
          "custom/playpause"
          "custom/next"
          "custom/hdr"
        ];
        # Centre : 3 ronds workspaces
        modules-center = [ "custom/wsdot" ];
        # Droite : cpu + ram + volume + bt + heure + power
        modules-right = [
          "cpu"
          "memory"
          "pulseaudio"
          "custom/bt"
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
          format = "⏮";
          on-click = "playerctl previous";
          tooltip = false;
        };
        "custom/playpause" = {
          exec = "${pkgs.bash}/bin/bash ${pkgs.writeScript "wp" ''#!/usr/bin/env bash
status=$(playerctl status 2>/dev/null)
if [ "$status" = "Playing" ]; then echo "⏸"; else echo "▶"; fi''}";
          interval = 2;
          on-click = "${pkgs.bash}/bin/bash ${pkgs.writeScript "wp2" ''#!/usr/bin/env bash
playerctl play-pause 2>/dev/null
sleep 0.2
status=$(playerctl status 2>/dev/null)
if [ "$status" = "Playing" ]; then echo "⏸"; else echo "▶"; fi
pkill -RTMIN+1 waybar''}";
          signal = 1;
          tooltip = false;
        };
        "custom/next" = {
          format = "⏭";
          on-click = "playerctl next";
          tooltip = false;
        };
        "custom/hdr" = {
          exec = "wb-hdr";
          on-click = "wb-hdr toggle";
          signal = 2;
          interval = 10;
          return-type = "json";
        };
        "custom/wsdot" = {
          exec = "wb-wsdot";
          interval = 1;
          return-type = "json";
        };
        cpu = {
          interval = 3;
          format = "  {usage}%";
          tooltip = false;
        };
        memory = {
          interval = 5;
          format = "  {percentage}%";
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
          on-click = "wb-bt toggle";
          signal = 3;
          interval = 30;
          return-type = "json";
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
      };
    };

    style = ''
      * {
        font-family: "JetBrains Mono Nerd Font";
        font-size: 13px;
        border: none;
        border-radius: 0;
        min-height: 0;
        padding: 0;
      }

      tooltip {
        background: #1e1e2e;
        border: 1px solid #313244;
        border-radius: 8px;
        color: #cdd6f4;
      }

      /* Barre transparente : juste les 3 encoches visibles */
      window#waybar {
        background: transparent;
        color: #cdd6f4;
      }

      /* --- Encoch Gauche (rectangle collé en haut gauche) --- */
      #waybar .modules-left {
        padding: 0 12px;
        background: rgba(30, 30, 46, 0.9);
        border: 1px solid #313244;
        border-radius: 0 0 14px 14px;
      }

      /* --- Encoch Centre (pilule fine centrée) --- */
      #waybar .modules-center {
        padding: 0 16px;
        margin: 0 10px;
        background: rgba(30, 30, 46, 0.9);
        border: 1px solid #313244;
        border-radius: 0 0 14px 14px;
      }

      /* --- Encoch Droite (rectangle collé en haut droite) --- */
      #waybar .modules-right {
        padding: 0 12px;
        background: rgba(30, 30, 46, 0.9);
        border: 1px solid #313244;
        border-radius: 0 0 14px 14px;
      }

      /* --- Modules --- */
      #custom-logo {
        padding: 0 8px;
        font-size: 16px;
        color: #89b4fa;
      }
      #custom-settings, #custom-prev, #custom-playpause, #custom-next {
        padding: 0 6px;
        color: #cdd6f4;
      }
      #custom-prev, #custom-next { color: #a6adc8; }
      #custom-playpause { color: #a6e3a1; }
      #custom-hdr { padding: 0 8px; font-size: 14px; }
      #custom-hdr.hdr-on { color: #f9e2af; }
      #custom-hdr.hdr-off { color: #45475a; }

      #custom-wsdot {
        color: #cdd6f4;
        font-size: 14px;
        letter-spacing: 2px;
      }

      #cpu { padding: 0 8px; color: #a6e3a1; }
      #memory { padding: 0 8px; color: #f9e2af; }
      #pulseaudio { padding: 0 8px; color: #94e2d5; }
      #pulseaudio.muted { color: #f38ba8; }
      #custom-bt { padding: 0 8px; font-size: 14px; }
      #custom-bt.bt-on { color: #89b4fa; }
      #custom-bt.bt-off { color: #45475a; }
      #clock { padding: 0 8px; color: #cdd6f4; }
      #custom-power {
        padding: 0 8px;
        color: #f38ba8;
        font-size: 15px;
      }
    '';

    systemd = {
      enable = true;
    };
  };
}
