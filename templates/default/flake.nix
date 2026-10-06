{
  description = "Solana development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    solana-nix = {
      url = "github:0xgsvs/solana-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.solana-nix.flakeModules.default ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        { ... }:
        {
          solana = {
            enable = true;
            # Optional, both default to false:
            anchor.enable = true;
            surfpool.enable = true;
          };
        };
    };
}
