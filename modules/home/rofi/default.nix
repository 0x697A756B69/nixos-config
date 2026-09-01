# Menus rofi (drun, power menu), couleurs pilotées par matugen.
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
  # Ébauche menu wifi, non référencée : supersédée par l'app AGS/Astal.
  xdg.configFile."rofi/net-layout.rasi".source = ./net-layout.rasi;

  # @import charge les couleurs, @theme la mise en page par-dessus.
  xdg.configFile."rofi/config.rasi".text = ''
    @import "rofi-colors.rasi"
    @theme "config-layout.rasi"
  '';
  xdg.configFile."rofi/power.rasi".text = ''
    @import "rofi-colors.rasi"
    @theme "power-layout.rasi"
  '';
}
