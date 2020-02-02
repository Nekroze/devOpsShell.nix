let
  pinned = import ./pinnedNixpkgs.nix {
    channel = "nixpkgs-unstable";
    versionFile = ./.nixpkgs-version.json;
  };
  pkgs = pinned.pkgs;
in

with pkgs;

let
  devOpsShell = import ./default.nix {inherit pkgs;};
in devOpsShell {
  subcommander.enable = true;

  packages = [
    nix-prefetch-git
  ];

  variables.TEST = "foo";

  scripts.updateNixpkgs = pinned.updateScript;
  shellcheck.enable = true;

  variableSets.dev.TARGET = "local";
  variableSets.prod.TARGET = "cloud";
  exportNixPath = true;
  certificateBundle = "${pinned.pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
}
