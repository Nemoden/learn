{
  description = "Rust learning environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Rust toolchain
            rustc
            cargo
            clippy
            rustfmt
            rust-analyzer

            # Useful extras
            cargo-watch    # auto-rebuild on file changes
            cargo-expand   # expand macros for learning
          ];

          shellHook = ''
            echo "🦀 Rust Learning Environment Ready"
            echo ""
            echo "Available tools:"
            echo "  - rustc $(rustc --version | cut -d' ' -f2)"
            echo "  - cargo, clippy, rustfmt, rust-analyzer"
            echo "  - cargo-watch, cargo-expand"
            echo ""
            echo "Quick start:"
            echo "  cargo new my-project   # Create new project"
            echo "  cargo check            # Fast compile check"
            echo "  cargo clippy           # Lint for idiomatic Rust"
          '';
        };
      }
    );
}
