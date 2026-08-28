{
  description = "Configuration Flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Spicetify-nix
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, spicetify-nix, ... }@inputs: {

    # Define the system configuration. "nixos" must match networking.hostName
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      # Pass inputs down to configuration.nix so it can use spicetify-nix
      specialArgs = { inherit inputs; };

      # List of modules to build the system from
      modules = [
        ./configuration.nix

        # Enable the spicetify NixOS module.
        spicetify-nix.nixosModules.spicetify
      ];
    };
  };
}