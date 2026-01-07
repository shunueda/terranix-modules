{ inputs, flake-parts-lib, ... }:
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    {
      pkgs,
      lib,
      system,
      ...
    }:
    {
      options.scope = lib.mkOption { type = lib.types.raw; };
      config =
        let
          scope = lib.makeScope pkgs.newScope (scopeSelf: {
            inherit (pkgs) terraform;
            suite =
              label:
              { tests }:
              let
                failures = lib.runTests (
                  lib.mapAttrs' (
                    name: test:
                    # lib.runTests wants all names to be prefixed with "test", but I don't.
                    lib.nameValuePair "test${name}" {
                      inherit (test) expected;
                      expr =
                        let
                          # Note that this is not yet fully evaluated - Nix is lazy!
                          evaluated = lib.evalModules {
                            modules = [
                              { inherit (test) options; }
                              (
                                if lib.isFunction test.config then
                                  { config, ... }:
                                  {
                                    config = test.config config;
                                  }
                                else
                                  { inherit (test) config; }
                              )
                            ];
                          };
                        in
                        # Now we force full evaluation.
                        (builtins.tryEval (builtins.deepSeq evaluated.config true)).success;
                    }
                  ) tests
                );
              in
              # This feels wrong? I don't know Nix enough and don't know other pattern other than
              # making it a derivation and putting it in as a build time check, but should be able
              # to test on eval time.
              pkgs.runCommandLocal "test-suite-${label}" { } (
                builtins.deepSeq (lib.debug.throwTestFailures { inherit failures; }) ''
                  touch $out
                ''
              );
          });
          availableOnSystem = lib.meta.availableOn { inherit system; };
        in
        {
          inherit scope;
          checks =
            lib.concatMapAttrs (k: v: lib.optionalAttrs (availableOnSystem v) { "build-${k}" = v; }) (
              lib.filterAttrs (_: lib.isDerivation) scope
            )
            // lib.packagesFromDirectoryRecursive {
              inherit (scope) callPackage;
              directory = ../tests;
            };
        };
    }
  );
}
