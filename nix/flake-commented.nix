# ============================================================================
# NIX FLAKE - COMPREHENSIVE GUIDE
# ============================================================================
# A flake is Nix's modern way to define reproducible development environments,
# packages, and NixOS configurations. Think of it like package.json for npm
# or Cargo.toml for Rust, but much more powerful.

{
  # --------------------------------------------------------------------------
  # 1. DESCRIPTION (Optional but recommended)
  # --------------------------------------------------------------------------
  # A human-readable description of what this flake provides
  description = "Python development environment with httpx";

  # --------------------------------------------------------------------------
  # 2. INPUTS - External Dependencies
  # --------------------------------------------------------------------------
  # Inputs are other flakes or repositories that your flake depends on.
  # Think of these as your "dependencies" section in package.json
  inputs = {
    # nixpkgs: The main Nix packages repository (like npm registry)
    # - "github:NixOS/nixpkgs" means get it from GitHub
    # - "nixos-24.11" is the branch/tag (stable release from 2024 November)
    # - You could also use "nixos-unstable" for bleeding edge packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    # flake-utils: A helper library to reduce boilerplate
    # - Makes it easy to support multiple systems (Linux, macOS, etc.)
    # - Without this, you'd need to write code for each system manually
    flake-utils.url = "github:numtide/flake-utils";
  };

  # --------------------------------------------------------------------------
  # 3. OUTPUTS - What This Flake Produces
  # --------------------------------------------------------------------------
  # Outputs is a function that takes inputs and returns what this flake provides
  # The parameters here ({ self, nixpkgs, flake-utils }) correspond to the inputs above
  # - self: Reference to this flake itself
  # - nixpkgs: The nixpkgs input we defined
  # - flake-utils: The flake-utils input we defined
  outputs = { self, nixpkgs, flake-utils }:
    # -----------------------------------------------------------------------
    # flake-utils.lib.eachDefaultSystem - Multi-Platform Support
    # -----------------------------------------------------------------------
    # This is a convenience function that runs the code for each system
    # Default systems: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin
    # Without this, you'd need to manually specify configs for each platform
    flake-utils.lib.eachDefaultSystem (system:
      # ---------------------------------------------------------------------
      # LET...IN - Local Variable Bindings
      # ---------------------------------------------------------------------
      # The "let...in" block allows you to define local variables
      # Everything between "let" and "in" is a definition
      # Everything after "in" is the actual result/output
      let
        # Get the nixpkgs package set for the current system
        # legacyPackages contains all the packages (100,000+ packages!)
        # ${system} is string interpolation (like `${variable}` in JS)
        pkgs = nixpkgs.legacyPackages.${system};

        # Select Python 3.12 from the available packages
        # You could also use: pkgs.python311, pkgs.python310, etc.
        # This is just a shorthand to avoid typing pkgs.python312 repeatedly
        python = pkgs.python312;

        # Create a Python environment WITH packages installed
        # - python.withPackages is a function that takes a function as argument
        # - (ps: with ps; [...]) is an anonymous function:
        #   - ps: Python package set (all available Python packages)
        #   - with ps: brings all ps attributes into scope (like import * in Python)
        #   - [...]: list of packages to install
        pythonWithPackages = python.withPackages (ps: with ps; [
          pip    # Python package installer
          httpx  # Modern HTTP client library
          # You can add more packages here, like:
          # requests
          # pytest
          # black
        ]);

      # ---------------------------------------------------------------------
      # IN - The Actual Output
      # ---------------------------------------------------------------------
      in
      {
        # What outputs can a flake have?
        # - packages: Installable packages (nix build, nix run)
        # - devShells: Development environments (nix develop)
        # - apps: Runnable applications (nix run)
        # - nixosConfigurations: NixOS system configs
        # - overlays: Package modifications/additions
        # - modules: Reusable NixOS/home-manager modules

        # ===================================================================
        # devShells.default - Development Environment
        # ===================================================================
        # This creates a shell environment with all your dev tools
        # Usage: nix develop (or direnv loads it automatically)
        devShells.default = pkgs.mkShell {
          # -----------------------------------------------------------------
          # buildInputs - Packages Available in the Shell
          # -----------------------------------------------------------------
          # Everything listed here will be available in your PATH
          # when you enter the shell
          buildInputs = [
            pythonWithPackages  # Our Python with packages
            # You can add more tools here:
            # pkgs.nodejs
            # pkgs.git
            # pkgs.postgresql
          ];

          # -----------------------------------------------------------------
          # shellHook - Script Run When Entering the Shell
          # -----------------------------------------------------------------
          # This bash script runs every time you enter the dev shell
          # Useful for:
          # - Setting environment variables
          # - Printing welcome messages
          # - Running setup commands
          shellHook = ''
            # These are bash commands
            echo "Python environment with httpx is ready!"
            echo "Python version: $(python --version)"
            echo "httpx installed: $(python -c 'import httpx; print(httpx.__version__)')"

            # You could also do:
            # export DATABASE_URL="postgresql://localhost/mydb"
            # export PYTHONPATH="$PWD/src:$PYTHONPATH"
          '';

          # Other useful mkShell options you might use:
          # -----------------------------------------------------------------
          # packages = [...];  # Alternative to buildInputs (newer style)
          # nativeBuildInputs = [...];  # Build-time only dependencies
          # shellHook = "...";  # We already saw this
          # env = { VAR = "value"; };  # Set environment variables (structured)
          # stdenv = pkgs.clangStdenv;  # Use different compiler toolchain
        };

        # You could add more outputs here:
        # ---------------------------------------------------------------
        # packages.myapp = pkgs.writeShellScriptBin "myapp" ''
        #   echo "Hello from myapp"
        # '';
        #
        # apps.default = {
        #   type = "app";
        #   program = "${self.packages.${system}.myapp}/bin/myapp";
        # };
      }
    );
}

# ============================================================================
# KEY CONCEPTS TO REMEMBER
# ============================================================================
#
# 1. NURL (Nix URL): Format for referencing flakes
#    - github:owner/repo
#    - github:owner/repo/branch
#    - path:/absolute/path
#    - git+https://...
#
# 2. ATTRIBUTE SETS: Like objects/dictionaries
#    { a = 1; b = 2; }
#    Access with: set.a or set."a"
#
# 3. FUNCTIONS: Can be defined multiple ways
#    - arg: body              # Single argument
#    - { a, b }: body         # Pattern matching (like destructuring)
#    - { a, b, ... }: body    # With extra args allowed
#
# 4. LET...IN: Local bindings
#    let x = 1; y = 2; in x + y
#
# 5. WITH: Bring attributes into scope
#    with pkgs; [ git nodejs ]
#    # Instead of: [ pkgs.git pkgs.nodejs ]
#
# 6. STRING INTERPOLATION: ${...}
#    "Hello ${name}"
#    Paths: "${pkgs.hello}/bin/hello"
#
# 7. LISTS: Space-separated (NOT comma-separated!)
#    [ 1 2 3 ]
#    [ pkgs.git pkgs.vim ]
#
# 8. DERIVATIONS: Instructions to build something
#    - mkShell creates a shell derivation
#    - stdenv.mkDerivation creates a package
#    - Every package in nixpkgs is a derivation
#
# ============================================================================
