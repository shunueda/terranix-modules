{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    terranix = {
      url = "github:terranix/terranix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.systems.follows = "systems";
    };
    systems.url = "github:nix-systems/default";
  };
  outputs =
    {
      nixpkgs,
      flake-parts,
      treefmt-nix,
      devshell,
      systems,
      ...
    }@inputs:
    let
      flakeAllSystems = {
        perSystem =
          { system, ... }:
          {
            _module.args = {
              pkgs = import nixpkgs {
                inherit system;
                config.allowUnfree = true;
              };
            };
          };
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import systems;
      imports = [
        ./nix/devshells.nix
        ./nix/treefmt.nix
        ./nix/scope.nix
        ./nix/lib.nix
        devshell.flakeModule
        treefmt-nix.flakeModule
        flakeAllSystems
      ];
    };
}
