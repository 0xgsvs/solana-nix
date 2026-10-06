{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchurl,
  pkg-config,
  versionCheckHook,
  openssl,
  nix-update-script,
}:

let
  # Surfpool Studio UI assets; wired in via STUDIO_UI_DIST so the build
  # does not download them.
  studioUi = fetchurl {
    url = "https://github.com/solana-foundation/surfpool-web-ui/releases/download/v0.1.0/studio-dist.zip";
    hash = "sha256-DeWm2FzZbdaHXaEFA8W/YIIcJx4Z+uFkrxuajTM9n1M=";
  };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "surfpool-cli";
  version = "1.6.0";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "solana-foundation";
    repo = "surfpool";
    tag = "v${finalAttrs.version}";
    hash = "sha256-rKY19f4Dh6PecbpK2DEVtcNuncA0G3q4SqBdkzmQ5Fs=";
    fetchSubmodules = true;
  };

  cargoHash = "sha256-rpIKpX+Z9eBiO3HdiyEHOXpTmwxrqtck3Kd48xYlUXE=";

  env = {
    RUSTFLAGS = "-Aunused";
    OPENSSL_NO_VENDOR = 1;
    STUDIO_UI_DIST = "${studioUi}";
  };

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ openssl ];

  # Tests fail to resolve `localhost` under the Nix sandbox on
  # aarch64-darwin (upstream #821). Fixed upstream in #822, merged to main
  # but not in a tag yet. Remove this once a release includes it.
  doCheck = false;

  doInstallCheck = true;

  nativeInstallCheckInputs = [ versionCheckHook ];

  versionCheckProgram = "${placeholder "out"}/bin/surfpool";

  meta = {
    description = "Surfpool is where developers start their Solana journey";
    homepage = "https://www.surfpool.run/";
    longDescription = ''
      Surfpool is a drop-in replacement for solana-test-validator that lets
      developers spin up local Solana networks mirroring mainnet state without
      downloading the entire chain. It includes a built-in web UI (Surfpool Studio)
      served directly from the binary, Infrastructure as Code for declarative
      program deployment, transaction inspection, time travel, cheatcodes, and
      an MCP server for agentic workflows
    '';
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ _0xgsvs ];
    mainProgram = "surfpool";
  };

  passthru.updateScript = nix-update-script { };
})
