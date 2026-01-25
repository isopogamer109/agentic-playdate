#!/bin/bash
#===============================================================================
# Playdate Development Environment - Cross-Platform Utilities
#
# This file provides platform-agnostic functions for:
# - OS/platform detection
# - Opening files/URLs/applications
# - In-place file editing (sed)
# - File system watching
# - Package manager abstraction
#
# Source this file in other scripts:
#   source "$(dirname "${BASH_SOURCE[0]}")/platform-utils.sh"
#===============================================================================

#-------------------------------------------------------------------------------
# Platform Detection
#-------------------------------------------------------------------------------

# Detect OS type: "macos", "linux", "windows" (Git Bash/MSYS2/WSL)
detect_os() {
    case "$(uname -s)" in
        Darwin)
            echo "macos"
            ;;
        Linux)
            # Check if running under WSL
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Detect Linux distribution: "debian", "fedora", "arch", "unknown"
detect_linux_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|pop|linuxmint|elementary)
                echo "debian"
                ;;
            fedora|rhel|centos|rocky|alma)
                echo "fedora"
                ;;
            arch|manjaro|endeavouros)
                echo "arch"
                ;;
            opensuse*|suse*)
                echo "suse"
                ;;
            *)
                echo "unknown"
                ;;
        esac
    else
        echo "unknown"
    fi
}

# Detect CPU architecture
detect_arch() {
    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64|amd64)
            echo "x64"
            ;;
        arm64|aarch64)
            echo "arm64"
            ;;
        armv7*|armhf)
            echo "arm"
            ;;
        i386|i686)
            echo "x86"
            ;;
        *)
            echo "$arch"
            ;;
    esac
}

# Cache OS detection (call once at script start for performance)
PLATFORM_OS="${PLATFORM_OS:-$(detect_os)}"
PLATFORM_ARCH="${PLATFORM_ARCH:-$(detect_arch)}"
PLATFORM_DISTRO=""
if [[ "$PLATFORM_OS" == "linux" ]]; then
    PLATFORM_DISTRO="${PLATFORM_DISTRO:-$(detect_linux_distro)}"
fi

#-------------------------------------------------------------------------------
# SDK Path Configuration
#-------------------------------------------------------------------------------

# Get the default SDK installation path for the current platform
get_default_sdk_path() {
    case "$PLATFORM_OS" in
        macos)
            echo "$HOME/Developer/PlaydateSDK"
            ;;
        linux|wsl)
            echo "$HOME/PlaydateSDK"
            ;;
        windows)
            # Git Bash uses /c/Users/... format
            echo "$HOME/Documents/PlaydateSDK"
            ;;
        *)
            echo "$HOME/PlaydateSDK"
            ;;
    esac
}

# Get the simulator executable path
get_simulator_path() {
    local sdk_path="${1:-$PLAYDATE_SDK_PATH}"
    case "$PLATFORM_OS" in
        macos)
            echo "$sdk_path/Playdate Simulator.app"
            ;;
        linux|wsl)
            echo "$sdk_path/bin/PlaydateSimulator"
            ;;
        windows)
            echo "$sdk_path/bin/PlaydateSimulator.exe"
            ;;
        *)
            echo "$sdk_path/bin/PlaydateSimulator"
            ;;
    esac
}

# Get the simulator process name for pgrep/pkill
get_simulator_process_name() {
    case "$PLATFORM_OS" in
        macos)
            echo "Playdate Simulator"
            ;;
        *)
            echo "PlaydateSimulator"
            ;;
    esac
}

#-------------------------------------------------------------------------------
# Open Files/URLs/Applications
#-------------------------------------------------------------------------------

# Open a file, URL, or application in the default handler
# Usage: open_path <path_or_url>
open_path() {
    local target="$1"
    case "$PLATFORM_OS" in
        macos)
            open "$target"
            ;;
        linux)
            xdg-open "$target" 2>/dev/null || \
            sensible-browser "$target" 2>/dev/null || \
            x-www-browser "$target" 2>/dev/null || \
            gnome-open "$target" 2>/dev/null || \
            echo "Error: No suitable opener found. Install xdg-utils."
            ;;
        wsl)
            # WSL can use Windows' start command via cmd.exe
            cmd.exe /c start "" "$target" 2>/dev/null || \
            wslview "$target" 2>/dev/null || \
            xdg-open "$target" 2>/dev/null
            ;;
        windows)
            start "" "$target" 2>/dev/null || \
            cmd //c start "" "$target"
            ;;
        *)
            echo "Error: Unknown platform. Cannot open: $target"
            return 1
            ;;
    esac
}

