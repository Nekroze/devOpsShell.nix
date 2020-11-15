let
  pinned = import ./pinnedNixpkgs.nix {
    channel = "nixpkgs-unstable";
    versionFile = ./.nixpkgs-version.json;
    #versionConfig = {
    #  url = "https://github.com/nixos/nixpkgs/archive/89281dd1dfed6839610f0ccad0c0e493606168fe.tar.gz";
    #  sha256 = "14jwgdqbhxf9581z9afzjzj0r0maw3m7227gn5bpk4fn8057vs5s";
    #};
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
