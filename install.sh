#!/bin/bash
#===============================================================================
# Playdate Development Environment - Dependency Installer
#
# This script ONLY installs external dependencies that can't live in the repo:
# - Homebrew (package manager)
# - Playdate SDK (required location: ~/Developer/PlaydateSDK)
# - System tools (node, fswatch, etc.)
# - IDE extensions
#
# All helper scripts, templates, and docs live in this repo.
# After running this, source setup-env.sh to configure your shell.
#
# Usage: ./install.sh
#===============================================================================

set -euo pipefail

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cached system info
OS_NAME="$(uname)"
ARCH="$(uname -m)"
IS_ARM64=$([[ "$ARCH" == "arm64" ]] && echo true || echo false)
readonly OS_NAME ARCH IS_ARM64

# Configuration
readonly PLAYDATE_SDK_VERSION="2.6.2"
readonly SDK_INSTALL_DIR="$HOME/Developer"
readonly SDK_PATH="$SDK_INSTALL_DIR/PlaydateSDK"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_step() { echo -e "${BLUE}▶${NC} $1"; }
print_success() { echo -e "${GREEN}✔${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✖${NC} $1"; }
print_info() { echo -e "${CYAN}ℹ${NC} $1"; }

check_command() { command -v "$1" &> /dev/null; }

#-------------------------------------------------------------------------------
# Pre-flight Checks
#-------------------------------------------------------------------------------

preflight_checks() {
    print_header "Pre-flight Checks"

    if [[ "$OS_NAME" != "Darwin" ]]; then
        print_error "This script is designed for macOS only."
        exit 1
    fi
    print_success "Running on macOS"

    if [[ "$IS_ARM64" == "true" ]]; then
        print_success "Apple Silicon detected"
    else
        print_warning "Intel Mac detected - should still work"
    fi

    echo ""
    print_info "This will install external dependencies only."
    print_info "Scripts and templates stay in: $SCRIPT_DIR"
    echo ""
    read -r -p "Press Enter to continue or Ctrl+C to abort..."
}

#-------------------------------------------------------------------------------
# Install Homebrew
#-------------------------------------------------------------------------------

