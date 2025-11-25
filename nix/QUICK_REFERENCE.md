# Nix Flakes - Quick Reference Card

## The Minimal Flake (Copy This!)

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { nixpkgs, ... }: {
    devShells.aarch64-darwin.default =
      let pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      in pkgs.mkShell {
        packages = [ pkgs.hello ];
      };
  };
}
```

## Essential Commands (Memorize These 5)

```bash
nix develop              # Enter dev shell
nix flake update         # Update dependencies
nix flake check          # Validate flake
nix search nixpkgs NAME  # Find packages
nix repl '<nixpkgs>'     # Explore interactively
```

## Package Search Workflow

1. **Google**: "nix package NAME" → usually lands on search.nixos.org
2. **search.nixos.org**: Official package search
3. **Copy the attribute**: e.g., `python312Packages.httpx`
4. **Use in flake**: Add to packages list

## Common Attributes

```nix
pkgs.python312                 # Python interpreter
pkgs.python312Packages.httpx   # Python package
pkgs.nodejs_20                 # Node.js
pkgs.rustc                     # Rust compiler
pkgs.go                        # Go compiler
pkgs.postgresql_16             # PostgreSQL
pkgs.redis                     # Redis
pkgs.docker                    # Docker
pkgs.git                       # Git
```

## Nix Language Syntax (5-Minute Version)

```nix
# Attribute sets (like objects)
{ a = 1; b = 2; }

# Lists (space-separated, NOT commas!)
[ 1 2 3 ]
[ pkgs.git pkgs.vim ]

# Functions
x: x + 1                    # Single arg
{ a, b }: a + b             # Destructuring
{ a, b, ... }: a + b        # With extra args

# Let bindings
let x = 1; y = 2; in x + y

# With statement (import scope)
with pkgs; [ git vim ]      # Instead of [ pkgs.git pkgs.vim ]

# String interpolation
"Hello ${name}"
"${pkgs.hello}/bin/hello"

# Comments
# Single line
/* Multi
   line */
```

## Your System Architecture

Run this to find your system:
```bash
nix eval --impure --expr 'builtins.currentSystem'
```

Common values:
- `x86_64-linux` - Intel/AMD Linux
- `aarch64-linux` - ARM Linux
- `x86_64-darwin` - Intel Mac
- `aarch64-darwin` - Apple Silicon Mac (M1/M2/M3)

## Multi-Platform Support (Use flake-utils)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = [ pkgs.hello ];
        };
      });
}
```

## direnv Integration

```bash
# In project root
echo "use flake" > .envrc
direnv allow

# Now cd into directory auto-loads the environment!
```

## Debugging Checklist

1. **Flake not loading?**
   ```bash
   nix flake check --show-trace
   ```

2. **Package not found?**
   - Search on search.nixos.org
   - Try `nix search nixpkgs <package>`

3. **Want to see what's available?**
   ```bash
   nix repl '<nixpkgs>'
   nix-repl> pkgs.<TAB>  # Autocomplete!
   ```

4. **Need to rebuild?**
   ```bash
   nix flake update
   nix develop --refresh
   ```

## 3 Most Useful Resources

1. **search.nixos.org** - Find any package
2. **nixos.wiki** - Practical examples
3. **GitHub** - Search "flake.nix <language>" for examples

## Remember

**You don't need to memorize everything!**

- 90% of the time: copy existing flakes
- 9% of the time: search for packages
- 1% of the time: read docs

The Nix community shares everything. Just search, copy, and adapt!
