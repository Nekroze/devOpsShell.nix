# devOpsShell

A portable [Nix][1] based highly reproducible, highly cacheable, development
and operations shell environment framework.

Not dissimilar to `mkShell`, `devOpsShell` is a [Nix][1] expression that
provides a function, this function provides a wrapper around
`stdenv.mkDerivation` by simply passing through parameters. However some
parameters are intercepted and acted upon to generate a more useful derivation.

[1]: https://nixos.org/nix/
