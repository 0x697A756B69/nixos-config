# Hôte "nixos" : tout ce qui est réellement spécifique à cette machine
# (matériel, hostname, autologin). Le reste vit dans modules/system/*.
{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ../../modules/system/desktop.nix
    ../../modules/system/graphics-nvidia.nix
    ../../modules/system/networking.nix
    ../../modules/system/bluetooth.nix
    ../../modules/system/audio.nix
    ../../modules/system/locale.nix
    ../../modules/system/printing.nix
    ../../modules/system/steam.nix
    ../../modules/system/spicetify.nix
    ../../modules/system/nixvim.nix
    ../../modules/system/misc-programs.nix
    ../../modules/system/system-packages.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.udev.extraRules = ''
  # Dongle USB custom (VID:PID 3554:f508) — accès utilisateur
  SUBSYSTEMS=="usb", ATTRS{idVendor}=="3554", ATTRS{idProduct}=="f508", MODE="0666", GROUP="users"

  # Même device — désactive l'autosuspend de façon persistante
  SUBSYSTEM=="usb", ATTR{idVendor}=="3554", ATTR{idProduct}=="f508", TEST=="power/control", ATTR{power/control}="on"
'';
  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages;

  boot.kernelParams = [
    "usbcore.quirks=3554:f508:k"
  ];

  networking.hostName = "nixos"; # Define your hostname.

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."izuki" = {
    isNormalUser = true;
    description = "izuki";
    extraGroups = [ "networkmanager" "wheel" "input" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  services.displayManager.autoLogin = {
   enable = true;
   user = "izuki";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
