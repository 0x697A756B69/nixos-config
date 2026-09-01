# Rebuild and switch immediately.
rebuild:
    sudo nixos-rebuild switch --flake .#nixos

# Apply now without adding a boot menu entry; reverts on next reboot.
test:
    sudo nixos-rebuild test --flake .#nixos

# Apply on next boot only; current session stays untouched.
boot:
    sudo nixos-rebuild boot --flake .#nixos

# Evaluate and build without touching the running system or /etc.
check:
    nixos-rebuild dry-build --flake .#nixos

# Bump every flake input to its latest allowed revision.
update:
    nix flake update

# Bump a single flake input, e.g. `just update-input nixpkgs`.
update-input name:
    nix flake lock --update-input {{name}}

# Format every .nix file in the repo.
fmt:
    find . -name '*.nix' -not -path './.git/*' -exec nixpkgs-fmt {} +

# Remove old generations and unreachable store paths.
gc:
    sudo nix-collect-garbage -d
