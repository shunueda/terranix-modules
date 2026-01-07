{ lib, suite, ... }:
suite {
  label = "base";
  tests = [
    {
      label = "foo";
      options = {
        name = lib.mkOption { type = lib.types.str; };
      };
      config = {
        name = "foo";
      };
    }
    {
      label = "bar";
      options = {
        name = lib.mkOption { type = lib.types.str; };
      };
      config = {
        name = 0;
      };
      success = false;
    }
    {
      label = "baz";
      options = {
        name = lib.mkOption { type = lib.types.str; };
        fullname = lib.mkOption { type = lib.types.str; };
      };
      config = config: {
        name = "baz";
        fullname = config.name;
      };
    }
  ];
}
