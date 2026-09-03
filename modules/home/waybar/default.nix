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

        # Left: logo + menu + music
        modules-left = [
          "custom/logo"
          "custom/settings"
          "custom/prev"
          "custom/playpause"
          "custom/next"
          "custom/music"
        ];
        # Center: 3 workspace dots (event-driven)
        modules-center = [ "custom/ws1" "custom/ws2" "custom/ws3" ];
        # Right: cpu + ram + volume + wifi + ethernet + bt + clock + power
        modules-right = [
          "cpu"
          "memory"
          "pulseaudio"
          "network#wifi"
          "network#ethernet"
          "custom/bt"
          "clock"
          "custom/power"
        ];
        "custom/logo" = {
          format = "";
          tooltip = false;
        };
        "custom/settings" = {
          # Opens the settings app on the already-active tab.
          format = "󰒓";
          on-click = "wb-settings open";
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
          # Left click: toggle + auto-reconnect (wb-bt). Right click: Bluetooth tab.
          on-click = "wb-bt toggle";
          on-click-right = "wb-settings openTab bluetooth";
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
          # Ouvre le power menu Quickshell (shell dédiée, layer-shell overlay)
          # au lieu du menu rofi legacy.
          on-click = "wb-power-toggle";
          tooltip = false;
        };
        "network#wifi" = {
          # Left click: toggle radio (wb-net). Right click: Wi-Fi tab.
          interface = "wlp*";
          format-wifi = "{icon}";
          format-icons = [ "󰤯" "󰤟" "󰤢" "󰤨" ];
          format-disconnected = "";
          on-click = "wb-net toggle";
          on-click-right = "wb-settings openTab wifi";
          tooltip = false;
        };
        "network#ethernet" = {
          interface = "en*";
          format-ethernet = "󰈀";
          format-disconnected = "";
          on-click-right = "wb-settings openTab wifi";
          tooltip = false;
        };
      };
    };

    style = ''
      @import "${config.styling.paletteDir}/colors.css";

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

      /* --- Notches: opaque (unlike the translucent + blurred apps) --- */
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
        padding: 0 14px 0 4px;
        background: @base;
        border-radius: 0 0 16px 16px;
      }

      /* --- Left: compact, big airy NixOS logo --- */
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

      /* --- Center: tight notch, plain active pill, packed dots --- */
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

      /* --- Right: compact, palette --- */
      #cpu { padding: 0 7px; font-size: 13px; color: @text; min-width: 56px; }
      #memory { padding: 0 7px; font-size: 13px; color: @text; min-width: 56px; }
      #pulseaudio { padding: 0 7px; font-size: 13px; color: @text; min-width: 56px; }
      #pulseaudio.muted { color: @disabled; }
      #custom-bt { padding: 0 7px; font-size: 13px; color: @text; min-width: 26px; }
      #custom-bt.bt-off { color: @disabled; }
      #clock { padding: 0 7px; font-size: 13px; color: @text; min-width: 50px; }
      #custom-power {
        padding: 0 7px;
        color: @error;
        font-size: 13px;
        min-width: 24px;
      }

      /* --- Network --- */
      #network.wifi, #network.ethernet {
        padding: 0 6px;
        font-size: 13px;
        color: @text;
        min-width: 24px;
      }
    '';

    systemd = {
      enable = false;
    };
  };

  # --- Tools used by the modules above (volume, music, power menu) ---
  home.packages = with pkgs; [
    playerctl
    pavucontrol
    pamixer
    socat
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

    (pkgs.writeShellScriptBin "wb-net" ''
      #!/usr/bin/env bash
      # Toggles the wifi radio (nmcli). No state script: waybar's native
      # "network" module already watches NetworkManager over DBus.
      if [ "$1" = "toggle" ]; then
        state=$(nmcli radio wifi)
        if [ "$state" = "enabled" ]; then nmcli radio wifi off; else nmcli radio wifi on; fi
      fi
    '')

    (pkgs.writeShellScriptBin "wb-bt" ''
      #!/usr/bin/env bash
      # toggle: flips power, then reconnects already-paired devices in the background.
      state=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off)
      if [ "$1" = "toggle" ]; then
        if [ "$state" = "on" ]; then
          bluetoothctl power off
        else
          bluetoothctl power on
          sleep 1
          bluetoothctl devices Paired 2>/dev/null | awk '{print $2}' | while read -r mac; do
            [ -n "$mac" ] && bluetoothctl connect "$mac" >/dev/null 2>&1 &
          done
        fi
        pkill -RTMIN+3 waybar
        state=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off)
      fi
      if [ "$state" = "on" ]; then
        echo '{"text":"󰂯","class":"bt-on","tooltip":"Bluetooth actif (clic droit : gestion)"}'
      else
        echo '{"text":"󰂲","class":"bt-off","tooltip":"Bluetooth inactif (clic droit : gestion)"}'
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
  ];
}
