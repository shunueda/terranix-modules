{ flake-parts-lib, ... }:
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { config, ... }:
    let
      inherit (config) scope;
    in
    {
      devshells.default = {
        packages = with scope; [ terraform ];
      };
    }
  );
}
