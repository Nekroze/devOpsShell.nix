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

    shellcheck = {
      enable = mkEnableOption "checking all `scripts` with shellcheck for safety.";

      package = mkOption {
        type = types.path;
        default = pkgs.shellcheck;
        description = "The shellcheck package to use when checking `scripts`.";
      };

      switches = mkOption {
        type = types.listOf types.str;
        default = ["--exclude" "SC1008" "--external-sources" "--color"];
        description = "Options or flags to pass to shellcheck before the file name to check.";
      };
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
      type = types.nullOr types.str;
      default = null;
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

    certificateBundle = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      description = ''
        If not null this path will be set as the value for various environment
        variables defined in certificateBundleVariables to enable HTTPS.
      '';
    };

    certificateBundleVariables = mkOption {
      type = types.listOf types.str;
      default = ["CURL_CA_BUNDLE" "GIT_SSL_CAINFO" "NIX_SSL_CERT_FILE" "SSL_CERT_FILE"];
      description = ''
        When certificateBundle is not null, these environment variables will be set to its value.
      '';
    };

    exportNixPath = mkEnableOption "setting $NIX_PATH to the pinned nixpkgs version";
    workingDirNixPath = mkEnableOption "adding the current working directory to $NIX_PATH, useful for NixOps";
  };

  config = let
    mkCertBundleVar = v: {
      name  = v;
      value = config.certificateBundle;
    };
    mkCertBundleVars = names: builtins.listToAttrs (map mkCertBundleVar names);
  in {

    variables = mkMerge [
      (mkIf config.subcommander.enable {
        APPLICATION = config.subcommander.alias;
        SUBCOMMANDS = config.subcommander.path;
      })
      (mkIf (config.certificateBundle != null)
        (mkCertBundleVars config.certificateBundleVariables)
      )
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
            cd "$NIX_SHELL_ROOT" || exit 1
            exec env DEVOPSSHELL_SWITCHTO="$1" nix-shell --keep DEVOPSSHELL_SWITCHTO
            ;;
          ''}
          *)
            echo "Please give one of the following variable sets as an argument to switch to it:"
            ${concatMapStringsSep "\n" (n: "echo ${n}") (attrNames config.variableSets)}
            exit 1
            ;;
          esac
        '';
      }

    ];

    _mkShell.shellHook = let
      kvToExport = name: value: ''
        echo '${name}="${value}"'
        ${name}="${value}"
      '';
      setToExports = set: concatStringsSep "\n" (attrValues (mapAttrs kvToExport set)) + ''
        export ${concatStringsSep " " (attrNames set)}
      '';
      shoutCmd = "${pkgs.toilet}/bin/toilet --termwidth --font future";
    in ''
      ${optionalString config.exportNixPath "export NIX_PATH=${pkgs.path}:nixpkgs=${pkgs.path}"}
      ${optionalString config.workingDirNixPath "export NIX_PATH=$NIX_PATH:$PWD"}

      ${optionalString (config.variableSetDefault != null && config.variableSets != {}) ''
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
          echo "variableSet: $1 is not defined!" 1>&2
          ;;
        esac
      }

      if [ -n "$DEVOPSSHELL_SWITCHTO" ]; then
          switchTo "$DEVOPSSHELL_SWITCHTO"
      else
          switchTo ${config.variableSetDefault}
      fi
      ''}

      help() {
        echo 'The following scripts have been exposed in this shell:' 1>&2
        echo ${concatStringsSep " " (attrNames config.scripts)} | column -c 100 1>&2
      }
      help
    '';

  };
}
