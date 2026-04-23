# Nix Flake Template

Only generate a flake.nix if the topic has tools/runtimes to install locally. Many topics (music theory, history, pure math) don't need one.

```nix
{
  description = "{{TOPIC}} learning environment";

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
            {{PACKAGES — only what's needed, e.g.:
            # Rust: rustc cargo clippy rustfmt rust-analyzer cargo-watch
            # Python: (python3.withPackages (ps: with ps; [ boto3 pytest ]))
            # Go: go gopls
            # Node: nodejs typescript
            # Science: python3 jupyter (python3.withPackages (ps: with ps; [ numpy matplotlib scipy ]))
            }}
          ];

          shellHook = ''
            echo "{{EMOJI}} {{TOPIC}} Learning Environment Ready"
            echo ""
            echo "Available tools:"
            {{TOOL_ECHO_LINES — one per key tool, e.g.:
            echo "  - rustc $(rustc --version | cut -d' ' -f2)"
            echo "  - cargo, clippy, rustfmt"
            }}
          '';
        };
      }
    );
}
```

Pair with `.envrc`:
```
has nix && use flake || true
```

## When NOT to generate

- Music theory (no tools to install)
- History (no tools)
- Pure math (maybe just a calculator/CAS — consider if worth a flake)
- Topics learned entirely through conversation + exercises

When in doubt, ask the user if they need local tools.
