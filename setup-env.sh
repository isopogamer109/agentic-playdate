#!/bin/bash
#===============================================================================
# Playdate Development Environment - Shell Configuration
#
# Cross-platform support for: macOS, Linux, Windows (Git Bash/MSYS2/WSL)
#
# Source this file in your shell configuration:
#   macOS:   Add to ~/.zshrc:   source "/path/to/playdate-dev/setup-env.sh"
#   Linux:   Add to ~/.bashrc:  source "/path/to/playdate-dev/setup-env.sh"
#   Windows: Add to ~/.bashrc:  source "/path/to/playdate-dev/setup-env.sh"
#
# This sets up:
# - PLAYDATE_SDK_PATH environment variable
# - PATH additions for SDK tools and repo scripts
# - Helpful aliases and functions (cross-platform)
#===============================================================================

# Get the directory where this script lives (works when sourced)
if [[ -n "${BASH_SOURCE[0]}" ]]; then
    PLAYDATE_DEV_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ -n "${(%):-%x}" ]]; then
    # zsh
    PLAYDATE_DEV_ROOT="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
    echo "Warning: Could not determine playdate-dev location"
    return 1
fi

# Source platform utilities for cross-platform functions
if [[ -f "$PLAYDATE_DEV_ROOT/scripts/platform-utils.sh" ]]; then
    source "$PLAYDATE_DEV_ROOT/scripts/platform-utils.sh"
fi

#-------------------------------------------------------------------------------
# Environment Variables
#-------------------------------------------------------------------------------

# Set SDK path based on platform (can be overridden by user)
if [[ -z "$PLAYDATE_SDK_PATH" ]]; then
    if [[ -n "$PLATFORM_OS" ]]; then
        PLAYDATE_SDK_PATH="$(get_default_sdk_path)"
    else
        # Fallback if platform-utils not loaded
        case "$(uname -s)" in
            Darwin)
                PLAYDATE_SDK_PATH="$HOME/Developer/PlaydateSDK"
                ;;
            Linux)
                PLAYDATE_SDK_PATH="$HOME/PlaydateSDK"
                ;;
            MINGW*|MSYS*|CYGWIN*)
                PLAYDATE_SDK_PATH="$HOME/Documents/PlaydateSDK"
                ;;
            *)
                PLAYDATE_SDK_PATH="$HOME/PlaydateSDK"
                ;;
        esac
    fi
fi

export PLAYDATE_SDK_PATH
export PLAYDATE_DEV_ROOT

# Set simulator path based on platform
if [[ -n "$PLATFORM_OS" ]]; then
    export PLAYDATE_SIMULATOR="$(get_simulator_path "$PLAYDATE_SDK_PATH")"
else
    # Fallback
    case "$(uname -s)" in
        Darwin)
            export PLAYDATE_SIMULATOR="$PLAYDATE_SDK_PATH/Playdate Simulator.app"
            ;;
        *)
            export PLAYDATE_SIMULATOR="$PLAYDATE_SDK_PATH/bin/PlaydateSimulator"
            ;;
    esac
fi

#-------------------------------------------------------------------------------
# PATH Configuration
#-------------------------------------------------------------------------------

# Add SDK bin to PATH (for pdc, pdutil)
if [[ -d "$PLAYDATE_SDK_PATH/bin" ]]; then
    export PATH="$PLAYDATE_SDK_PATH/bin:$PATH"
fi

# Add this repo's scripts to PATH
if [[ -d "$PLAYDATE_DEV_ROOT/scripts" ]]; then
    export PATH="$PLAYDATE_DEV_ROOT/scripts:$PATH"
fi

#-------------------------------------------------------------------------------
# Quick Aliases (using cross-platform functions when available)
#-------------------------------------------------------------------------------

# Build commands (platform-independent)
alias pdc-build='pdc source output.pdx'
alias pdc-clean='rm -rf output.pdx'

# Simulator commands using cross-platform functions
if type open_simulator &>/dev/null; then
    alias playdate-sim='open_simulator'
    alias pdc-run='pdc source output.pdx && open_simulator output.pdx'