# Open the Playdate Simulator, optionally with a .pdx file
# Usage: open_simulator [pdx_file]
open_simulator() {
    local pdx_file="${1:-}"
    local sdk_path="${PLAYDATE_SDK_PATH:-$(get_default_sdk_path)}"
    local simulator
    simulator="$(get_simulator_path "$sdk_path")"

    case "$PLATFORM_OS" in
        macos)
            if [[ -n "$pdx_file" ]]; then
                open -a "$simulator" "$pdx_file"
            else
                open -a "$simulator"
            fi
            ;;
        linux)
            if [[ -x "$simulator" ]]; then
                if [[ -n "$pdx_file" ]]; then
                    "$simulator" "$pdx_file" &
                else
                    "$simulator" &
                fi
            else
                echo "Error: Simulator not found at $simulator"
                return 1
            fi
            ;;
        wsl)
            # For WSL, convert Linux path to Windows path and use Windows simulator
            local win_sim win_pdx
            win_sim=$(wslpath -w "$simulator" 2>/dev/null) || win_sim="$simulator"
            if [[ -n "$pdx_file" ]]; then
                win_pdx=$(wslpath -w "$pdx_file" 2>/dev/null) || win_pdx="$pdx_file"
                cmd.exe /c "$win_sim" "$win_pdx" &
            else
                cmd.exe /c "$win_sim" &
            fi
            ;;
        windows)
            if [[ -n "$pdx_file" ]]; then
                "$simulator" "$pdx_file" &
            else
                "$simulator" &
            fi
            ;;
        *)
            echo "Error: Unknown platform"
            return 1
            ;;
    esac
}

#-------------------------------------------------------------------------------
# In-Place File Editing (sed compatibility)
#-------------------------------------------------------------------------------

# In-place sed replacement (handles macOS vs GNU sed differences)
# Usage: sed_inplace 'pattern' file
sed_inplace() {
    local pattern="$1"
    local file="$2"

    case "$PLATFORM_OS" in
        macos)
            sed -i '' "$pattern" "$file"
            ;;
        *)
            sed -i "$pattern" "$file"
            ;;
    esac
}

#-------------------------------------------------------------------------------
# File System Watching
#-------------------------------------------------------------------------------

# Check if a file watcher is available
has_file_watcher() {
    case "$PLATFORM_OS" in
        macos)
            command -v fswatch &>/dev/null
            ;;
        linux|wsl)
            command -v inotifywait &>/dev/null || command -v fswatch &>/dev/null
            ;;
        windows)
            # On Windows, we can use a polling approach or check for specific tools
            command -v fswatch &>/dev/null || command -v inotifywait &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# Get installation instructions for file watcher
get_file_watcher_install_hint() {
    case "$PLATFORM_OS" in
        macos)
            echo "Install with: brew install fswatch"
            ;;
        linux)
            case "$PLATFORM_DISTRO" in
                debian)
                    echo "Install with: sudo apt install inotify-tools"
                    ;;
                fedora)
                    echo "Install with: sudo dnf install inotify-tools"
                    ;;
                arch)
                    echo "Install with: sudo pacman -S inotify-tools"
                    ;;
                *)
                    echo "Install inotify-tools from your package manager"
                    ;;
            esac
            ;;
        wsl)
            echo "Install with: sudo apt install inotify-tools"
            ;;
        windows)
            echo "Install Git Bash with 'inotify-win' or use polling mode"
            ;;
        *)
            echo "Install fswatch or inotifywait for your platform"
            ;;
    esac
}

# Watch a directory for changes and execute a command on each change
# Usage: watch_directory <dir> <command>
# The command will be executed in a loop when files change
watch_directory() {
    local watch_dir="$1"
    shift
    local cmd="$*"

    case "$PLATFORM_OS" in
        macos)
            if command -v fswatch &>/dev/null; then
                fswatch -o "$watch_dir" | while read -r; do
                    eval "$cmd"
                done
            else
                echo "Error: fswatch not found. $(get_file_watcher_install_hint)"
                return 1
            fi
            ;;
        linux|wsl)
            if command -v inotifywait &>/dev/null; then
                while inotifywait -r -e modify,create,delete "$watch_dir" 2>/dev/null; do
                    eval "$cmd"
                done
            elif command -v fswatch &>/dev/null; then
                fswatch -o "$watch_dir" | while read -r; do
                    eval "$cmd"
                done
            else
                echo "Error: No file watcher found. $(get_file_watcher_install_hint)"
                return 1
            fi
            ;;
        windows)
            # Fallback to polling on Windows if no watcher available
            if command -v inotifywait &>/dev/null; then
                while inotifywait -r -e modify,create,delete "$watch_dir" 2>/dev/null; do
                    eval "$cmd"
                done
            else
                echo "Warning: Using polling mode (checking every 2 seconds)"
                local last_hash=""
                while true; do
                    local current_hash
                    current_hash=$(find "$watch_dir" -type f -exec md5sum {} \; 2>/dev/null | sort | md5sum)
                    if [[ "$current_hash" != "$last_hash" && -n "$last_hash" ]]; then
                        eval "$cmd"
                    fi
                    last_hash="$current_hash"
                    sleep 2
                done
            fi
            ;;
        *)
            echo "Error: File watching not supported on this platform"
            return 1
            ;;
    esac
}

