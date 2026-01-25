#!/bin/bash

#===============================================================================
# Playdate Development Environment Setup Script
# For macOS (Apple Silicon M1/M2/M3)
# 
# This script sets up:
# - Homebrew (if not installed)
# - Playdate SDK
# - Google Antigravity IDE
# - Claude Code CLI
# - VS Code extensions for Playdate development
# - A starter project with all configurations
#
# Usage: chmod +x setup-playdate-dev.sh && ./setup-playdate-dev.sh
#===============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Cleanup trap for error handling
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo -e "\033[0;31m✖ Script failed with exit code $exit_code\033[0m" >&2
    fi
}
trap cleanup EXIT

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Cached system info (avoid repeated calls)
OS_NAME="$(uname)"
ARCH="$(uname -m)"
IS_ARM64=$([[ "$ARCH" == "arm64" ]] && echo true || echo false)
readonly OS_NAME ARCH IS_ARM64

# Global variables
SHELL_RC=""
SKIP_SDK=false
SKIP_ANTIGRAVITY=false

# Configuration
readonly PLAYDATE_SDK_VERSION="2.6.2"  # Update as needed
# Note: SDK requires manual download due to license agreement
# Reference URL: https://download.panic.com/playdate_sdk/PlaydateSDK-${PLAYDATE_SDK_VERSION}.zip
ANTIGRAVITY_URL="https://antigravity.google"
PROJECT_NAME="MyPlaydateGame"
INSTALL_DIR="$HOME/Developer"
SDK_PATH="$INSTALL_DIR/PlaydateSDK"
SIMULATOR_APP="$SDK_PATH/Playdate Simulator.app"
SIMULATOR_BIN="$SIMULATOR_APP/Contents/MacOS/Playdate Simulator"

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------

