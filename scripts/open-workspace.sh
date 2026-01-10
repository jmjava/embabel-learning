#!/bin/bash
# Open the organization learning workspace in Cursor
# Usage: ./open-workspace.sh

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
LEARNING_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/config-loader.sh"

WORKSPACE_FILE="$BASE_DIR/${WORKSPACE_NAME}.code-workspace"

if [ ! -f "$WORKSPACE_FILE" ]; then
    echo "❌ Workspace file not found at: $WORKSPACE_FILE"
    echo "Creating it now..."

    # Build workspace folders dynamically
    WORKSPACE_FOLDERS=""
    if [ -n "$MONITOR_REPOS" ]; then
        for repo in $MONITOR_REPOS; do
            WORKSPACE_FOLDERS="${WORKSPACE_FOLDERS}        {\n            \"path\": \"$repo\",\n            \"name\": \"📦 $repo\"\n        },\n"
        done
    else
        # Default to common repos if MONITOR_REPOS not set
        WORKSPACE_FOLDERS="        {\n            \"path\": \"guide\",\n            \"name\": \"📘 Guide\"\n        },\n        {\n            \"path\": \"embabel-agent\",\n            \"name\": \"🤖 ${UPSTREAM_ORG} Agent\"\n        },\n"
    fi
    
    # Add learning workspace itself
    WORKSPACE_DIR_NAME=$(basename "$LEARNING_DIR")
    WORKSPACE_FOLDERS="${WORKSPACE_FOLDERS}        {\n            \"path\": \"$WORKSPACE_DIR_NAME\",\n            \"name\": \"🎓 ${UPSTREAM_ORG} Learning\"\n        }\n"
    
    cat > "$WORKSPACE_FILE" << EOF
{
    "folders": [
${WORKSPACE_FOLDERS}
    ],
    "settings": {
        "gitlens.defaultDateFormat": "YYYY-MM-DD HH:mm",
        "gitlens.showWelcomeOnInstall": false,
        "gitlens.currentLine.enabled": true,
        "gitlens.hovers.currentLine.over": "line",
        "gitlens.codeLens.enabled": true
    }
}
EOF
    echo "✅ Workspace file created!"
fi

# Check if cursor command exists
if command -v cursor &> /dev/null; then
    echo "🚀 Opening workspace in Cursor..."
    cursor "$WORKSPACE_FILE"
elif command -v code &> /dev/null; then
    echo "🚀 Opening workspace in VS Code..."
    code "$WORKSPACE_FILE"
else
    echo "❌ Neither 'cursor' nor 'code' command found"
    echo "Please open manually:"
    echo "  cursor $WORKSPACE_FILE"
    echo "  or"
    echo "  code $WORKSPACE_FILE"
    exit 1
fi
