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

    # Préférences déclaratives (about:config) — user.js est relu à chaque
    # démarrage de Zen et prime sur prefs.js. Les prefs de transparence sont
    # vérifiées dans browser/omni.ja de ce build (firefox.js, l. 555 et 1769).
    home.file.".zen/user.js".text = ''
      // Zen Browser : préférences déclaratives (voir modules/zen.nix)
      user_pref("browser.tabs.allow_transparent_browser", true);
      user_pref("zen.widget.linux.transparency", true);
    '';

    # Thème Material You du wallpaper : contenu de zenChrome.css inliné au
    # build (même palette matugen que waybar/wofi/kitty, voir theming.nix).
    home.file.".zen/chrome/userChrome.css".text = ''
      /* Zen Browser : thème Material You du wallpaper (voir modules/theming.nix) */
      ${builtins.readFile "${config.styling.palette}/zenChrome.css"}
    '';

    home.activation = {
      # Zen réécrit profiles.ini à l'exécution => on ne peut pas le symlinker
      # vers le store (lecture seule). On le (ré)génère de façon idempotente
      # vers un profil à chemin ABSOLU ~/.zen (le flake pose MOZ_LEGACY_PROFILES=1,
      # donc la racine des profils est ~/.config/zen). L'ancien profile auto
      # (aohbx0bt…) reste intact sur le disque.
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

      # Migration one-shot : ancien profil automatique (hash) -> ~/.zen.
      # Copie signets/historique/prefs; exclut le CSS de mods périmé et les
      # artefacts d'exécution (lock, cache, crashreports).
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