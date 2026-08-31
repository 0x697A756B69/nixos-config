{ config, pkgs, ... }:

{
  # Configure Nvidia Driver
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;
  hardware.nvidia.modesetting.enable = true;
  hardware.graphics.enable32Bit = true;

  # Configure Hyprland + Nvidia
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
