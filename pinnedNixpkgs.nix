{ channel ? "nixpkgs-unstable", versionFile, nixpkgsRepo ? "https://github.com/nixos/nixpkgs" }:

rec {
  version = builtins.fromJSON (builtins.readFile versionFile);

  src = builtins.fetchTarball {
    inherit (version) url sha256;
    name = channel;
  };

  pkgs = import src {};

  updateScript = ''
    rev=$1
    if [ -z "$rev" ]; then
      rev=$(${pkgs.nix-prefetch-git}/bin/nix-prefetch-git \
        'https://github.com/nixos/nixpkgs.git' 'refs/heads/${channel}' \
        | ${pkgs.jq}/bin/jq -r '.rev' \
        | tr -d '[:space:]')
    fi
    url=${nixpkgsRepo}/archive/$rev.tar.gz
    sha=$(${pkgs.nix}/bin/nix-prefetch-url --unpack \
      "$url" \
      | tr -d '[:space:]')
    echo "{\"url\":\"$url\",\"sha256\":\"$sha\"}" | ${pkgs.jq}/bin/jq -r > '${toString versionFile}'
  '';
}
