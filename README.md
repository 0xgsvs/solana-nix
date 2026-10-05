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
            # Optional: defaults to the latest solana-cli.
            package = solanaPkgs.solana-cli_43;
            platformTools = with solanaPkgs; [
              solana-platform-tools_155
              solana-platform-tools_156
            ];
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
| `anchor` | `anchor_12`, `anchor_latest` |
| `surfpool` | `surfpool_15`, `surfpool_latest` |

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

### Using with mise (or other version managers)

Some tools (e.g. [mise](https://mise.jdx.dev)) re-prepend their own directories
to `PATH` when your interactive shell starts. Since a dev shell's `shellHook`
runs *before* your shell's rc, those tools can shadow the shell's `solana` /
`cargo-build-sbf`, even though the shell is "active".

To make the Nix toolchain win inside dev shells while keeping mise everywhere
else, have the shell publish its `PATH` (done automatically via
`NIX_DEVSHELL_PATH`) and re-prepend it at the **end** of your shell rc, after
the version manager has run.

For fish, append to `~/.config/fish/config.fish`:

```fish
# Inside a Nix dev shell, put the shell's own bin dirs ahead of mise.
# `--path` keeps this session-only; reverse the iteration so the original
# PATH order is preserved when prepending.
if set -q IN_NIX_SHELL
    for d in (string split : "$NIX_DEVSHELL_PATH")[-1..1]
        fish_add_path --path --move --prepend $d
    end
end
```

Without `--path`, `fish_add_path` writes to the persistent universal
`fish_user_paths`, which is not what you want here.

`NIX_DEVSHELL_PATH` is only set inside the dev shell, so this has no effect on
other shells, other users, or mise outside dev shells. It is inert unless your
rc reads it.

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
