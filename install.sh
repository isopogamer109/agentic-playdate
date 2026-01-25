#!/bin/bash
#===============================================================================
# Playdate Development Environment - Cross-Platform Dependency Installer
#
# Supports: macOS, Linux (Debian/Ubuntu, Fedora, Arch), Windows (Git Bash/MSYS2)
#
# This script ONLY installs external dependencies that can't live in the repo:
# - Package manager setup (Homebrew on macOS, native on Linux, Chocolatey on Windows)
# - Playdate SDK (platform-specific installation)
# - System tools (node, fswatch/inotify-tools, etc.)
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

# Source platform utilities
source "$SCRIPT_DIR/scripts/platform-utils.sh"

# Configuration
readonly PLAYDATE_SDK_VERSION="2.6.2"

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

    print_success "Detected platform: $PLATFORM_OS ($PLATFORM_ARCH)"

    case "$PLATFORM_OS" in
        macos)
            print_success "Running on macOS"
            if [[ "$PLATFORM_ARCH" == "arm64" ]]; then
                print_success "Apple Silicon detected"
            else
                print_info "Intel Mac detected"
            fi
            ;;
        linux)
            print_success "Running on Linux"
            print_info "Distribution: $PLATFORM_DISTRO"
            ;;
        wsl)
            print_success "Running on Windows Subsystem for Linux (WSL)"
            print_warning "Some features may require Windows-native tools"
            ;;
        windows)
            print_success "Running on Windows (Git Bash/MSYS2)"
            print_warning "Make sure you're running as Administrator for some operations"
            ;;
        *)
            print_error "Unknown platform: $PLATFORM_OS"
            print_info "This script supports macOS, Linux, and Windows"
            exit 1
            ;;
    esac

    echo ""
    print_info "This will install external dependencies only."
    print_info "Scripts and templates stay in: $SCRIPT_DIR"
    echo ""
    read -r -p "Press Enter to continue or Ctrl+C to abort..."
}

#-------------------------------------------------------------------------------
# Install Package Manager (macOS and Windows only)
#-------------------------------------------------------------------------------

install_package_manager() {
    print_header "Package Manager"

    case "$PLATFORM_OS" in
        macos)
            if check_command brew; then
                print_success "Homebrew is already installed"
                print_step "Updating Homebrew..."
                brew update
            else
                print_step "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

                if [[ "$PLATFORM_ARCH" == "arm64" ]]; then
                    if ! grep -q '/opt/homebrew/bin/brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
                        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
                    fi
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                fi
                print_success "Homebrew installed"
            fi
            ;;
        linux|wsl)
            # Linux uses native package managers
            local pm
            pm="$(get_package_manager)"
            print_success "Using native package manager: $pm"

            case "$pm" in
                apt)
                    print_step "Updating package lists..."
                    sudo apt update
                    ;;
                dnf)
                    print_step "Updating package cache..."
                    sudo dnf check-update || true
                    ;;
                pacman)
                    print_step "Updating package database..."
                    sudo pacman -Sy
                    ;;
            esac
            ;;
        windows)
            if check_command winget; then
                print_success "Windows Package Manager (winget) is available"
            elif check_command choco; then
                print_success "Chocolatey is available"
            elif check_command scoop; then
                print_success "Scoop is available"
            else
                print_warning "No package manager found"
                print_info "Recommended: Install Chocolatey from https://chocolatey.org/install"
                print_info "Or install winget from the Microsoft Store (App Installer)"
                echo ""
                read -r -p "Continue without package manager? [y/N] " response
                if [[ ! "$response" =~ ^[Yy]$ ]]; then
                    exit 1
                fi
            fi
            ;;
    esac
}

#-------------------------------------------------------------------------------
# Install System Dependencies
#-------------------------------------------------------------------------------

install_dependencies() {
    print_header "System Dependencies"

    local needs_node=false
    local needs_watcher=false

    check_command node || needs_node=true
    has_file_watcher || needs_watcher=true

    if [[ "$needs_node" == "false" && "$needs_watcher" == "false" ]]; then
        print_success "All dependencies already installed"
        return 0
    fi

    case "$PLATFORM_OS" in
        macos)
            local to_install=()
            [[ "$needs_node" == "true" ]] && to_install+=("node")
            [[ "$needs_watcher" == "true" ]] && to_install+=("fswatch")

            if [[ ${#to_install[@]} -gt 0 ]]; then
                print_step "Installing: ${to_install[*]}..."
                brew install "${to_install[@]}"
                print_success "Dependencies installed"
            fi
            ;;
        linux|wsl)
            local pm
            pm="$(get_package_manager)"

            if [[ "$needs_node" == "true" ]]; then
                print_step "Installing Node.js..."
                case "$pm" in
                    apt)
                        sudo apt install -y nodejs npm
                        ;;
                    dnf)
                        sudo dnf install -y nodejs npm
                        ;;
                    pacman)
                        sudo pacman -S --noconfirm nodejs npm
                        ;;
                esac
            fi

            if [[ "$needs_watcher" == "true" ]]; then
                print_step "Installing inotify-tools..."
                case "$pm" in
                    apt)
                        sudo apt install -y inotify-tools
                        ;;
                    dnf)
                        sudo dnf install -y inotify-tools
                        ;;
                    pacman)
                        sudo pacman -S --noconfirm inotify-tools
                        ;;
                esac
            fi
            print_success "Dependencies installed"
            ;;
        windows)
            local pm
            pm="$(get_package_manager)"

            if [[ "$needs_node" == "true" ]]; then
                print_step "Installing Node.js..."
                case "$pm" in
                    winget)
                        winget install OpenJS.NodeJS.LTS
                        ;;
                    choco)
                        choco install nodejs-lts -y
                        ;;
                    scoop)
                        scoop install nodejs-lts
                        ;;
                    *)
                        print_warning "Please install Node.js manually from https://nodejs.org/"
                        ;;
                esac
            fi

            if [[ "$needs_watcher" == "true" ]]; then
                print_warning "File watching on Windows uses polling mode"
                print_info "For better performance, consider using WSL"
            fi
            print_success "Dependencies installed"
            ;;
    esac
}

