{ config, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  programs.firefox.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    glib
    cudaPackages.cudatoolkit
  ];

  # pip/uv-installed CUDA wheels (PyTorch, TensorFlow, ...) link against the
  # driver's libcuda.so at runtime, not a Nix-built one -- NixOS already
  # publishes it under /run/opengl-driver/lib (hardware.graphics.enable),
  # this just makes non-Nix binaries able to find it too.
  environment.variables.LD_LIBRARY_PATH = [ "/run/opengl-driver/lib" ];
}
