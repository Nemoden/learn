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
          boto3-stubs  # otherwise boto3 is PITA to use
          pip          # Python package installer
        ]);
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Python with AWS SDK
            pythonEnv

            # Container & orchestration tools
            kubectl

            # Infrastructure as Code
            opentofu
            aws-sam-cli
          ];

          shellHook = ''
            echo "🚀 AWS Learning Environment Ready"
            echo ""
            echo "Available tools:"
            echo "  - aws (CLI v2)"
            echo "  - sam (Serverless Application Model CLI)"
            echo "  - python3 with boto3 and pip"
            echo "  - kubectl, opentofu"
            echo ""
            echo "Quick start:"
            echo "  aws configure  # Set up credentials"
            echo "  sam init       # Create serverless project"
            echo "  python3        # Start Python REPL with boto3"
          '';
        };
      }
    );
}
