#!/bin/bash
# View and analyze a specific PR from upstream
# Usage: ./view-pr.sh [guide|agent] <PR_NUMBER>

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 [guide|agent] <PR_NUMBER>"
    echo "Example: $0 guide 123"
    exit 1
fi

REPO=$1
PR_NUM=$2

GUIDE_DIR="$HOME/github/jmjava/guide"
AGENT_DIR="$HOME/github/jmjava/embabel-agent"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

case "$REPO" in
    guide)
        REPO_DIR="$GUIDE_DIR"
        UPSTREAM_REPO="embabel/guide"
        ;;
    agent)
        REPO_DIR="$AGENT_DIR"
        UPSTREAM_REPO="embabel/embabel-agent"
        ;;
    *)
        echo "Invalid repo. Use 'guide' or 'agent'"
        exit 1
        ;;
esac

cd "$REPO_DIR"

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
