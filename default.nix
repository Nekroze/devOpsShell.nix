{ pkgs }:
# A special kind of derivation that is only meant to be consumed by the nix-shell.
{
  shellHook ? "", # arbitrary extra shell hook code
  packages ? [], # these packages will be made available in the shell
  scripts ? {}, # string pairs of script names and their contents to be available in the shell
  environment ? {}, # string pairs of env variable names and their contents to be available in the shell
  subcommander ? false, # Enable https://github.com/Nekroze/subcommander
  subcommanderAlias ? "just", # Give subcommander an easy alias
  subcommanderPath ? "$NIX_SHELL_ROOT/.just/", # Default path to the subcommands directory
  ...
}:

with pkgs;
with lib;

let
  subcommanderSrc = fetchFromGitHub {
    owner = "Nekroze";
    repo = "subcommander";
    rev = "17a56fb71119833e92bb6a1219bd49a1478f51f6";
    sha256 = "03mwcp67bl7z6zibgz14z7qr8xwmlfcpk1a8xfskf4jbrqqgv9ks";
  };
  subcommanderPkg = callPackage subcommanderSrc {};

  envVars = {
    NIX_SHELL_ROOT = "$PWD";
    PS1 = ''\[\e[0;32m\]\u\[\e[0;35m\]@\[\e[0;36m\]devOpsShell.\[\e[0;36m\]\h\[\e[0;35m\]:\[\e[0;33m\]\W \[\e[0;35m\]$ \[\e[0m\]'';
  } // (if subcommander then {
    APPLICATION = subcommanderAlias;
    SUBCOMMANDS = subcommanderPath;
  } else {}) // environment;

  extraScripts = if subcommander then {
    "${subcommanderAlias}" = ''
    exec subcommander "$@"
    '';
  } else {};
  allScripts = extraScripts // scripts;

in mkShell {
  name = "devops-shell";

  buildInputs = packages
  ++ attrValues (mapAttrs writeShellScriptBin allScripts)
  ++ optional subcommander subcommanderPkg;

  shellHook =  ''
    ${concatStringsSep "\n" (attrValues (mapAttrs (n: v: ''export ${n}="${v}"'') envVars))}
    ${shellHook}
  '';
}
