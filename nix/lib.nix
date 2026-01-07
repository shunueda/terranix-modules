{ lib, ... }:
let
  typemap = {
    string = lib.types.str;
    number = lib.types.int;
    bool = lib.types.bool;
  };
in
{
  flake.lib.mkTerranixModule =
    name: schema:
    let
      parseAttributes =
        attributes:
        lib.types.submodule {
          options = builtins.mapAttrs (k: v: lib.mkOption { type = typemap.${v.type}; }) attributes;
        };
      fqn = builtins.head (builtins.attrNames schema.provider_schemas);
      provider =
        let
          providerSchema = schema.provider_schemas.${fqn};
        in
        lib.mkOption {
          type = lib.types.submodule {
            options = {
              ${name} = lib.mkOption { type = parseAttributes providerSchema.provider.block.attributes; };
            };
          };
        };
    in
    {
      inherit provider;
    };
}
