{ pkgs, lib, config, ... }:

with pkgs;
with lib;

{
  options = {

    subcommander = {
      enable = mkEnableOption ''
        Dispatcher for executing scripts as a tree of subcommands represented
        by directories and files.
      '';

      alias = mkOption {
        type = types.str;
        default = "just";
        description = ''
          Instead of using the `subcommander` command, this command will wrap
          it for easier use.
        '';
      };

      path = mkOption {
        type = types.str;
        default = "$NIX_SHELL_ROOT/.${config.subcommander.alias}/";
        description = ''
          Root directory of the subcommand tree. Each executable file is a
          subcommand, each directory a namespace for more files.
        '';
      };
    };

    scripts = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = ''
        Each key will be made a command available within the shell executing
        the attached string with bash.
      '';
    };

    packages = mkOption {
      type = types.listOf types.path;
      default = [];
      description = "List of packages to install in the shell.";
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Environment variable name value pairs.";
    };

  };

  config = {

    environment = mkMerge [
      (mkIf config.subcommander.enable {
        APPLICATION = config.subcommander.alias;
        SUBCOMMANDS = config.subcommander.path;
      })
      {
        NIX_SHELL_ROOT = "$PWD";
        PS1 = ''\[\e[0;32m\]\u\[\e[0;35m\]@\[\e[0;36m\]devOpsShell.\[\e[0;36m\]\h\[\e[0;35m\]:\[\e[0;33m\]\W \[\e[0;35m\]$ \[\e[0m\]'';
      }
    ];

    scripts = mkIf config.subcommander.enable {
      "${config.subcommander.alias}" = ''exec subcommander "$@"'';
    };

  };
}
