# Shared helper for building a Solana development shell.
{ lib }:
{
  # A dev shell with the Solana toolchain.
  #
  # The platform-tools cache at `~/.cache/solana/v<version>/platform-tools` is
  # primed by the wrapped `cargo-build-sbf` itself (see pkgs/cargo-build-sbf.nix),
  # so no shellHook is needed.
  mkDevShell =
    {
      pkgs,
      package,
      extraPackages ? [ ],
    }:
    pkgs.mkShell {
      packages = [ package ] ++ extraPackages;
    };
}
