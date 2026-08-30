{ config, pkgs, ... }:

{
  home.username = "izuki";
  home.homeDirectory = "/home/izuki";
  home.stateVersion = "26.05";

  imports = [
    ./modules/hyprland.nix
    ./modules/waybar.nix
    ./modules/infinite-desktop.nix
  ];

  programs.kitty.enable = true;
  programs.wofi.enable = true;

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    mpvpaper
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

    (pkgs.writeShellScriptBin "wb-wsdot" ''
      #!/usr/bin/env bash
      ws="$1"
      active=$(hyprctl -j activeworkspace 2>/dev/null | grep '"id"' | head -1 | sed 's/.*"id": *\([0-9]*\).*/\1/')
      [ -z "$active" ] && active="1"
      if [ "$ws" = "$active" ]; then
        echo '{"text":" ","class":"active"}'
      else
        echo '{"text":"●","class":"inactive"}'
      fi
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
