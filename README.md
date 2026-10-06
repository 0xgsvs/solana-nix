# solana-nix

A self-contained Nix flake providing a Solana development environment: the
Agave `solana-cli` and its pinned `cargo-build-sbf`, `cargo-test-sbf`, and
`spl-token-cli`, plus `solana-platform-tools`.

This is the standalone home for the packaging work that is being upstreamed to
nixpkgs, so it can be used before those packages land.

Inspired by https://github.com/arijoon/solana-nix, which laid the groundwork for
managing Solana and Anchor toolchains with Nix.

## Packages

| Attribute | Version |
| --- | --- |
| `solanaCli` | 4.3.0 |
| `cargoBuildSbf` | 4.4.0 |
| `splTokenCli` | 5.6.1 |
| `solanaPlatformTools` | 1.57 |
| `anchor` | 1.2.0 |
| `surfpool` | 1.6.0 |

Each version is pinned to the one Agave 4.3.0 depends on, so the toolchain is
always internally consistent. `solanaCli` re-exports the `cargo-build-sbf` /
`cargo-test-sbf` / `spl-token` binaries it was built against.

## Usage

### Template

Scaffold a flake-parts project that uses the dev shell module:

```console
$ nix flake init -t github:0xgsvs/solana-nix
$ nix develop
```

It targets `x86_64-linux`, `aarch64-linux`, `x86_64-darwin` and
`aarch64-darwin`; trim the `systems` list to what you actually need.

### Add as an input

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
    solana-nix = {
      url = "github:0xgsvs/solana-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.solana-nix.flakeModules.default ];

      systems = [ "x86_64-linux" ];

      perSystem = { inputs', ... }:
        let solanaPkgs = inputs'.solana-nix.packages;
        in {
          solana = {
            enable = true;
            # Optional, both default to false:
            anchor.enable = true;
            surfpool.enable = true;
          };
        };
    };
}
```

The option namespace is `perSystem.solana`, named after the software (the
flake-parts convention, as with `treefmt` and `pre-commit`). Package options
resolve from `inputs'.solana-nix.packages`, so you do **not** need to add an
overlay.

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
        package = pkgs.solanaCli;
      };
    };
}
```

### Overlay

Every attribute is available as `pkgs.<attr>` once the overlay is applied, and
as `solana-nix.packages.<system>.<attr>` directly:

```nix
{
  nixpkgs.overlays = [ inputs.solana-nix.overlays.default ];
}
```
