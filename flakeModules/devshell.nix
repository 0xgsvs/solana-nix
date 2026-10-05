# flake-parts module: configure a Solana development shell.
#
# This is the portable surface — it works for any flake-parts consumer on any
# system, with no NixOS or home-manager required.
#
# Usage:
#
#   {
#     inputs.solana-nix.url = "github:0xgsvs/solana-nix";
#     outputs = inputs@{ flake-parts, ... }:
#       flake-parts.lib.mkFlake { inherit inputs; } {
#         imports = [ inputs.solana-nix.flakeModules.default ];
#         systems = [ "x86_64-linux" ];
#
#         perSystem = { inputs', ... }:
#           let solana = inputs'.solana-nix.packages;
#           in {
#             solana = {
#               enable = true;
#               package = solana.solana-cli_43;
#               platformTools = [
#                 solana.solana-platform-tools_155
#                 solana.solana-platform-tools_156
#               ];
#             };
#           };
#       };
#   }
#
# It defines `devShells.default` (so `nix develop` / `nom develop` just works)
# and primes `~/.cache/solana/v<version>/platform-tools` on shell entry.
{
  flake-parts-lib,
  lib,
  ...
}:

{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { ... }:
    {
      options.solana = {
        enable = lib.mkEnableOption "the Solana development shell";

        package = lib.mkOption {
          type = lib.types.package;
          defaultText = lib.literalExpression "inputs'.solana-nix.packages.solana-cli";
          description = ''
            The `solana-cli` package providing `solana`, `cargo-build-sbf`,
            `cargo-test-sbf` and `spl-token`. Defaults to the latest release.
          '';
        };

        platformTools = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          example = lib.literalExpression ''
            [ inputs'.solana-nix.packages.solana-platform-tools_155 ]
          '';
          description = ''
            Extra `solana-platform-tools` versions to make selectable with
            `cargo build-sbf --tools-version <version>`.
          '';
        };

        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Additional packages to include in the development shell.";
        };
      };
    }
  );

  config.perSystem =
    {
      config,
      pkgs,
      inputs',
      ...
    }:
    let
      cfg = config.solana;
      helpers = import ../modules/lib.nix { inherit lib; };
      solanaPkgs = inputs'.solana-nix.packages;
    in
    {
      solana.package = lib.mkDefault solanaPkgs.solana-cli;

      devShells = lib.mkIf cfg.enable {
        default = helpers.mkDevShell {
          inherit pkgs;
          inherit (cfg) package platformTools extraPackages;
        };
      };

      # So `nix build` / `nom build` works out of the box. `mkDefault` lets a
      # consumer override it with their own `packages.default`.
      packages = lib.mkIf cfg.enable {
        default = lib.mkDefault cfg.package;
      };
    };
}
