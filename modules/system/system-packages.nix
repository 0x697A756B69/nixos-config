{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
  vscodium
  nixd
  nixpkgs-fmt
  just
  opencode-desktop
  git
  curl
  unzip
  cabextract
  p7zip
  file
  btop
  claude-code
  sbctl
  cudaPackages.cudatoolkit
  nvtopPackages.full
  ];
}
