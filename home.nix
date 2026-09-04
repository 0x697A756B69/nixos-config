{ config, pkgs, inputs, ... }:

{
  home.username = "izuki";
  home.homeDirectory = "/home/izuki";
  home.stateVersion = "26.05";

  imports = [
    ./modules/home/hyprland
    ./modules/home/waybar
    ./modules/home/swaync
    ./modules/home/theming/matugen
    ./modules/home/theming/gtk.nix
    ./modules/home/kitty
    ./modules/home/walker
    ./modules/home/rofi
    ./modules/home/quickshell
    ./modules/home/quickshell/power
    ./modules/home/quickshell/cava
    ./modules/home/nvim
    ./modules/home/zen.nix
    ./modules/home/apps.nix
  ];
}