#-------------------------------------------------------------------------------
# Install Playdate SDK
#-------------------------------------------------------------------------------

install_playdate_sdk() {
    print_header "Playdate SDK"

    local sdk_path
    sdk_path="$(get_default_sdk_path)"
    local sdk_dir
    sdk_dir="$(dirname "$sdk_path")"

    if [[ -d "$sdk_path" ]]; then
        print_success "Playdate SDK already installed at $sdk_path"
        return 0
    fi

    mkdir -p "$sdk_dir"
    cd "$sdk_dir"

    print_warning "The Playdate SDK requires manual download"
    print_info "Please follow these steps:"
    echo ""
    echo "  1. Visit https://play.date/dev/ in your browser"
    echo "  2. Create an account or sign in"

    case "$PLATFORM_OS" in
        macos)
            echo "  3. Download the macOS SDK"
            ;;
        linux|wsl)
            echo "  3. Download the Linux SDK"
            ;;
        windows)
            echo "  3. Download the Windows SDK"
            ;;
    esac

    echo "  4. Move the downloaded file to: $sdk_dir/"
    echo ""

    open_path "https://play.date/dev/"
    read -r -p "Press Enter after downloading the SDK..."

    case "$PLATFORM_OS" in
        macos)
            install_sdk_macos "$sdk_path"
            ;;
        linux|wsl)
            install_sdk_linux "$sdk_path"
            ;;
        windows)
            install_sdk_windows "$sdk_path"
            ;;
    esac
}

install_sdk_macos() {
    local sdk_path="$1"
    local sdk_dir
    sdk_dir="$(dirname "$sdk_path")"
    cd "$sdk_dir"

    # Find the SDK zip
    local sdk_zip
    sdk_zip=$(find . -maxdepth 1 -name "PlaydateSDK*.zip" -type f -print -quit 2>/dev/null)

    if [[ -z "$sdk_zip" ]]; then
        print_error "SDK zip not found in $sdk_dir"
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
        if [[ -d "$sdk_path" ]]; then
            print_success "Playdate SDK installed to $sdk_path"
            # Clean up
            rm -f "$pkg_file"
            rm -rf "__MACOSX" 2>/dev/null || true
            rm -f "$sdk_zip"
        else
            print_error "SDK installation failed - $sdk_path not found"
            print_info "Run the installer manually: open $pkg_file"
            exit 1
        fi
    else
        handle_sdk_directory "$sdk_path" "$sdk_zip"
    fi

    # Remove quarantine (macOS-specific)
    xattr -dr com.apple.quarantine "$sdk_path/Playdate Simulator.app" 2>/dev/null || true
}

install_sdk_linux() {
    local sdk_path="$1"
    local sdk_dir
    sdk_dir="$(dirname "$sdk_path")"
    cd "$sdk_dir"

    # Find the SDK tarball or zip
    local sdk_archive
    sdk_archive=$(find . -maxdepth 1 \( -name "PlaydateSDK*.tar.gz" -o -name "PlaydateSDK*.zip" \) -type f -print -quit 2>/dev/null)

    if [[ -z "$sdk_archive" ]]; then
        print_error "SDK archive not found in $sdk_dir"
        print_info "Download the Linux SDK and re-run this script"
        exit 1
    fi

    print_step "Extracting SDK..."
    case "$sdk_archive" in
        *.tar.gz)
            tar -xzf "$sdk_archive"
            ;;
        *.zip)
            unzip -q -o "$sdk_archive"
            ;;
    esac

    handle_sdk_directory "$sdk_path" "$sdk_archive"

    # Make binaries executable
    if [[ -d "$sdk_path/bin" ]]; then
        chmod +x "$sdk_path/bin/"* 2>/dev/null || true
    fi
}

