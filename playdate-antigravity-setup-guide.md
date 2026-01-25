# Playdate Game Development Setup Guide
## Using Google Antigravity IDE on Mac M3 Pro

---

## Table of Contents
1. [Overview](#overview)
2. [System Requirements](#system-requirements)
3. [Step 1: Install the Playdate SDK](#step-1-install-the-playdate-sdk)
4. [Step 2: Install Google Antigravity IDE](#step-2-install-google-antigravity-ide)
5. [Step 3: Configure Extensions](#step-3-configure-extensions)
6. [Step 4: Configure the Development Environment](#step-4-configure-the-development-environment)
7. [Step 5: Create Your First Project](#step-5-create-your-first-project)
8. [Step 6: Using the Agent Manager & Eye Agent](#step-6-using-the-agent-manager--eye-agent)
9. [Step 7: Using Claude Code in Terminal](#step-7-using-claude-code-in-terminal)
10. [Playdate Development Quick Reference](#playdate-development-quick-reference)
11. [Game Ideas to Get Started](#game-ideas-to-get-started)

---

## Overview

This guide walks you through setting up a complete Playdate development environment using:

- **Playdate SDK** - Panic's official development kit for the Playdate handheld console
- **Google Antigravity IDE** - Google's AI-powered "agent-first" development platform (a VS Code fork with powerful AI agents)
- **Claude Code** - Anthropic's terminal-based AI coding assistant

### What is Playdate?

Playdate is a unique handheld gaming console by Panic featuring:
- 400 × 240 pixel **1-bit monochrome** display (black and white only)
- **Crank** - a unique rotating input mechanism
- D-pad and A/B buttons
- Accelerometer
- Built-in speaker and microphone
- WiFi and Bluetooth connectivity
- 16MB RAM, 4GB storage

### What is Antigravity?

Google Antigravity is an "agent-first" IDE that goes beyond traditional code completion. Key features:
- **Agent Manager** - Spawn and orchestrate multiple AI agents working in parallel
- **Browser Agent** - AI can interact with browsers to test your applications
- **Artifacts** - Verifiable deliverables (plans, screenshots, recordings) for trust
- **Gemini 3 Pro** - Powers the AI with massive context windows
- **VS Code Compatibility** - Uses familiar VS Code extensions and workflows

---

## System Requirements

- **macOS** on Apple Silicon (M1/M2/M3)
- **Homebrew** (for package management)
- **Google Account** (free tier available for Antigravity)
- **Anthropic Account** (for Claude Code)
- At least 8GB RAM recommended
- 10GB free disk space

---

## Step 1: Install the Playdate SDK

### 1.1 Download the SDK

1. Visit: https://play.date/dev/
2. Create a Playdate Developer account (free)
3. Download the **macOS SDK installer**
4. Run the installer application

The SDK installs to: `~/Developer/PlaydateSDK`

### 1.2 Set Environment Variable

Add to your shell profile (`~/.zshrc` for zsh or `~/.bash_profile` for bash):

```bash
# Playdate SDK Path
export PLAYDATE_SDK_PATH="$HOME/Developer/PlaydateSDK"
export PATH="$PLAYDATE_SDK_PATH/bin:$PATH"
```

Then reload your shell:
```bash
source ~/.zshrc  # or source ~/.bash_profile
```

### 1.3 Verify Installation

```bash
# Check pdc compiler
pdc --version

# Check simulator
open "$PLAYDATE_SDK_PATH/Playdate Simulator.app"
```

### 1.4 Explore the SDK Contents

```
PlaydateSDK/
├── bin/           # pdc compiler, pdutil tools
├── C_API/         # C development headers and examples
├── CoreLibs/      # Lua libraries (sprites, timers, animation, etc.)
├── Disk/          # Virtual disk for simulator
├── Resources/     # Fonts and assets
├── Examples/      # Sample games (great for learning!)
└── Playdate Simulator.app
```

---

## Step 2: Install Google Antigravity IDE

### 2.1 Download Antigravity

1. Visit: https://antigravity.google/ (or search "Google Antigravity download")
2. Download the macOS version (.dmg file)
3. Open the DMG and drag Antigravity to Applications
4. Launch Antigravity

### 2.2 Initial Setup

On first launch, Antigravity will guide you through:

1. **Development Mode Selection:**
   - **Agent-driven**: AI writes and executes autonomously
   - **Review-driven**: AI makes decisions but asks for approval (RECOMMENDED)
   - **Agent-assisted**: You stay in control, AI assists safely

2. **Keybindings**: Choose VS Code style (recommended for familiarity)

3. **Sign in with Google**: Uses your Google account (free preview)

4. **Extensions Setup**: Install recommended extensions

### 2.3 Access the VS Code Marketplace (Optional)

Antigravity uses OpenVSX by default. To access the full VS Code Marketplace:

1. Open Settings: `Cmd + ,`
2. Search for "marketplace"
3. Update Extension Gallery URLs to Microsoft's marketplace (optional, not required for most extensions)

---

## Step 3: Configure Extensions

### 3.1 Essential Extensions for Playdate

Open the Extensions panel (`Cmd + Shift + X`) and install:

| Extension | Purpose |
|-----------|---------|
| **sumneko.lua** | Lua language server (autocomplete, linting) |
| **Orta.playdate** | Playdate SDK integration |
| **midouest.playdate-debug** | Debugger for Playdate (breakpoints, stepping) |

### 3.2 Install via Search

Search for and install:
1. "Lua" by sumneko
2. "Playdate" by Orta
3. "Playdate Debug" by midouest

### 3.3 Optional Helpful Extensions

- **Lua Plus** (jep-a.lua-plus) - Additional Lua features
- **GitLens** - Git integration
- **Error Lens** - Inline error display

---

## Step 4: Configure the Development Environment

### 4.1 Create Workspace Settings

Create a `.vscode/settings.json` file in your project directory:

```json
{
  "Lua.runtime.version": "Lua 5.4",
  "Lua.diagnostics.disable": [
    "undefined-global",
    "lowercase-global"
  ],
  "Lua.diagnostics.globals": [
    "playdate",
    "import",
    "class"
  ],
  "Lua.runtime.nonstandardSymbol": [
    "+=",
    "-=",
    "*=",
    "/=",
    "//=",
    "%=",
    "<<=",
    ">>=",
    "&=",
    "|=",
    "^="
  ],
  "Lua.workspace.library": [
    "${env:PLAYDATE_SDK_PATH}/CoreLibs"
  ],
  "Lua.workspace.preloadFileSize": 1000,
  "playdate.sdkPath": "${env:PLAYDATE_SDK_PATH}",
  "playdate.source": "source",
  "playdate.output": "output.pdx"
}
```

### 4.2 Create Build Tasks

Create `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "type": "pdc",
      "problemMatcher": ["$pdc-lua", "$pdc-external"],
      "label": "Playdate: Build"
    },
    {
      "type": "playdate-simulator",
      "problemMatcher": ["$pdc-external"],
      "label": "Playdate: Run"
    },
    {
      "label": "Playdate: Build and Run",
      "dependsOn": ["Playdate: Build", "Playdate: Run"],
      "dependsOrder": "sequence",
      "problemMatcher": [],
      "group": {
        "kind": "build",
        "isDefault": true
      }
    }
  ]
}
```

### 4.3 Create Launch Configuration

Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "playdate",
      "request": "launch",
      "name": "Playdate: Debug",
      "preLaunchTask": "${defaultBuildTask}"
    }
  ]
}
```

---

## Step 5: Create Your First Project

### 5.1 Project Structure

Create a new folder and set up this structure:

```
MyPlaydateGame/
├── .vscode/
│   ├── settings.json
│   ├── tasks.json
│   └── launch.json
├── source/
│   └── main.lua
└── pdxinfo
```

### 5.2 Create pdxinfo (Game Metadata)

Create `source/pdxinfo`:

```ini
name=My First Game
author=Your Name
description=A simple Playdate game
bundleID=com.yourname.myfirstgame
version=1.0
buildNumber=1
imagePath=images
```

### 5.3 Create main.lua (Basic Template)

Create `source/main.lua`:

```lua
-- Import essential CoreLibs
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

-- Create shorthand for graphics module (improves performance)
local gfx <const> = playdate.graphics

-- Game state
local playerX = 200
local playerY = 120

-- Setup function (called once at start)
function setup()
    -- Clear the screen
    gfx.clear()
    
    -- Draw initial message
    gfx.drawTextAligned("Hello Playdate!", 200, 100, kTextAlignment.center)
    gfx.drawTextAligned("Use D-pad to move", 200, 130, kTextAlignment.center)
end

-- Main update function (called every frame, default 30fps)
function playdate.update()
    -- Clear screen
    gfx.clear()
    
    -- Handle input
    if playdate.buttonIsPressed(playdate.kButtonUp) then
        playerY = playerY - 3
    end
    if playdate.buttonIsPressed(playdate.kButtonDown) then
        playerY = playerY + 3
    end
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        playerX = playerX - 3
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        playerX = playerX + 3
    end
    
    -- Keep player on screen
    playerX = math.max(10, math.min(390, playerX))
    playerY = math.max(10, math.min(230, playerY))
    
    -- Draw player (simple circle)
    gfx.fillCircleAtPoint(playerX, playerY, 10)
    
    -- Draw instructions
    gfx.drawText("X: " .. playerX .. " Y: " .. playerY, 5, 5)
    
    -- Update timers (required for timer functionality)
    playdate.timer.updateTimers()
end

-- Initialize
setup()
```

### 5.4 Build and Run

**Option 1: Command Palette**
- Press `Cmd + Shift + P`
- Type "Playdate: Build and Run"

**Option 2: Keyboard Shortcut**
- Press `Cmd + Shift + B` (default build task)

**Option 3: Terminal**
```bash
cd MyPlaydateGame
pdc source output.pdx
open "$PLAYDATE_SDK_PATH/Playdate Simulator.app" output.pdx
```

---

## Step 6: Using the Agent Manager & Eye Agent

### 6.1 Understanding Antigravity's Agent System

Antigravity introduces an "agent-first" paradigm with:

1. **Editor View** - Traditional IDE with agent sidebar (like Cursor/Copilot)
2. **Agent Manager View** - Mission Control for multiple parallel agents
3. **Browser Surface** - AI can test web apps and take screenshots

### 6.2 Accessing Agent Manager

- Click the Agent Manager icon in the activity bar (left sidebar)
- Or press `Cmd + L` to toggle the agent panel
- Or use View → Agent Manager

### 6.3 Creating Tasks for Playdate Development

**Example prompts for the Agent Manager:**

```
Create a simple breakout/brick-breaker game for Playdate. 
The game should:
- Use the crank to move a paddle
- Have bouncing ball physics
- Include 3 rows of bricks
- Track score
- Have game over and restart functionality
```

```
Add sprite-based animation to my Playdate game. 
Create an animated player character that:
- Has 4-frame walk cycle animations for each direction
- Moves with the D-pad
- Uses the Playdate sprite system
```

```
Implement a simple tilemap-based level for my Playdate game.
Include:
- A 12x8 tile grid (32px tiles)
- Collision detection with walls
- A goal tile the player must reach
```

### 6.4 Using Browser Agent for Testing

The Browser Agent can:
- Take screenshots of your game running in the simulator
- Verify game behavior
- Document your development progress

**Note:** For Playdate development, the Browser Agent is less useful since games run in the Simulator, not a browser. However, you can use it to research Playdate APIs, find assets, and read documentation.

### 6.5 Working with Artifacts

Agents generate "Artifacts" including:
- **Plans** - Step-by-step implementation strategy
- **Code Diffs** - What changed in your files
- **Screenshots** - Visual verification
- **Task Lists** - Progress tracking

Review artifacts before approving changes to maintain code quality.

---

## Step 7: Using Claude Code in Terminal

### 7.1 Install Claude Code

```bash
# Install via npm (requires Node.js)
npm install -g @anthropic/claude-code

# Or via Homebrew
brew install claude-code
```

### 7.2 Authenticate

```bash
claude-code auth
```

Follow the prompts to sign in with your Anthropic account.

### 7.3 Using Claude Code for Playdate Development

Navigate to your project directory and start Claude Code:

```bash
cd MyPlaydateGame
claude-code
```

**Example commands:**

```
# Get help with Playdate APIs
What are the different ways to draw shapes in Playdate?

# Generate code
Create a crank-controlled menu system for Playdate with 5 options

# Debug issues
Why isn't my sprite showing up? Here's my code: [paste code]

# Optimize performance
How can I improve the frame rate of my Playdate game that uses tilemaps?
```

### 7.4 Claude Code + Antigravity Workflow

1. **Use Antigravity's Agent Manager** for larger tasks (new features, refactoring)
2. **Use Claude Code** for quick questions, debugging, and API exploration
3. **Use the Editor** for fine-tuned manual coding

---

## Playdate Development Quick Reference

### Display Specifications

| Property | Value |
|----------|-------|
| Resolution | 400 × 240 pixels |
| Color Depth | 1-bit (black/white only) |
| Default FPS | 30 fps (max 50 fps) |
| Pixel Pitch | 173 PPI |

### Input Constants

```lua
-- Buttons
playdate.kButtonA
playdate.kButtonB
playdate.kButtonUp
playdate.kButtonDown
playdate.kButtonLeft
playdate.kButtonRight

-- Button functions
playdate.buttonIsPressed(button)     -- Held down
playdate.buttonJustPressed(button)   -- Just this frame
playdate.buttonJustReleased(button)  -- Released this frame

-- Crank
playdate.getCrankPosition()    -- Absolute angle (0-359.9999)
playdate.getCrankChange()      -- Delta since last frame
playdate.getCrankTicks(n)      -- Ticks per revolution
playdate.isCrankDocked()       -- Is crank folded in?
```

### Essential Graphics Functions

```lua
local gfx <const> = playdate.graphics

-- Screen
gfx.clear()                              -- Clear to background color
gfx.setBackgroundColor(gfx.kColorBlack)  -- or kColorWhite

-- Drawing
gfx.drawRect(x, y, w, h)                 -- Outline rectangle
gfx.fillRect(x, y, w, h)                 -- Filled rectangle
gfx.drawCircleAtPoint(x, y, r)           -- Outline circle
gfx.fillCircleAtPoint(x, y, r)           -- Filled circle
gfx.drawLine(x1, y1, x2, y2)             -- Line
gfx.drawPixel(x, y)                      -- Single pixel

-- Text
gfx.drawText(text, x, y)
gfx.drawTextAligned(text, x, y, alignment)

-- Colors
gfx.setColor(gfx.kColorBlack)  -- or kColorWhite, kColorClear, kColorXOR

-- Images
local img = gfx.image.new("images/myImage")  -- Load .png
img:draw(x, y)
```

### Sprite System (Recommended)

```lua
import "CoreLibs/sprites"

-- Create sprite from image
local playerImage = gfx.image.new("images/player")
local playerSprite = gfx.sprite.new(playerImage)
playerSprite:moveTo(200, 120)
playerSprite:add()  -- Add to display list

-- In update()
gfx.sprite.update()  -- Draws all sprites

-- Movement
playerSprite:moveBy(dx, dy)
playerSprite:moveTo(x, y)
```

### File Organization Best Practices

```
source/
├── main.lua           # Entry point
├── game.lua           # Main game logic
├── player.lua         # Player class
├── enemy.lua          # Enemy class
├── images/
│   ├── player.png
│   ├── enemy.png
│   └── tiles.png
├── sounds/
│   ├── jump.wav
│   └── music.mp3
└── levels/
    └── level1.json
```

---

## Game Ideas to Get Started

### Beginner Projects

1. **Pong Clone**
   - Two paddles, one ball
   - Use crank for player paddle
   - Simple score tracking

2. **Snake**
   - D-pad controls direction
   - Crank controls speed
   - Growing tail mechanics

3. **Breakout/Arkanoid**
   - Crank-controlled paddle
   - Bouncing ball physics
   - Brick destruction

### Intermediate Projects

4. **Top-Down Shooter**
   - Sprite-based player and enemies
   - Tilemap background
   - Crank for aiming

5. **Platformer**
   - Gravity and jumping
   - Collision detection
   - Multiple levels

6. **Puzzle Game**
   - Grid-based mechanics
   - State management
   - Level progression

### Advanced Projects

7. **Roguelike**
   - Procedural generation
   - Turn-based combat
   - Inventory system

8. **Racing Game**
   - Mode 7-style graphics
   - Crank for steering
   - AI opponents

---

## Troubleshooting

### Common Issues

**"pdc not found"**
- Ensure `PLAYDATE_SDK_PATH` is set correctly
- Run `source ~/.zshrc` to reload shell

**"Simulator won't launch"**
- Check that the `.pdx` file was created
- Verify no syntax errors in Lua files

**"Extension not working in Antigravity"**
- Some VS Code extensions require the Microsoft marketplace
- Try the OpenVSX alternative or install via .vsix

**"Autocomplete not working"**
- Verify `Lua.workspace.library` points to CoreLibs
- Ensure sumneko.lua extension is installed

### Getting Help

- **Playdate Developer Forum**: https://devforum.play.date/
- **Playdate Discord**: Check play.date for invite link
- **SDK Documentation**: `Inside Playdate.html` in SDK folder
- **Example Games**: `PlaydateSDK/Examples/` directory

---

## Summary

You now have a complete Playdate development environment with:

1. ✅ Playdate SDK installed and configured
2. ✅ Antigravity IDE with Lua support
3. ✅ Build/debug tasks configured
4. ✅ Agent Manager for AI-assisted development
5. ✅ Claude Code for terminal-based AI help

**Start building!** The best way to learn is to experiment. Start with a simple game idea, use the agents to help you implement features, and iterate.

Remember:
- Test frequently in the Simulator
- The 1-bit display requires thoughtful design
- The crank is your unique advantage—use it creatively!

Happy coding! 🎮
