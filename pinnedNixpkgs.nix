{ channel ? "nixpkgs-unstable", versionFile }:

let
  version = builtins.fromJSON (builtins.readFile versionFile);
in rec {
  pkgs = import (builtins.fetchGit {
    inherit (version) url rev;

    ref = channel;
  }) {};

  updateScript = ''
    ${pkgs.nix-prefetch-git}/bin/nix-prefetch-git \
      https://github.com/nixos/nixpkgs-channels.git refs/heads/${channel} \
      > "${toString versionFile}"
  '';
}
