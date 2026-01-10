#!/bin/bash
# Step-by-step PR review workflow
# Usage: ./review-pr-workflow.sh <repo-name> <PR_NUMBER>

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
LEARNING_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/config-loader.sh"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <repo-name> <PR_NUMBER>"
    echo "Example: $0 guide 1223"
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

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}📋 PR Review Workflow${NC}"
echo -e "${GREEN}========================================${NC}\n"
echo -e "${BLUE}Repository:${NC} $UPSTREAM_REPO"
echo -e "${BLUE}PR Number:${NC} #$PR_NUM"
echo ""

# Step 1: Check sync status
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Step 1: Check Repository Sync Status${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

cd "$REPO_DIR"

# Check if repo is in sync
if git remote | grep -q "upstream"; then
    git fetch upstream --quiet 2>/dev/null || true
    BEHIND=$(git rev-list --count HEAD..upstream/main 2>/dev/null || git rev-list --count HEAD..upstream/master 2>/dev/null || echo "0")

    if [ "$BEHIND" != "0" ]; then
        echo -e "${YELLOW}⚠️  Repository is $BEHIND commits behind upstream${NC}"
        echo -e "${YELLOW}   Syncing now...${NC}\n"

        # Check for uncommitted changes
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            echo -e "${RED}✗ You have uncommitted changes. Please commit or stash first.${NC}"
            git status --short
            echo ""
            echo -e "${YELLOW}Options:${NC}"
            echo -e "  ${CYAN}1.${NC} Stash changes: ${GREEN}git stash${NC}"
            echo -e "  ${CYAN}2.${NC} Commit changes: ${GREEN}git commit -am 'Your message'${NC}"
            exit 1
        fi

        # Sync
        MAIN_BRANCH=$(git show-ref --verify --quiet refs/remotes/upstream/main 2>/dev/null && echo "main" || echo "master")
        git merge upstream/$MAIN_BRANCH --no-edit 2>/dev/null || {
            echo -e "${RED}✗ Merge conflicts. Resolve them first.${NC}"
            exit 1
        }
        echo -e "${GREEN}✓ Synced with upstream${NC}\n"
    else
        echo -e "${GREEN}✓ Repository is in sync${NC}\n"
    fi
else
    echo -e "${YELLOW}⚠️  Upstream remote not configured${NC}"
    echo -e "${YELLOW}   Setting up upstream...${NC}\n"
    git remote add upstream "git@github.com:${UPSTREAM_ORG}/$REPO_NAME.git" 2>/dev/null || true
    git fetch upstream
    echo -e "${GREEN}✓ Upstream configured${NC}\n"
fi

# Step 2: Get PR info
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Step 2: Get PR Information${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

PR_INFO=$(gh pr view "$PR_NUM" --repo "$UPSTREAM_REPO" --json title,author,state,createdAt,body,files,additions,deletions 2>/dev/null)

if [ -z "$PR_INFO" ] || [ "$PR_INFO" = "null" ]; then
    echo -e "${RED}✗ Could not fetch PR #$PR_NUM${NC}"
    exit 1
fi

TITLE=$(echo "$PR_INFO" | jq -r '.title')
AUTHOR=$(echo "$PR_INFO" | jq -r '.author.login')
STATE=$(echo "$PR_INFO" | jq -r '.state')
CREATED=$(echo "$PR_INFO" | jq -r '.createdAt')
ADDITIONS=$(echo "$PR_INFO" | jq -r '.additions')
DELETIONS=$(echo "$PR_INFO" | jq -r '.deletions')
FILES_COUNT=$(echo "$PR_INFO" | jq -r '.files | length')

echo -e "${BLUE}Title:${NC} $TITLE"
echo -e "${BLUE}Author:${NC} $AUTHOR"
echo -e "${BLUE}State:${NC} $STATE"
echo -e "${BLUE}Created:${NC} $CREATED"
echo -e "${BLUE}Changes:${NC} +$ADDITIONS / -$DELETIONS lines across $FILES_COUNT file(s)"
echo ""

# Step 3: Show files changed
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Step 3: Files Changed${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo "$PR_INFO" | jq -r '.files[] | "\(.path) (+\(.additions)/-\(.deletions))"' | while read -r file_info; do
    echo -e "  ${GREEN}•${NC} $file_info"
done
echo ""

# Step 4: Checkout PR locally
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Step 4: Checkout PR Locally (Optional)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}Do you want to checkout this PR locally to test it? (y/n)${NC}"
read -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Checking out PR #$PR_NUM...${NC}"

    # Save current branch
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

    # Checkout PR
    if gh pr checkout "$PR_NUM" --repo "$UPSTREAM_REPO" 2>/dev/null; then
        echo -e "${GREEN}✓ PR checked out${NC}"
        echo -e "${YELLOW}You're now on a branch with the PR changes${NC}"
        echo -e "${YELLOW}To return to your branch:${NC} git checkout $CURRENT_BRANCH"
        echo ""

        # Refresh IDE suggestion
        echo -e "${CYAN}💡 IDE Tip:${NC}"
        echo -e "  ${GREEN}1.${NC} Reload window: ${CYAN}Cmd/Ctrl+Shift+P → 'Developer: Reload Window'${NC}"
        echo -e "  ${GREEN}2.${NC} Or close and reopen the repo folder"
        echo ""
    else
        echo -e "${RED}✗ Could not checkout PR${NC}"
    fi
else
    echo -e "${YELLOW}Skipping local checkout${NC}"
    echo ""
fi

# Step 5: View diff
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Step 5: Review Changes${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}View full diff? (y/n)${NC}"
read -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    gh pr diff "$PR_NUM" --repo "$UPSTREAM_REPO" | less -R
fi

# Step 6: Summary
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Review Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${BLUE}PR Summary:${NC}"
echo -e "  ${CYAN}URL:${NC} https://github.com/$UPSTREAM_REPO/pull/$PR_NUM"
echo -e "  ${CYAN}Author:${NC} $AUTHOR"
echo -e "  ${CYAN}Files:${NC} $FILES_COUNT"
echo -e "  ${CYAN}Changes:${NC} +$ADDITIONS / -$DELETIONS"
echo ""

echo -e "${BLUE}Next Steps:${NC}"
echo -e "  ${GREEN}1.${NC} Review the code changes"
echo -e "  ${GREEN}2.${NC} Test locally (if checked out)"
echo -e "  ${GREEN}3.${NC} Add comments on GitHub"
echo -e "  ${GREEN}4.${NC} Approve or request changes"
echo ""

echo -e "${YELLOW}Quick Commands:${NC}"
echo -e "  ${CYAN}View PR:${NC} gh pr view $PR_NUM --repo $UPSTREAM_REPO"
echo -e "  ${CYAN}View diff:${NC} gh pr diff $PR_NUM --repo $UPSTREAM_REPO"
echo -e "  ${CYAN}Checkout:${NC} gh pr checkout $PR_NUM --repo $UPSTREAM_REPO"
echo ""
