{ config, pkgs, ... }:

{
  services.swaync = {
    enable = true;

    settings = {
      positionX = "right";
      positionY = "top";
      control-center-width = 380;
      control-center-height = 600;
      notification-window-width = 380;
      timeout = 6;
      timeout-low = 3;
      timeout-critical = 0;
      notification-icon-size = 48;
      notification-body-image-height = 100;
      notification-body-image-width = 200;
      keyboard-shortcuts = true;
      image-visibility = "when-available";
      transition-time = 200;
      hide-on-clear = false;
      hide-on-action = true;
      script-fail-notify = true;
      widgets = [ "title" "dnd" "notifications" ];
      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Tout effacer";
        };
        dnd = {
          text = "Ne pas déranger";
        };
      };
    };

    # Accent color from the matugen pipeline, same runtime-symlink approach
    # as waybar/rofi/kitty: re-read at every swaync restart, no rebuild
    # needed when the wallpaper (and thus accent) changes.
    style = ''
      @import "${config.styling.paletteDir}/colors.css";

      .control-center {
        background: @base;
        border-radius: 12px;
      }
      .notification-row .notification-background {
        background: @base_alt;
        border-radius: 10px;
      }
      .notification-row .notification-background .notification-default-action,
      .notification-row .notification-background .notification-action {
        color: @text;
      }
      widget-title > button {
        background: @accent;
        color: @on_accent;
        border-radius: 8px;
      }
      .widget-dnd > switch:checked {
        background: @accent;
      }
      .close-button {
        background: @error;
        color: @on_accent;
        border-radius: 100%;
      }
    '';
  };

  home.packages = [
    (pkgs.writeShellScriptBin "wb-notifications" ''
      #!/usr/bin/env bash
      exec swaync-client -t -sw
    '')
  ];
}
