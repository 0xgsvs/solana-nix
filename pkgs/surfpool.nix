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
  mkSurfpool =
    {
      version,
      hash,
      cargoHash,
      studioUiVersion,
      studioUiHash,
    }:
    let
      # Surfpool Studio UI assets; wired in via STUDIO_UI_DIST so the build
      # does not download them.
      studioUi = fetchurl {
        url = "https://github.com/solana-foundation/surfpool-web-ui/releases/download/${studioUiVersion}/studio-dist.zip";
        hash = studioUiHash;
      };
    in
    rustPlatform.buildRustPackage (finalAttrs: {
      pname = "surfpool-cli";
      inherit version;
      __structuredAttrs = true;

      src = fetchFromGitHub {
        owner = "solana-foundation";
        repo = "surfpool";
        tag = "v${finalAttrs.version}";
        inherit hash;
        fetchSubmodules = true;
      };

      inherit cargoHash;

      env = {
        RUSTFLAGS = "-Aunused";
        OPENSSL_NO_VENDOR = 1;
        STUDIO_UI_DIST = "${studioUi}";
      };

      nativeBuildInputs = [ pkg-config ];

      buildInputs = [ openssl ];

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
    });
in
{
  surfpool_15 = mkSurfpool {
    version = "1.5.0";
    hash = "sha256-DszqgmMW+hQ3wKhh3ZMioX1sAca333WzRIikKJFuyXg=";
    cargoHash = "sha256-eOgPoHQVQVm+aSLsxAokjMyAyZBia/j/Bxux69WfklI=";
    studioUiVersion = "v0.1.0";
    studioUiHash = "sha256-DeWm2FzZbdaHXaEFA8W/YIIcJx4Z+uFkrxuajTM9n1M=";
  };

  surfpool_latest = mkSurfpool {
    version = "1.5.0";
    hash = "sha256-DszqgmMW+hQ3wKhh3ZMioX1sAca333WzRIikKJFuyXg=";
    cargoHash = "sha256-eOgPoHQVQVm+aSLsxAokjMyAyZBia/j/Bxux69WfklI=";
    studioUiVersion = "v0.1.0";
    studioUiHash = "sha256-DeWm2FzZbdaHXaEFA8W/YIIcJx4Z+uFkrxuajTM9n1M=";
  };
}
