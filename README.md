# devOpsShell

A portable [Nix][1] based highly reproducible, highly cacheable, development
and operations, shell environment framework. This is a spiritual successor to
(at least a subset of) [Dab][2] allowing many disparate projects to have a
unified interface for development and operation but resides entirely within a
project repository rather than being a central place to configure and manage a
whole swath of projects ditching docker for [Nix][1].

Not dissimilar to `mkShell`, `devOpsShell` is a [Nix][1] expression that
provides a function, this function provides a wrapper around
`stdenv.mkDerivation` by simply passing through parameters. However some
parameters are intercepted and acted upon to generate a more useful derivation
for day to day operations including the ability to define and select
environments with differing configurations.

[1]: https://nixos.org/nix/
[2]: https://github.com/Nekroze/dab
