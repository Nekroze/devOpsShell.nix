{ pkgs }:
# A special kind of derivation that is only meant to be consumed by the nix-shell.
mainModule:

with pkgs;
with lib;

let
  evaluated = lib.evalModules {
    modules = [
      {
        _module.args.pkgs = pkgs;
        _module.args.lib = lib;
      }
      ./options.nix
      ./modules/mkShell.nix
      mainModule
    ];
  };
in mkShell evaluated.config._mkShell