install_homebrew() {
    print_header "Homebrew"

    if check_command brew; then
        print_success "Homebrew is already installed"
        print_step "Updating Homebrew..."
        brew update
    else
        print_step "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

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
# Install System Dependencies
#-------------------------------------------------------------------------------

install_dependencies() {
    print_header "System Dependencies"

    local to_install=()

    check_command node || to_install+=("node")
    check_command fswatch || to_install+=("fswatch")

    if [[ ${#to_install[@]} -gt 0 ]]; then
        print_step "Installing: ${to_install[*]}..."
        brew install "${to_install[@]}"
        print_success "Dependencies installed"
    else
        print_success "All dependencies already installed"
    fi
}

#-------------------------------------------------------------------------------
# Install Playdate SDK
#-------------------------------------------------------------------------------

install_playdate_sdk() {
    print_header "Playdate SDK"

    if [[ -d "$SDK_PATH" ]]; then
        print_success "Playdate SDK already installed at $SDK_PATH"
        return 0
    fi

    mkdir -p "$SDK_INSTALL_DIR"
    cd "$SDK_INSTALL_DIR"

    print_warning "The Playdate SDK requires manual download"
    print_info "Please follow these steps:"
    echo ""
    echo "  1. Opening https://play.date/dev/ in your browser"
    echo "  2. Create an account or sign in"
    echo "  3. Download the macOS SDK"
    echo "  4. Move the .zip to: $SDK_INSTALL_DIR/"
    echo ""

    open "https://play.date/dev/"
    read -r -p "Press Enter after downloading the SDK..."

    # Find the SDK zip
    local sdk_zip
    sdk_zip=$(find . -maxdepth 1 -name "PlaydateSDK*.zip" -type f -print -quit 2>/dev/null)

    if [[ -z "$sdk_zip" ]]; then
        print_error "SDK zip not found in $SDK_INSTALL_DIR"
        print_info "Download manually and re-run this script"
        exit 1
    fi

    print_step "Extracting SDK zip..."
    unzip -q -o "$sdk_zip"

    # Look for .pkg installer (Panic distributes SDK as a .pkg)
    local pkg_file
    pkg_file=$(find . -maxdepth 1 -name "PlaydateSDK*.pkg" -type f -print -quit 2>/dev/null)

    if [[ -n "$pkg_file" ]]; then
        print_info "Found installer package: $pkg_file"
        print_warning "The SDK installer will now open."
        print_info "Please complete the installation, then return here."
        echo ""
        read -r -p "Press Enter to open the installer..."

        open "$pkg_file"

        echo ""
        print_info "Complete the installation in the GUI, then press Enter."
        read -r -p "Press Enter after installation is complete..."

        # Verify installation succeeded
        if [[ -d "$SDK_PATH" ]]; then
            print_success "Playdate SDK installed to $SDK_PATH"
            # Clean up
            rm -f "$pkg_file"
            rm -rf "__MACOSX" 2>/dev/null || true
            rm -f "$sdk_zip"
        else
            print_error "SDK installation failed - $SDK_PATH not found"
            print_info "Run the installer manually: open $pkg_file"
            exit 1
        fi
    else
        # Fallback: maybe it's a direct directory extraction (older SDK versions?)
        local sdk_dir
        sdk_dir=$(find . -maxdepth 1 -type d -name "PlaydateSDK*" -print -quit 2>/dev/null)

        if [[ -n "$sdk_dir" && "$sdk_dir" != "./PlaydateSDK" ]]; then
            sdk_dir="${sdk_dir#./}"
            if [[ -d "PlaydateSDK" ]]; then
                rm -rf "PlaydateSDK"
            fi
            mv "$sdk_dir" "PlaydateSDK"
        fi

        if [[ -d "$SDK_PATH" ]]; then
            rm -f "$sdk_zip"
            print_success "Playdate SDK installed to $SDK_PATH"
        else
            print_error "SDK installation failed"
            print_info "Could not find SDK directory or installer package"
            exit 1
        fi
    fi

    # Remove quarantine
    xattr -dr com.apple.quarantine "$SDK_PATH/Playdate Simulator.app" 2>/dev/null || true
}

#-------------------------------------------------------------------------------
# Install IDE Extensions
#-------------------------------------------------------------------------------

install_extensions() {
    print_header "IDE Extensions"

    local code_cli=""

    if [[ -f "/Applications/Antigravity.app/Contents/Resources/app/bin/antigravity" ]]; then
        code_cli="/Applications/Antigravity.app/Contents/Resources/app/bin/antigravity"
        print_info "Using Antigravity CLI"
    elif check_command code; then
        code_cli="code"
        print_info "Using VS Code CLI"
    else
        print_warning "No IDE CLI found - install extensions manually:"
        echo "  • sumneko.lua"
        echo "  • Orta.playdate"
        return 0
    fi

    local extensions=("sumneko.lua" "Orta.playdate")

    for ext in "${extensions[@]}"; do
        print_step "Installing: $ext"
        "$code_cli" --install-extension "$ext" 2>/dev/null || \
            print_warning "Could not install $ext"
    done

    print_success "Extensions installation complete"
}

#-------------------------------------------------------------------------------
# Final Instructions
#-------------------------------------------------------------------------------

print_instructions() {
    print_header "Setup Complete!"

    echo -e "${GREEN}External dependencies installed successfully.${NC}"
    echo ""
    echo -e "${BOLD}Next Steps:${NC}"
    echo ""
    echo "  1. Add this repo's scripts to your PATH. Add to ~/.zshrc:"
    echo ""
    echo -e "     ${CYAN}source \"$SCRIPT_DIR/setup-env.sh\"${NC}"
    echo ""
    echo "  2. Reload your shell:"
    echo ""
    echo -e "     ${CYAN}source ~/.zshrc${NC}"
    echo ""
    echo "  3. Create a new project from template:"
    echo ""
    echo -e "     ${CYAN}make new-project NAME=MyGame${NC}"
    echo ""
    echo -e "${BOLD}Available Commands (after sourcing setup-env.sh):${NC}"
    echo ""
    echo -e "  ${CYAN}pdsim${NC}        - Launch Playdate Simulator"
    echo -e "  ${CYAN}pdbr${NC}         - Build and run current project"
    echo -e "  ${CYAN}pdwatch${NC}      - Watch mode (auto-rebuild)"
    echo -e "  ${CYAN}pddevice${NC}     - Deploy to physical Playdate"
    echo ""
    echo -e "${BOLD}Makefile Commands:${NC}"
    echo ""
    echo -e "  ${CYAN}make new-project NAME=MyGame${NC}     - Create from template"
    echo -e "  ${CYAN}make new-project NAME=MyGame TEMPLATE=crank-game${NC}"
    echo -e "  ${CYAN}make list-templates${NC}              - Show available templates"
    echo -e "  ${CYAN}make list-examples${NC}               - Show example projects"
    echo ""
}

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------

main() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}Playdate Development Environment - Installer${NC}                     ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"

    preflight_checks
    install_homebrew
    install_dependencies
    install_playdate_sdk
    install_extensions
    print_instructions
}

main "$@"
