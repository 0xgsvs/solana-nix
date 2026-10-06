# Shared helper for building a Solana development shell.
{ lib }:

let
  # Makes each platform-tools version resolvable by
  # `cargo build-sbf --tools-version`.
  #
  # cargo-build-sbf resolves a toolchain only via
  # `$HOME/.cache/solana/v<version>/platform-tools`; it never looks at the
  # user's profile or `$PATH`. A separately installed `solana-platform-tools`
  # is therefore invisible to it unless we create that symlink ourselves.
  #
  # Interpolating `${p}` keeps each store path referenced, so the symlink
  # target cannot be garbage collected.
  mkCacheScript =
    platformTools:
    lib.optionalString (platformTools != [ ]) ''
      if [ -n "''${HOME-}" ]; then
      ${lib.concatMapStrings (p: ''
        mkdir -p "$HOME/.cache/solana/v${p.version}"
        ln -sfn "${p}" "$HOME/.cache/solana/v${p.version}/platform-tools"
      '') platformTools}
      fi
    '';

  # A dev shell with the Solana toolchain, priming the platform-tools cache on
  # entry.
  mkDevShell =
    {
      pkgs,
      package,
      platformTools ? [ ],
      extraPackages ? [ ],
    }:
    pkgs.mkShell {
      packages = [ package ] ++ extraPackages;
      shellHook = mkCacheScript platformTools;
    };
in
{
  inherit mkCacheScript mkDevShell;
}
