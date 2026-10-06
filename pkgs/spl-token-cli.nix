{
  lib,
  stdenv,
  fetchCrate,
  rustPlatform,
  darwin,
  udev,
  protobuf,
  pkg-config,
  openssl,
  clang,
  libclang,
  libusb1,
  nix-update-script,
  versionCheckHook,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "spl-token-cli";
  version = "5.6.1";

  src = fetchCrate {
    pname = "spl-token-cli";
    inherit (finalAttrs) version;
    hash = "sha256-nlbnDTEAUBpY1oz5kqEBpvt0WFA9qmzmokBOftf1qVk=";
  };

  cargoHash = "sha256-fH5AgpMtnOKuB0jf5tiXDAeWBL+JcA7KJ8xjYGd1bek=";
  __structuredAttrs = true;
  strictDeps = true;

  nativeBuildInputs = [
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

  env = {
    # Do not fail on lints introduced by newer rustc.
    RUSTFLAGS = "--cap-lints warn";
    OPENSSL_NO_VENDOR = 1;
  };

  # The tests spin up a local RPC / need network access and assets that only
  # exist in the upstream workspace.
  doCheck = false;

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = "${placeholder "out"}/bin/spl-token";

  meta = {
    description = "Command-line utility for the SPL Token program";
    homepage = "https://github.com/solana-program/token-2022";
    changelog = "https://github.com/solana-program/token-2022/releases";
    license = lib.licenses.asl20;
    mainProgram = "spl-token";
    maintainers = with lib.maintainers; [ _0xgsvs ];
    platforms = lib.platforms.unix;
  };

  passthru.updateScript = nix-update-script { };
})
