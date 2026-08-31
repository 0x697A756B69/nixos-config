# Applications et outils généraux, sans module dédié (une ligne ou presque
# chacun) : client Discord, polices, utilitaires réseau/bluetooth/debug.
{ config, pkgs, ... }:

{
  # Vesktop : client Discord (Vencord intégré), meilleur support Linux pour les
  # appels/streams. Installation propre sans theming ni transparence custom.
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
