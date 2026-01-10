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

# Load .env file if it exists (takes precedence over config.sh)
ENV_FILE="$LEARNING_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    # Export variables from .env file (handle comments, empty lines, and variable expansion)
    set -a  # Automatically export all variables
    # Parse .env file line by line
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Split on first = sign
        if [[ "$line" == *"="* ]]; then
            key="${line%%=*}"
            value="${line#*=}"
            
            # Remove leading/trailing whitespace from key and value
            key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            # Remove surrounding quotes if present
            if [[ "$value" =~ ^\"(.*)\"$ ]] || [[ "$value" =~ ^\'(.*)\'$ ]]; then
                value="${value:1:-1}"
            fi
            
            # Expand variables in value (e.g., $HOME, ${YOUR_GITHUB_USER})
            value=$(eval "echo \"$value\"")
            
            # Export the variable
            [ -n "$key" ] && export "$key=$value" 2>/dev/null || true
        fi
    done < "$ENV_FILE"
    set +a  # Disable auto-export
    USING_CONFIG=true
fi

# Load config.sh if it exists and .env wasn't loaded (backward compatibility)
CONFIG_FILE="$LEARNING_DIR/config.sh"
if [ -z "$USING_CONFIG" ] && [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    USING_CONFIG=true
fi

# If neither .env nor config.sh found, use defaults
if [ "${USING_CONFIG:-false}" != "true" ]; then
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
        echo "⚠️  Warning: No configuration file found (.env or config.sh)" >&2
        echo "   Using defaults (${UPSTREAM_ORG}/${YOUR_GITHUB_USER})" >&2
        echo "   Create .env from .env-template to customize:" >&2
        echo "   cp $LEARNING_DIR/.env-template $ENV_FILE" >&2
        echo "   # Or use config.sh: cp $LEARNING_DIR/config.sh.example $CONFIG_FILE" >&2
        export CONFIG_WARNING_SHOWN=true
    fi
fi

# Handle test organization override
# If TEST_UPSTREAM_ORG is set and we're in a test context, use it instead
if [ -n "${TEST_UPSTREAM_ORG:-}" ] && [ "${TEST_MODE:-false}" = "true" ]; then
    UPSTREAM_ORG="$TEST_UPSTREAM_ORG"
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
export TEST_UPSTREAM_ORG

# Validate required variables
if [ -z "$YOUR_GITHUB_USER" ] || [ -z "$UPSTREAM_ORG" ]; then
    echo "Error: YOUR_GITHUB_USER and UPSTREAM_ORG must be set" >&2
    exit 1
fi

