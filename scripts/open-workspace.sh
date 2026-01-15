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

    # Build workspace file dynamically
    {
        echo "{"
        echo "    \"folders\": ["

        # Add configured repos
        if [ -n "$MONITOR_REPOS" ]; then
            for repo in $MONITOR_REPOS; do
                echo "        {"
                echo "            \"path\": \"$repo\","
                echo "            \"name\": \"📦 $repo\""
                echo "        },"
            done
        else
            # Default to common repos if MONITOR_REPOS not set
            echo "        {"
            echo "            \"path\": \"guide\","
            echo "            \"name\": \"📘 Guide\""
            echo "        },"
            echo "        {"
            echo "            \"path\": \"${UPSTREAM_ORG}-agent\","
            echo "            \"name\": \"🤖 ${UPSTREAM_ORG} Agent\""
            echo "        },"
        fi

        # Add learning workspace itself
        WORKSPACE_DIR_NAME=$(basename "$LEARNING_DIR")
        echo "        {"
        echo "            \"path\": \"$WORKSPACE_DIR_NAME\","
        echo "            \"name\": \"🎓 ${UPSTREAM_ORG} Learning\""
        echo "        }"

        echo "    ],"
        echo "    \"settings\": {"
        echo "        \"gitlens.defaultDateFormat\": \"YYYY-MM-DD HH:mm\","
        echo "        \"gitlens.showWelcomeOnInstall\": false,"
        echo "        \"gitlens.currentLine.enabled\": true,"
        echo "        \"gitlens.hovers.currentLine.over\": \"line\","
        echo "        \"gitlens.codeLens.enabled\": true"
        echo "    }"
        echo "}"
    } > "$WORKSPACE_FILE"

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
