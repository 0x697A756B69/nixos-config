{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    # confirm_os_window_close: nombre de fenêtres OS ouvertes à partir duquel
    # kitty demande confirmation avant de fermer ; 0 = jamais de confirmation,
    # quel que soit le déclencheur (SUPER+Q, bouton, ctrl+shift+w). Voir
    # modules/home/hyprland/binds.nix pour la vérification du bind SUPER+Q.
    settings."confirm_os_window_close" = "0";
    extraConfig = ''
      # Couleurs depuis la palette du wallpaper (matugen, voir modules/home/theming/matugen)
      include ${config.styling.palette}/kitty.conf
    '';
  };
}