else
    # Fallback for direct sourcing without platform-utils
    case "$(uname -s)" in
        Darwin)
            alias playdate-sim='open "$PLAYDATE_SIMULATOR"'
            alias pdc-run='pdc source output.pdx && open "$PLAYDATE_SIMULATOR" output.pdx'
            ;;
        *)
            alias playdate-sim='"$PLAYDATE_SIMULATOR" &'
            alias pdc-run='pdc source output.pdx && "$PLAYDATE_SIMULATOR" output.pdx &'
            ;;
    esac
fi

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------

# Build and run any source directory
playdate-test() {
    local target="${1:-source}"
    local output="${2:-output.pdx}"

    if [[ -d "$target" ]]; then
        echo "Building $target -> $output..."
        pdc "$target" "$output"
        if [[ $? -eq 0 ]]; then
            echo "Launching simulator..."
            if type open_simulator &>/dev/null; then
                open_simulator "$output"
            else
                # Fallback
                case "$(uname -s)" in
                    Darwin)
                        open "$PLAYDATE_SIMULATOR" "$output"
                        ;;
                    *)
                        "$PLAYDATE_SIMULATOR" "$output" &
                        ;;
                esac
            fi
        else
            echo "Build failed!"
            return 1
        fi
    elif [[ -d "$target.pdx" ]]; then
        echo "Launching $target.pdx..."
        if type open_simulator &>/dev/null; then
            open_simulator "$target.pdx"
        else
            case "$(uname -s)" in
                Darwin)
                    open "$PLAYDATE_SIMULATOR" "$target.pdx"
                    ;;
                *)
                    "$PLAYDATE_SIMULATOR" "$target.pdx" &
                    ;;
            esac
        fi
    else
        echo "Usage: playdate-test [source_dir] [output.pdx]"
        return 1
    fi
}

# Watch for changes and auto-rebuild (cross-platform)
playdate-watch() {
    local source_dir="${1:-source}"
    local output="${2:-output.pdx}"

    # Check for file watcher
    if type has_file_watcher &>/dev/null; then
        if ! has_file_watcher; then
            echo "No file watcher installed."
            get_file_watcher_install_hint
            return 1
        fi
    else
        # Fallback check
        if ! command -v fswatch &>/dev/null && ! command -v inotifywait &>/dev/null; then
            echo "No file watcher installed."
            case "$(uname -s)" in
                Darwin)
                    echo "Install with: brew install fswatch"
                    ;;
                Linux)
                    echo "Install with: sudo apt install inotify-tools"
                    ;;
                *)
                    echo "Install fswatch or inotify-tools"
                    ;;
            esac
            return 1
        fi
    fi

    echo "Watching $source_dir for changes... (Ctrl+C to stop)"

    # Initial build and launch
    pdc "$source_dir" "$output"
    if type open_simulator &>/dev/null; then
        open_simulator "$output"
    else
        case "$(uname -s)" in
            Darwin)
                open "$PLAYDATE_SIMULATOR" "$output"
                ;;
            *)
                "$PLAYDATE_SIMULATOR" "$output" &
                ;;
        esac
    fi

    # Watch for changes using appropriate tool
    if type watch_directory &>/dev/null; then
        watch_directory "$source_dir" "echo 'Change detected, rebuilding...'; pdc '$source_dir' '$output'"
    elif command -v fswatch &>/dev/null; then
        fswatch -o "$source_dir" | while read -r; do
            echo "Change detected, rebuilding..."
            pdc "$source_dir" "$output"
        done
    elif command -v inotifywait &>/dev/null; then
        while inotifywait -r -e modify,create,delete "$source_dir" 2>/dev/null; do
            echo "Change detected, rebuilding..."
            pdc "$source_dir" "$output"
        done
    fi
}

# Open SDK documentation (cross-platform)
playdate-docs() {
    local doc="$PLAYDATE_SDK_PATH/Documentation/Inside Playdate.html"
    local url="https://sdk.play.date/Inside%20Playdate.html"

    if [[ -f "$doc" ]]; then
        if type open_path &>/dev/null; then
            open_path "$doc"
        else
            case "$(uname -s)" in
                Darwin)
                    open "$doc"
                    ;;
                Linux)
                    xdg-open "$doc" 2>/dev/null || sensible-browser "$doc"
                    ;;
                MINGW*|MSYS*|CYGWIN*)
                    start "" "$doc"
                    ;;
            esac
        fi
    else
        if type open_path &>/dev/null; then
            open_path "$url"
        else
            case "$(uname -s)" in
                Darwin)
                    open "$url"
                    ;;
                Linux)
                    xdg-open "$url" 2>/dev/null || sensible-browser "$url"
                    ;;
                MINGW*|MSYS*|CYGWIN*)
                    start "" "$url"
                    ;;
            esac
        fi
    fi
}

