{ flake-parts-lib, ... }:
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { pkgs, ... }:
    {
      devshells.default = {
        packages = with pkgs; [ terraform ];
      };
    }
  );
}
