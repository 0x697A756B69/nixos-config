# Rofi menus (drun, power menu), colors driven by matugen.
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    rofi
    rofi-bluetooth
  ];

  # Symlink, not a store copy: rofi-colors.rasi is regenerated at runtime
  # by theme-apply (see modules/home/theming/matugen), not at Nix build time.
  xdg.configFile."rofi/rofi-colors.rasi".source =
    config.lib.file.mkOutOfStoreSymlink "${config.styling.paletteDir}/rofi-colors.rasi";
  xdg.configFile."rofi/config-layout.rasi".source = ./config-layout.rasi;
  xdg.configFile."rofi/power-layout.rasi".source = ./power-layout.rasi;
  xdg.configFile."rofi/capture-layout.rasi".source = ./capture-layout.rasi;

  # @import loads the colors, @theme the layout on top.
  xdg.configFile."rofi/config.rasi".text = ''
    @import "rofi-colors.rasi"
    @theme "config-layout.rasi"
  '';
  xdg.configFile."rofi/power.rasi".text = ''
    @import "rofi-colors.rasi"
    @theme "power-layout.rasi"
  '';
}
