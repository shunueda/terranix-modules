{ flake-parts-lib, self, ... }:
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
          });
          availableOnSystem = lib.meta.availableOn { inherit system; };
        in
        {
          inherit scope;
          checks = lib.concatMapAttrs (k: v: lib.optionalAttrs (availableOnSystem v) { "build-${k}" = v; }) (
            lib.filterAttrs (_: lib.isDerivation) scope
          );
        };
    }
  );
}
