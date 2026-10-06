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

      flake.flakeModules.default = ./flakeModules/devshell.nix;

      flake.templates.default = {
        path = ./templates/default;
        description = "Solana development shell (flake-parts)";
      };

      # For plain (non-flake-parts) flakes:
      #   solana-nix.lib.mkDevShell { inherit pkgs; package = pkgs.solana-cli; }
      flake.lib.mkDevShell = args: (import ./lib.nix).mkDevShell args;

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
          cargoBuildSbf = pkgs.callPackage ./pkgs/cargo-build-sbf.nix { inherit solanaPlatformTools; };
          splTokenCli = pkgs.callPackage ./pkgs/spl-token-cli.nix { };
          solanaCli = pkgs.callPackage ./pkgs/solana-cli.nix { inherit cargoBuildSbf splTokenCli; };
          anchor = pkgs.callPackage ./pkgs/anchor.nix { };
          surfpool = pkgs.callPackage ./pkgs/surfpool.nix { };

          packageSet = {
            inherit
              solanaPlatformTools
              cargoBuildSbf
              splTokenCli
              solanaCli
              anchor
              surfpool
              ;
          };
        in
        {
          packages = packageSet;

          overlayAttrs = packageSet;

          formatter = pkgs.nixfmt-tree;

          devShells.default = pkgs.mkShell {
            packages = [
              solanaCli
              cargoBuildSbf
              splTokenCli
              anchor
              surfpool
            ];
          };
        };
    };
}
