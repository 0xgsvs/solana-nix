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
  # `pkgs` is passed explicitly so the returned function is usable from any
  # module system; the caller resolves it.
  mkDevShell =
    {
      pkgs,
      package,
      platformTools ? [ ],
      extraPackages ? [ ],
    }:
    let
      available = map (p: "v${p.version}") platformTools;
      availableLine = lib.optionalString (available != [ ]) (
        "echo '  also available via --tools-version: ${lib.concatStringsSep " " available}'"
      );
      # Use the package's absolute paths so the banner reports the tools this
      # shell actually provides, even if e.g. mise's shims shadow them on PATH.
      solana = "${package}/bin/solana";
      cargoBuildSbf = "${package}/bin/cargo-build-sbf";
    in
    pkgs.mkShell {
      packages = [ package ] ++ extraPackages;

      shellHook = ''
        # Publish this shell's PATH so the user's interactive shell can restore
        # its precedence after tools like mise re-prepend directories on startup.
        # The shellHook runs before the user's rc (e.g. fish config.fish), so it
        # cannot win the PATH ordering itself; this variable is the handoff.
        # It is inert unless the user's rc opts in. See the README.
        export NIX_DEVSHELL_PATH="$PATH"

        ${mkCacheScript platformTools}

        # Only print the banner to a terminal. `nom develop` / `nix develop`
        # replay the hook while building the environment, where stdout is not a
        # tty; this keeps the banner from appearing during that replay.
        if [ -t 1 ] && [ -z "''${SOLANA_NIX_BANNER_SHOWN-}" ]; then
          export SOLANA_NIX_BANNER_SHOWN=1

          echo "solana-cli: $(${solana} --version 2>/dev/null || echo 'not found')"
          echo "cargo-build-sbf: $(${cargoBuildSbf} --version 2>/dev/null | head -n1 || echo 'not found')"

          recommended="$(${cargoBuildSbf} --version 2>/dev/null | sed -n 's/^platform-tools //p')"
          if [ -n "$recommended" ]; then
            echo "platform-tools: $recommended (recommended)"
          fi

          ${availableLine}
        fi
      '';
    };
in
{
  inherit mkCacheScript mkDevShell;
}
