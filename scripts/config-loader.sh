#!/bin/bash
# Configuration loader utility
# Source this file in other scripts to load configuration with backward compatibility
#
# Usage:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   LEARNING_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
#   source "$SCRIPT_DIR/config-loader.sh"

# Determine learning directory if not already set
if [ -z "$LEARNING_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
    LEARNING_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
fi

# Load configuration file if it exists
CONFIG_FILE="$LEARNING_DIR/config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    USING_CONFIG=true
else
    USING_CONFIG=false
    # Set defaults for backward compatibility
    YOUR_GITHUB_USER="${YOUR_GITHUB_USER:-jmjava}"
    UPSTREAM_ORG="${UPSTREAM_ORG:-embabel}"
    BASE_DIR="${BASE_DIR:-$HOME/github/jmjava}"
    LEARNING_DIR="${LEARNING_DIR:-$HOME/github/jmjava/embabel-learning}"
    MONITOR_REPOS="${MONITOR_REPOS:-}"
    WORKSPACE_NAME="${WORKSPACE_NAME:-${UPSTREAM_ORG}-workspace}"
    MAX_MONITOR_REPOS="${MAX_MONITOR_REPOS:-10}"
    
    # Show warning once per script execution
    if [ "${CONFIG_WARNING_SHOWN:-false}" != "true" ]; then
        echo "⚠️  Warning: config.sh not found. Using defaults (${UPSTREAM_ORG}/${YOUR_GITHUB_USER})" >&2
        echo "   Create config.sh from config.sh.example to customize:" >&2
        echo "   cp $LEARNING_DIR/config.sh.example $CONFIG_FILE" >&2
        export CONFIG_WARNING_SHOWN=true
    fi
fi

# Export all variables for use in scripts
export YOUR_GITHUB_USER
export UPSTREAM_ORG
export BASE_DIR
export LEARNING_DIR
export MONITOR_REPOS
export WORKSPACE_NAME
export MAX_MONITOR_REPOS
export USING_CONFIG

# Validate required variables
if [ -z "$YOUR_GITHUB_USER" ] || [ -z "$UPSTREAM_ORG" ]; then
    echo "Error: YOUR_GITHUB_USER and UPSTREAM_ORG must be set" >&2
    exit 1
fi

