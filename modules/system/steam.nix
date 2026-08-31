{ config, pkgs, ... }:

{
  # Install steam.
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  programs.gamemode.enable = true;

  programs.steam.extraCompatPackages = [ pkgs.steamtinkerlaunch ];

  #List packages installed in steam profil
  programs.steam.package = pkgs.steam.override {
    extraPkgs = pkgs': with pkgs'; [
      libXcursor
      libXi
      libXinerama
      libXScrnSaver
      libpng
      libpulseaudio
      libvorbis
      stdenv.cc.cc.lib # Provides libstdc++.so.6
      libkrb5
      keyutils
      # Add other libraries as needed
    ];
  };
}
