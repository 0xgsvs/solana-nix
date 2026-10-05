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
#         perSystem = {
#           solana = {
#             enable = true;
#             package = "4.3";                      # or a package
#             platformTools = [ "1.55" "1.56" ];    # or packages
#           };
#         };
#       };
#   }
#
# `package` and `platformTools` accept either a version string (resolved
# against this flake's packages) or a package for full control. It defines
# `devShells.default` (so `nix develop` / `nom develop` just works) and primes
# `~/.cache/solana/v<version>/platform-tools` on shell entry.
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
          type = lib.types.either lib.types.str lib.types.package;
          defaultText = lib.literalExpression "inputs'.solana-nix.packages.solana-cli";
          description = ''
            The `solana-cli` package providing `solana`, `cargo-build-sbf`,
            `cargo-test-sbf` and `spl-token`. Either a version string such as
            `"4.3"` or `"4.3.0"`, or an explicit package. Defaults to the
            latest release.
          '';
        };

        platformTools = lib.mkOption {
          type = lib.types.listOf (lib.types.either lib.types.str lib.types.package);
          default = [ ];
          example = lib.literalExpression ''[ "1.55" "1.56" ]'';
          description = ''
            Extra `solana-platform-tools` versions to make selectable with
            `cargo build-sbf --tools-version <version>`. Each entry is either a
            version string such as `"1.55"`, or an explicit package.
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

      # "4.3" / "4.3.0" -> "43", "1.55" -> "155"
      versionKey = v: lib.concatStringsSep "" (lib.take 2 (lib.splitVersion v));

      resolve =
        name: value:
        if builtins.isString value then
          let
            key = "${name}_${versionKey value}";
          in
          solanaPkgs.${key}
            or (throw "solana-nix: no '${key}' available (requested ${name} version '${value}')")
        else
          value;
    in
    {
      solana.package = lib.mkDefault solanaPkgs.solana-cli;

      devShells = lib.mkIf cfg.enable {
        default = helpers.mkDevShell {
          inherit pkgs;
          package = resolve "solana-cli" cfg.package;
          platformTools = map (resolve "solana-platform-tools") cfg.platformTools;
          inherit (cfg) extraPackages;
        };
      };

      # So `nix build` / `nom build` works out of the box. `mkDefault` lets a
      # consumer override it with their own `packages.default`.
      packages = lib.mkIf cfg.enable {
        default = lib.mkDefault (resolve "solana-cli" cfg.package);
      };
    };
}
