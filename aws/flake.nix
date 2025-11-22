{
  description = "AWS learning environment with CLI and Python SDK";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          boto3        # AWS SDK for Python (includes botocore automatically)
        ]);
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # AWS CLI (standalone)
            awscli2

            # Python with AWS SDK
            pythonEnv

            # Container & orchestration tools
            kubectl

            # Infrastructure as Code
            opentofu
          ];

          shellHook = ''
            echo "🚀 AWS Learning Environment Ready"
            echo ""
            echo "Available tools:"
            echo "  - aws (CLI v2)"
            echo "  - python3 with boto3"
            echo "  - kubectl, opentofu"
            echo ""
            echo "Quick start:"
            echo "  aws configure  # Set up credentials"
            echo "  python3        # Start Python REPL with boto3"
          '';
        };
      }
    );
}
