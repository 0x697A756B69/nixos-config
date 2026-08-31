{ config, pkgs, ... }:

{
  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the Hyprland Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.defaultSession = "hyprland";
  services.desktopManager.plasma6.enable = false;

  # Install Hyprland.
  programs.hyprland.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };
}
