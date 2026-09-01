# General apps and tools without a dedicated module.
{ config, pkgs, ... }:

{
  # Vesktop: Discord client with Vencord built in, better Linux support for calls/streams.
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
    discord
    # lsfg_vk  # undefined in nixpkgs as-is, commented out to unblock builds — see with 0x697A756B69
  ];
}
