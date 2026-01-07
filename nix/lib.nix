{ lib, ... }:
{
  flake = {
    lib = {
      foo = {
        name = lib.mkOption { type = lib.types.str; };
      };
    };
  };
}
