{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    rofi
    rofi-bluetooth
  ];

  # --- Config rofi ---
  xdg.configFile."rofi/config.rasi".text = ''
    @theme "~/.config/rofi/catppuccin-mocha.rasi"
    configuration {
      modi: "drun,run,window";
      show-icons: true;
      drun-display-format: "{icon} {name}";
    }
  '';
  xdg.configFile."rofi/power.rasi".text = ''
    @theme "~/.config/rofi/catppuccin-mocha.rasi"
    configuration {
      lines: 5;
      location: 0;
      width: 220;
      padding: 10;
    }
  '';
  xdg.configFile."rofi/catppuccin-mocha.rasi".text = ''
    * {
      bg0:    #1e1e2e;
      bg1:    #181825;
      fg0:    #cdd6f4;
      fg1:    #a6adc8;
      accent: #89b4fa;
      red:    #f38ba8;
      window-padding: 8px;
      window-border: 2px;
      window-border-color: #313244;
      border-radius: 12px;
      spacing: 6px;
      font: "JetBrains Mono Nerd Font 12";
    }
    window {
      background-color: @bg0;
      border: @window-border @window-border-color;
      border-radius: @border-radius;
      padding: @window-padding;
    }
    inputbar {
      background-color: @bg1;
      border-radius: 8px;
      padding: 6px 10px;
      text-color: @fg0;
    }
    element {
      padding: 8px 10px;
      border-radius: 8px;
      text-color: @fg0;
    }
    element selected {
      background-color: @accent;
      text-color: @bg0;
    }
    listview {
      lines: 10;
      padding: 6px 0 0 0;
    }
    mainbox {
      text-color: @fg0;
    }
  '';
}
