{
  description = "NixOS + End-4 illogical-impulse (Hyprland Dotfiles Session)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Same QuickShell commit End-4 pins in its Arch package (illogical-impulse-quickshell-git)
    quickshell = {
      url = "github:quickshell-mirror/quickshell/4f508be500dea6e5732cc3d50382a0048b17e7b1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... } @ inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        ./end4.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-backup";
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.musabase = import ./end4-home.nix;
        }
      ];
    };
  };
}
