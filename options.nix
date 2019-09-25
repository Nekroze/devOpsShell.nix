{ pkgs, lib, config, ... }:

with pkgs;
with lib;

{
  options = {

    subcommander = {
      enable = mkEnableOption ''
        dispatcher for executing scripts as a tree of subcommands represented
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

    variableSetDefault = mkOption {
      type = types.str;
      default = "dev";
      description = ''
        Which variable set should be activated initially.
      '';
    };

    verbose = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Call out actions and variable changes where possible.
      '';
    };

    exportNixPath = mkEnableOption "setting $NIX_PATH to the pinned nixpkgs version";
    workingDirNixPath = mkEnableOption "adding the current working directory to $NIX_PATH, useful for NixOps";

  };

  config = {

    variables = mkMerge [
      (mkIf config.subcommander.enable {
        APPLICATION = config.subcommander.alias;
        SUBCOMMANDS = config.subcommander.path;
      })
      {
        NIX_SHELL_ROOT = "$PWD";
        PS1 = ''\[\e[0;32m\]''${variableSet:-\u}\[\e[0;35m\]@\[\e[0;36m\]devOpsShell.\[\e[0;36m\]\h\[\e[0;35m\]:\[\e[0;33m\]\W \[\e[0;35m\]$ \[\e[0m\]'';
      }
    ];

    scripts = mkMerge [

      (mkIf config.subcommander.enable {
        "${config.subcommander.alias}" = ''exec subcommander "$@"'';
      })

      {
        # This version of switch to is a shim for shells that do not get
        # functions from the shellHook.
        switchTo = ''
          case "$1" in
          ${optionalString (config.variableSets != {}) ''
          ${concatStringsSep "|" (attrNames config.variableSets)})
            cd $NIX_SHELL_ROOT
            switches=
            [ -z "$IN_NIX_SHELL" ] || switches=--pure
            exec env DEVOPSSHELL_SWITCHTO="$1" nix-shell --keep DEVOPSSHELL_SWITCHTO $switches
            ;;
          ''}
          *)
            echo "Please give one of the following variable sets as an argument to switch to it:"
            ${concatMapStringsSep "\n" (n: "echo ${n}") (attrNames config.variableSets)}
            ;;
          esac
        '';
      }

    ];

    _mkShell.shellHook = let
      kvToExport = name: value: ''
        echo '${name}=${value}'
        ${name}="${value}"
      '';
      setToExports = set: concatStringsSep "\n" (attrValues (mapAttrs kvToExport set)) + ''
        export ${concatStringsSep " " (attrNames set)}
      '';
      shoutCmd = "${pkgs.toilet}/bin/toilet --termwidth --font future";
    in ''
      ${optionalString config.exportNixPath "export NIX_PATH=${pkgs.path}:nixpkgs=${pkgs.path}"}
      ${optionalString config.workingDirNixPath "export NIX_PATH=$NIX_PATH:$NIX_SHELL_ROOT"}

      switchTo() {
        case "''${1:-${config.variableSetDefault}}" in
        ${concatMapStringsSep "\n" (n: ''
        ${n})
          # TODO: Remove janky use of GPG_TTY to detect direnv auto entering nix-shell
          if [ -z "$GPG_TTY" ]; then
            echo "
              ${shoutCmd} 'Activating variableSet: $1';
            "
          else
            ${shoutCmd} "Activating variableSet: $1"
          fi
          export variableSet="${n}"
          ${setToExports config.variableSets."${n}"}
          export PS1="${config.variables.PS1}"
          ;;
        '') (attrNames config.variableSets)}
        *)
          true
          ;;
        esac
      }

      if [ -n "$DEVOPSSHELL_SWITCHTO" ]; then
          switchTo "$DEVOPSSHELL_SWITCHTO"
      else
          switchTo ${config.variableSetDefault}
      fi
    '';


  };
}
