{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
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
    nix-unit = {
      url = "github:nix-community/nix-unit";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    systems.url = "github:nix-systems/default";
  };
  outputs =
    {
      nixpkgs,
      flake-parts,
      treefmt-nix,
      nix-unit,
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
            nix-unit = { inherit inputs; };
          };
        flake = {
          tests = {
            test1 = {
              expr = builtins.tryEval (throw "I give up");
              expected = {
                success = false;
              };
            };
          };
        };
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import systems;
      imports = [
        ./nix/treefmt.nix
        ./nix/scope.nix
        ./nix/lib.nix
        treefmt-nix.flakeModule
        nix-unit.modules.flake.default
        flakeAllSystems
      ];
    };
}
