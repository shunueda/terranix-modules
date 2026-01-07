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
              { label, tests }:
              let
                report = map (
                  test:
                  let
                    # Note that this is not yet fully evaluated - Nix is lazy evaluated!
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
                    # Now we force full evaluation with deepSeq.
                    result = builtins.tryEval (builtins.deepSeq evaluated.config true);
                  in
                  {
                    inherit (test) label;
                    success = result.success == (test.success or true);
                  }
                ) tests;
              in
              pkgs.runCommandLocal "test-suite-${label}" { } ''
                ${lib.concatMapStringsSep "\n" (
                  { success, label }: "echo ${if success then "✓" else "✗"} ${label}"
                ) report}
                ${if builtins.elem false (map ({ success, ... }: success) report) then "exit 1" else ""}
                touch $out
              '';
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
