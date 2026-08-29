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

  # List packages installed in home profile
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    mpvpaper
    wev
  ];
}
