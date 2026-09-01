{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    # 0 = jamais de confirmation à la fermeture.
    settings."confirm_os_window_close" = "0";
    extraConfig = ''
      include ${config.styling.palette}/kitty.conf
    '';
  };
}