#-------------------------------------------------------------------------------
# Process Management
#-------------------------------------------------------------------------------

# Kill simulator process
kill_simulator() {
    local proc_name
    proc_name="$(get_simulator_process_name)"

    case "$PLATFORM_OS" in
        macos)
            if pgrep -x "$proc_name" > /dev/null 2>&1; then
                pkill -x "$proc_name"
                return 0
            fi
            ;;
        linux|wsl)
            if pgrep -f "$proc_name" > /dev/null 2>&1; then
                pkill -f "$proc_name"
                return 0
            fi
            ;;
        windows)
            taskkill //IM "${proc_name}.exe" //F 2>/dev/null || \
            taskkill /IM "${proc_name}.exe" /F 2>/dev/null
            return 0
            ;;
    esac
    return 1
}

# Check if simulator is running
is_simulator_running() {
    local proc_name
    proc_name="$(get_simulator_process_name)"

    case "$PLATFORM_OS" in
        macos)
            pgrep -x "$proc_name" > /dev/null 2>&1
            ;;
        linux|wsl)
            pgrep -f "$proc_name" > /dev/null 2>&1
            ;;
        windows)
            tasklist 2>/dev/null | grep -qi "${proc_name}.exe"
            ;;
        *)
            return 1
            ;;
    esac
}

#-------------------------------------------------------------------------------
# Package Manager Abstraction
#-------------------------------------------------------------------------------

# Get the package manager command for the current platform
get_package_manager() {
    case "$PLATFORM_OS" in
        macos)
            echo "brew"
            ;;
        linux)
            case "$PLATFORM_DISTRO" in
                debian)
                    echo "apt"
                    ;;
                fedora)
                    echo "dnf"
                    ;;
                arch)
                    echo "pacman"
                    ;;
                suse)
                    echo "zypper"
                    ;;
                *)
                    echo "unknown"
                    ;;
            esac
            ;;
        wsl)
            echo "apt"
            ;;
        windows)
            if command -v winget &>/dev/null; then
                echo "winget"
            elif command -v choco &>/dev/null; then
                echo "choco"
            elif command -v scoop &>/dev/null; then
                echo "scoop"
            else
                echo "unknown"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Install a package using the appropriate package manager
# Usage: install_package <package_name> [alternate_names...]
# Example: install_package fswatch inotify-tools
install_package() {
    local pkg_manager
    pkg_manager="$(get_package_manager)"

    case "$pkg_manager" in
        brew)
            brew install "$1"
            ;;
        apt)
            sudo apt update && sudo apt install -y "${2:-$1}"
            ;;
        dnf)
            sudo dnf install -y "${2:-$1}"
            ;;
        pacman)
            sudo pacman -S --noconfirm "${2:-$1}"
            ;;
        zypper)
            sudo zypper install -y "${2:-$1}"
            ;;
        winget)
            winget install "$1"
            ;;
        choco)
            choco install "$1" -y
            ;;
        scoop)
            scoop install "$1"
            ;;
        *)
            echo "Error: Unknown package manager"
            return 1
            ;;
    esac
}

#-------------------------------------------------------------------------------
# Utility Functions
#-------------------------------------------------------------------------------

# Print platform info (useful for debugging)
print_platform_info() {
    echo "Platform: $PLATFORM_OS"
    echo "Architecture: $PLATFORM_ARCH"
    [[ -n "$PLATFORM_DISTRO" ]] && echo "Distribution: $PLATFORM_DISTRO"
    echo "Package Manager: $(get_package_manager)"
    echo "SDK Path: ${PLAYDATE_SDK_PATH:-$(get_default_sdk_path)}"
    echo "Simulator: $(get_simulator_path "${PLAYDATE_SDK_PATH:-$(get_default_sdk_path)}")"
}

# Export platform variables for child processes
export PLATFORM_OS PLATFORM_ARCH PLATFORM_DISTRO
