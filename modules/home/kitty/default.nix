{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    # 0 = never confirm on close.
    settings."confirm_os_window_close" = "0";
    extraConfig = ''
      include ${config.styling.palette}/kitty.conf
    '';
  };
}
