# Helpers shared by every surface of solana-nix.
#
# Takes `lib` explicitly so it can be reused from a flake without depending on
# the private internals of any particular module system.
{ lib }:

let
  # A shell fragment that makes each platform-tools version resolvable by
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

  # Build a dev shell that provides the Solana toolchain and primes the
  # platform-tools cache on entry.
  #
  # `callPackage` is passed explicitly so a flake's `pkgs` argument is resolved
  # by the caller, keeping the returned function usable in any module system.
  mkDevShell =
    {
      pkgs,
      package,
      platformTools ? [ ],
      extraPackages ? [ ],
    }:
    pkgs.mkShell {
      packages = [ package ] ++ extraPackages;
      shellHook = ''
        ${mkCacheScript platformTools}
        echo "solana-cli: $(solana --version 2>/dev/null || echo 'not found')"
        echo "cargo-build-sbf: $(cargo-build-sbf --version 2>/dev/null | head -n1 || echo 'not found')"
      '';
    };
in
{
  inherit mkCacheScript mkDevShell;
}
