{
  description = ""; # FIXME: add a description
  inputs = {
    flake-utils.url = "github:numtide/flake-utils"; # TODO: pin
    rust-overlay.url = "github:oxalica/rust-overlay"; # TODO: pin
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, flake-utils, nixpkgs, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = (import nixpkgs) {
          inherit system overlays;
        };
        # Generate a user-friendly version number.
        version = builtins.substring 0 8 self.lastModifiedDate;
        rust_toolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;

        info = (builtins.fromTOML (builtins.readFile ./Cargo.toml));
      in
      {
        packages = {
          # For `nix build` & `nix run`:
          default = pkgs.rustPlatform.buildRustPackage {
            # https://nixos.org/manual/nixpkgs/stable/#compiling-rust-applications-with-cargo
            inherit version;
            pname = info.package.name;
            src = ./.; # TODO: narrow
              cargoLock = {
                lockFile = ./Cargo.lock;
              };
            # see https://johns.codes/blog/efficient-nix-derivations-with-file-sets
            # see https://github.com/JRMurr/roc2nix/blob/main/lib/languageFilters.nix
            nativeBuildInputs = [ rust_toolchain ];
          };
        };
        # For `nix develop`:
        devShell = pkgs.mkShell {
          # see https://github.com/NixOS/nixpkgs/issues/52447
          # see https://hoverbear.org/blog/rust-bindgen-in-nix/
          # see https://slightknack.dev/blog/nix-os-bindgen/
          # https://nixos.wiki/wiki/Rust#Installation_via_rustup
          nativeBuildInputs = [ rust_toolchain ];
          buildInputs = with pkgs;
            [
              # rust tools
              rust-analyzer-unwrapped
              rustfmt
              cargo-bloat

              # nix support
              nixpkgs-fmt
              nil

              # other
              lychee
              shellcheck
              git
              bashInteractive
            ];

          # Environment variables
          RUST_SRC_PATH = "${rust_toolchain}/lib/rustlib/src/rust/library";
        };
      }
    );
}
