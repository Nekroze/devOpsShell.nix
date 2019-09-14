{ pkgs, lib, config, ... }:

with pkgs;
with lib;

{

  options = {

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
    _mkShell = {
      buildInputs = config.packages
      ++ optional config.subcommander.enable subcommanderPkg
      ++ attrValues (mapAttrs writeShellScriptBin config.scripts);

      shellHook = ''
        ${concatStringsSep "\n" (attrValues (mapAttrs (n: v: ''export ${n}="${v}"'') config.environment))}
      '';
    };
  };
}
