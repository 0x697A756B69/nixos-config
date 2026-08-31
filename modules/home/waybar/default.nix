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
      enable = false;
    };
  };

  # --- Outils consommés par les modules ci-dessus (volume, musique, power menu) ---
  home.packages = with pkgs; [
    playerctl
    pavucontrol
    pamixer
    socat
    jq
    hyprlock

    (pkgs.writeShellScriptBin "wb-music" ''
      #!/usr/bin/env bash
      win=6
      state="$HOME/.cache/wb-music-pos"
      NBSP=$(printf ' ')
      pad() {
        local s="$1" n="$2" d
        d=$(printf '%s' "$s" | wc -m)
        while [ "$d" -lt "$n" ]; do s="$s$NBSP"; d=$((d+1)); done
        printf '%s' "$s"
      }
      meta=$(playerctl metadata title 2>/dev/null)
      status=$(playerctl status 2>/dev/null)
      if [ -z "$meta" ] || [ "$status" != "Playing" ] && [ "$status" != "Paused" ]; then
        rm -f "$state"
        echo '{"text":"","class":"stopped"}'
        exit 0
      fi
      title=$(printf '%s' "$meta" | sed 's/<[^>]*>//g')
      len=$(printf '%s' "$title" | wc -m)
      if [ "$len" -le "$win" ]; then
        rm -f "$state"
        text=$(pad "$title" "$win")
      else
        pos=0
        [ -f "$state" ] && pos=$(cat "$state" 2>/dev/null)
        pos=$((pos % len))
        text=$(printf '%s' "$title" | cut -c$((pos+1))-$((pos+win)))
        text=$(pad "$text" "$win")
        echo $((pos+1)) > "$state"
      fi
      cls=playing
      [ "$status" = "Paused" ] && cls=paused
      text=$(printf '%s' "$text" | sed 's/\\/\\\\/g; s/"/\\"/g')
      tooltip=$(printf '%s' "$meta" | sed 's/\\/\\\\/g; s/"/\\"/g')
      printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$text" "$cls" "$tooltip"
    '')
    (pkgs.writeShellScriptBin "wb-playpause" ''
      #!/usr/bin/env bash
      playerctl play-pause 2>/dev/null
      sleep 0.2
      status=$(playerctl status 2>/dev/null)
      if [ "$status" = "Playing" ]; then echo "󰏤"; else echo "󰐊"; fi
    '')

    (pkgs.writeShellScriptBin "wb-prev" ''
      #!/usr/bin/env bash
      playerctl previous 2>/dev/null
      echo ""
    '')

    (pkgs.writeShellScriptBin "wb-next" ''
      #!/usr/bin/env bash
      playerctl next 2>/dev/null
      echo ""
    '')

    (pkgs.writeShellScriptBin "wb-bt" ''
      #!/usr/bin/env bash
      state=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off)
      if [ "$1" = "toggle" ]; then
        if [ "$state" = "on" ]; then bluetoothctl power off; else bluetoothctl power on; fi
        pkill -RTMIN+3 waybar
        state=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off)
      fi
      if [ "$state" = "on" ]; then
        echo '{"text":"󰂯","class":"bt-on","tooltip":"Bluetooth actif"}'
      else
        echo '{"text":"󰂲","class":"bt-off","tooltip":"Bluetooth inactif"}'
      fi
    '')

    (pkgs.writeShellScriptBin "wb-wsd" ''
      #!/usr/bin/env bash
      CACHE="$HOME/.cache/ws"
      SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
      update() {
        local id w
        id=$(hyprctl -j activeworkspace 2>/dev/null | grep '"id"' | head -1 | sed 's/.*"id": *\([0-9]*\).*/\1/')
        [ -z "$id" ] && id="1"
        for w in 1 2 3; do
          if [ "$w" = "$id" ]; then
            printf '{"text":" ","class":"active"}\n' > "$CACHE$w"
          else
            printf '{"text":"●","class":"inactive"}\n' > "$CACHE$w"
          fi
        done
        pkill -RTMIN+4 waybar 2>/dev/null
      }
      update
      [ -S "$SOCK" ] || exit 0
      socat -U - "UNIX-CONNECT:$SOCK" | while read -r ev; do
        case "$ev" in
          workspacev2*|focusedmonv2*|activeworkspace*|workspace*|focusedmon*) update ;;
        esac
      done
    '')

    (pkgs.writeShellScriptBin "wb-wsreader" ''
      #!/usr/bin/env bash
      f="$HOME/.cache/ws$1"
      if [ -f "$f" ]; then cat "$f"; else printf '{"text":"●","class":"inactive"}\n'; fi
    '')
    (pkgs.writeShellScriptBin "wb-hdr" ''
      #!/usr/bin/env bash
      # wb-hdr — état + toggle HDR du moniteur (Hyprland >= 0.55, config Lua).
      # Usage:  wb-hdr            → JSON pour waybar (class hdr-on / hdr-off)
      #         wb-hdr toggle     → bascule cm/bitdepth puis notifie waybar (RTMIN+10)
      CACHE="$HOME/.cache/wb-hdr"

      read_info() {
        hyprctl monitors -j 2>/dev/null | jq -r '
          (map(select(.focused)) | .[0]) // .[0]
          | [ .name,
              (.colorManagementPreset // "srgb"),
              ("\(.width)x\(.height)@\((.refreshRate + 0.5) | floor)"),
              .scale,
              "\(.x)x\(.y)" ] | @tsv' 2>/dev/null
      }

      info=$(read_info)
      if [ -z "$info" ]; then
        info=$(cat "$CACHE" 2>/dev/null)
      fi
      [ -z "$info" ] && info=$'DP-4\tsrgb\t2560x1440@280\t1\t0x0'

      MON=$(printf '%s' "$info" | cut -f1)
      CM=$(printf '%s' "$info"   | cut -f2)
      MODE=$(printf '%s' "$info" | cut -f3)
      SC=$(printf '%s' "$info"   | cut -f4)
      POS=$(printf '%s' "$info"  | cut -f5)

      case "$CM" in
        hdr|hdredid) on=1 ;;
        *) on=0 ;;
      esac

      if [ "$1" = "toggle" ]; then
        if [ "$on" = "1" ]; then
          CMOUT="srgb"; BITS=8
        else
          CMOUT="hdr"; BITS=10
        fi
        hyprctl eval "hl.monitor({ output = \"$MON\", mode = \"$MODE\", position = \"$POS\", scale = $SC, cm = \"$CMOUT\", bitdepth = $BITS })" >/dev/null 2>&1
        printf '%s\t%s\t%s\t%s\t%s\n' "$MON" "$CMOUT" "$MODE" "$SC" "$POS" > "$CACHE"
        pkill -RTMIN+10 waybar 2>/dev/null
        CM=$CMOUT
      fi

      if [ "$CM" = "hdr" ] || [ "$CM" = "hdredid" ]; then
        printf '{"text":"HDR","class":"hdr-on","tooltip":"HDR activé (%s)"}\n' "$CM"
      else
        printf '{"text":"HDR","class":"hdr-off","tooltip":"HDR désactivé"}\n'
      fi
    '')
    (pkgs.writeShellScriptBin "power-menu" ''
      #!/usr/bin/env bash
      options=$'⏻ Éteindre\n󰜉 Redémarrer\n󰒲 Veille\n Verrouiller\n󰗼 Quitter Hyprland'
      choice=$(printf '%s' "$options" | rofi -dmenu -p "Power" -theme "$HOME/.config/rofi/power.rasi" 2>/dev/null)
      case "$choice" in
        *"Éteindre") systemctl poweroff ;;
        *"Redémarrer") systemctl reboot ;;
        *"Veille") systemctl suspend ;;
        *"Verrouiller") hyprlock ;;
        *"Quitter") hyprctl dispatch exit ;;
      esac
    '')
  ];
}
