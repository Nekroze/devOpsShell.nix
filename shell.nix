let
  # Look here for information about how to generate `nixpkgs-version.json`.
  #  → https://nixos.wiki/wiki/FAQ/Pinning_Nixpkgs
  pinnedChannel = "nixpkgs-unstable";
  pinnedVersion = builtins.fromJSON (builtins.readFile ./.nixpkgs-version.json);
  pinnedPkgs = import (builtins.fetchGit {
    inherit (pinnedVersion) url rev;

    ref = pinnedChannel;
  }) {};
in

# This allows overriding pkgs by passing `--arg pkgs ...`
{ pkgs ? pinnedPkgs }:

with pkgs;

let
  devOpsShell = import ./default.nix {inherit pkgs;};
in devOpsShell {

  packages = [
    nix-prefetch-git
  ];

  subcommander = true;

  environment.TEST = "foo";

  scripts.updateNixpkgs = ''
    nix-prefetch-git https://github.com/nixos/nixpkgs-channels.git refs/heads/${pinnedChannel} \
      > "$(git rev-parse --show-toplevel)/.nixpkgs-version.json"
  '';
}
