{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.solana-cli;
  helpers = import ./lib.nix { inherit lib; };
in
{
  options.programs.solana-cli = {
    enable = lib.mkEnableOption "the Solana CLI and its SBF toolchain";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.solana-cli;
      defaultText = lib.literalExpression "pkgs.solana-cli";
      description = ''
        The `solana-cli` package to install. Its pinned `cargo-build-sbf`,
        `cargo-test-sbf` and `spl-token` binaries are installed alongside it.

        Requires the `solana-nix` overlay, e.g.
        `nixpkgs.overlays = [ inputs.solana-nix.overlays.default ];`.
      '';
    };

    platformTools = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression ''
        with pkgs; [
          solana-platform-tools_154
          solana-platform-tools_155
          solana-platform-tools_156
          solana-platform-tools_157
        ]
      '';
      description = ''
        Additional `solana-platform-tools` versions to make available to
        `cargo build-sbf --tools-version <version>`.

        `cargo-build-sbf` resolves toolchains only from
        {file}`~/.cache/solana/v<version>/platform-tools`, so each entry here is
        symlinked into that cache. The version recommended by the installed
        `package` is always available regardless of this list.

        The default is empty so that enabling the module does not pull every
        platform-tools version into the user closure.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.activation = lib.mkIf (cfg.platformTools != [ ]) {
      solana-platform-tools = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        helpers.mkCacheScript cfg.platformTools
      );
    };
  };
}
