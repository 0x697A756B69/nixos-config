# Menus rofi (drun, power menu) : couleurs pilotées par matugen (aucune
# couleur en dur), layouts définis dans les *-layout.rasi ci-contre.
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    rofi
    rofi-bluetooth
  ];

  xdg.configFile."rofi/rofi-colors.rasi".source =
    "${config.styling.palette}/rofi-colors.rasi";
  xdg.configFile."rofi/config-layout.rasi".source = ./config-layout.rasi;
  xdg.configFile."rofi/power-layout.rasi".source = ./power-layout.rasi;
  xdg.configFile."rofi/capture-layout.rasi".source = ./capture-layout.rasi;
  # net-layout.rasi : ébauche pour un menu wifi, supersédée par le dropdown
  # AGS/Astal (voir modules/home/ags). Conservée sur disque, non référencée.
  xdg.configFile."rofi/net-layout.rasi".source = ./net-layout.rasi;

  # @import charge les variables de couleur, @theme charge ensuite la mise
  # en page par-dessus (voir `man rofi-theme`, section "Multiple file
  # handling" : @import fusionne, @theme remplace le thème mais pas les
  # propriétés globales déjà importées).
  xdg.configFile."rofi/config.rasi".text = ''
    @import "rofi-colors.rasi"
    @theme "config-layout.rasi"
  '';
  xdg.configFile."rofi/power.rasi".text = ''
    @import "rofi-colors.rasi"
    @theme "power-layout.rasi"
  '';
}
