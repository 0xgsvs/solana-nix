# solana-nix

A self-contained Nix flake providing a configurable Solana development
environment: the Agave `solana-cli` and its pinned `cargo-build-sbf`,
`cargo-test-sbf`, and `spl-token-cli`, plus multiple versions of
`solana-platform-tools`.

This is the standalone home for the packaging work that is being upstreamed to
nixpkgs, so it can be used before those packages land.

Inspired by https://github.com/arijoon/solana-nix, which laid the groundwork for
managing Solana and Anchor toolchains with Nix.

## Usage

Add the flake as an input:

```nix
{
  inputs.solana-nix.url = "github:0xgsvs/solana-nix";
}
```

### flake-parts: `flakeModules.default`

If you use [flake-parts](https://flake.parts), this is the most direct option.
It gives you a `devShells.default` with the Solana toolchain, so `nix develop` /
`nom develop` just work:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    solana-nix.url = "github:0xgsvs/solana-nix";
    solana-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.solana-nix.flakeModules.default ];

      systems = [ "x86_64-linux" ];

      perSystem = {
        solana = {
          enable = true;
          # Optional: defaults to the latest solana-cli. Accepts a version
          # string or a package.
          package = "4.3";
          platformTools = [ "1.55" "1.56" ];
        };
      };
    };
}
```

`package` and `platformTools` accept either a version string (`"4.3"`, `"1.55"`)
resolved against this flake's packages, or an explicit package
(`inputs'.solana-nix.packages.solana-cli_43`) for full control. No overlay is
needed.

### Plain flake: `lib.mkDevShell`

Without flake-parts, apply the overlay and call the helper directly:

```nix
{
  inputs.solana-nix.url = "github:0xgsvs/solana-nix";

  outputs = { self, nixpkgs, solana-nix, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ solana-nix.overlays.default ];
      };
    in {
      devShells.${system}.default = solana-nix.lib.mkDevShell {
        inherit pkgs;
        package = pkgs.solana-cli_43;
        platformTools = [ pkgs.solana-platform-tools_155 ];
      };
    };
}
```

### Packages and overlay

Every versioned attribute is available as `pkgs.<attr>` once the overlay is
applied, and as `solana-nix.packages.<system>.<attr>` directly:

```nix
{
  nixpkgs.overlays = [ inputs.solana-nix.overlays.default ];
}
```

| Package | Available attributes |
| --- | --- |
| `solana-cli` | `solana-cli_41`, `solana-cli_42`, `solana-cli_43`, `solana-cli_latest` |
| `cargo-build-sbf` | `cargo-build-sbf_41`, `cargo-build-sbf_44`, `cargo-build-sbf_latest` |
| `spl-token-cli` | `spl-token-cli_56`, `spl-token-cli_latest` |
| `solana-platform-tools` | `solana-platform-tools_152` … `solana-platform-tools_157`, `solana-platform-tools_latest` |

`solana-cli_*` re-exports the `cargo-build-sbf` / `cargo-test-sbf` /
`spl-token` binaries that Agave pins for that release, so the toolchain is
always internally consistent.

### `--tools-version`

`cargo-build-sbf` resolves SBF toolchains only from
`~/.cache/solana/v<version>/platform-tools`, never from your profile or
`$PATH`. Listing a version in `platformTools` symlinks it into that cache (from
the dev shell's `shellHook`), so it becomes selectable:

```console
$ cargo build-sbf --tools-version v1.55
```

The version Agave recommends for the chosen `package` is always available.

## Modules

`nixosModules.default` and `homeManagerModules.default` additionally let you
install the toolchain declaratively:

```nix
{
  imports = [ inputs.solana-nix.nixosModules.default ]; # or homeManagerModules.default
  nixpkgs.overlays = [ inputs.solana-nix.overlays.default ];

  programs.solana-cli = {
    enable = true;
    package = pkgs.solana-cli_43;
    platformTools = with pkgs; [
      solana-platform-tools_155
      solana-platform-tools_156
    ];
  };
}
```

These are for NixOS / home-manager users only. Everyone else should use
`flakeModules.default` or `lib.mkDevShell`.
