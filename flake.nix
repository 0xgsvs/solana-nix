{
  description = "Solana development environment for Nix — packages and modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
      ];

      flake.nixosModules.default = ./modules/nixos.nix;
      flake.homeManagerModules.default = ./modules/home-manager.nix;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        { system, ... }:
        let
          # Plain nixpkgs, no self-overlay: the packages below are wired together
          # explicitly and then re-exported through `overlayAttrs`. This keeps the
          # flake free of the `pkgs` <-> `overlays.default` recursion.
          pkgs = import inputs.nixpkgs { inherit system; };

          solanaPlatformTools = pkgs.callPackage ./pkgs/solana-platform-tools.nix { };
          cargoBuildSbf = pkgs.callPackage ./pkgs/cargo-build-sbf.nix {
            inherit (solanaPlatformTools)
              solana-platform-tools_154
              solana-platform-tools_157
              ;
          };
          splTokenCli = pkgs.callPackage ./pkgs/spl-token-cli.nix { };
          solanaCli = pkgs.callPackage ./pkgs/solana-cli.nix {
            inherit (cargoBuildSbf)
              cargo-build-sbf_41
              cargo-build-sbf_44
              ;
            inherit (splTokenCli) spl-token-cli_56;
          };

          packageSet = {
            solana-platform-tools = solanaPlatformTools.solana-platform-tools_latest;
            inherit (solanaPlatformTools)
              solana-platform-tools_152
              solana-platform-tools_153
              solana-platform-tools_154
              solana-platform-tools_155
              solana-platform-tools_156
              solana-platform-tools_157
              ;

            cargo-build-sbf = cargoBuildSbf.cargo-build-sbf_latest;
            inherit (cargoBuildSbf)
              cargo-build-sbf_41
              cargo-build-sbf_44
              ;

            spl-token-cli = splTokenCli.spl-token-cli_latest;
            inherit (splTokenCli) spl-token-cli_56;

            solana-cli = solanaCli.solana-cli_latest;
            inherit (solanaCli)
              solana-cli_41
              solana-cli_42
              solana-cli_43
              ;
          };
        in
        {
          packages = packageSet;

          overlayAttrs = packageSet;

          formatter = pkgs.nixfmt-tree;

          devShells.default = pkgs.mkShell {
            packages = [
              solanaCli.solana-cli_latest
              cargoBuildSbf.cargo-build-sbf_latest
              splTokenCli.spl-token-cli_latest
            ];
          };
        };
    };
}
