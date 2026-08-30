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
  ];

  home.file = {
    # --- Scripts waybar (encoches) ---
    ".local/bin/wb-music".source = pkgs.writeScript "wb-music" ''
      #!/usr/bin/env bash
      status=$(playerctl status 2>/dev/null) || { echo "No music"; exit 0; }
      if [ "$status" = "Playing" ] || [ "$status" = "Paused" ]; then
        title=$(playerctl metadata --format '{{ artist }} - {{ title }}' 2>/dev/null)
        [ -z "$title" ] && title=$(playerctl metadata title 2>/dev/null)
        [ -z "$title" ] && title="..."
        if [ "$status" = "Paused" ]; then
          echo "⏸ $title"
        else
          echo "$title"
        fi
      else
        echo "No music"
      fi
    '';
    ".local/bin/wb-playpause".source = pkgs.writeScript "wb-playpause" ''
      #!/usr/bin/env bash
      playerctl play-pause 2>/dev/null
      sleep 0.2
      status=$(playerctl status 2>/dev/null)
      if [ "$status" = "Playing" ]; then echo "⏸"; else echo "▶"; fi
    '';
    ".local/bin/wb-prev".source = pkgs.writeScript "wb-prev" ''
      #!/usr/bin/env bash
      playerctl previous 2>/dev/null
      echo ""
    '';
    ".local/bin/wb-next".source = pkgs.writeScript "wb-next" ''
      #!/usr/bin/env bash
      playerctl next 2>/dev/null
      echo ""
    '';
    ".local/bin/wb-hdr".source = pkgs.writeScript "wb-hdr" ''
      #!/usr/bin/env bash
      state_file="$HOME/.cache/wb-hdr"
      [ -f "$state_file" ] || echo off > "$state_file"
      state=$(cat "$state_file")
      if [ "$1" = "toggle" ]; then
        if [ "$state" = "on" ]; then echo off > "$state_file"; else echo on > "$state_file"; fi
        pkill -RTMIN+2 waybar
        state=$(cat "$state_file")
      fi
      if [ "$state" = "on" ]; then
        echo '{"text":"HDR ON","class":"hdr-on","tooltip":"HDR actif"}'
      else
        echo '{"text":"HDR OFF","class":"hdr-off","tooltip":"HDR inactif"}'
      fi
    '';
    ".local/bin/wb-bt".source = pkgs.writeScript "wb-bt" ''
      #!/usr/bin/env bash
      state=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off)
      if [ "$1" = "toggle" ]; then
        if [ "$state" = "on" ]; then bluetoothctl power off; else bluetoothctl power on; fi
        pkill -RTMIN+3 waybar
        state=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off)
      fi
      if [ "$state" = "on" ]; then
        echo '{"text":"BT ON","class":"bt-on","tooltip":"Bluetooth actif"}'
      else
        echo '{"text":"BT OFF","class":"bt-off","tooltip":"Bluetooth inactif"}'
      fi
    '';
    ".local/bin/wb-wsdot".source = pkgs.writeScript "wb-wsdot" ''
      #!/usr/bin/env bash
      active=$(hyprctl -j activeworkspace 2>/dev/null | grep '"id"' | head -1 | sed 's/.*"id": *\([0-9]*\).*/\1/')
      [ -z "$active" ] && active="1"
      out=""
      for i in 1 2 3; do
        out="$out "
        if [ "$i" = "$active" ]; then
          out="$out<span background='#89b4fa' foreground='#1e1e2e'>▭</span>"
        else
          out="$out<span background='#585b70' foreground='#1e1e2e'>●</span>"
        fi
      done
      echo -e "$out"
    '';
    ".local/bin/power-menu".source = pkgs.writeScript "power-menu" ''
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
    '';
    # --- Config rofi ---
    ".config/rofi/config.rasi".text = ''
      @theme "~/.config/rofi/catppuccin-mocha.rasi"
      configuration {
        modi: "drun,run,window";
        show-icons: true;
        drun-display-format: "{icon} {name}";
      }
    '';
    ".config/rofi/theme.rasi".text = ''
      @theme "~/.config/rofi/catppuccin-mocha.rasi"
    '';
    ".config/rofi/power.rasi".text = ''
      @theme "~/.config/rofi/catppuccin-mocha.rasi"
      configuration {
        lines: 5;
        location: 0;
        width: 220;
        padding: 10;
      }
    '';
    ".config/rofi/catppuccin-mocha.rasi".text = ''
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
  };
}
