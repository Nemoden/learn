# Nix Learning Guide - From Zero to Hero

## How to Actually Learn Nix (Without Memorizing Everything)

### The Truth About Learning Nix

**You DON'T need to memorize everything!** Here's how experienced Nix users actually work:

1. **Search existing examples** (most common approach)
2. **Use interactive search tools** (search.nixos.org, nix repl)
3. **Copy and modify** working flakes
4. **Read package definitions** in nixpkgs to learn patterns

---

## Essential Tools & Resources

### 1. Package Search Tools

#### **search.nixos.org** ⭐ MOST IMPORTANT
- **URL**: https://search.nixos.org/packages
- **Use for**: Finding packages and their attribute names
- **Example**: Search "httpx" to find `python312Packages.httpx`

#### **Nix REPL** - Interactive Exploration
```bash
# Start the REPL
nix repl '<nixpkgs>'

# Then you can explore:
nix-repl> pkgs = import <nixpkgs> {}
nix-repl> pkgs.python312Packages.<TAB>  # Press TAB to autocomplete
nix-repl> pkgs.python312Packages.httpx
nix-repl> :q  # Quit
```

### 2. Flake Templates & Generators

#### **nix flake init** - Official Templates
```bash
# List available templates
nix flake show templates

# Initialize from a template
nix flake init -t templates#python

# Or create from scratch
nix flake init
```

#### **devenv.sh** ⭐ RECOMMENDED FOR BEGINNERS
- **URL**: https://devenv.sh
- **Why**: Much simpler than raw flakes for dev environments
- **Features**: Pre-configured languages, services, and tools

```bash
# Install devenv
nix profile install nixpkgs#devenv

# Create a new project
devenv init
```

#### **flake.parts** - Modular Flakes
- **URL**: https://flake.parts
- **For**: Organizing complex flakes into modules
- **When**: After you're comfortable with basic flakes

### 3. Documentation

#### **Official Nix Manual**
- **URL**: https://nixos.org/manual/nix/stable/
- **Focus on**:
  - Quick Start
  - Flakes section
  - nix develop command

#### **NixOS Wiki**
- **URL**: https://nixos.wiki/
- **Use for**: Practical examples and common patterns
- **Search**: "python development", "nodejs flake", etc.

#### **Nix Pills** (Deep Dive)
- **URL**: https://nixos.org/guides/nix-pills/
- **Warning**: Very detailed, read selectively
- **Best for**: Understanding how Nix works internally

#### **Zero to Nix**
- **URL**: https://zero-to-nix.com/
- **Best for**: Quick start guide for beginners

---

## Learning Path (Progressive)

### Week 1: Basic Flakes
- [ ] Create a simple flake with one package
- [ ] Use `nix develop` to enter the shell
- [ ] Understand inputs and outputs
- [ ] Add environment variables in shellHook

### Week 2: Language-Specific Environments
- [ ] Create Python environment with packages
- [ ] Create Node.js environment
- [ ] Learn about `withPackages` pattern
- [ ] Try multiple language environments

### Week 3: Advanced Features
- [ ] Use multiple inputs (overlays)
- [ ] Create custom packages
- [ ] Understand derivations
- [ ] Use `buildInputs` vs `nativeBuildInputs`

### Week 4: Real Projects
- [ ] Convert existing project to Nix
- [ ] Add services (PostgreSQL, Redis)
- [ ] Create custom scripts
- [ ] Share flake with team

---

## Practical Workflow - How to Write a Flake

### Step 1: Find Examples
```bash
# Search GitHub for similar projects
https://github.com/search?q=flake.nix+python+httpx

# Look at popular flake templates
https://github.com/nix-community/awesome-nix#templates
```

### Step 2: Search for Packages
```bash
# On search.nixos.org
1. Search "python httpx"
2. Note the attribute: python312Packages.httpx
3. Use in your flake

# Or use nix search
nix search nixpkgs python312Packages.httpx
```

### Step 3: Build Incrementally
```bash
# Start with minimal flake
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  outputs = { nixpkgs, ... }: {
    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      packages = [ nixpkgs.legacyPackages.x86_64-linux.hello ];
    };
  };
}

# Then add flake-utils for multi-platform
# Then add more packages
# Then add shellHook
# etc.
```

