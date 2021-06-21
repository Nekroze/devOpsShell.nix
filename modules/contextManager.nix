{ pkgs, lib, config, ... }:

with pkgs;
with lib;

{

  options = let
    cmOptions = { name, ... }: {
      setUp = mkOption {
        type = types.nullOr types.str;
        description = "Shell code to execute when entering this context manager.";
      };

      tearDown = mkOption {
        type = types.nullOr types.str;
        description = "Shell code to execute when exiting this context manager.";
      };
    };
  in {

    contextManagers = mkOption {
      default = {};
      type = types.attrsOf (types.submodule cmOptions);
      example = literalExample ''
        {
          dockerRegistry.setUp = "docker login registry.gitlab.com";
        };
      '';
      description = ''
        Attribute set of context managers that can be strung together to automatically configure ephemeral environments.
      '';
    };

  };

  config = let
    cfg = config.contextManagers;
  in {
  };
}
