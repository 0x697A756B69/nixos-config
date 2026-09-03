{ config, pkgs, ... }:

{
  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;

    # Accent color from the matugen pipeline (see theming/matugen), same
    # runtime-symlink approach as rofi/kitty/zen: re-read on every app
    # launch, no rebuild needed when the wallpaper (and thus accent) changes.
    gtk3.extraCss = ''@import url("file://${config.styling.paletteDir}/gtk-accent.css");'';
    gtk4.extraCss = ''@import url("file://${config.styling.paletteDir}/gtk-accent.css");'';
  };

  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
  };
}
