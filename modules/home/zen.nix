{ config, lib, pkgs, inputs, ... }:

{
  options.zen-browser.package = lib.mkOption {
    type = lib.types.package;
    default = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;
    defaultText = lib.literalExpression
      "inputs.zen-browser.packages.\${pkgs.stdenv.hostPlatform.system}.default";
    description = "Zen Browser package (youwen5/zen-browser-flake).";
  };

  config = {
    home.packages = [ config.zen-browser.package ];

    # user.js is re-read on every Zen startup and takes priority over prefs.js.
    home.file.".zen/user.js".text = ''
      user_pref("browser.tabs.allow_transparent_browser", true);
      user_pref("zen.widget.linux.transparency", true);
    '';

    # @import (not readFile): zenChrome.css is regenerated at runtime by
    # theme-apply, readFile would freeze its content at Nix eval time.
    home.file.".zen/chrome/userChrome.css".text = ''
      @import url("file://${config.styling.paletteDir}/zenChrome.css");
    '';

    home.activation = {
      # Zen rewrites profiles.ini at runtime, so no store symlink: regenerate
      # it idempotently pointing at ~/.zen (profile root = ~/.config/zen).
      initZenProfile = lib.hm.dag.entryBefore [ "migrateZenProfile" ] ''
        profile="${config.home.homeDirectory}/.zen"
        ini="${config.home.homeDirectory}/.config/zen/profiles.ini"
        mkdir -p "$profile"
        mkdir -p "$(dirname "$ini")"
        if ! grep -q "^Path=$profile" "$ini" 2>/dev/null; then
          cat > "$ini" <<EOF
[General]
StartWithLastProfile=1
Version=2

[Profile0]
Name=Desktop
IsRelative=0
Path=$profile
Default=1
EOF
        fi
      '';

      # One-shot migration: old auto-generated profile (hash) -> ~/.zen.
      migrateZenProfile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        marker="$HOME/.zen/.zen-migrated"
        if [ ! -f "$marker" ]; then
          mkdir -p "$HOME/.zen"
          old="$(ls -d "$HOME"/.config/zen/*.Default\ Profile 2>/dev/null | head -n1 || true)"
          if [ -n "$old" ] && [ -d "$old" ]; then
            ( cd "$old" && find . -mindepth 1 -maxdepth 1 \
                ! -name chrome ! -name user.js ! -name lock ! -name .parentlock \
                ! -name '*.lz4' ! -name cache2 ! -name crashreports ! -name minidumps \
                -exec cp -a {} "$HOME/.zen/" \; ) || true
          fi
          touch "$marker"
        fi
      '';
    };
  };
}
