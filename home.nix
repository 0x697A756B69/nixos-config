{ config, pkgs, inputs, ... }:

{
  home.username = "izuki";
  home.homeDirectory = "/home/izuki";
  home.stateVersion = "26.05";

  imports = [
    ./modules/hyprland.nix
    ./modules/waybar.nix
    ./modules/theming.nix
    ./modules/infinite-desktop.nix
    # Zen Browser : profil déclaratif + thème matugen (voir modules/zen.nix)
    ./modules/zen.nix
  ];

  programs.kitty = {
    enable = true;
    extraConfig = ''
      # Couleurs depuis la palette du wallpaper (matugen, voir theming.nix)
      include ${config.styling.palette}/kitty.conf
    '';
  };
  programs.wofi = {
    enable = true;
    style = ''
      @import "${config.styling.palette}/colors.css";

      * {
        font-family: "JetBrains Mono Nerd Font";
      }
      window {
        background-color: @base_glass;
        color: @text;
        border: 1px solid @border;
        border-radius: 12px;
      }
      #input {
        background-color: @base_alt;
        color: @text;
        border: none;
        border-radius: 8px;
        margin: 8px;
      }
      #inner-box { padding: 0 8px 8px 8px; }
      #entry { border-radius: 8px; padding: 6px 10px; }
      #entry:selected {
        background-color: @accent;
        color: @on_accent;
      }
    '';
  };

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    mpvpaper
    matugen
    wev
    networkmanagerapplet
    blueman
    ripgrep
    rofi
    rofi-bluetooth
    networkmanager_dmenu
    playerctl
    pavucontrol
    jq
    hyprlock
    pamixer
    socat

    # --- Capture d'écran + vidéo (façon Plasma Wayland) ---
    grim
    slurp
    grimblast
    swappy
    wf-recorder
    wl-clipboard
    libnotify

    # --- Scripts waybar (encoches) ---
    (pkgs.writeShellScriptBin "wb-music" ''
      #!/usr/bin/env bash
      win=6
      state="$HOME/.cache/wb-music-pos"
      NBSP=$(printf '\u00a0')
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
    (pkgs.writeShellScriptBin "wb-cap" ''
      #!/usr/bin/env bash
      # wb-cap — capture d'écran + vidéo (façon Plasma Wayland).
      # Usage: wb-cap area|screen|record
      mkdir -p "$HOME/Images" "$HOME/Videos"
      case "$1" in
        area)
          grimblast --notify copy area
          ;;
        screen)
          grimblast --notify save output "$HOME/Images/ecran-$(date +%F-%H%M%S).png"
          ;;
        record)
          state="$HOME/.cache/wb-cap-record"
          if [ -f "$state" ]; then
            pid=$(cat "$state" 2>/dev/null)
            kill "$pid" 2>/dev/null
            rm -f "$state"
            notify-send -t 2500 "Enregistrement arrêté" "Sauvegardé dans ~/Videos"
          else
            file="$HOME/Videos/capture-$(date +%F-%H%M%S).mp4"
            geom=$(${pkgs.slurp}/bin/slurp -f "%g" 2>/dev/null)
            [ -z "$geom" ] && exit 1
            ${pkgs.wf-recorder}/bin/wf-recorder -g "$geom" -f "$file" &
            echo $! > "$state"
            notify-send -t 2500 "Enregistrement en cours" "Raccourci pour arrêter"
          fi
          ;;
      esac
    '')
    (pkgs.writeShellScriptBin "power-menu" ''
      #!/usr/bin/env bash
      options=$'⏻ Éteindre\n󰜉 Redémarrer\n󰒲 Veille\n Verrouiller\n󰗼 Quitter Hyprland'
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

  # --- Config rofi ---
  xdg.configFile."rofi/config.rasi".text = ''
    @theme "~/.config/rofi/catppuccin-mocha.rasi"
    configuration {
      modi: "drun,run,window";
      show-icons: true;
      drun-display-format: "{icon} {name}";
    }
  '';
  xdg.configFile."rofi/power.rasi".text = ''
    @theme "~/.config/rofi/catppuccin-mocha.rasi"
    configuration {
      lines: 5;
      location: 0;
      width: 220;
      padding: 10;
    }
  '';
  xdg.configFile."rofi/catppuccin-mocha.rasi".text = ''
    * {
      bg0:    #1e1e2e;
      bg1:    #181825;
      fg0:    #cdd6f4;
      fg1:    #a6adc8;
      accent: #89b4fa;
      red:    #f38ba8;
      window-padding: 8px;
      window-border: 2px;
      window-border-color: #313244;
      border-radius: 12px;
      spacing: 6px;
      font: "JetBrains Mono Nerd Font 12";
    }
    window {
      background-color: @bg0;
      border: @window-border @window-border-color;
      border-radius: @border-radius;
      padding: @window-padding;
    }
    inputbar {
      background-color: @bg1;
      border-radius: 8px;
      padding: 6px 10px;
      text-color: @fg0;
    }
    element {
      padding: 8px 10px;
      border-radius: 8px;
      text-color: @fg0;
    }
    element selected {
      background-color: @accent;
      text-color: @bg0;
    }
    listview {
      lines: 10;
      padding: 6px 0 0 0;
    }
    mainbox {
      text-color: @fg0;
    }
  '';
}
