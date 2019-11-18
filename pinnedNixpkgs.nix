{ channel ? "nixpkgs-unstable", versionFile }:

rec {
  version = builtins.fromJSON (builtins.readFile versionFile);

  src = builtins.fetchGit {
    inherit (version) url rev;

    ref = channel;
  };

  pkgs = import src {};

  updateScript = ''
    ${pkgs.nix-prefetch-git}/bin/nix-prefetch-git \
      https://github.com/nixos/nixpkgs-channels.git refs/heads/${channel} \
      > "${toString versionFile}"
  '';
}
