{
  lib,
  suite,
  terranix-modules,
  ...
}:
suite "type" {
  tests = {
    "bool" = {
      options = {
        value = lib.mkOption { type = terranix-modules.lib.internal.parseType "bool"; };
      };
      config = {
        value = true;
      };
    };
    "string" = {
      options = {
        value = lib.mkOption { type = terranix-modules.lib.internal.parseType "string"; };
      };
      config = {
        value = "";
      };
    };
    "number" = {
      options = {
        value = lib.mkOption { type = terranix-modules.lib.internal.parseType "number"; };
      };
      config = {
        value = 0;
      };
    };
    "list bool" = {
      options = {
        value = lib.mkOption {
          type = terranix-modules.lib.internal.parseType [
            "list"
            "bool"
          ];
        };
      };
      config = {
        value = [ true ];
      };
    };
    "map bool" = {
      options = {
        value = lib.mkOption {
          type = terranix-modules.lib.internal.parseType [
            "map"
            "bool"
          ];
        };
      };
      config = {
        value = {
          foo = true;
          bar = false;
        };
      };
    };
  };
}
