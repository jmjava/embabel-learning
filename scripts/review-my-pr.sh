#!/bin/bash
# Quick review of a specific PR you submitted
# Usage: ./review-my-pr.sh <repo> <pr_number>
# Example: ./review-my-pr.sh guide 123

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ $# -lt 2 ]; then
    echo "Usage: $0 <repo> <pr_number>"
    echo "Example: $0 guide 123"
    exit 1
fi

REPO=$1
PR_NUM=$2
EMBABEL_ORG="embabel"
BASE_DIR="$HOME/github/jmjava"
UPSTREAM_REPO="$EMBABEL_ORG/$REPO"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}PR Review Helper${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${CYAN}Repository: $UPSTREAM_REPO${NC}"
echo -e "${CYAN}PR Number: #$PR_NUM${NC}\n"

# 1. Show PR overview
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 PR Overview${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

gh pr view "$PR_NUM" --repo "$UPSTREAM_REPO"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📁 Files Changed${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

gh pr view "$PR_NUM" --repo "$UPSTREAM_REPO" --json files -q '.files[] | "  \(.path)\n    +\(.additions) -\(.deletions) lines"'

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}💬 Reviews & Comments${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

gh pr view "$PR_NUM" --repo "$UPSTREAM_REPO" --comments

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📝 Code Changes${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}Show full diff? (y/n)${NC}"
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    gh pr diff "$PR_NUM" --repo "$UPSTREAM_REPO" | less -R
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Quick Reference for Discussion${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Extract key information
TITLE=$(gh pr view "$PR_NUM" --repo "$UPSTREAM_REPO" --json title -q .title)
STATE=$(gh pr view "$PR_NUM" --repo "$UPSTREAM_REPO" --json state -q .state)
ADDITIONS=$(gh pr view "$PR_NUM" --repo "$UPSTREAM_REPO" --json additions -q .additions)
DELETIONS=$(gh pr view "$PR_NUM" --repo "$UPSTREAM_REPO" --json deletions -q .deletions)
FILES_COUNT=$(gh pr view "$PR_NUM" --repo "$UPSTREAM_REPO" --json files -q '.files | length')
CREATED=$(gh pr view "$PR_NUM" --repo "$UPSTREAM_REPO" --json createdAt -q .createdAt)

echo "**PR #$PR_NUM:** $TITLE"
echo "**Status:** $STATE"
echo "**Created:** $CREATED"
echo "**Changes:** +$ADDITIONS / -$DELETIONS lines across $FILES_COUNT file(s)"
echo ""

# Show key files changed
echo "**Key Files Modified:**"
gh pr view "$PR_NUM" --repo "$UPSTREAM_REPO" --json files -q '.files[].path' | while read -r file; do
    echo "  - $file"
done

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Actions${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo "1. View in browser:"
echo "   gh pr view $PR_NUM --repo $UPSTREAM_REPO --web"
echo ""
echo "2. Checkout locally to test:"
echo "   cd $BASE_DIR/$REPO"
echo "   gh pr checkout $PR_NUM --repo $UPSTREAM_REPO"
echo ""
echo "3. View specific file diff:"
echo "   gh pr diff $PR_NUM --repo $UPSTREAM_REPO -- path/to/file"
echo ""
echo "4. Add a comment:"
echo "   gh pr comment $PR_NUM --repo $UPSTREAM_REPO"
echo ""

