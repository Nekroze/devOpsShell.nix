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

    _mkShell = {
      name = mkOption {
        type = types.str;
        default = "devOpsShell";
        description = "Name of the nix shell derivation.";
      };

      buildInputs = mkOption {
        type = types.listOf types.path;
        default = [];
        description = "List of packages to install in the shell.";
      };

      shellHook = mkOption {
        type = types.lines;
        default = "";
        description = "Bash shell code ran on entry to the shell.";
      };
    };

  };

  config = let

    subcommanderPkg = callPackage (fetchFromGitHub {
      owner = "Nekroze";
      repo = "subcommander";
      rev = "17a56fb71119833e92bb6a1219bd49a1478f51f6";
      sha256 = "03mwcp67bl7z6zibgz14z7qr8xwmlfcpk1a8xfskf4jbrqqgv9ks";
    }) {};

  in {
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

    _mkShell.buildInputs = config.packages
    ++ optional config.subcommander.enable subcommanderPkg
    ++ attrValues (mapAttrs writeShellScriptBin config.scripts);

    _mkShell.shellHook = ''
      ${concatStringsSep "\n" (attrValues (mapAttrs (n: v: ''export ${n}="${v}"'') config.environment))}
    '';
  };
}
