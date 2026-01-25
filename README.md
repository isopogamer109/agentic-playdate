# Playdate Development Environment

A cross-platform development environment for Playdate handheld game development. Supports **macOS**, **Linux**, and **Windows** (via Git Bash/MSYS2).

## Features

- **Cross-platform** - Works on macOS, Linux (Debian/Ubuntu, Fedora, Arch), and Windows
- **Minimal installer** - Only installs external dependencies (SDK, packages)
- **Self-contained** - Scripts, templates, and docs live in this repo
- **Project templates** - Quickly scaffold new games
- **Helper scripts** - Build, run, watch, deploy commands
- **Examples** - Learn from working code

## Platform Support

| Platform | Package Manager | File Watcher | SDK Location |
|----------|----------------|--------------|--------------|
| macOS | Homebrew | fswatch | `~/Developer/PlaydateSDK` |
| Linux (Debian/Ubuntu) | apt | inotify-tools | `~/PlaydateSDK` |
| Linux (Fedora) | dnf | inotify-tools | `~/PlaydateSDK` |
| Linux (Arch) | pacman | inotify-tools | `~/PlaydateSDK` |
| Windows (Git Bash) | Chocolatey/Winget | polling | `~/Documents/PlaydateSDK` |

## Quick Start

```bash
# 1. Clone this repo
git clone <repo-url> playdate-dev
cd playdate-dev

# 2. Run the installer (detects your platform)
./install.sh

# 3. Add to your shell config
# macOS (~/.zshrc):
source "/path/to/playdate-dev/setup-env.sh"

# Linux/Windows (~/.bashrc):
source "/path/to/playdate-dev/setup-env.sh"

# 4. Reload shell
source ~/.zshrc   # or ~/.bashrc

# 5. Create a new project
make new-project NAME=MyGame
cd MyGame
pdbr  # Build and run!
```

## Directory Structure

```
playdate-dev/
├── install.sh           # Installs external dependencies (cross-platform)
├── setup-env.sh         # Source this in your shell config
├── Makefile             # Project creation and utilities
├── scripts/             # CLI tools (added to PATH)
│   ├── pdsim            # Simulator launcher
│   ├── pdbr             # Build and run
│   ├── pdwatch          # Watch mode (auto-rebuild)
│   ├── pddevice         # Deploy to physical Playdate
│   └── platform-utils.sh # Cross-platform utility functions
├── templates/           # Project templates
│   ├── basic/           # Simple D-pad movement starter
│   ├── crank-game/      # Crank-focused game
│   └── sprite-based/    # Sprite system with collisions
├── examples/            # Learning examples
│   ├── hello-world/
│   ├── crank-demo/
│   └── sprite-animation/
└── docs/
    ├── setup-guide.md   # Detailed setup instructions
    └── agent-prompts.md # AI assistant prompts
```

## Commands

After sourcing `setup-env.sh`:

| Command | Description |
|---------|-------------|
| `pdsim` | Launch Playdate Simulator |
| `pdsim game.pdx` | Launch specific game |
| `pdsim -e` | Browse SDK examples |
| `pdsim -i` | Show platform info |
| `pdbr` | Build and run current project |
| `pdwatch` | Watch mode (auto-rebuild on save) |
| `pddevice` | Deploy to physical Playdate |
| `playdate-info` | Show environment and platform details |

## Makefile Commands

```bash
make help                           # Show all commands
make new-project NAME=MyGame        # Create from basic template
make new-project NAME=MyGame TEMPLATE=crank-game
make list-templates                 # Show available templates
make list-examples                  # Show example projects
make run-example EX=hello-world     # Build and run an example
make clean                          # Remove build artifacts (.pdx files)
make platform-info                  # Show platform detection info
```

## Templates

| Template | Description |
|----------|-------------|
| `basic` | Simple D-pad movement starter |
| `crank-game` | Crank as primary input |
| `sprite-based` | Sprite system with collisions |

## Environment Variables

Set by `setup-env.sh` (paths vary by platform):

| Variable | Description |
|----------|-------------|
| `PLAYDATE_SDK_PATH` | Path to the Playdate SDK |
| `PLAYDATE_DEV_ROOT` | Path to this repository |
| `PLAYDATE_SIMULATOR` | Path to the simulator executable |

## Updating

```bash
cd playdate-dev
git pull  # Get latest scripts, templates, examples
```

No reinstall needed - just pull and go.

## Requirements

- **macOS**: macOS 10.15+ (Apple Silicon or Intel)
- **Linux**: Debian/Ubuntu, Fedora, Arch, or compatible distributions
- **Windows**: Git Bash or MSYS2 environment

The installer will set up:
- Playdate SDK
- Required packages (via your platform's package manager)
- VS Code extensions (recommended IDE)

## License

MIT
