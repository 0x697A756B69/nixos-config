{ config, lib, pkgs, inputs, ... }:

{
  options.zen-browser.package = lib.mkOption {
    type = lib.types.package;
    default = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;
    defaultText = lib.literalExpression
      "inputs.zen-browser.packages.\${pkgs.stdenv.hostPlatform.system}.default";
    description = "Paquet Zen Browser (flake youwen5/zen-browser-flake).";
  };

  config = {
    home.packages = [ config.zen-browser.package ];

    # user.js est relu à chaque démarrage de Zen et prime sur prefs.js.
    home.file.".zen/user.js".text = ''
      user_pref("browser.tabs.allow_transparent_browser", true);
      user_pref("zen.widget.linux.transparency", true);
    '';

    home.file.".zen/chrome/userChrome.css".text = ''
      ${builtins.readFile "${config.styling.palette}/zenChrome.css"}
    '';

    home.activation = {
      # Zen réécrit profiles.ini à l'exécution, donc pas de symlink store :
      # on régénère idempotent vers ~/.zen (racine profils = ~/.config/zen).
      initZenProfile = lib.hm.dag.entryBefore [ "migrateZenProfile" ] ''
        profile="${config.home.homeDirectory}/.zen"
        ini="${config.home.homeDirectory}/.config/zen/profiles.ini"
        mkdir -p "$profile"
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

      # Migration one-shot : ancien profil auto (hash) -> ~/.zen.
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