install_sdk_windows() {
    local sdk_path="$1"
    local sdk_dir
    sdk_dir="$(dirname "$sdk_path")"
    cd "$sdk_dir"

    # Find the SDK zip
    local sdk_zip
    sdk_zip=$(find . -maxdepth 1 -name "PlaydateSDK*.zip" -type f -print -quit 2>/dev/null)

    if [[ -z "$sdk_zip" ]]; then
        # Check for exe installer
        local sdk_exe
        sdk_exe=$(find . -maxdepth 1 -name "PlaydateSDK*.exe" -type f -print -quit 2>/dev/null)

        if [[ -n "$sdk_exe" ]]; then
            print_info "Found installer: $sdk_exe"
            print_warning "Please run the installer and follow the prompts."
            read -r -p "Press Enter to run the installer..."

            # Run the installer
            cmd //c "$sdk_exe" || "$sdk_exe"

            read -r -p "Press Enter after installation is complete..."

            if [[ -d "$sdk_path" ]]; then
                print_success "Playdate SDK installed to $sdk_path"
                rm -f "$sdk_exe"
            else
                print_error "SDK installation failed - $sdk_path not found"
                exit 1
            fi
            return 0
        fi

        print_error "SDK file not found in $sdk_dir"
        print_info "Download the Windows SDK and re-run this script"
        exit 1
    fi

    print_step "Extracting SDK zip..."
    unzip -q -o "$sdk_zip"

    handle_sdk_directory "$sdk_path" "$sdk_zip"
}

# Helper to handle SDK directory naming after extraction
handle_sdk_directory() {
    local sdk_path="$1"
    local sdk_archive="$2"

    local sdk_dir_name
    sdk_dir_name="$(basename "$sdk_path")"

    local extracted_dir
    extracted_dir=$(find . -maxdepth 1 -type d -name "PlaydateSDK*" ! -name "$sdk_dir_name" -print -quit 2>/dev/null)

    if [[ -n "$extracted_dir" ]]; then
        extracted_dir="${extracted_dir#./}"
        if [[ -d "$sdk_dir_name" ]]; then
            rm -rf "$sdk_dir_name"
        fi
        mv "$extracted_dir" "$sdk_dir_name"
    fi

    if [[ -d "$sdk_path" ]]; then
        rm -f "$sdk_archive"
        print_success "Playdate SDK installed to $sdk_path"
    else
        print_error "SDK installation failed"
        print_info "Could not find SDK directory after extraction"
        exit 1
    fi
}

#-------------------------------------------------------------------------------
# Install IDE Extensions
#-------------------------------------------------------------------------------

install_extensions() {
    print_header "IDE Extensions"

    local code_cli=""

    # Check for VS Code variants (cross-platform)
    if check_command code; then
        code_cli="code"
        print_info "Using VS Code CLI"
    elif check_command codium; then
        code_cli="codium"
        print_info "Using VSCodium CLI"
    elif [[ "$PLATFORM_OS" == "macos" && -f "/Applications/Antigravity.app/Contents/Resources/app/bin/antigravity" ]]; then
        # Antigravity is macOS-only alternative
        code_cli="/Applications/Antigravity.app/Contents/Resources/app/bin/antigravity"
        print_info "Using Antigravity CLI (macOS)"
    else
        print_warning "VS Code not found - install extensions manually:"
        echo "  - sumneko.lua"
        echo "  - Orta.playdate"
        echo ""
        print_info "Install VS Code from: https://code.visualstudio.com/"
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

    local sdk_path
    sdk_path="$(get_default_sdk_path)"
    local shell_rc

    case "$PLATFORM_OS" in
        macos)
            shell_rc="~/.zshrc"
            ;;
        linux|wsl)
            shell_rc="~/.bashrc"
            ;;
        windows)
            shell_rc="~/.bashrc or Git Bash profile"
            ;;
    esac

    echo -e "${GREEN}External dependencies installed successfully.${NC}"
    echo ""
    echo -e "${BOLD}Next Steps:${NC}"
    echo ""
    echo "  1. Add this repo's scripts to your PATH. Add to $shell_rc:"
    echo ""
    echo -e "     ${CYAN}source \"$SCRIPT_DIR/setup-env.sh\"${NC}"
    echo ""
    echo "  2. Reload your shell:"
    echo ""

    case "$PLATFORM_OS" in
        macos)
            echo -e "     ${CYAN}source ~/.zshrc${NC}"
            ;;
        linux|wsl)
            echo -e "     ${CYAN}source ~/.bashrc${NC}"
            ;;
        windows)
            echo -e "     ${CYAN}source ~/.bashrc${NC}  (or restart Git Bash)"
            ;;
    esac

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
    echo -e "${BOLD}Platform Information:${NC}"
    echo ""
    echo -e "  OS: ${CYAN}$PLATFORM_OS${NC}"
    echo -e "  SDK Path: ${CYAN}$sdk_path${NC}"
    echo ""
}

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------

main() {
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}Playdate Development Environment - Installer${NC}                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  Supports: macOS, Linux, Windows                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"

    preflight_checks
    install_package_manager
    install_dependencies
    install_playdate_sdk
    install_extensions
    print_instructions
}

main "$@"
