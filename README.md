# Playdate Development Environment

A self-contained development environment for Playdate game development on macOS.

## Features

- **Minimal installer** - Only installs external dependencies (SDK, Homebrew packages)
- **Self-contained** - Scripts, templates, and docs live in this repo
- **Project templates** - Quickly scaffold new games
- **Helper scripts** - Build, run, watch, deploy commands
- **Examples** - Learn from working code

## Quick Start

```bash
# 1. Clone this repo
git clone <repo-url> playdate-dev
cd playdate-dev

# 2. Run the installer (installs SDK and dependencies)
./install.sh

# 3. Add to your shell config (~/.zshrc)
source "/path/to/playdate-dev/setup-env.sh"

# 4. Reload shell
source ~/.zshrc

# 5. Create a new project
make new-project NAME=MyGame
cd MyGame
pdbr  # Build and run!
```

## Directory Structure

```
playdate-dev/
├── install.sh          # Installs external dependencies only
├── setup-env.sh        # Source this in your shell config
├── Makefile            # Project creation and utilities
├── scripts/            # CLI tools (added to PATH)
│   ├── pdsim           # Simulator launcher
│   ├── pdbr            # Build and run
│   ├── pdwatch         # Watch mode (auto-rebuild)
│   └── pddevice        # Deploy to physical Playdate
├── templates/          # Project templates
│   ├── basic/          # Simple starter
│   ├── crank-game/     # Crank-focused game
│   └── sprite-based/   # Sprite system demo
├── examples/           # Learning examples
│   ├── hello-world/
│   ├── crank-demo/
│   └── sprite-animation/
└── docs/
    ├── setup-guide.md  # Detailed setup instructions
    └── agent-prompts.md # AI assistant prompts
```

## Commands

After sourcing `setup-env.sh`:

| Command | Description |
|---------|-------------|
| `pdsim` | Launch Playdate Simulator |
| `pdsim game.pdx` | Launch specific game |
| `pdsim -e` | Browse SDK examples |
| `pdbr` | Build and run current project |
| `pdwatch` | Watch mode (auto-rebuild on save) |
| `pddevice` | Deploy to physical Playdate |
| `playdate-new MyGame` | Create project from template |
| `playdate-docs` | Open SDK documentation |

## Makefile Commands

```bash
make help                           # Show all commands
make new-project NAME=MyGame        # Create from basic template
make new-project NAME=MyGame TEMPLATE=crank-game
make list-templates                 # Show available templates
make list-examples                  # Show example projects
make run-example EX=hello-world     # Build and run an example
```

## Templates

| Template | Description |
|----------|-------------|
| `basic` | Simple D-pad movement starter |
| `crank-game` | Crank as primary input |
| `sprite-based` | Sprite system with collisions |

## Updating

```bash
cd playdate-dev
git pull  # Get latest scripts, templates, examples
```

No reinstall needed - just pull and go.

## Requirements

- macOS (Apple Silicon or Intel)
- Playdate SDK (installed by `install.sh`)
- Homebrew (installed by `install.sh`)

## License

MIT
