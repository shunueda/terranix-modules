{ lib, suite, ... }:
suite {
  label = "base";
  tests = [
    {
      label = "simple";
      options = {
        name = lib.mkOption { type = lib.types.str; };
      };
      config = {
        name = "foo";
      };
    }
    {
      label = "expect to fail";
      options = {
        name = lib.mkOption { type = lib.types.str; };
      };
      config = {
        name = 0;
      };
      success = false;
    }
    {
      label = "self-referencing config";
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
