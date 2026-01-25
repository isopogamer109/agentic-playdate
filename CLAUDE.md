# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A cross-platform development environment for Playdate handheld game development. Supports **macOS**, **Linux**, and **Windows** (via Git Bash/MSYS2). The repo manages scripts, templates, and documentation while external dependencies (SDK, packages) are installed separately via `install.sh`.

## Platform Support

| Platform | Package Manager | File Watcher | SDK Location |
|----------|----------------|--------------|--------------|
| macOS | Homebrew | fswatch | `~/Developer/PlaydateSDK` |
| Linux (Debian/Ubuntu) | apt | inotify-tools | `~/PlaydateSDK` |
| Linux (Fedora) | dnf | inotify-tools | `~/PlaydateSDK` |
| Linux (Arch) | pacman | inotify-tools | `~/PlaydateSDK` |
| Windows (Git Bash) | Chocolatey/Winget | polling | `~/Documents/PlaydateSDK` |

## Common Commands

### CLI Tools (after sourcing `setup-env.sh`)

```bash
pdbr                    # Build and run current project (finds source/, Source/, or src/)
pdwatch                 # Watch mode - auto-rebuild on file changes
pdsim                   # Launch Playdate Simulator
pdsim game.pdx          # Launch specific game
pdsim -e                # Browse SDK examples
pdsim -i                # Show platform info
pddevice                # Deploy to physical Playdate via USB
playdate-info           # Show environment and platform details
```

### Makefile Commands

```bash
make new-project NAME=MyGame                    # Create from basic template
make new-project NAME=MyGame TEMPLATE=crank-game  # Use specific template
make list-templates                             # Show available templates
make list-examples                              # Show example projects
make run-example EX=hello-world                 # Build and run an example
make clean                                      # Remove build artifacts (.pdx files)
make platform-info                              # Show platform detection info
```

### Building Manually

```bash
pdc source output.pdx                           # Compile Lua to .pdx bundle

# macOS:
open -a "$PLAYDATE_SDK_PATH/Playdate Simulator.app" output.pdx

# Linux/Windows:
"$PLAYDATE_SDK_PATH/bin/PlaydateSimulator" output.pdx
```

## Architecture

### Cross-Platform Utilities

The `scripts/platform-utils.sh` file provides platform-agnostic functions:

- `detect_os` - Returns "macos", "linux", "wsl", or "windows"
- `get_default_sdk_path` - Platform-specific SDK location
- `open_simulator [pdx]` - Launch simulator on any platform
- `sed_inplace` - Cross-platform in-place sed
- `watch_directory` - Cross-platform file watching

### Playdate Game Structure

Games use Lua with Playdate's CoreLibs. Standard pattern:

```lua
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx <const> = playdate.graphics

function playdate.update()
    -- Main game loop: handle input, update state, render
    gfx.sprite.update()
end
```

### Sprite-Based OOP Pattern

Templates use Playdate's class system for game objects:

```lua
class('Player').extends(gfx.sprite)

function Player:init(x, y)
    Player.super.init(self)
    self:setImage(img)
    self:moveTo(x, y)
    self:setCollideRect(0, 0, w, h)
    self:add()
end

function Player:update()
    -- Per-frame update logic
end
```

### Screen Constants

Playdate has a fixed 1-bit 400x240 display:

```lua
local SCREEN_WIDTH <const> = 400
local SCREEN_HEIGHT <const> = 240
```

## Templates

- **basic** - D-pad movement starter
- **crank-game** - Crank as primary input mechanism
- **sprite-based** - Sprite classes with collision detection

Each template includes VS Code configuration for Lua language server and Playdate extension.

## Environment Variables

Set by `setup-env.sh` (paths vary by platform):

| Variable | macOS | Linux | Windows |
|----------|-------|-------|---------|
| `PLAYDATE_SDK_PATH` | `~/Developer/PlaydateSDK` | `~/PlaydateSDK` | `~/Documents/PlaydateSDK` |
| `PLAYDATE_DEV_ROOT` | This repo's location | Same | Same |
| `PLAYDATE_SIMULATOR` | `.../Playdate Simulator.app` | `.../bin/PlaydateSimulator` | `.../bin/PlaydateSimulator.exe` |

## Installation

### Quick Start (All Platforms)

```bash
# 1. Clone the repo
git clone <repo-url>
cd agentic-playdate

# 2. Run installer (detects your platform)
./install.sh

# 3. Add to shell config
# macOS (~/.zshrc):
source "/path/to/agentic-playdate/setup-env.sh"

# Linux/Windows (~/.bashrc):
source "/path/to/agentic-playdate/setup-env.sh"

# 4. Create a project
make new-project NAME=MyGame
cd MyGame
pdbr
```
