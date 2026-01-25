#!/bin/bash
#===============================================================================
# Playdate Development Environment - Shell Configuration
#
# Source this file in your ~/.zshrc or ~/.bashrc:
#   source "/path/to/playdate-dev/setup-env.sh"
#
# This sets up:
# - PLAYDATE_SDK_PATH environment variable
# - PATH additions for SDK tools and repo scripts
# - Helpful aliases and functions
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

#-------------------------------------------------------------------------------
# Environment Variables
#-------------------------------------------------------------------------------

export PLAYDATE_SDK_PATH="$HOME/Developer/PlaydateSDK"
export PLAYDATE_DEV_ROOT
export PLAYDATE_SIMULATOR="$PLAYDATE_SDK_PATH/Playdate Simulator.app"

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
# Quick Aliases
#-------------------------------------------------------------------------------

alias playdate-sim='open "$PLAYDATE_SIMULATOR"'
alias pdc-build='pdc source output.pdx'
alias pdc-run='pdc source output.pdx && open "$PLAYDATE_SIMULATOR" output.pdx'
alias pdc-clean='rm -rf output.pdx'

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
        return 1
    fi
}

# Watch for changes and auto-rebuild
playdate-watch() {
    local source_dir="${1:-source}"
    local output="${2:-output.pdx}"

    if ! command -v fswatch &> /dev/null; then
        echo "fswatch not installed. Install with: brew install fswatch"
        return 1
    fi

    echo "Watching $source_dir for changes... (Ctrl+C to stop)"
    pdc "$source_dir" "$output" && open "$PLAYDATE_SIMULATOR" "$output"

    fswatch -o "$source_dir" | while read -r; do
        echo "Change detected, rebuilding..."
        pdc "$source_dir" "$output"
    done
}

# Open SDK documentation
playdate-docs() {
    local doc="$PLAYDATE_SDK_PATH/Documentation/Inside Playdate.html"
    if [[ -f "$doc" ]]; then
        open "$doc"
    else
        open "https://sdk.play.date/Inside%20Playdate.html"
    fi
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

# Create new project from template
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

    # Update pdxinfo with project name
    if [[ -f "$name/source/pdxinfo" ]]; then
        sed -i '' "s/TemplateName/$name/g" "$name/source/pdxinfo"
        local safe_bundle
        safe_bundle=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')
        sed -i '' "s/templatename/$safe_bundle/g" "$name/source/pdxinfo"
    fi

    echo "Created project: $name (from template: $template)"
    echo ""
    echo "Next steps:"
    echo "  cd $name"
    echo "  pdbr    # Build and run"
}

#-------------------------------------------------------------------------------
# Confirmation
#-------------------------------------------------------------------------------

# Only print if interactive shell
if [[ $- == *i* ]]; then
    echo "Playdate dev environment loaded. Run 'playdate-new MyGame' to start."
fi
