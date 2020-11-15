{ channel ? "nixpkgs-unstable", versionFile ? null, versionConfig ? null, nixpkgsRepo ? "https://github.com/nixos/nixpkgs" }:

let
  switchedVersionConfig = if versionConfig != null then versionConfig else builtins.fromJSON (builtins.readFile versionFile);
  versionConfigOrFileProvided = (versionFile != null) || (versionConfig != null);
in rec {
  version = assert versionConfigOrFileProvided; switchedVersionConfig;

  src = builtins.fetchTarball {
    inherit (version) url sha256;
    name = channel;
  };

  pkgs = import src {};

  updateScript = let
    generatedVersionFile = builtins.toFile "version.json" (builtins.toJSON version);
  in ''
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
    echo "{\"url\":\"$url\",\"sha256\":\"$sha\"}" | ${pkgs.jq}/bin/jq -r > '${toString generatedVersionFile}'
  '';
}
