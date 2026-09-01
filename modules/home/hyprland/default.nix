{ config, pkgs, lib, self, ... }:

let
  mainMod = "SUPER";
  terminal = "kitty";
  menu = "walker";
  inline = lib.generators.mkLuaInline;
  infinite = config.programs.hyprland-infinite.package;
  core = "${infinite}/lib/hyprland-infinite/infinite_desktop_core.py";
  py = (pkgs.python3.withPackages (ps: [ ps.evdev ]));
  wallpaper = "${self}/modules/home/theming/wallpapers/wallpaper_upscaled_2k.mp4";
in
{
  imports = [ ./infinite-desktop.nix ];

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    package = pkgs.hyprland;

    settings = {
      monitor = {
        output = "";
        mode = "2560x1440@280";
        position = "auto";
        scale = 1;
      };

      # Blur is handled globally by decoration.blur.xray; window_rule has no blur field.
      window_rule = {
        match.class = "zen";
        opacity = "0.95 0.95";
      };

      layer_rule = {
        match.namespace = "^(settings-window)$";
        animation = "pop";
      };

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
          blur = {
            enabled = true;
            size = 6;
            passes = 2;
            xray = true;
          };
        };
        animations = {
          enabled = true;
        };
        input = {
          kb_layout = "fr";
        };
      };

      bind = import ./binds.nix { inherit mainMod terminal menu inline; };

      on = {
        _args = [
          "hyprland.start"
          (inline ''
            function()
              hl.exec_cmd("${py}/bin/python ${core} 1.6 > /tmp/infinite-desktop.log 2>&1")
              hl.exec_cmd("elephant")
              hl.exec_cmd("walker --gapplication-service")
              hl.exec_cmd("wb-wallpaper")
              hl.exec_cmd("wb-wsd")
              hl.exec_cmd("waybar")
              hl.exec_cmd("wb-dropdown")
            end
          '')
        ];
      };
    };
  };

  # --- Tools used by the Hyprland binds (wallpaper, screenshots) ---
  home.packages = with pkgs; [
    mpvpaper
    awww
    grim
    slurp
    grimblast
    swappy
    wf-recorder
    wl-clipboard
    libnotify

    (pkgs.writeShellScriptBin "wb-wallpaper" ''
      #!/usr/bin/env bash
      # wb-wallpaper [path]: switch (or restart) the desktop wallpaper and
      # re-theme from it. With no argument, re-applies the persisted choice
      # (falling back to the default) -- used at session startup, the
      # SUPER+B restart bind, and the Quickshell wallpaper tab. Videos go
      # through mpvpaper (no transition); stills go through awww (animated
      # transition) -- awww itself has no video support, hence the dispatch.
      set -euo pipefail
      statefile="$HOME/.local/state/wallpaper/path.txt"
      mkdir -p "$(dirname "$statefile")"
      path="''${1:-}"
      if [ -z "$path" ]; then
        path=$(cat "$statefile" 2>/dev/null || true)
        [ -z "$path" ] && path="${wallpaper}"
      fi
      printf '%s' "$path" > "$statefile"

      case "$path" in
        *.mp4|*.mkv|*.webm|*.mov)
          pkill awww-daemon 2>/dev/null || true
          pkill mpvpaper 2>/dev/null || true
          sleep 0.2
          ${pkgs.mpvpaper}/bin/mpvpaper -o 'no-audio loop --cache=no --demuxer-max-bytes=64MiB --demuxer-max-back-bytes=16MiB' DP-4 "$path" &
          disown
          ;;
        *)
          pkill mpvpaper 2>/dev/null || true
          pgrep -x awww-daemon >/dev/null 2>&1 || { ${pkgs.awww}/bin/awww-daemon & disown; sleep 0.3; }
          ${pkgs.awww}/bin/awww img "$path" --resize crop --transition-type grow --transition-duration 1
          ;;
      esac

      theme-apply "$path"
    '')

    (pkgs.writeShellScriptBin "wb-cap" ''
      #!/usr/bin/env bash
      # wb-cap: screenshot + video capture (Plasma Wayland style).
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
  ];
}
