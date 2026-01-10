#!/bin/bash
# View and analyze a specific PR from upstream
# Usage: ./view-pr.sh <repo-name> <PR_NUMBER>

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
LEARNING_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/config-loader.sh"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <repo-name> <PR_NUMBER>"
    echo "Example: $0 guide 123"
    echo ""
    echo "Available repos (cloned in $BASE_DIR):"
    find "$BASE_DIR" -maxdepth 1 -type d -not -path "$BASE_DIR" 2>/dev/null | \
        xargs -I {} basename {} | \
        head -10 || echo "  (none found)"
    exit 1
fi

REPO_NAME=$1
PR_NUM=$2

REPO_DIR="$BASE_DIR/$REPO_NAME"
UPSTREAM_REPO="${UPSTREAM_ORG}/$REPO_NAME"

if [ ! -d "$REPO_DIR" ] || [ ! -d "$REPO_DIR/.git" ]; then
    echo -e "${RED}❌ Repository not found: $REPO_DIR${NC}"
    echo "Make sure the repository is cloned to $BASE_DIR"
    exit 1
fi

cd "$REPO_DIR"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 Analyzing PR #$PR_NUM in $UPSTREAM_REPO${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Show PR details
echo -e "${YELLOW}PR Details:${NC}"
gh pr view "$PR_NUM" --repo "$UPSTREAM_REPO"
echo ""

# Show diff
echo -e "${YELLOW}Files changed:${NC}"
gh pr diff "$PR_NUM" --repo "$UPSTREAM_REPO"
echo ""

# Show comments/reviews
echo -e "${YELLOW}Reviews and Comments:${NC}"
gh pr view "$PR_NUM" --repo "$UPSTREAM_REPO" --comments
echo ""

# Offer to checkout locally for testing
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Want to test this PR locally?${NC}"
echo -e "${GREEN}Run: gh pr checkout $PR_NUM --repo $UPSTREAM_REPO${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
