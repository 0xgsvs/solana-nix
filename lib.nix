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

      shellHook = ''
        # Publish this shell's PATH so the user's interactive shell can restore
        # its precedence after tools like mise re-prepend directories on startup.
        # The shellHook runs before the user's rc, so it cannot win the PATH
        # ordering itself; this variable is the handoff. It is inert unless the
        # user's rc opts in. See the README.
        export NIX_DEVSHELL_PATH="$PATH"

        ${mkCacheScript platformTools}
      '';
    };
in
{
  inherit mkCacheScript mkDevShell;
}
