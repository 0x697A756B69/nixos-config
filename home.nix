{ config, pkgs, ... }:

{
  home.username = "izuki";
  home.homeDirectory = "/home/izuki";
  home.stateVersion = "26.05";

  programs.kitty.enable = true;
  programs.wofi.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    extraConfig = ''
      hl.monitor({
          output = "",
          mode = "preferred",
          position = "auto",
          scale = "auto",
      })

      local terminal = "kitty"
      local menu = "wofi --show drun"

      hl.on("hyprland.start", function()
          hl.exec_cmd(terminal)
      end)

      hl.config({
          general = {
              gaps_in = 5,
              gaps_out = 10,
              border_size = 2,
              col = {
                  active_border = "rgba(89b4faee)",
                  inactive_border = "rgba(45475aaa)",
              },
              layout = "dwindle",
          },
          decoration = {
              rounding = 8,
          },
          animations = {
              enabled = true,
          },
          input = {
            kb_layout = "fr",
          },
      })

      local mainMod = "SUPER"

      hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
      hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
      hl.bind(mainMod .. " + Q", hl.dsp.window.close())
      hl.bind(mainMod .. " + M", hl.dsp.exit())
      hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

      hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
      hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
      hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
      hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

      for i = 1, 4 do
          hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
          hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
      end
    '';
  };

  programs.home-manager.enable = true;
}