print_header() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}$1${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✔${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✖${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

check_command() {
    command -v "$1" &> /dev/null
}

prompt_continue() {
    echo ""
    read -r -p "Press Enter to continue or Ctrl+C to abort..."
    echo ""
}

#-------------------------------------------------------------------------------
# Pre-flight Checks
#-------------------------------------------------------------------------------

preflight_checks() {
    print_header "Pre-flight Checks"

    # Check macOS
    if [[ "$OS_NAME" != "Darwin" ]]; then
        print_error "This script is designed for macOS only."
        exit 1
    fi
    print_success "Running on macOS"

    # Check Apple Silicon
    if [[ "$IS_ARM64" == "true" ]]; then
        print_success "Apple Silicon detected (M1/M2/M3)"
    else
        print_warning "Intel Mac detected - script should still work"
    fi
    
    # Check for existing installations
    if [[ -d "$SDK_PATH" ]]; then
        print_warning "Playdate SDK already exists at $SDK_PATH"
        read -r -p "Do you want to reinstall? (y/N): " reinstall
        if [[ "$reinstall" != "y" && "$reinstall" != "Y" ]]; then
            SKIP_SDK=true
        fi
    fi
    
    if [[ -d "/Applications/Antigravity.app" ]]; then
        print_warning "Antigravity is already installed"
        SKIP_ANTIGRAVITY=true
    fi
    
    echo ""
    print_info "This script will install:"
    echo "  • Homebrew (package manager)"
    echo "  • Playdate SDK ${PLAYDATE_SDK_VERSION}"
    echo "  • Google Antigravity IDE"
    echo "  • Claude Code CLI"
    echo "  • Node.js (for tooling)"
    echo "  • Required VS Code/Antigravity extensions"
    echo "  • A starter Playdate project"
    echo ""
    
    prompt_continue
}

#-------------------------------------------------------------------------------
# Install Homebrew
#-------------------------------------------------------------------------------

install_homebrew() {
    print_header "Installing Homebrew"

    if check_command brew; then
        print_success "Homebrew is already installed"
        print_step "Updating Homebrew..."
        brew update
    else
        print_step "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add to PATH for Apple Silicon (only if not already present)
        if [[ "$IS_ARM64" == "true" ]]; then
            if ! grep -q '/opt/homebrew/bin/brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
            fi
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi

        print_success "Homebrew installed"
    fi
}

#-------------------------------------------------------------------------------
# Install Dependencies
#-------------------------------------------------------------------------------

install_dependencies() {
    print_header "Installing Dependencies"

    local to_install=()

    # Check each dependency
    if check_command node; then
        print_success "Node.js is already installed ($(node --version))"
    else
        to_install+=("node")
    fi

    if check_command wget; then
        print_success "wget is already installed"
    else
        to_install+=("wget")
    fi

    if check_command jq; then
        print_success "jq is already installed"
    else
        to_install+=("jq")
    fi

    if check_command fswatch; then
        print_success "fswatch is already installed"
    else
        to_install+=("fswatch")
    fi

    # Install all missing dependencies in one brew call
    if [[ ${#to_install[@]} -gt 0 ]]; then
        print_step "Installing: ${to_install[*]}..."
        brew install "${to_install[@]}"
        print_success "Dependencies installed: ${to_install[*]}"
    fi
}

#-------------------------------------------------------------------------------
# Install Playdate SDK
#-------------------------------------------------------------------------------

install_playdate_sdk() {
    print_header "Installing Playdate SDK"
    
    if [[ "$SKIP_SDK" == true ]]; then
        print_info "Skipping SDK installation (already installed)"
        return
    fi
    
    # Create install directory
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    print_step "Downloading Playdate SDK ${PLAYDATE_SDK_VERSION}..."
    
    # Try to download from Panic
    # Note: The SDK requires accepting license on play.date/dev
    # We'll check if it's already downloaded or guide user to download manually
    
    SDK_ZIP="PlaydateSDK-${PLAYDATE_SDK_VERSION}.zip"
    
    if [[ -f "$SDK_ZIP" ]]; then
        print_info "SDK zip already downloaded"
    else
        print_warning "The Playdate SDK requires manual download from play.date/dev"
        print_info "Please follow these steps:"
        echo ""
        echo "  1. Open https://play.date/dev/ in your browser"
        echo "  2. Create an account or sign in"
        echo "  3. Download the macOS SDK"
        echo "  4. Move the downloaded .zip file to: $INSTALL_DIR/"
        echo ""
        
        # Open the download page
        open "https://play.date/dev/"
        
        read -r -p "Press Enter after you've downloaded the SDK to $INSTALL_DIR/..."

        # Find the downloaded SDK (safe pattern matching)
        SDK_ZIP=$(find . -maxdepth 1 -name "PlaydateSDK*.zip" -type f -print -quit 2>/dev/null)

        if [[ -z "$SDK_ZIP" ]]; then
            print_error "SDK zip file not found in $INSTALL_DIR"
            print_info "Please download manually and re-run this script"
            exit 1
        fi
    fi

    print_step "Extracting SDK..."
    unzip -q -o "$SDK_ZIP"

    # Find the extracted directory (safe pattern matching)
    SDK_DIR=$(find . -maxdepth 1 -type d -name "PlaydateSDK*" ! -name "*.zip" -print -quit 2>/dev/null)

    if [[ -n "$SDK_DIR" && "$SDK_DIR" != "./PlaydateSDK" && "$SDK_DIR" != "PlaydateSDK" ]]; then
        # Remove leading ./ if present
        SDK_DIR="${SDK_DIR#./}"
        if [[ -d "PlaydateSDK" ]]; then
            print_warning "PlaydateSDK directory already exists, removing old version..."
            rm -rf "PlaydateSDK"
        fi
        mv "$SDK_DIR" "PlaydateSDK"
    fi
    
    print_success "Playdate SDK installed to $SDK_PATH"

    # Clean up only if SDK was successfully installed
    if [[ -d "$SDK_PATH" ]]; then
        rm -f "$SDK_ZIP"
    else
        print_warning "Keeping SDK zip file since installation may have failed"
    fi
}

#-------------------------------------------------------------------------------
# Configure and Verify Playdate Simulator
#-------------------------------------------------------------------------------

configure_simulator() {
    print_header "Configuring Playdate Simulator"
    
    # Verify simulator exists
    if [[ -d "$SIMULATOR_APP" ]]; then
        print_success "Playdate Simulator found"
    else
        print_error "Playdate Simulator not found at $SIMULATOR_APP"
        print_info "The SDK may not have been installed correctly"
        return 1
    fi
    
    # Check if simulator can run
    print_step "Verifying simulator..."
    if [[ -f "$SIMULATOR_BIN" ]]; then
        print_success "Simulator binary verified"
    else
        print_warning "Simulator binary not found - may need to open manually first"
    fi
    
    # Remove quarantine attribute (macOS security)
    print_step "Removing macOS quarantine attribute..."
    xattr -dr com.apple.quarantine "$SIMULATOR_APP" 2>/dev/null || true
    print_success "Quarantine attribute removed"
    
    # Create Playdate data directory
    PLAYDATE_DATA_DIR="$HOME/.Playdate"
    if [[ ! -d "$PLAYDATE_DATA_DIR" ]]; then
        print_step "Creating Playdate data directory..."
        mkdir -p "$PLAYDATE_DATA_DIR"
        print_success "Data directory created at $PLAYDATE_DATA_DIR"
    fi
    
    # Create simulator preferences if they don't exist
    SIMULATOR_PREFS="$HOME/Library/Preferences/com.panic.playdatesimulator.plist"
    if [[ ! -f "$SIMULATOR_PREFS" ]]; then
        print_step "Initializing simulator preferences..."
        # Launch and quit simulator to create default preferences
        open -a "$SIMULATOR_APP"
        sleep 1
        osascript -e 'quit app "Playdate Simulator"' 2>/dev/null || true
        print_success "Simulator preferences initialized"
    fi
    
    # Configure simulator settings via defaults (if possible)
    print_step "Configuring simulator settings..."
    
    # Enable showing console output
    defaults write com.panic.playdatesimulator ShowConsole -bool true 2>/dev/null || true
    
    # Set default refresh rate display
    defaults write com.panic.playdatesimulator ShowFPS -bool true 2>/dev/null || true
    
    print_success "Simulator configured"
    
    # Test the simulator with a quick launch
    print_step "Testing simulator launch..."
    open -a "$SIMULATOR_APP"
    sleep 1

    if pgrep -x "Playdate Simulator" > /dev/null; then
        print_success "Simulator is running!"
        osascript -e 'quit app "Playdate Simulator"' 2>/dev/null || true
    else
        print_warning "Simulator may not have launched - check manually"
    fi
}

#-------------------------------------------------------------------------------
# Configure Shell Environment
#-------------------------------------------------------------------------------

configure_shell() {
    print_header "Configuring Shell Environment"

    # Determine shell config file (sets global SHELL_RC)
    if [[ "${SHELL:-}" == *"zsh"* ]]; then
        SHELL_RC="$HOME/.zshrc"
    else
        SHELL_RC="$HOME/.bashrc"
    fi

    # Ensure the shell config file exists
    touch "$SHELL_RC"

    print_step "Adding environment variables to $SHELL_RC"
    
    # Check if already configured
    if grep -q "PLAYDATE_SDK_PATH" "$SHELL_RC" 2>/dev/null; then
        print_warning "Playdate environment already configured in $SHELL_RC"
    else
        cat >> "$SHELL_RC" << 'SHELLCONFIG'

#-------------------------------------------------------------------------------
# Playdate Development Environment
#-------------------------------------------------------------------------------
export PLAYDATE_SDK_PATH="$HOME/Developer/PlaydateSDK"
export PATH="$PLAYDATE_SDK_PATH/bin:$PATH"

# Simulator path
export PLAYDATE_SIMULATOR="$PLAYDATE_SDK_PATH/Playdate Simulator.app"

# Quick aliases
alias playdate-sim='open "$PLAYDATE_SIMULATOR"'
alias pdc-build='pdc source output.pdx'
alias pdc-run='pdc source output.pdx && open "$PLAYDATE_SIMULATOR" output.pdx'
alias pdc-clean='rm -rf output.pdx'

# Function to build and run any .pdx or source directory
playdate-test() {
    local target="${1:-source}"
    local output="${2:-output.pdx}"
    
    if [[ -d "$target" ]]; then
        echo "Building $target -> $output..."
        pdc "$target" "$output"
        if [[ $? -eq 0 ]]; then
            echo "Launching simulator..."
            open "$PLAYDATE_SIMULATOR" "$output"
        else
            echo "Build failed!"
            return 1
        fi
    elif [[ -d "$target.pdx" ]]; then
        echo "Launching $target.pdx..."
        open "$PLAYDATE_SIMULATOR" "$target.pdx"
    else
        echo "Usage: playdate-test [source_dir] [output.pdx]"
        echo "       playdate-test game.pdx"
        return 1
    fi
}

# Function to watch for changes and auto-rebuild (requires fswatch)
playdate-watch() {
    local source_dir="${1:-source}"
    local output="${2:-output.pdx}"
    
    if ! command -v fswatch &> /dev/null; then
        echo "fswatch not installed. Install with: brew install fswatch"
        return 1
    fi
    
    echo "Watching $source_dir for changes... (Ctrl+C to stop)"
    echo "Initial build..."
    pdc "$source_dir" "$output" && open "$PLAYDATE_SIMULATOR" "$output"
    
    fswatch -o "$source_dir" | while read; do
        echo "Change detected, rebuilding..."
        pdc "$source_dir" "$output"
        if [[ $? -eq 0 ]]; then
            echo "Build successful! Refreshing simulator..."
            # The simulator auto-reloads when the .pdx changes
        fi
    done
}

# Function to run simulator with specific options
playdate-debug() {
    local pdx="${1:-output.pdx}"
    if [[ ! -d "$pdx" ]]; then
        echo "PDX not found: $pdx"
        echo "Build first with: pdc source output.pdx"
        return 1
    fi
    echo "Launching $pdx in debug mode..."
    open "$PLAYDATE_SIMULATOR" "$pdx"
    echo "Tip: Use Cmd+D in simulator to open debugger"
}

# List SDK examples
playdate-examples() {
    echo "Playdate SDK Examples:"
    echo "======================"
    ls -1 "$PLAYDATE_SDK_PATH/Examples/"
    echo ""
    echo "To run an example:"
    echo "  cd \"\$PLAYDATE_SDK_PATH/Examples/[ExampleName]\""
    echo "  pdc-run"
}

# Open SDK documentation
playdate-docs() {
    local doc="$PLAYDATE_SDK_PATH/Documentation/Inside Playdate.html"
    if [[ -f "$doc" ]]; then
        open "$doc"
    else
        echo "Opening online documentation..."
        open "https://sdk.play.date/Inside%20Playdate.html"
    fi
}

SHELLCONFIG
        print_success "Environment variables added"
    fi
    
    # Source the config
    # shellcheck source=/dev/null
    source "$SHELL_RC"
    
    # Export for current session
    export PLAYDATE_SDK_PATH="$SDK_PATH"
    export PATH="$SDK_PATH/bin:$PATH"
}

#-------------------------------------------------------------------------------
# Install Google Antigravity
#-------------------------------------------------------------------------------

install_antigravity() {
    print_header "Installing Google Antigravity IDE"
    
    if [[ "$SKIP_ANTIGRAVITY" == true ]]; then
        print_info "Skipping Antigravity installation (already installed)"
        return
    fi
    
    print_warning "Antigravity requires manual download from Google"
    print_info "Please follow these steps:"
    echo ""
    echo "  1. The download page will open in your browser"
    echo "  2. Download the macOS version"
    echo "  3. Open the .dmg file"
    echo "  4. Drag Antigravity to Applications"
    echo ""
    
    # Open the download page
    open "$ANTIGRAVITY_URL"
    
    read -r -p "Press Enter after you've installed Antigravity..."
    
    if [[ -d "/Applications/Antigravity.app" ]]; then
        print_success "Antigravity installed successfully"
    else
        print_warning "Antigravity not found in /Applications"
        print_info "You can install it later and continue with the setup"
    fi
}

#-------------------------------------------------------------------------------
# Install Claude Code
#-------------------------------------------------------------------------------

install_claude_code() {
    print_header "Installing Claude Code CLI"
    
    if check_command claude; then
        print_success "Claude Code is already installed"
    else
        print_step "Installing Claude Code via npm..."
        npm install -g @anthropic-ai/claude-code 2>/dev/null || {
            print_warning "npm install failed, trying alternative method..."
            # Alternative: direct install if available
            brew install claude-code 2>/dev/null || {
                print_warning "Could not install Claude Code automatically"
                print_info "You can install it manually later with: npm install -g @anthropic-ai/claude-code"
            }
        }
    fi
    
    if check_command claude; then
        print_success "Claude Code installed"
        print_info "Run 'claude auth' to authenticate"
    fi
}

#-------------------------------------------------------------------------------
# Install VS Code / Antigravity Extensions
#-------------------------------------------------------------------------------

install_extensions() {
    print_header "Installing IDE Extensions"
    
    # Find the CLI tool
    ANTIGRAVITY_CLI="/Applications/Antigravity.app/Contents/Resources/app/bin/antigravity"
    CODE_CLI=""
    
    if [[ -f "$ANTIGRAVITY_CLI" ]]; then
        CODE_CLI="$ANTIGRAVITY_CLI"
        print_info "Using Antigravity CLI"
    elif check_command code; then
        CODE_CLI="code"
        print_info "Using VS Code CLI"
    else
        print_warning "No IDE CLI found - skipping extension installation"
        print_info "You can install extensions manually in Antigravity/VS Code:"
        echo "  • sumneko.lua"
        echo "  • Orta.playdate"
        echo "  • midouest.playdate-debug"
        return
    fi
    
    # Extensions to install
    EXTENSIONS=(
        "sumneko.lua"
        "Orta.playdate"
    )
    
    for ext in "${EXTENSIONS[@]}"; do
        print_step "Installing extension: $ext"
        "$CODE_CLI" --install-extension "$ext" 2>/dev/null || {
            print_warning "Could not install $ext - you may need to install manually"
        }
    done
    
    # Try to install debug extension (may need VS Code marketplace)
    print_step "Installing Playdate Debug extension..."
    "$CODE_CLI" --install-extension "midouest.playdate-debug" 2>/dev/null || {
        print_warning "Debug extension not found in OpenVSX"
        print_info "Install manually from: https://github.com/midouest/vscode-playdate-debug"
    }
    
    print_success "Extensions installation complete"
}

#-------------------------------------------------------------------------------
# Create Starter Project
#-------------------------------------------------------------------------------

create_starter_project() {
    print_header "Creating Starter Project"
    
    PROJECT_DIR="$HOME/Developer/$PROJECT_NAME"
    
    if [[ -d "$PROJECT_DIR" ]]; then
        print_warning "Project directory already exists: $PROJECT_DIR"
        read -r -p "Create with different name? Enter name (or press Enter to skip): " new_name
        if [[ -n "$new_name" ]]; then
            # Sanitize: only allow alphanumeric, dash, underscore
            new_name="${new_name//[^a-zA-Z0-9_-]/}"
            if [[ -z "$new_name" ]]; then
                print_error "Invalid project name (only alphanumeric, dash, underscore allowed)"
                return 1
            fi
            PROJECT_NAME="$new_name"
            PROJECT_DIR="$HOME/Developer/$PROJECT_NAME"
        else
            return 0
        fi
    fi
    
    print_step "Creating project at $PROJECT_DIR"
    
    mkdir -p "$PROJECT_DIR"/{source/images,.vscode}
    cd "$PROJECT_DIR"
    
    #---------------------------------------------------------------------------
    # Create .vscode/settings.json
    #---------------------------------------------------------------------------
    cat > .vscode/settings.json << 'SETTINGS'
{
    "Lua.runtime.version": "Lua 5.4",
    "Lua.diagnostics.disable": [
        "undefined-global",
        "lowercase-global"
    ],
    "Lua.diagnostics.globals": [
        "playdate",
        "import",
        "class",
        "Object"
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
    "Lua.workspace.checkThirdParty": false,
    "playdate.sdkPath": "${env:PLAYDATE_SDK_PATH}",
    "playdate.source": "source",
    "playdate.output": "output.pdx",
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "files.trimTrailingWhitespace": true
}
SETTINGS

    #---------------------------------------------------------------------------
    # Create .vscode/tasks.json
    #---------------------------------------------------------------------------
    cat > .vscode/tasks.json << 'TASKS'
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Playdate: Build",
            "type": "shell",
            "command": "pdc",
            "args": [
                "${workspaceFolder}/source",
                "${workspaceFolder}/output.pdx"
            ],
            "problemMatcher": {
                "owner": "pdc",
                "fileLocation": ["relative", "${workspaceFolder}"],
                "pattern": {
                    "regexp": "^(.*):(\\d+):\\s+(.*)$",
                    "file": 1,
                    "line": 2,
                    "message": 3
                }
            },
            "group": "build"
        },
        {
            "label": "Playdate: Run Simulator",
            "type": "shell",
            "command": "open",
            "args": [
                "-a",
                "${env:PLAYDATE_SDK_PATH}/Playdate Simulator.app",
                "${workspaceFolder}/output.pdx"
            ],
            "problemMatcher": [],
            "presentation": {
                "reveal": "silent"
            }
        },
        {
            "label": "Playdate: Build and Run",
            "dependsOn": [
                "Playdate: Build",
                "Playdate: Run Simulator"
            ],
            "dependsOrder": "sequence",
            "problemMatcher": [],
            "group": {
                "kind": "build",
                "isDefault": true
            }
        },
        {
            "label": "Playdate: Clean",
            "type": "shell",
            "command": "rm",
            "args": ["-rf", "${workspaceFolder}/output.pdx"],
            "problemMatcher": []
        },
        {
            "label": "Playdate: Clean and Rebuild",
            "dependsOn": [
                "Playdate: Clean",
                "Playdate: Build"
            ],
            "dependsOrder": "sequence",
            "problemMatcher": []
        },
        {
            "label": "Playdate: Watch Mode (Auto-Rebuild)",
            "type": "shell",
            "command": "fswatch",
            "args": [
                "-o",
                "${workspaceFolder}/source",
                "|",
                "xargs",
                "-n1",
                "-I{}",
                "pdc",
                "${workspaceFolder}/source",
                "${workspaceFolder}/output.pdx"
            ],
            "isBackground": true,
            "problemMatcher": {
                "owner": "pdc-watch",
                "fileLocation": ["relative", "${workspaceFolder}"],
                "pattern": {
                    "regexp": "^(.*):(\\d+):\\s+(.*)$",
                    "file": 1,
                    "line": 2,
                    "message": 3
                },
                "background": {
                    "activeOnStart": true,
                    "beginsPattern": "^Change detected",
                    "endsPattern": "^Build"
                }
            },
            "presentation": {
                "reveal": "always",
                "panel": "dedicated"
            }
        },
        {
            "label": "Playdate: Open Simulator Only",
            "type": "shell",
            "command": "open",
            "args": [
                "-a",
                "${env:PLAYDATE_SDK_PATH}/Playdate Simulator.app"
            ],
            "problemMatcher": []
        },
        {
            "label": "Playdate: View SDK Examples",
            "type": "shell",
            "command": "open",
            "args": ["${env:PLAYDATE_SDK_PATH}/Examples"],
            "problemMatcher": []
        },
        {
            "label": "Playdate: Open Documentation",
            "type": "shell",
            "command": "open",
            "args": ["${env:PLAYDATE_SDK_PATH}/Documentation/Inside Playdate.html"],
            "problemMatcher": []
        }
    ]
}
TASKS

    #---------------------------------------------------------------------------
    # Create .vscode/launch.json
    #---------------------------------------------------------------------------
    cat > .vscode/launch.json << 'LAUNCH'
{
    "version": "0.2.0",
    "configurations": [
        {
            "type": "playdate",
            "request": "launch",
            "name": "Debug Playdate Game",
            "preLaunchTask": "Playdate: Build"
        }
    ]
}
LAUNCH

    #---------------------------------------------------------------------------
    # Create source/pdxinfo
    #---------------------------------------------------------------------------
    # Create safe bundle ID (lowercase, alphanumeric only)
    local safe_bundle_id
    safe_bundle_id=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')

    cat > source/pdxinfo << PDXINFO
name=$PROJECT_NAME
author=Your Name
description=A Playdate game created with the automated setup script
bundleID=com.example.${safe_bundle_id}
version=1.0
buildNumber=1
imagePath=images
PDXINFO

    #---------------------------------------------------------------------------
    # Create source/main.lua
    #---------------------------------------------------------------------------
    cat > source/main.lua << 'MAINLUA'
--[[
    Playdate Starter Game
    Created with the Playdate Development Setup Script
    
    Controls:
    - D-pad: Move the player
    - Crank: Rotate the player
    - A button: Boost speed
    - B button: Show debug info
]]

-- Import CoreLibs
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/crank"

-- Performance optimization: local references
local gfx <const> = playdate.graphics
local geo <const> = playdate.geometry

--=============================================================================
-- GAME CONSTANTS
--=============================================================================

local SCREEN_WIDTH <const> = 400
local SCREEN_HEIGHT <const> = 240
local PLAYER_SIZE <const> = 16
local PLAYER_SPEED <const> = 3
local BOOST_MULTIPLIER <const> = 2

--=============================================================================
-- GAME STATE
--=============================================================================

local player = {
    x = SCREEN_WIDTH / 2,
    y = SCREEN_HEIGHT / 2,
    rotation = 0,
    speed = PLAYER_SPEED,
    score = 0
}

local collectibles = {}
local showDebug = false
local gameTime = 0

--=============================================================================
-- HELPER FUNCTIONS
--=============================================================================

-- Keep value within bounds
local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Create a new collectible at random position
local function spawnCollectible()
    local collectible = {
        x = math.random(20, SCREEN_WIDTH - 20),
        y = math.random(20, SCREEN_HEIGHT - 20),
        radius = 8,
        collected = false
    }
    table.insert(collectibles, collectible)
end

-- Check collision between player and collectible
local function checkCollision(c)
    local dx = player.x - c.x
    local dy = player.y - c.y
    local distance = math.sqrt(dx * dx + dy * dy)
    return distance < (PLAYER_SIZE / 2 + c.radius)
end

--=============================================================================
-- GAME SETUP
--=============================================================================

local function setup()
    -- Set up display
    playdate.display.setRefreshRate(30)
    gfx.setBackgroundColor(gfx.kColorWhite)
    
    -- Spawn initial collectibles
    for i = 1, 5 do
        spawnCollectible()
    end
    
    print("Game initialized!")
    print("Use D-pad to move, Crank to rotate")
    print("Collect the circles to score points!")
end

--=============================================================================
-- INPUT HANDLING
--=============================================================================

local function handleInput()
    -- Get base speed (with boost if A is pressed)
    local speed = player.speed
    if playdate.buttonIsPressed(playdate.kButtonA) then
        speed = speed * BOOST_MULTIPLIER
    end
    
    -- D-pad movement
    if playdate.buttonIsPressed(playdate.kButtonUp) then
        player.y = player.y - speed
    end
    if playdate.buttonIsPressed(playdate.kButtonDown) then
        player.y = player.y + speed
    end
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        player.x = player.x - speed
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        player.x = player.x + speed
    end
    
    -- Keep player on screen
    player.x = clamp(player.x, PLAYER_SIZE / 2, SCREEN_WIDTH - PLAYER_SIZE / 2)
    player.y = clamp(player.y, PLAYER_SIZE / 2, SCREEN_HEIGHT - PLAYER_SIZE / 2)
    
    -- Crank rotation
    local crankChange = playdate.getCrankChange()
    player.rotation = player.rotation + crankChange
    
    -- Toggle debug with B button
    if playdate.buttonJustPressed(playdate.kButtonB) then
        showDebug = not showDebug
    end
end

--=============================================================================
-- GAME LOGIC
--=============================================================================

local function updateGame()
    gameTime = gameTime + 1
    
    -- Check collisions with collectibles
    for i = #collectibles, 1, -1 do
        local c = collectibles[i]
        if checkCollision(c) then
            table.remove(collectibles, i)
            player.score = player.score + 10
            spawnCollectible()  -- Spawn a new one
            print("Score: " .. player.score)
        end
    end
end

--=============================================================================
-- RENDERING
--=============================================================================

local function drawPlayer()
    gfx.pushContext()
    
    -- Translate to player position
    gfx.setDrawOffset(-player.x + PLAYER_SIZE / 2, -player.y + PLAYER_SIZE / 2)
    
    -- Draw player as a triangle (shows rotation)
    local angle = math.rad(player.rotation)
    local points = {
        geo.point.new(
            player.x + math.cos(angle) * PLAYER_SIZE / 2,
            player.y + math.sin(angle) * PLAYER_SIZE / 2
        ),
        geo.point.new(
            player.x + math.cos(angle + 2.4) * PLAYER_SIZE / 2,
            player.y + math.sin(angle + 2.4) * PLAYER_SIZE / 2
        ),
        geo.point.new(
            player.x + math.cos(angle - 2.4) * PLAYER_SIZE / 2,
            player.y + math.sin(angle - 2.4) * PLAYER_SIZE / 2
        )
    }
    
    gfx.setDrawOffset(0, 0)
    
    -- Draw filled triangle
    gfx.setColor(gfx.kColorBlack)
    gfx.fillTriangle(
        points[1].x, points[1].y,
        points[2].x, points[2].y,
        points[3].x, points[3].y
    )
    
    gfx.popContext()
end

local function drawCollectibles()
    gfx.setColor(gfx.kColorBlack)
    for _, c in ipairs(collectibles) do
        gfx.drawCircleAtPoint(c.x, c.y, c.radius)
    end
end

local function drawUI()
    -- Score
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText("Score: " .. player.score, 5, 5)
    
    -- Crank indicator if docked
    if playdate.isCrankDocked() then
        gfx.drawText("↻ Extend crank!", 5, SCREEN_HEIGHT - 20)
    end
    
    -- Debug info
    if showDebug then
        local debugY = 25
        gfx.drawText("X: " .. math.floor(player.x), 5, debugY)
        gfx.drawText("Y: " .. math.floor(player.y), 5, debugY + 15)
        gfx.drawText("Rot: " .. math.floor(player.rotation) .. "°", 5, debugY + 30)
        gfx.drawText("FPS: " .. playdate.getFPS(), 5, debugY + 45)
        
        -- Draw FPS graph
        playdate.drawFPS(SCREEN_WIDTH - 30, 5)
    end
end

local function drawInstructions()
    gfx.setColor(gfx.kColorBlack)
    local instructions = {
        "D-pad: Move",
        "Crank: Rotate", 
        "A: Boost",
        "B: Debug"
    }
    local startY = SCREEN_HEIGHT - 15 * #instructions - 5
    for i, text in ipairs(instructions) do
        gfx.drawText(text, SCREEN_WIDTH - 80, startY + (i - 1) * 15)
    end
end

--=============================================================================
-- MAIN UPDATE LOOP
--=============================================================================

function playdate.update()
    -- Clear screen
    gfx.clear()
    
    -- Handle input
    handleInput()
    
    -- Update game state
    updateGame()
    
    -- Draw everything
    drawCollectibles()
    drawPlayer()
    drawUI()
    
    -- Only show instructions for first few seconds
    if gameTime < 300 then  -- ~10 seconds at 30fps
        drawInstructions()
    end
    
    -- Update sprite system (if using sprites)
    gfx.sprite.update()
    
    -- Update timers
    playdate.timer.updateTimers()
end

--=============================================================================
-- SYSTEM CALLBACKS
--=============================================================================

-- Called when game is about to be terminated
function playdate.gameWillTerminate()
    -- Save game state here if needed
    print("Game ending. Final score: " .. player.score)
end

-- Called when device is going to sleep
function playdate.deviceWillSleep()
    -- Save game state here if needed
    print("Device sleeping. Score: " .. player.score)
end

-- Called when crank is docked/undocked
function playdate.crankDocked()
    print("Crank docked")
end

function playdate.crankUndocked()
    print("Crank undocked - use it to rotate!")
end

--=============================================================================
-- INITIALIZE GAME
--=============================================================================

setup()
MAINLUA

    #---------------------------------------------------------------------------
    # Create .gitignore
    #---------------------------------------------------------------------------
    cat > .gitignore << 'GITIGNORE'
# Compiled game
output.pdx/
*.pdx/

# macOS
.DS_Store
*.swp
*~

# IDE
.idea/
*.sublime-*

# Build artifacts
*.pdc
*.pdz
GITIGNORE

    #---------------------------------------------------------------------------
    # Create README.md
    #---------------------------------------------------------------------------
    cat > README.md << README
# $PROJECT_NAME

A Playdate game created with the automated development setup script.

## Requirements

- Playdate SDK (installed at \`~/Developer/PlaydateSDK\`)
- Antigravity IDE or VS Code with Lua extensions

## Building

### Using IDE (Recommended)
1. Open this folder in Antigravity/VS Code
2. Press \`Cmd+Shift+B\` to build and run

### Using Terminal
\`\`\`bash
# Build
pdc source output.pdx

# Run in simulator
open "\$PLAYDATE_SDK_PATH/Playdate Simulator.app" output.pdx

# Or use the alias
pdc-run
\`\`\`

## Project Structure

\`\`\`
$PROJECT_NAME/
├── source/           # Game source code
│   ├── main.lua      # Main entry point
│   ├── pdxinfo       # Game metadata
│   └── images/       # Image assets
├── output.pdx/       # Compiled game (generated)
├── .vscode/          # IDE configuration
└── README.md
\`\`\`

## Controls

- **D-pad**: Move the player
- **Crank**: Rotate the player
- **A Button**: Speed boost
- **B Button**: Toggle debug info

## Resources

- [Playdate SDK Documentation](https://sdk.play.date/)
- [Playdate Developer Forum](https://devforum.play.date/)
- [Inside Playdate](https://sdk.play.date/Inside%20Playdate.html)

## License

MIT License - feel free to use this as a starting point for your games!
README

    print_success "Starter project created at $PROJECT_DIR"
    
    # Try to build the project
    print_step "Building starter project..."
    if check_command pdc; then
        cd "$PROJECT_DIR"
        pdc source output.pdx && print_success "Project built successfully!" || print_warning "Build failed - check SDK installation"
    else
        print_warning "pdc not found - reload your shell and try building manually"
    fi
}

#-------------------------------------------------------------------------------
# Create Simulator Helper Scripts
#-------------------------------------------------------------------------------

create_simulator_scripts() {
    print_header "Creating Simulator Helper Scripts"
    
    SCRIPTS_DIR="$HOME/Developer/playdate-scripts"
    mkdir -p "$SCRIPTS_DIR"
    
    #---------------------------------------------------------------------------
    # Create playdate-simulator.sh - Advanced simulator launcher
    #---------------------------------------------------------------------------
    cat > "$SCRIPTS_DIR/playdate-simulator.sh" << 'SIMSCRIPT'
#!/bin/bash
#===============================================================================
# Playdate Simulator Launcher
# Usage: playdate-simulator.sh [options] [game.pdx]
#===============================================================================

SDK_PATH="${PLAYDATE_SDK_PATH:-$HOME/Developer/PlaydateSDK}"
SIMULATOR_APP="$SDK_PATH/Playdate Simulator.app"

show_help() {
    echo "Playdate Simulator Launcher"
    echo ""
    echo "Usage: $(basename $0) [options] [game.pdx]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -l, --list      List recently played games"
    echo "  -e, --examples  Launch SDK examples browser"
    echo "  -k, --kill      Kill running simulator"
    echo "  -r, --restart   Restart simulator with last game"
    echo "  -c, --console   Show console output in terminal"
    echo ""
    echo "Examples:"
    echo "  $(basename $0) output.pdx     # Launch specific game"
    echo "  $(basename $0)                # Launch simulator only"
    echo "  $(basename $0) -e             # Browse SDK examples"
}

list_recent() {
    echo "Recent .pdx files:"
    find ~/Developer -name "*.pdx" -type d -mtime -7 2>/dev/null | head -10
}

launch_examples() {
    echo "SDK Examples available:"
    ls -1 "$SDK_PATH/Examples/"
    echo ""
    read -p "Enter example name to run (or press Enter to cancel): " example
    if [[ -n "$example" && -d "$SDK_PATH/Examples/$example" ]]; then
        cd "$SDK_PATH/Examples/$example"
        if [[ -d "Source" ]]; then
            pdc Source output.pdx
        elif [[ -d "source" ]]; then
            pdc source output.pdx
        fi
        open -a "$SIMULATOR_APP" output.pdx
    fi
}

kill_simulator() {
    if pgrep -x "Playdate Simulator" > /dev/null; then
        echo "Killing Playdate Simulator..."
        pkill -x "Playdate Simulator"
        echo "Done."
    else
        echo "Simulator is not running."
    fi
}

launch_with_console() {
    local game="$1"
    echo "Launching simulator with console output..."
    echo "Press Ctrl+C to stop monitoring."
    echo "---"
    
    # Launch simulator
    if [[ -n "$game" ]]; then
        open -a "$SIMULATOR_APP" "$game"
    else
        open -a "$SIMULATOR_APP"
    fi
    
    # Follow simulator log (macOS Console approach)
    sleep 1
    log stream --predicate 'subsystem == "com.panic.playdatesimulator"' --style compact 2>/dev/null || {
        echo "Note: Console streaming requires macOS permissions"
        echo "Simulator is running - check its built-in console with Cmd+Shift+C"
    }
}

# Parse arguments
case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    -l|--list)
        list_recent
        exit 0
        ;;
    -e|--examples)
        launch_examples
        exit 0
        ;;
    -k|--kill)
        kill_simulator
        exit 0
        ;;
    -r|--restart)
        kill_simulator
        sleep 1
        open -a "$SIMULATOR_APP"
        exit 0
        ;;
    -c|--console)
        launch_with_console "$2"
        exit 0
        ;;
    "")
        # No arguments - just launch simulator
        open -a "$SIMULATOR_APP"
        ;;
    *)
        # Assume it's a .pdx file
        if [[ -d "$1" ]]; then
            open -a "$SIMULATOR_APP" "$1"
        else
            echo "Error: $1 is not a valid .pdx directory"
            exit 1
        fi
        ;;
esac
SIMSCRIPT
    chmod +x "$SCRIPTS_DIR/playdate-simulator.sh"
    
    #---------------------------------------------------------------------------
    # Create playdate-build-run.sh - Quick build and run
    #---------------------------------------------------------------------------
    cat > "$SCRIPTS_DIR/playdate-build-run.sh" << 'BUILDSCRIPT'
#!/bin/bash
#===============================================================================
# Quick Build and Run for Playdate
# Builds the current directory's source and launches in simulator
#===============================================================================

SDK_PATH="${PLAYDATE_SDK_PATH:-$HOME/Developer/PlaydateSDK}"
SIMULATOR_APP="$SDK_PATH/Playdate Simulator.app"

# Find source directory
if [[ -d "source" ]]; then
    SOURCE_DIR="source"
elif [[ -d "Source" ]]; then
    SOURCE_DIR="Source"
elif [[ -d "src" ]]; then
    SOURCE_DIR="src"
else
    echo "Error: No source directory found (looking for source/, Source/, or src/)"
    exit 1
fi

# Output name
OUTPUT="${1:-output.pdx}"

echo "🔨 Building $SOURCE_DIR -> $OUTPUT"
pdc "$SOURCE_DIR" "$OUTPUT"

if [[ $? -eq 0 ]]; then
    echo "✅ Build successful!"
    echo "🎮 Launching simulator..."
    open -a "$SIMULATOR_APP" "$OUTPUT"
else
    echo "❌ Build failed!"
    exit 1
fi
BUILDSCRIPT
    chmod +x "$SCRIPTS_DIR/playdate-build-run.sh"
    
    #---------------------------------------------------------------------------
    # Create playdate-watch.sh - File watcher for auto-rebuild
    #---------------------------------------------------------------------------
    cat > "$SCRIPTS_DIR/playdate-watch.sh" << 'WATCHSCRIPT'
#!/bin/bash
#===============================================================================
# Playdate Watch Mode - Auto-rebuild on file changes
# Requires: fswatch (brew install fswatch)
#===============================================================================

SDK_PATH="${PLAYDATE_SDK_PATH:-$HOME/Developer/PlaydateSDK}"
SIMULATOR_APP="$SDK_PATH/Playdate Simulator.app"

# Check for fswatch
if ! command -v fswatch &> /dev/null; then
    echo "Error: fswatch is required but not installed."
    echo "Install with: brew install fswatch"
    exit 1
fi

# Find source directory
if [[ -d "source" ]]; then
    SOURCE_DIR="source"
elif [[ -d "Source" ]]; then
    SOURCE_DIR="Source"
elif [[ -d "src" ]]; then
    SOURCE_DIR="src"
else
    echo "Error: No source directory found"
    exit 1
fi

OUTPUT="${1:-output.pdx}"

echo "👀 Watching $SOURCE_DIR for changes..."
echo "📦 Output: $OUTPUT"
echo "Press Ctrl+C to stop"
echo ""

# Initial build
echo "🔨 Initial build..."
pdc "$SOURCE_DIR" "$OUTPUT"
if [[ $? -eq 0 ]]; then
    echo "✅ Build successful! Launching simulator..."
    open -a "$SIMULATOR_APP" "$OUTPUT"
else
    echo "❌ Initial build failed!"
fi

echo ""
echo "Watching for changes..."

# Watch for changes
fswatch -o "$SOURCE_DIR" | while read event; do
    echo ""
    echo "📝 Change detected at $(date '+%H:%M:%S')"
    echo "🔨 Rebuilding..."
    
    pdc "$SOURCE_DIR" "$OUTPUT" 2>&1
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Build successful!"
        # Simulator auto-reloads when .pdx changes
    else
        echo "❌ Build failed!"
    fi
done
WATCHSCRIPT
    chmod +x "$SCRIPTS_DIR/playdate-watch.sh"
    
    #---------------------------------------------------------------------------
    # Create playdate-test-device.sh - Deploy to physical Playdate
    #---------------------------------------------------------------------------
    cat > "$SCRIPTS_DIR/playdate-test-device.sh" << 'DEVICESCRIPT'
#!/bin/bash
#===============================================================================
# Deploy to Physical Playdate Device
# Requires: Playdate connected via USB
#===============================================================================

SDK_PATH="${PLAYDATE_SDK_PATH:-$HOME/Developer/PlaydateSDK}"
PDUTIL="$SDK_PATH/bin/pdutil"

show_help() {
    echo "Deploy to Physical Playdate Device"
    echo ""
    echo "Usage: $(basename $0) [game.pdx]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help"
    echo "  -l, --list     List games on device"
    echo "  -i, --info     Show device info"
    echo ""
    echo "Note: Playdate must be connected via USB and unlocked"
}

check_device() {
    if ! "$PDUTIL" info &>/dev/null; then
        echo "❌ No Playdate device found!"
        echo ""
        echo "Make sure:"
        echo "  1. Playdate is connected via USB"
        echo "  2. Playdate is unlocked (press Lock button)"
        echo "  3. Playdate is not in storage mode"
        return 1
    fi
    return 0
}

case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    -l|--list)
        check_device || exit 1
        echo "Games on device:"
        "$PDUTIL" datadisk list
        ;;
    -i|--info)
        check_device || exit 1
        "$PDUTIL" info
        ;;
    "")
        # Build and install current project
        if [[ -d "source" ]]; then
            echo "🔨 Building..."
            pdc source output.pdx || exit 1
        fi
        
        if [[ -d "output.pdx" ]]; then
            check_device || exit 1
            echo "📲 Installing output.pdx to Playdate..."
            "$PDUTIL" install output.pdx
            echo "✅ Done! Game should now appear on your Playdate."
        else
            echo "❌ No output.pdx found. Build first!"
            exit 1
        fi
        ;;
    *)
        if [[ -d "$1" ]]; then
            check_device || exit 1
            echo "📲 Installing $1 to Playdate..."
            "$PDUTIL" install "$1"
            echo "✅ Done!"
        else
            echo "❌ $1 is not a valid .pdx directory"
            exit 1
        fi
        ;;
esac
DEVICESCRIPT
    chmod +x "$SCRIPTS_DIR/playdate-test-device.sh"
    
    #---------------------------------------------------------------------------
    # Create symlinks in /usr/local/bin (optional)
    #---------------------------------------------------------------------------
    print_step "Creating command shortcuts..."

    # Add scripts directory to PATH in shell config
    if [[ -n "$SHELL_RC" ]] && [[ -f "$SHELL_RC" ]]; then
        if ! grep -q "playdate-scripts" "$SHELL_RC" 2>/dev/null; then
            echo "" >> "$SHELL_RC"
            echo "# Playdate helper scripts" >> "$SHELL_RC"
            echo 'export PATH="$HOME/Developer/playdate-scripts:$PATH"' >> "$SHELL_RC"
        fi
    else
        print_warning "Shell config not found, skipping PATH addition"
        print_info "Add this to your shell config manually:"
        echo '  export PATH="$HOME/Developer/playdate-scripts:$PATH"'
    fi
    
    # Create shorter aliases
    ln -sf "$SCRIPTS_DIR/playdate-simulator.sh" "$SCRIPTS_DIR/pdsim"
    ln -sf "$SCRIPTS_DIR/playdate-build-run.sh" "$SCRIPTS_DIR/pdbr"
    ln -sf "$SCRIPTS_DIR/playdate-watch.sh" "$SCRIPTS_DIR/pdwatch"
    ln -sf "$SCRIPTS_DIR/playdate-test-device.sh" "$SCRIPTS_DIR/pddevice"
    
    print_success "Helper scripts created in $SCRIPTS_DIR"
    print_info "Commands available: pdsim, pdbr, pdwatch, pddevice"
}

#-------------------------------------------------------------------------------
# Create Agent Prompts File
#-------------------------------------------------------------------------------

create_agent_prompts() {
    print_header "Creating Agent Prompts Reference"
    
    PROMPTS_FILE="$HOME/Developer/playdate-agent-prompts.md"
    
    cat > "$PROMPTS_FILE" << 'PROMPTS'
# Playdate Development Agent Prompts

Use these prompts with Antigravity's Agent Manager or Claude Code to accelerate your Playdate game development.

## Getting Started

### Basic Game Structure
```
Create a basic Playdate game structure with:
- A player sprite that moves with the D-pad
- Screen boundary collision
- A simple score counter
- Game over state when pressing B button
```

### Crank-Based Game
```
Create a Playdate game that uses the crank as the primary input:
- Player controls a rotating object with the crank
- Objects spawn from the edges
- Player must align rotation to "catch" objects
- Track score and show game over screen
```

## Game Mechanics

### Add Sprite Animation
```
Add sprite animation to my Playdate game:
- Create an AnimatedSprite class
- Support for multiple animation states (idle, walk, jump)
- Frame-based animation with configurable speed
- Direction flipping for left/right movement
```

### Implement Tilemap
```
Implement a tilemap system for my Playdate game:
- Load a tilemap from a simple text file or table
- Support solid tiles for collision
- Camera scrolling that follows the player
- Efficient rendering using dirty rectangles
```

### Add Particle System
```
Create a simple particle system for Playdate:
- Particles spawn at a position with random velocities
- Support for gravity and drag
- Fade out over lifetime
- Object pooling for performance
```

### Implement State Machine
```
Create a game state machine for Playdate:
- States: Menu, Playing, Paused, GameOver
- Clean transitions between states
- Each state handles its own input and rendering
- Easy to add new states
```

## UI Components

### Create Menu System
```
Create a menu system for my Playdate game:
- Crank-controlled selection (like a dial)
- Visual feedback for current selection
- Support for nested submenus
- Sound effects for navigation
```

### Add Dialog System
```
Implement a dialog/text box system:
- Character-by-character text reveal
- Support for multiple pages
- A button to advance, B to skip
- Optional character portrait support
```

### Create HUD
```
Create a HUD overlay for my game:
- Health bar (hearts or bar style)
- Score display with animated counting
- Timer display
- Item inventory slots
```

## Audio

### Add Sound Effects
```
Set up a sound effect system:
- Preload common sounds (jump, collect, hit)
- Support for pitch variation
- Volume control
- Don't overlap same sound too quickly
```

### Add Music System
```
Implement background music:
- Looping music playback
- Fade in/out transitions
- Multiple tracks for different game states
- Pause/resume with game state
```

## Save System

### Implement Save/Load
```
Create a save game system:
- Save player progress, score, and settings
- Load on game start
- Auto-save on game pause/exit
- Handle missing or corrupted save data
```

## Performance

### Optimize Rendering
```
Help me optimize my Playdate game's rendering:
- Identify what's being redrawn unnecessarily  
- Implement dirty rectangle tracking
- Use sprites efficiently
- Profile and target 30 FPS consistently
```

### Memory Management
```
Review my code for memory issues:
- Find potential memory leaks
- Optimize table usage
- Reduce garbage collection pauses
- Use object pooling where appropriate
```

## Debugging

### Add Debug Mode
```
Add a debug mode to my game:
- Toggle with B button hold
- Show FPS counter
- Display player position and state
- Show collision boxes
- Memory usage display
```

## Complete Game Examples

### Breakout Clone
```
Create a complete Breakout/Arkanoid clone for Playdate:
- Crank-controlled paddle
- Ball physics with angle reflection
- 3 rows of destructible bricks
- Lives system (3 lives)
- Score tracking
- Game over and restart
```

### Endless Runner
```
Create an endless runner game for Playdate:
- Auto-scrolling background
- A button to jump
- Crank to control lane (3 lanes)
- Obstacles to avoid
- Collectibles for points
- Increasing difficulty over time
```

### Puzzle Game
```
Create a match-3 puzzle game for Playdate:
- 6x6 grid of symbols
- D-pad to move cursor
- A to select/swap
- Crank to rotate selected piece
- Match 3+ to clear
- Cascade falling pieces
- Score and level system
```

## Tips for Working with AI Agents

1. **Be Specific**: Include Playdate-specific requirements (1-bit graphics, 400x240 resolution, crank input)

2. **Mention Performance**: Always ask for Playdate-optimized code (local variables, object pooling)

3. **Request Comments**: Ask for well-commented code explaining Playdate-specific patterns

4. **Test Incrementally**: Build and test after each feature, don't try to generate entire games at once

5. **Provide Context**: Share your existing code structure so the agent can integrate properly
PROMPTS

    print_success "Agent prompts saved to $PROMPTS_FILE"
}

#-------------------------------------------------------------------------------
# Final Summary
#-------------------------------------------------------------------------------

print_summary() {
    print_header "Setup Complete! 🎮"
    
    echo -e "${GREEN}Your Playdate development environment is ready!${NC}"
    echo ""
    echo -e "${BOLD}Installed Components:${NC}"
    echo "  ✔ Playdate SDK at: $SDK_PATH"
    echo "  ✔ Playdate Simulator configured"
    [[ -d "/Applications/Antigravity.app" ]] && echo "  ✔ Google Antigravity IDE"
    check_command claude && echo "  ✔ Claude Code CLI"
    echo "  ✔ Starter project at: $HOME/Developer/$PROJECT_NAME"
    echo "  ✔ Helper scripts at: $HOME/Developer/playdate-scripts/"
    echo ""
    echo -e "${BOLD}Quick Start:${NC}"
    echo ""
    echo "  1. Reload your shell:"
    echo -e "     ${CYAN}source ~/.zshrc${NC}"
    echo ""
    echo "  2. Open your project in Antigravity:"
    echo -e "     ${CYAN}cd ~/Developer/$PROJECT_NAME${NC}"
    echo -e "     ${CYAN}open -a Antigravity .${NC}"
    echo ""
    echo "  3. Build and run with Cmd+Shift+B"
    echo ""
    echo -e "${BOLD}Simulator Commands:${NC}"
    echo ""
    echo -e "  ${CYAN}pdsim${NC}              - Launch Playdate Simulator"
    echo -e "  ${CYAN}pdsim game.pdx${NC}     - Launch specific game"
    echo -e "  ${CYAN}pdsim -e${NC}           - Browse SDK examples"
    echo -e "  ${CYAN}pdsim -k${NC}           - Kill running simulator"
    echo ""
    echo -e "${BOLD}Build Commands:${NC}"
    echo ""
    echo -e "  ${CYAN}pdbr${NC}               - Build and run current project"
    echo -e "  ${CYAN}pdwatch${NC}            - Watch mode (auto-rebuild on save)"
    echo -e "  ${CYAN}pdc-build${NC}          - Build only"
    echo -e "  ${CYAN}pdc-run${NC}            - Build and run"
    echo -e "  ${CYAN}pdc-clean${NC}          - Remove output.pdx"
    echo ""
    echo -e "${BOLD}Device Commands:${NC}"
    echo ""
    echo -e "  ${CYAN}pddevice${NC}           - Deploy to physical Playdate"
    echo -e "  ${CYAN}pddevice -l${NC}        - List games on device"
    echo -e "  ${CYAN}pddevice -i${NC}        - Show device info"
    echo ""
    echo -e "${BOLD}Helper Functions:${NC}"
    echo ""
    echo -e "  ${CYAN}playdate-test${NC}      - Build and run (with options)"
    echo -e "  ${CYAN}playdate-watch${NC}     - Watch mode with full output"
    echo -e "  ${CYAN}playdate-docs${NC}      - Open SDK documentation"
    echo -e "  ${CYAN}playdate-examples${NC}  - List SDK examples"
    echo ""
    echo -e "${BOLD}IDE Tasks (Cmd+Shift+P):${NC}"
    echo ""
    echo "  • Playdate: Build and Run      (Cmd+Shift+B)"
    echo "  • Playdate: Watch Mode         (auto-rebuild)"
    echo "  • Playdate: Open Documentation"
    echo "  • Playdate: View SDK Examples"
    echo ""
    echo -e "${BOLD}Resources:${NC}"
    echo ""
    echo "  • SDK Docs: $SDK_PATH/Documentation/Inside Playdate.html"
    echo "  • Examples: $SDK_PATH/Examples/"
    echo "  • Agent Prompts: ~/Developer/playdate-agent-prompts.md"
    echo "  • Dev Forum: https://devforum.play.date/"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Reload your shell: source ~/.zshrc"
    echo "  2. Test the simulator: pdsim"
    echo "  3. Run the starter project: cd ~/Developer/$PROJECT_NAME && pdbr"
    echo "  4. Sign into Antigravity with your Google account"
    echo "  5. Authenticate Claude Code: claude auth"
    echo ""
    echo -e "${GREEN}Happy game development! 🕹️${NC}"
}

#-------------------------------------------------------------------------------
# Main Execution
#-------------------------------------------------------------------------------

main() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                                                                   ║"
    echo "║   🎮  Playdate Development Environment Setup Script  🎮          ║"
    echo "║                                                                   ║"
    echo "║   For macOS with Google Antigravity + Claude Code                ║"
    echo "║                                                                   ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    preflight_checks
    install_homebrew
    install_dependencies
    install_playdate_sdk
    configure_simulator
    configure_shell
    install_antigravity
    install_claude_code
    install_extensions
    create_starter_project
    create_simulator_scripts
    create_agent_prompts
    print_summary
}

# Run main function
main "$@"
