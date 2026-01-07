{
  terranix-modules,
  lib,
  suite,
  ...
}:
let
  options = terranix-modules.lib.mkTerranixModule "myprovider" {
    "format_version" = "1.0";
    "provider_schemas" = {
      "registry.terraform.io/mycorp/myprovider" = {
        "provider" = {
          "version" = 0;
          "block" = {
            "attributes" = {
              "base_url" = {
                "type" = "string";
              };
            };
          };
        };
      };
    };
  };
in
suite "provider" {
  tests = {
    "basic" = {
      inherit options;
      config = {
        provider = {
          myprovider = {
            base_url = "https://example.test";
          };
        };
      };
    };

    "no extra" = {
      inherit options;
      config = {
        provider = {
          myprovider = {
            base_url = "https://example.test";
            extra = "foo";
          };
        };
      };
      expected = false;
    };

    "no missing" = {
      inherit options;
      config = {
        provider = {
          myprovider = { };
        };
      };
      expected = false;
    };

    "type check" = {
      inherit options;
      config = {
        provider = {
          myprovider = {
            base_url = 0;
          };
        };
      };
      expected = false;
    };
  };
}
