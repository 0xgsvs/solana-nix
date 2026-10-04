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
  inputs.solana-nix.url = "github:<you>/solana-nix";
  outputs = { self, nixpkgs, solana-nix, ... }: {
    nixpkgs.overlays = [ solana-nix.overlays.default ];
  };
}
```

### Overlay

`solana-nix.overlays.default` exposes every versioned attribute:

```nix
{
  nixpkgs.overlays = [ inputs.solana-nix.overlays.default ];
}
```

Then use `pkgs.solana-cli_43`, `pkgs.solana-platform-tools_155`, etc.

### Packages

| Package | Available attributes |
| --- | --- |
| `solana-cli` | `solana-cli_41`, `solana-cli_42`, `solana-cli_43`, `solana-cli_latest` |
| `cargo-build-sbf` | `cargo-build-sbf_41`, `cargo-build-sbf_44`, `cargo-build-sbf_latest` |
| `spl-token-cli` | `spl-token-cli_56`, `spl-token-cli_latest` |
| `solana-platform-tools` | `solana-platform-tools_152` … `solana-platform-tools_157`, `solana-platform-tools_latest` |

`solana-cli_*` re-exports the `cargo-build-sbf` / `cargo-test-sbf` /
`spl-token` binaries that Agave pins for that release, so the toolchain is
always internally consistent.

### Dev shell

```console
$ nix develop
```

## Modules

NixOS and home-manager modules are planned and will let you configure which
`solana-cli` release is installed and which `solana-platform-tools` versions
are available to `--tools-version`.