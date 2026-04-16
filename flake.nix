{
  inputs.sops-nix.url = "github:Mic92/sops-nix";
  inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.vps = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs self;
        };
        modules = [
          ./configuration.nix
          ./tailscale.nix
          ./planka.nix
          ./tasktrove.nix
          ./glance.nix
          ./yapblog.nix
          ./disko.nix
          ./hardware-configuration.nix
          ./sops.nix
          inputs.disko.nixosModules.disko
        ];
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-tree;
    };

}
