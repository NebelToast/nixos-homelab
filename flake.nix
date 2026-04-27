{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
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

      formatter.${system} = pkgs.nixfmt-tree;

      checks.${system} = {
        statix = pkgs.runCommand "statix" { buildInputs = [ pkgs.statix ]; } ''
          statix check ${self}
          touch $out
        '';

        deadnix = pkgs.runCommand "deadnix" { buildInputs = [ pkgs.deadnix ]; } ''
          deadnix --fail ${self}
          touch $out
        '';
      };
    };

}
