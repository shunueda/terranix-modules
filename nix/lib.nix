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
          # TODO: tuple, object
          list = lib.types.listOf;
          # TODO: set != list but no good way of representing in nixos module system. Custom type?
          set = lib.types.listOf;
          map = lib.types.attrsOf;
        }
        .${aggregate}
          elementType;

    parseAttribute =
      name:
      {
        type,
        required ? false,
        optional ? false,
        computed ? false,
        description ? null,
        sensitive ? false,
      }:
      assert lib.assertMsg (!(required && optional)) "Attribute cannot be both required and optional.";
      assert lib.assertMsg (!(required && computed)) "Attribute cannot be both required and computed.";
      let
        parsedType = parseType type;

        optionType =
          if computed && !optional then
            lib.types.enum [ null ]
          else if optional || computed then
            lib.types.nullOr parsedType
          else
            parsedType;

        hasDefault = optional || computed;
      in
      lib.mkOption (
        {
          type = optionType;
          inherit description;
        }
        // lib.optionalAttrs hasDefault { default = null; }
      );

    parseBlockType =
      name:
      {
        nesting_mode,
        block,
        min_items ? null,
        # TODO: nixos module system can't represent this.
        max_items ? null,
      }:
      let
        blockType = parseBlock block;
        isRequiredSingle = nesting_mode == "single" && min_items == 1;
      in
      lib.mkOption {
        type =
          {
            list = lib.types.listOf;
            set = lib.types.listOf;
            map = lib.types.attrsOf;
            single = if isRequiredSingle then blockType else lib.types.nullOr blockType;
          }
          .${nesting_mode}
            blockType;
      };

    parseBlock =
      {
        attributes ? { },
        block_types ? { },
      }:
      lib.types.submodule {
        options =
          (builtins.mapAttrs internal.parseAttribute attributes)
          // (builtins.mapAttrs internal.parseBlockType block_types);
      };

    parseSchema =
      { version, block }:
      assert lib.assertMsg (version == 0) "schema version must be 0";
      lib.mkOption { type = parseBlock block; };

    parseProviderSchema =
      fqn:
      {
        provider ? { },
        resource_schemas ? { },
        data_source_schemas ? { },
      }:
      {
        provider = internal.parseSchema (provider);
        resource = lib.mkOption {
          type = lib.types.submodule {
            options = builtins.mapAttrs (_: value: internal.parseSchema value) (resource_schemas);
          };
        };
        data = lib.mkOption {
          type = lib.types.submodule {
            options = builtins.mapAttrs (_: value: internal.parseSchema value) data_source_schemas;
          };
        };
        # TODO: ephemeral, function
      };
  };
in
{
  flake.lib = {
    inherit internal;

    mkTerranixModule =
      name:
      { format_version, provider_schemas }:
      assert lib.assertMsg (format_version == "1.0") "format_version must be 1.0";
      let
        fqn = builtins.head (builtins.attrNames provider_schemas);
      in
      (builtins.mapAttrs internal.parseProviderSchema provider_schemas).${fqn};
  };
}
