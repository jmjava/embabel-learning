#!/bin/bash
# Install git hooks to prevent commits/pushes to embabel organization
# Usage: ./install-git-safety-hooks.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEARN_DIR="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Installing Git Safety Hooks${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Create pre-commit hook
cat > "$LEARN_DIR/.git/hooks/pre-commit" << 'HOOK_EOF'
#!/bin/bash
# Pre-commit hook to prevent commits to embabel organization repos

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"
source "$SCRIPT_DIR/safety-checks.sh" 2>/dev/null || exit 0

if ! block_embabel_commit; then
    exit 1
fi
HOOK_EOF

chmod +x "$LEARN_DIR/.git/hooks/pre-commit"
echo -e "${GREEN}✓ Installed pre-commit hook${NC}"

# Create pre-push hook
cat > "$LEARN_DIR/.git/hooks/pre-push" << 'HOOK_EOF'
#!/bin/bash
# Pre-push hook to prevent pushes to embabel organization repos

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"
source "$SCRIPT_DIR/safety-checks.sh" 2>/dev/null || exit 0

# Get remote name from stdin (git push <remote> <branch>)
while read local_ref local_sha remote_ref remote_sha; do
    if [ -z "$remote_ref" ]; then
        continue
    fi

    # Extract remote name (e.g., "origin" from "refs/heads/main")
    remote=$(echo "$remote_ref" | cut -d'/' -f1)

    if ! block_embabel_push "$remote"; then
        exit 1
    fi
done
HOOK_EOF

chmod +x "$LEARN_DIR/.git/hooks/pre-push"
echo -e "${GREEN}✓ Installed pre-push hook${NC}"

echo ""
echo -e "${GREEN}✓ Git safety hooks installed!${NC}"
echo ""
echo -e "${YELLOW}These hooks will:${NC}"
echo -e "  • Block commits if 'origin' points to embabel"
echo -e "  • Block pushes to embabel organization"
echo -e "  • Allow all operations on your forks (jmjava/...)"
echo ""
