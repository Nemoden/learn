{
  description = "Authentication learning environment (Python + Node.js + Docker)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python312;
        pythonWithPackages = python.withPackages (ps: with ps; [
          pip
          httpx
        ]);
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            # Python (Sprint 1, Sprint 3)
            pythonWithPackages

            # Node.js + TypeScript (Sprint 2, Sprint 4)
            pkgs.nodejs_20
            pkgs.nodePackages.typescript
            pkgs.nodePackages.ts-node

            # Utilities
            pkgs.curl
            pkgs.jq
            pkgs.postgresql  # psql client for DB inspection
            pkgs.redis  # redis-cli for Redis inspection
          ];

          shellHook = ''
            echo "╔════════════════════════════════════════════════════════╗"
            echo "║  Auth Learning Environment                             ║"
            echo "╚════════════════════════════════════════════════════════╝"
            echo ""
            echo "🐍 Python:     $(python --version)"
            echo "📦 Node.js:    $(node --version)"
            echo "📘 TypeScript: $(tsc --version)"
            echo "🐳 Docker:     $(docker --version | cut -d' ' -f3 | tr -d ',')"
            echo "🔧 Compose:    $(docker-compose --version | cut -d' ' -f4 | tr -d ',')"
            echo ""
            echo "📚 Quick Start:"
            echo "   cd projects/devcollab-platform"
            echo "   /learn  (to start teaching from plan.md)"
            echo ""
          '';
        };
      }
    );
}
