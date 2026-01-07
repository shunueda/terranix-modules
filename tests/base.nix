{ lib, suite, ... }:
suite "base" {
  tests = {
    "simple" = {
      options = {
        name = lib.mkOption { type = lib.types.str; };
      };
      config = {
        name = "foo";
      };
    };

    "expect to fail" = {
      options = {
        name = lib.mkOption { type = lib.types.str; };
      };
      config = {
        name = 0;
      };
      expected = false;
    };

    "self-referencing config" = {
      options = {
        name = lib.mkOption { type = lib.types.str; };
        fullname = lib.mkOption { type = lib.types.str; };
      };
      config = config: {
        name = "baz";
        fullname = config.name;
      };
    };
  };
}
