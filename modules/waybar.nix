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
        background: #1e1e2e;
        border: 1px solid #313244;
        border-radius: 8px;
        color: #cdd6f4;
      }

      window#waybar {
        background: transparent;
        color: #cdd6f4;
      }

      /* --- Encoches : sans bordure, larges φ --- */
      #waybar .modules-left {
        padding: 0 8px;
        background: rgba(30, 30, 46, 0.9);
        border-radius: 0 0 16px 16px;
      }
      #waybar .modules-center {
        padding: 0 70px;
        margin: 0 16px;
        background: rgba(30, 30, 46, 0.9);
        border-radius: 0 0 16px 16px;
      }
      #waybar .modules-right {
        padding: 0 65px;
        background: rgba(30, 30, 46, 0.9);
        border-radius: 0 0 16px 16px;
      }

      /* --- Gauche --- */
      #custom-logo {
        padding: 0 6px;
        margin-right: 8px;
        font-size: 22px;
        color: #89b4fa;
      }
      #custom-settings, #custom-prev, #custom-playpause, #custom-next {
        padding: 0 12px;
        color: #cdd6f4;
      }
      #custom-prev, #custom-next { color: #a6adc8; }
      #custom-playpause { color: #a6e3a1; }
      #custom-music { padding: 0 8px; color: #a6adc8; }
      #custom-music.playing { color: #a6e3a1; }
      #custom-music.paused { color: #f9e2af; }

      /* --- Centre: ronds imposants + rectangle actif --- */
      #custom-ws1, #custom-ws2, #custom-ws3 {
        margin: 8px 6px;
        font-size: 16px;
        color: #89b4fa;
        background: transparent;
        border-radius: 9px;
        min-width: 24px;
        min-height: 18px;
      }
      #custom-ws1.active, #custom-ws2.active, #custom-ws3.active {
        color: #1e1e2e;
        background: rgba(137, 180, 250, 0.55);
        min-width: 48px;
        min-height: 18px;
      }

      /* --- Droite --- */
      #cpu { padding: 0 12px; color: #a6e3a1; }
      #memory { padding: 0 12px; color: #f9e2af; }
      #pulseaudio { padding: 0 12px; color: #94e2d5; }
      #pulseaudio.muted { color: #f38ba8; }
      #custom-bt { padding: 0 12px; font-size: 17px; }
      #custom-bt.bt-on { color: #89b4fa; }
      #custom-bt.bt-off { color: #45475a; }
      #clock { padding: 0 12px; color: #cdd6f4; }
      #custom-power {
        padding: 0 12px;
        color: #f38ba8;
        font-size: 20px;
      }
    '';

    systemd = {
      enable = true;
    };
  };
}