### Step 4: Test Frequently
```bash
# Check flake syntax
nix flake check

# Enter the dev shell
nix develop

# See what's in the shell
nix develop --command env | grep -E 'PATH|PYTHON'

# Debug with verbose output
nix develop --show-trace
```

---

## Common Patterns (Copy These!)

### Python Development
```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python312;
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            (python.withPackages (ps: [ ps.httpx ps.pytest ]))
          ];
        };
      });
}
```

### Node.js Development
```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { nixpkgs, ... }: {
    devShells.x86_64-darwin.default =
      let pkgs = nixpkgs.legacyPackages.x86_64-darwin;
      in pkgs.mkShell {
        packages = [ pkgs.nodejs_20 pkgs.yarn ];
      };
  };
}
```

### Multiple Languages
```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { nixpkgs, ... }: {
    devShells.x86_64-darwin.default =
      let pkgs = nixpkgs.legacyPackages.x86_64-darwin;
      in pkgs.mkShell {
        packages = [
          pkgs.nodejs_20
          pkgs.python312
          pkgs.go
          pkgs.rustc
          pkgs.cargo
        ];
      };
  };
}
```

---

## Cheat Sheet - Common Commands

### Flake Operations
```bash
# Initialize new flake
nix flake init

# Update flake.lock
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# Show flake info
nix flake show

# Check flake for errors
nix flake check
```

### Development Shell
```bash
# Enter dev shell
nix develop

# Run command in shell without entering
nix develop --command python --version

# Use specific flake from GitHub
nix develop github:owner/repo

# Print shell environment
nix print-dev-env
```

### Package Search
```bash
# Search packages
nix search nixpkgs python

# Search with regex
nix search nixpkgs '^python3.*httpx'

# Show package info
nix eval nixpkgs#python312Packages.httpx
```

### Debugging
```bash
# Show detailed error traces
nix develop --show-trace

# Evaluate expression
nix eval '.#devShells.x86_64-darwin.default'

# Build derivation (test without entering)
nix build '.#devShells.x86_64-darwin.default'
```

---

## Pro Tips

### 1. Use direnv for Automatic Loading
```bash
# In your project root
echo "use flake" > .envrc
direnv allow
```

### 2. Pin Nixpkgs Version
Always specify a version (never use just `github:NixOS/nixpkgs`):
- `nixos-24.11` - Stable (recommended)
- `nixos-unstable` - Latest packages (may break)

### 3. Read Other People's Flakes
Best way to learn is reading real projects:
- https://github.com/nix-community/awesome-nix
- https://github.com/topics/nix-flakes

### 4. Use nix repl for Experimentation
```bash
nix repl
nix-repl> :l <nixpkgs>
nix-repl> pkgs.lib.version  # Explore functions
nix-repl> :t map  # Show type of function
```

### 5. Cache Common Patterns
Keep a personal collection of flake snippets for:
- Python + PostgreSQL
- Node.js + Redis
- Rust development
- Go development

---

## Troubleshooting Common Issues

### "error: experimental feature 'nix-command' is not enabled"
```bash
# Add to ~/.config/nix/nix.conf
experimental-features = nix-command flakes
```

### "could not find package X"
1. Search on search.nixos.org
2. Check if package name changed
3. Try different nixpkgs version

### Package works on Linux but not macOS
- Check package is available for darwin
- On search.nixos.org, filter by platform
- Some packages are Linux-only

### Build fails with unclear error
```bash
# Use --show-trace for full error
nix develop --show-trace

# Check recent nixpkgs changes
https://github.com/NixOS/nixpkgs/issues
```

---

## Community & Help

- **Discourse**: https://discourse.nixos.org/
- **Reddit**: r/NixOS
- **Discord**: https://discord.gg/RbvHtGa
- **Matrix**: #nix:nixos.org
- **GitHub Discussions**: https://github.com/NixOS/nixpkgs/discussions

---

## Summary - You DON'T Need to Memorize!

**What to actually remember:**
1. Basic flake structure (inputs → outputs)
2. How to search for packages (search.nixos.org)
3. `nix develop` to enter shell
4. `nix flake update` to update dependencies

**Everything else:**
- Copy from examples
- Search when needed
- Use tools (search, repl, templates)
- Read other flakes

**The Nix way**: Compose existing solutions, don't reinvent the wheel!
