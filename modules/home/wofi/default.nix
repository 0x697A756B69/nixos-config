{ config, pkgs, ... }:

{
  programs.wofi = {
    enable = true;
    style = ''
      @import "${config.styling.palette}/colors.css";

      * {
        font-family: "JetBrains Mono Nerd Font";
      }
      window {
        background-color: @base_glass;
        color: @text;
        border: 1px solid @border;
        border-radius: 12px;
      }
      #input {
        background-color: @base_alt;
        color: @text;
        border: none;
        border-radius: 8px;
        margin: 8px;
      }
      #inner-box { padding: 0 8px 8px 8px; }
      #entry { border-radius: 8px; padding: 6px 10px; }
      #entry:selected {
        background-color: @accent;
        color: @on_accent;
      }
    '';
  };
}
