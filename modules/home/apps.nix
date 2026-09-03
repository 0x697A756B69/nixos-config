{ config, pkgs, ... }:

{
  programs.vesktop.enable = true;

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    matugen
    wev
    networkmanagerapplet
    blueman
    ripgrep
    networkmanager_dmenu
  ];
}
