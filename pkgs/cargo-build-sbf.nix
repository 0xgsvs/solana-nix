{
  lib,
  rustPlatform,
  fetchCrate,
  openssl,
  pkg-config,
  makeWrapper,
  coreutils,
  nix-update-script,
  versionCheckHook,
  solanaPlatformTools,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "cargo-build-sbf";
  version = "4.4.0";

  src = fetchCrate {
    pname = "cargo-build-sbf";
    inherit (finalAttrs) version;
    hash = "sha256-CDOn/MJAih6+1wPnBV112CVN4r2ALGMBUq7ZKjJld0g=";
  };

  cargoHash = "sha256-QTbQr81KOSePrSvwPtVHXmSwOlCDRusqBVbuTOlWk9g=";

  __structuredAttrs = true;
  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    openssl
    solanaPlatformTools
  ];

  env.OPENSSL_NO_VENDOR = 1;

  # tests/crates.rs drives the built binary end-to-end: it force-downloads
  # platform-tools (`--force-tools-install`), then compiles SBF programs from
  # `tests/crates/`. That needs network access and writes to a user cache.
  doCheck = false;

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = "${placeholder "out"}/bin/cargo-build-sbf";

  postFixup = ''
    for bin in cargo-build-sbf cargo-test-sbf; do
      wrapProgram $out/bin/$bin \
        --prefix PATH : "${lib.makeBinPath [ coreutils ]}:${solanaPlatformTools}/rust/bin" \
        --set RUSTC "${solanaPlatformTools}/rust/bin/rustc" \
        --run 'args=("$@")
        if [ "''${args[0]-}" = build-sbf ]; then args=("''${args[@]:1}"); fi
        if [ "''${args[0]-}" = test-sbf ]; then args=("''${args[@]:1}"); fi
        extra=()
        case " ''${args[*]-} " in *" --skip-tools-install "*) ;; *) extra+=(--skip-tools-install);; esac
        case " ''${args[*]-} " in *" --no-rustup-override "*) ;; *) extra+=(--no-rustup-override);; esac
        set -- "''${extra[@]}" "''${args[@]}"
        if [ -z "''${HOME-}" ]; then
          HOME="''${TMPDIR:-/tmp}/cargo-build-sbf-home.$$.$(head -c8 /dev/urandom | od -An -tx1 | tr -d " \n")";
          while ! mkdir -m700 "$HOME" 2>/dev/null; do HOME="$HOME.$$"; done
          export HOME
        fi
        cache="$HOME/.cache/solana/v${solanaPlatformTools.version}"
        if mkdir -p "$cache" && \
          { [ -e "$cache/platform-tools/rust/bin/rustc" ] || \
            { rm -f "$cache/platform-tools" && ln -s "${solanaPlatformTools}" "$cache/platform-tools"; }; }; then
          :
        else
          echo "cargo-build-sbf: could not set up solana-platform-tools cache at $cache" >&2
        fi || true'
    done
  '';

  meta = {
    description = "Compile Solana programs using the Solana SBF SDK";
    homepage = "https://github.com/anza-xyz/cargo-build-sbf";
    changelog = "https://github.com/anza-xyz/cargo-build-sbf/releases";
    license = lib.licenses.asl20;
    mainProgram = "cargo-build-sbf";
    maintainers = with lib.maintainers; [ _0xgsvs ];
    platforms = lib.platforms.unix;
  };

  passthru.updateScript = nix-update-script { };
})
