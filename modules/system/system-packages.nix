{ config, pkgs, ... }:

{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget

  vscodium
  nixd
  nixpkgs-fmt
  just
  opencode-desktop
  protonup-qt
  (symlinkJoin {
    name = "modrinth-app";
    paths = [ modrinth-app ];
    nativeBuildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/ModrinthApp \
        --set WEBKIT_DISABLE_DMABUF_RENDERER 1
    '';
  })
  temurin-jre-bin-21  # Minecraft
  temurin-jre-bin-25  # Minecraft
  git
  curl
  unzip
  cabextract
  p7zip
  file
  steamtinkerlaunch
  btop
  claude-code
  sbctl
  ];
}
