{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    extraConfig = ''
      # Couleurs depuis la palette du wallpaper (matugen, voir modules/home/theming/matugen)
      include ${config.styling.palette}/kitty.conf
    '';
  };
}
