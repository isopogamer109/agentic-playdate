# Playdate Game Development Setup Guide

## Cross-Platform Support: macOS, Linux, and Windows

---

## Table of Contents
1. [Overview](#overview)
2. [System Requirements](#system-requirements)
3. [Platform-Specific Setup](#platform-specific-setup)
   - [macOS Setup](#macos-setup)
   - [Linux Setup](#linux-setup)
   - [Windows Setup](#windows-setup)
4. [Install the Playdate SDK](#install-the-playdate-sdk)
5. [Configure Extensions](#configure-extensions)
6. [Configure the Development Environment](#configure-the-development-environment)
7. [Create Your First Project](#create-your-first-project)
8. [Using Claude Code in Terminal](#using-claude-code-in-terminal)
9. [Playdate Development Quick Reference](#playdate-development-quick-reference)
10. [Game Ideas to Get Started](#game-ideas-to-get-started)
11. [Troubleshooting](#troubleshooting)

---

## Overview

This guide walks you through setting up a complete Playdate development environment on **macOS**, **Linux**, or **Windows**.

### What is Playdate?

Playdate is a unique handheld gaming console by Panic featuring:
- 400 x 240 pixel **1-bit monochrome** display (black and white only)
- **Crank** - a unique rotating input mechanism
- D-pad and A/B buttons
- Accelerometer
- Built-in speaker and microphone
- WiFi and Bluetooth connectivity
- 16MB RAM, 4GB storage

---

## System Requirements

### All Platforms
- At least 8GB RAM recommended
- 10GB free disk space
- Git installed

### macOS
- macOS on Apple Silicon (M1/M2/M3) or Intel
- **Homebrew** (will be installed automatically)

### Linux
- Ubuntu 20.04+, Debian 11+, Fedora 35+, or Arch Linux
- One of: **apt**, **dnf**, or **pacman** package manager
- **inotify-tools** for file watching (installed automatically)

### Windows
- Windows 10 or later
- **Git Bash** or **MSYS2** (required for bash scripts)
- Optional: **Chocolatey** or **winget** for package management

---

## Platform-Specific Setup

### macOS Setup

1. **Install Homebrew** (if not already installed):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Clone and run the installer**:
   ```bash
   git clone <repo-url> ~/Developer/agentic-playdate
   cd ~/Developer/agentic-playdate
   ./install.sh
   ```

3. **Add to shell configuration** (`~/.zshrc`):
   ```bash
   source "$HOME/Developer/agentic-playdate/setup-env.sh"
   ```

4. **Reload shell**:
   ```bash
   source ~/.zshrc
   ```

### Linux Setup

1. **Install prerequisites**:

   **Debian/Ubuntu:**
   ```bash
   sudo apt update
   sudo apt install git curl unzip
   ```

   **Fedora:**
   ```bash
   sudo dnf install git curl unzip
   ```

   **Arch Linux:**
   ```bash
   sudo pacman -S git curl unzip
   ```

2. **Clone and run the installer**:
   ```bash
   git clone <repo-url> ~/agentic-playdate
   cd ~/agentic-playdate
   ./install.sh
   ```

3. **Add to shell configuration** (`~/.bashrc`):
   ```bash
   source "$HOME/agentic-playdate/setup-env.sh"
   ```

4. **Reload shell**:
   ```bash
   source ~/.bashrc
   ```

### Windows Setup

1. **Install Git Bash**:
   - Download from https://git-scm.com/download/win
   - Install with default options (make sure "Git Bash" is selected)

2. **Optional: Install Chocolatey** (for automatic Node.js installation):
   - Open PowerShell as Administrator
   - Run: `Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))`

3. **Clone and run the installer** (in Git Bash):
   ```bash
   git clone <repo-url> ~/Documents/agentic-playdate
   cd ~/Documents/agentic-playdate
   ./install.sh
   ```

4. **Add to shell configuration** (`~/.bashrc` in Git Bash):
   ```bash
   source "$HOME/Documents/agentic-playdate/setup-env.sh"
   ```

5. **Reload Git Bash** or restart the terminal.

---

## Install the Playdate SDK

The `install.sh` script will guide you through SDK installation. The SDK is downloaded from https://play.date/dev/ and installed to:

| Platform | SDK Location |
|----------|--------------|
| macOS | `~/Developer/PlaydateSDK` |
| Linux | `~/PlaydateSDK` |
| Windows | `~/Documents/PlaydateSDK` |

### Verify Installation

```bash
# Check pdc compiler
pdc --version

# Show platform info
playdate-info

# Launch simulator (if SDK is installed)
pdsim
```

---

## Configure Extensions

### VS Code (Recommended - Cross-Platform)

**Install VS Code**: Download from https://code.visualstudio.com/ for your platform.

Open the Extensions panel (`Cmd/Ctrl + Shift + X`) and install:

| Extension | Purpose |
|-----------|---------|
| **sumneko.lua** | Lua language server (autocomplete, linting) |
| **Orta.playdate** | Playdate SDK integration |
| **midouest.playdate-debug** | Debugger for Playdate (optional) |

---

## Configure the Development Environment

### Workspace Settings

Each template includes `.vscode/settings.json` with Lua configuration:

```json
{
  "Lua.runtime.version": "Lua 5.4",
  "Lua.diagnostics.globals": ["playdate", "import", "class"],
  "Lua.workspace.library": ["${env:PLAYDATE_SDK_PATH}/CoreLibs"],
  "playdate.sdkPath": "${env:PLAYDATE_SDK_PATH}"
}
```

### Build Tasks

Templates include cross-platform VS Code tasks:

- **Playdate: Build** - Compile Lua to .pdx
- **Playdate: Run** - Launch in simulator (cross-platform)
- **Playdate: Build and Run** - Both (default task)
- **Playdate: Watch** - Auto-rebuild on file changes

Use `Cmd/Ctrl + Shift + B` to run the default build task.

---

## Create Your First Project

### Using Make

```bash
# Create from basic template
make new-project NAME=MyGame

# Create from specific template
make new-project NAME=MyGame TEMPLATE=crank-game

# List available templates
make list-templates
```

### Using Shell Function

```bash
# After sourcing setup-env.sh
playdate-new MyGame
playdate-new MyGame crank-game  # with specific template
```

### Build and Run

```bash
cd MyGame
pdbr          # Build and run
pdwatch       # Watch mode (auto-rebuild)
```

---

## Using Claude Code in Terminal

### Install Claude Code

```bash
# Install via npm (requires Node.js)
npm install -g @anthropic/claude-code

# Or via Homebrew (macOS)
brew install claude-code
```

### Usage

Navigate to your project directory and start Claude Code:

```bash
cd MyGame
claude-code
```

**Example prompts:**

```
# Get help with Playdate APIs
What are the different ways to draw shapes in Playdate?

# Generate code
Create a crank-controlled menu system for Playdate with 5 options

# Debug issues
Why isn't my sprite showing up? Here's my code: [paste code]
```

---

## Playdate Development Quick Reference

### Display Specifications

| Property | Value |
|----------|-------|
| Resolution | 400 x 240 pixels |
| Color Depth | 1-bit (black/white only) |
| Default FPS | 30 fps (max 50 fps) |

### Input Constants

```lua
-- Buttons
playdate.kButtonA
playdate.kButtonB
playdate.kButtonUp, playdate.kButtonDown
playdate.kButtonLeft, playdate.kButtonRight

-- Button functions
playdate.buttonIsPressed(button)     -- Held down
playdate.buttonJustPressed(button)   -- Just this frame
playdate.buttonJustReleased(button)  -- Released this frame

-- Crank
playdate.getCrankPosition()    -- Absolute angle (0-359.9999)
playdate.getCrankChange()      -- Delta since last frame
playdate.isCrankDocked()       -- Is crank folded in?
```

### Essential Graphics Functions

```lua
local gfx <const> = playdate.graphics

-- Screen
gfx.clear()
gfx.setBackgroundColor(gfx.kColorBlack)

-- Drawing
gfx.drawRect(x, y, w, h)
gfx.fillRect(x, y, w, h)
gfx.drawCircleAtPoint(x, y, r)
gfx.fillCircleAtPoint(x, y, r)
gfx.drawLine(x1, y1, x2, y2)

-- Text
gfx.drawText(text, x, y)
gfx.drawTextAligned(text, x, y, alignment)

-- Images
local img = gfx.image.new("images/myImage")
img:draw(x, y)
```

### Sprite System

```lua
import "CoreLibs/sprites"

local playerImage = gfx.image.new("images/player")
local playerSprite = gfx.sprite.new(playerImage)
playerSprite:moveTo(200, 120)
playerSprite:add()

-- In update()
gfx.sprite.update()
```

---

## Game Ideas to Get Started

### Beginner Projects

1. **Pong Clone** - Two paddles, crank control
2. **Snake** - D-pad direction, crank speed
3. **Breakout** - Crank-controlled paddle

### Intermediate Projects

4. **Top-Down Shooter** - Sprite-based, crank aiming
5. **Platformer** - Gravity, jumping, collision
6. **Puzzle Game** - Grid-based mechanics

---

## Troubleshooting

### All Platforms

**"pdc not found"**
- Ensure `PLAYDATE_SDK_PATH` is set correctly
- Run `playdate-info` to verify environment
- Re-source your shell config

**"Simulator won't launch"**
- Check that the `.pdx` file was created
- Verify no syntax errors in Lua files
- Run `pdsim -i` to check simulator path

### Linux-Specific

**"Permission denied" for USB device**
- Add udev rules for Playdate
- Try `sudo pddevice` for device operations

**"inotifywait not found"**
- Install: `sudo apt install inotify-tools`

### Windows-Specific

**"Scripts not running"**
- Make sure you're using Git Bash, not CMD or PowerShell
- Verify Git Bash installed correctly

**"File watching slow"**
- Windows uses polling mode (every 2 seconds)
- Consider using WSL for better performance

### macOS-Specific

**"App can't be opened" (Gatekeeper)**
- The installer runs `xattr` to remove quarantine
- If needed: `xattr -dr com.apple.quarantine "$PLAYDATE_SDK_PATH/Playdate Simulator.app"`

---

## Summary

You now have a cross-platform Playdate development environment with:

1. Playdate SDK installed and configured
2. IDE with Lua support
3. Cross-platform build/run scripts
4. Templates for quick project creation

**Start building!** The best way to learn is to experiment. Start simple, use the tools to help, and iterate.

Remember:
- Test frequently in the Simulator
- The 1-bit display requires thoughtful design
- The crank is your unique advantage - use it creatively!

Happy coding!
