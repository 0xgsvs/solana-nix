# Shared helpers for the NixOS and home-manager modules.
{ lib }:

{
  # Shell fragment that makes each entry in `platformTools` resolvable by
  # `cargo build-sbf --tools-version`.
  #
  # cargo-build-sbf resolves a toolchain only via
  # `$HOME/.cache/solana/v<version>/platform-tools`; it never looks at the
  # user's profile or `$PATH`. A separately installed `solana-platform-tools`
  # is therefore invisible to it unless we create that symlink ourselves.
  #
  # Referencing `${p}` keeps each store path alive, so the symlink target
  # cannot be garbage collected.
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
}
