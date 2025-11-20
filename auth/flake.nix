{
  description = "Python development environment with httpx";

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
            pythonWithPackages
          ];

          shellHook = ''
            echo "Python environment with httpx is ready!"
            echo "Python version: $(python --version)"
            echo "httpx installed: $(python -c 'import httpx; print(httpx.__version__)')"
          '';
        };
      }
    );
}
