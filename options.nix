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

    variables = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Environment variable name value pairs.";
    };

    variableSets = mkOption {
      type = types.attrsOf (types.attrsOf types.str);
      default = {};
      description = ''
        You can activate a variable set's environment variables using the
        `switchTo <SET_NAME>` command.
      '';
    };

  };

  config = {

    variables = mkMerge [
      (mkIf config.subcommander.enable {
        APPLICATION = config.subcommander.alias;
        SUBCOMMANDS = config.subcommander.path;
      })
      {
        NIX_SHELL_ROOT = "$PWD";
        PS1 = ''\[\e[0;32m\]\u\[\e[0;35m\]@\[\e[0;36m\]devOpsShell.\[\e[0;36m\]\h\[\e[0;35m\]:\[\e[0;33m\]\W \[\e[0;35m\]$ \[\e[0m\]'';
      }
    ];

    scripts = mkMerge [

      (mkIf config.subcommander.enable {
        "${config.subcommander.alias}" = ''exec subcommander "$@"'';
      })

      {
        "switchTo" = let
          setToExports = set: concatStringsSep "\n" (attrValues (mapAttrs (n: v: ''${n}="${v}"'') set)) + "\nexport ${concatStringsSep " " (attrNames set)}";
        in ''
          set -e
          case "$1" in
          ${concatMapStringsSep "\n" (n: ''
          ${n})
            export variableSet="${n}"
            ${setToExports config.variableSets."${n}"}
            exec "$SHELL"
            ;;
          '') (attrNames config.variableSets)}
          *)
            echo "Please give one of the following variable sets as an argument to switch to it:"
            ${concatMapStringsSep "\n" (n: "echo ${n}") (attrNames config.variableSets)}
            ;;
          esac
        '';
      }

    ];

  };
}
