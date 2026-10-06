{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  darwin,
  udev,
  protobuf,
  installShellFiles,
  pkg-config,
  openssl,
  clang,
  libclang,
  libusb1,
  nix-update-script,
  versionCheckHook,
  # you need to check https://github.com/anza-xyz/agave/blob/v<*.*>/scripts/cargo-build-sbf-version.sh
  cargoBuildSbf,
  # you need to check https://github.com/anza-xyz/agave/blob/v<*.*>/scripts/spl-token-cli-version.sh
  splTokenCli,
}:

let
  # https://github.com/anza-xyz/agave/blob/master/scripts/agave-build-lists.sh
  solanaPkgs = [
    # AGAVE_BINS_END_USER
    "agave-install"
    "solana"
    "solana-keygen"
    # AGAVE_BINS_DEV
    "solana-test-validator"
    # AGAVE_BINS_VAL_OP
    "agave-validator"
    "agave-watchtower"
    "solana-gossip"
    "solana-faucet"
    # XXX: Ensure `solana-genesis` is built LAST!
    # See https://github.com/solana-labs/solana/issues/5826
    "solana-genesis"
  ];
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "solana-cli";
  version = "4.3.0";

  src = fetchFromGitHub {
    owner = "anza-xyz";
    repo = "agave";
    tag = "v${finalAttrs.version}";
    hash = "sha256-HHLh8cHL0qvGVepSemJTguTsUh0XXNPeeazfCtQPwAA=";
  };

  cargoHash = "sha256-pChrXSP9ez+26TQLPon/Z9y459PzksT6us++Yd50N1s=";

  strictDeps = true;

  cargoBuildFlags = map (n: "--bin=${n}") solanaPkgs;

  env = {
    # Cap all lints to warnings so the build does not break when nixpkgs moves
    # to a newer rustc than the one a given agave release was tested with.
    RUSTFLAGS = "--cap-lints warn";
    LIBCLANG_PATH = "${libclang.lib}/lib";

    # Require this on darwin otherwise the compiler starts rambling about missing
    # cmath functions
    CPPFLAGS = lib.optionalString stdenv.hostPlatform.isDarwin "-isystem ${lib.getInclude stdenv.cc.libcxx}/include/c++/v1";
    LDFLAGS = lib.optionalString stdenv.hostPlatform.isDarwin "-L${lib.getLib stdenv.cc.libcxx}/lib";

    # If set, always finds OpenSSL in the system, even if the vendored feature is enabled.
    OPENSSL_NO_VENDOR = 1;

    # Agave patches `librocksdb-sys` to a fork (v4.2+) whose RocksDB vendors a
    # PinnableSlice C API that upstream releases do not export, so the vendored
    # copy is built. GCC 13+ needs <cstdint> included explicitly for the
    # vendored RocksDB C++ sources.
    CXXFLAGS = "-include cstdint";
  };

  # Even tho the tests work, a shit ton of them try to connect to a local RPC
  # or access internet in other ways, eventually failing due to Nix sandbox.
  doCheck = false;

  nativeBuildInputs = [
    installShellFiles
    protobuf
    pkg-config
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [ darwin.DarwinTools ];

  buildInputs = [
    openssl
    clang
    libclang
    libusb1
    rustPlatform.bindgenHook
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ udev ];

  doInstallCheck = true;

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = "${placeholder "out"}/bin/solana";

  postInstall = ''
    install -Dm755 ${cargoBuildSbf}/bin/cargo-build-sbf $out/bin/cargo-build-sbf
    install -Dm755 ${cargoBuildSbf}/bin/cargo-test-sbf $out/bin/cargo-test-sbf
    install -Dm755 ${splTokenCli}/bin/spl-token $out/bin/spl-token
  ''
  + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd solana \
      --bash <($out/bin/solana completion --shell bash) \
      --fish <($out/bin/solana completion --shell fish)
  '';

  passthru = {
    inherit solanaPkgs;
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Web-Scale Blockchain for fast, secure, scalable, decentralized apps and marketplaces";
    homepage = "https://solana.com";
    changelog = "https://github.com/anza-xyz/agave/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [
      netfox
      happysalada
      aikooo7
      JacoMalan1
      _0xgsvs
    ];
    platforms = lib.platforms.unix;
  };
})
