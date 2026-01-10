{ lib, ... }:
let
  # https://developer.hashicorp.com/terraform/cli/commands/providers/schema#providers-schema-representation
  internal = rec {
    parseType =
      tfType:
      if (builtins.typeOf tfType == "string") then
        {
          bool = lib.types.bool;
          string = lib.types.str;
          number = lib.types.number;
        }
        .${tfType}
      else
        let
          aggregate = builtins.head tfType;
          elementType = parseType (builtins.elemAt tfType 1);
        in
        {
          list = lib.types.listOf;
          set = lib.types.listOf;
          map = lib.types.attrsOf;
        }
        .${aggregate}
          elementType;

    parseAttributes =
      attributes:
      builtins.mapAttrs
        (
          name:
          {
            type,
            optional ? false,
            computed ? false,
            description ? null,
            deprecated ? false,
          }:
          lib.mkOption (
            {
              type =
                let
                  parsed = parseType type;
                in
                if optional || computed then lib.types.nullOr parsed else parsed;
              inherit description;
            }
            // lib.optionalAttrs (optional || computed) { default = null; }
            // lib.optionalAttrs deprecated { deprecationMessage = "warning: ${name} is deprecated"; }
          )
        )
        (
          builtins.filterAttrs (
            name:
            {
              computed ? false,
              optional ? false,
            }:
            !(computed && !optional) # computed && non-optional is read-only
          ) attributes
        );

    parseBlock =
      name:
      {
        attributes ? { },
        block_types ? { },
        description ? null,
        deprecated ? false,
      }:
      let
        blockType = parseSchema { inherit attributes block_types; };
      in
      lib.mkOption (
        {
          type = blockType;
          inherit description;
        }
        // lib.optionalAttrs deprecated { deprecationMessage = "warning: ${name} is deprecated"; }
      );

    parseBlockTypes =
      blockTypes:
      builtins.mapAttrs (
        name:
        {
          nesting_mode,
          block,
          min_items ? 0,
          max_items ? null,
        }:
        let
          blockType = parseBlock name block;
          baseType = blockType.type;
        in
        lib.mkOption (
          {
            type =
              {
                list = lib.types.listOf;
                set = lib.types.listOf;
                single = lib.types.nullOr;
                map = lib.types.attrsOf;
              }
              .${nesting_mode}
                baseType;
            description = blockType.description or null;
          }
          // lib.optionalAttrs (blockType ? deprecationMessage) { inherit (blockType) deprecationMessage; }
        )
      ) blockTypes;

    parseSchema =
      {
        attributes ? { },
        block_types ? { },
      }:
      lib.types.submodule {
        options = (internal.parseAttributes attributes) // (internal.parseBlockTypes block_types);
      };
  };
in
{
  flake.lib = {
    inherit internal;
    mkTerranixModule =
      name: schema:
      let
        fqn = builtins.head (builtins.attrNames schema.provider_schemas);
        providerSchema = schema.provider_schemas.${fqn};
        provider = lib.mkOption {
          type = lib.types.submodule {
            options = {
              ${name} = lib.mkOption { type = internal.parseSchema providerSchema.provider.block; };
            };
          };
        };
        resource = lib.mkOption {
          type = lib.types.submodule {
            options = {
              ${name} = lib.mkOption { type = internal.parseSchema providerSchema.resource_schemas.block; };
            };
          };
        };

        data = lib.mkOption {
          type = lib.types.submodule {
            options = {
              ${name} = lib.mkOption { type = internal.parseSchema providerSchema.data_source_schemas.block; };
            };
          };
        };
      in
      {
        inherit provider resource data;
      };
  };
}
