{ config, pkgs, ... }:

{
  home.username = "izuki";
  home.homeDirectory = "/home/izuki";
  home.stateVersion = "26.05";

  programs.kitty.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;
  };

  programs.home-manager.enable = true;
}