# List SDK examples
playdate-examples() {
    echo "Playdate SDK Examples:"
    echo "======================"
    if [[ -d "$PLAYDATE_SDK_PATH/Examples" ]]; then
        ls -1 "$PLAYDATE_SDK_PATH/Examples/"
    else
        echo "SDK Examples directory not found at $PLAYDATE_SDK_PATH/Examples/"
    fi
    echo ""
    echo "To run an example:"
    echo "  cd \"\$PLAYDATE_SDK_PATH/Examples/[ExampleName]\""
    echo "  pdc-run"
}

# Create new project from template (cross-platform)
playdate-new() {
    local name="$1"
    local template="${2:-basic}"

    if [[ -z "$name" ]]; then
        echo "Usage: playdate-new <project-name> [template]"
        echo ""
        echo "Available templates:"
        ls -1 "$PLAYDATE_DEV_ROOT/templates/"
        return 1
    fi

    local template_dir="$PLAYDATE_DEV_ROOT/templates/$template"
    if [[ ! -d "$template_dir" ]]; then
        echo "Template not found: $template"
        echo "Available: $(ls -1 "$PLAYDATE_DEV_ROOT/templates/" | tr '\n' ' ')"
        return 1
    fi

    if [[ -d "$name" ]]; then
        echo "Directory already exists: $name"
        return 1
    fi

    cp -r "$template_dir" "$name"

    # Update pdxinfo with project name (cross-platform sed)
    if [[ -f "$name/source/pdxinfo" ]]; then
        if type sed_inplace &>/dev/null; then
            sed_inplace "s/TemplateName/$name/g" "$name/source/pdxinfo"
            local safe_bundle
            safe_bundle=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')
            sed_inplace "s/templatename/$safe_bundle/g" "$name/source/pdxinfo"
        else
            # Fallback with OS detection
            case "$(uname -s)" in
                Darwin)
                    sed -i '' "s/TemplateName/$name/g" "$name/source/pdxinfo"
                    local safe_bundle
                    safe_bundle=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')
                    sed -i '' "s/templatename/$safe_bundle/g" "$name/source/pdxinfo"
                    ;;
                *)
                    sed -i "s/TemplateName/$name/g" "$name/source/pdxinfo"
                    local safe_bundle
                    safe_bundle=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')
                    sed -i "s/templatename/$safe_bundle/g" "$name/source/pdxinfo"
                    ;;
            esac
        fi
    fi

    echo "Created project: $name (from template: $template)"
    echo ""
    echo "Next steps:"
    echo "  cd $name"
    echo "  pdbr    # Build and run"
}

# Show platform info (helpful for debugging)
playdate-info() {
    echo "Playdate Development Environment"
    echo "================================="
    echo ""
    if type print_platform_info &>/dev/null; then
        print_platform_info
    else
        echo "Platform: $(uname -s)"
        echo "SDK Path: $PLAYDATE_SDK_PATH"
        echo "Simulator: $PLAYDATE_SIMULATOR"
    fi
    echo ""
    echo "Dev Root: $PLAYDATE_DEV_ROOT"
    echo ""

    # Check if SDK is installed
    if [[ -d "$PLAYDATE_SDK_PATH" ]]; then
        echo "SDK Status: Installed"
        if command -v pdc &>/dev/null; then
            echo "PDC Version: $(pdc --version 2>/dev/null || echo 'unknown')"
        fi
    else
        echo "SDK Status: Not installed"
        echo "Run: $PLAYDATE_DEV_ROOT/install.sh"
    fi
}

#-------------------------------------------------------------------------------
# Confirmation
#-------------------------------------------------------------------------------

# Only print if interactive shell
if [[ $- == *i* ]]; then
    echo "Playdate dev environment loaded. Run 'playdate-new MyGame' to start."
fi
