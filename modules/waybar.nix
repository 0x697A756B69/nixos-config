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
        modules-right = [ "cpu" "memory" "network" "bluetooth" ];

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

        network = {
          format-wifi = "{icon} {essid}";
          format-icons = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];
          format-ethernet = "󰈀";
          format-disconnected = "󰤮";
          tooltip-format = "{ifname} | {ipaddr} | {signalStrength}%";
          on-click = "nm-connection-editor";
        };

        bluetooth = {
          format-on = "󰂯";
          format-off = "󰂲";
          format-connected = "󰂯 {num_connections}";
          tooltip-format = "{controller_alias} | {num_connections} apparié(s)";
          on-click = "blueman-manager";
        };      };
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

      #clock, #cpu, #memory, #network, #bluetooth {
        padding: 0 10px;
        color: #cdd6f4;
      }

      #cpu {
        color: #a6e3a1;
      }
      #memory {
        color: #f9e2af;
      }

    '';

    systemd = {
      enable = true;
    };
  };
}
