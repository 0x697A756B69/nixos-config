{ config, pkgs, inputs, ... }:

{
  # Install Spicetify.
  programs.spicetify =
    let spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
    in {
      enable = true;
      enabledExtensions = with spicePkgs.extensions; [
        adblockify
        hidePodcasts
        shuffle
      ];
      enabledCustomApps = with spicePkgs.apps; [
        marketplace
      ];
      theme = spicePkgs.themes.catppuccin;
      colorScheme = "mocha";
    };
}
