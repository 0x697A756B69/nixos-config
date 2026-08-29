{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        spacing = 4;

        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [ "cpu" "memory" "battery" "tray" ];

        "hyprland/workspaces" = {
          format = "{id}";
          format-icons = {
            active = " ";
            default = " ";
          };
          sort-by-number = true;
        };

        clock = {
          format = "{:%H:%M}";
          tooltip-format = "{:%A %d %B %Y}";
        };

        cpu = {
          interval = 5;
          format = " {}%";
          format-alt = "{icon} {usage}%";
          format-icons = [ "" "" "" "" ];
        };

        memory = {
          interval = 10;
          format = " {}%";
          tooltip-format = "{} used";
        };

        battery = {
          interval = 30;
          format = "{capacity}%";
          format-charging = "{capacity}% ";
          format-discharging = "{capacity}%";
        };

        tray = {
          icon-size = 18;
          spacing = 6;
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
      }

      window#waybar {
        background: rgba(30, 30, 46, 0.85);
        color: #cdd6f4;
      }

      #workspaces button {
        padding: 0 8px;
        color: #585b70;
      }
      #workspaces button.active {
        color: #89b4fa;
      }

      #clock, #cpu, #memory, #battery, #tray {
        padding: 0 10px;
        color: #cdd6f4;
      }

      #cpu {
        color: #a6e3a1;
      }
      #memory {
        color: #f9e2af;
      }
      #battery {
        color: #94e2d5;
      }
    '';
  };
}