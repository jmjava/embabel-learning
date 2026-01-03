#!/bin/bash
# Open the embabel workspace in Cursor
# Usage: ./open-workspace.sh

WORKSPACE_FILE="$HOME/github/jmjava/embabel-workspace.code-workspace"

if [ ! -f "$WORKSPACE_FILE" ]; then
    echo "❌ Workspace file not found at: $WORKSPACE_FILE"
    echo "Creating it now..."

    cat > "$WORKSPACE_FILE" << 'EOF'
{
    "folders": [
        {
            "path": "guide",
            "name": "📘 Guide"
        },
        {
            "path": "embabel-agent",
            "name": "🤖 Embabel Agent"
        },
        {
            "path": "embabel-learning",
            "name": "🎓 Embabel Learning"
        }
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
