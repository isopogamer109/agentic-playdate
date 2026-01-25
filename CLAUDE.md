# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A self-contained macOS development environment for Playdate handheld game development. The repo manages scripts, templates, and documentation while external dependencies (SDK, Homebrew packages) are installed separately via `install.sh`.

## Common Commands

### CLI Tools (after sourcing `setup-env.sh`)

```bash
pdbr                    # Build and run current project (finds source/, Source/, or src/)
pdwatch                 # Watch mode - auto-rebuild on file changes (requires fswatch)
pdsim                   # Launch Playdate Simulator
pdsim game.pdx          # Launch specific game
pdsim -e                # Browse SDK examples
pddevice                # Deploy to physical Playdate via USB
```

### Makefile Commands

```bash
make new-project NAME=MyGame                    # Create from basic template
make new-project NAME=MyGame TEMPLATE=crank-game  # Use specific template
make list-templates                             # Show available templates
make list-examples                              # Show example projects
make run-example EX=hello-world                 # Build and run an example
make clean                                      # Remove build artifacts (.pdx files)
```

### Building Manually

```bash
pdc source output.pdx                           # Compile Lua to .pdx bundle
open -a "$PLAYDATE_SDK_PATH/Playdate Simulator.app" output.pdx
```

## Architecture

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

Set by `setup-env.sh`:
- `PLAYDATE_SDK_PATH` → `$HOME/Developer/PlaydateSDK`
- `PLAYDATE_DEV_ROOT` → This repo's location
- `PLAYDATE_SIMULATOR` → Path to Simulator.app
