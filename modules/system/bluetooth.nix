{ config, pkgs, ... }:

{
  # Enable bluethooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
}
