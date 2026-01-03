#!/bin/bash
# Safe push with GitGuardian and pre-commit checks
# Usage: ./safe-push.sh [branch-name] [remote]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEARN_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get current directory (should be a git repo)
if [ ! -d .git ]; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    echo "Usage: cd to your repo, then run: safe-push"
    exit 1
fi

BRANCH=${1:-$(git rev-parse --abbrev-ref HEAD)}
REMOTE=${2:-origin}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🔒 Safe Push with Security Checks${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}Branch:${NC} $BRANCH"
echo -e "${BLUE}Remote:${NC} $REMOTE"
echo ""

# Step 1: Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}⚠️  You have uncommitted changes${NC}"
    git status --short
    echo ""
    echo -e "${YELLOW}Commit your changes first:${NC}"
    echo "  git add ."
    echo "  git commit -m 'Your message'"
    exit 1
fi

# Step 2: Run pre-commit hooks on staged files (if any)
if [ -f .pre-commit-config.yaml ]; then
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Step 1: Running Pre-commit Hooks${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    if command -v pre-commit &> /dev/null; then
        # Run on all files in the repo (comprehensive check)
        if ! pre-commit run --all-files; then
            echo -e "${RED}✗ Pre-commit checks failed${NC}"
            echo -e "${YELLOW}Fix the issues above before pushing${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ Pre-commit checks passed${NC}\n"
    else
        echo -e "${YELLOW}⚠️  pre-commit not installed. Skipping pre-commit checks${NC}"
        echo -e "${YELLOW}   Install with: ./scripts/setup-pre-commit.sh${NC}\n"
    fi
else
    echo -e "${YELLOW}⚠️  No .pre-commit-config.yaml found. Skipping pre-commit checks${NC}\n"
fi

# Step 3: Run GitGuardian scan
if command -v ggshield &> /dev/null; then
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Step 2: Running GitGuardian Scan${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    # Scan the entire repository
    if ! ggshield scan; then
        echo -e "${RED}✗ GitGuardian scan found secrets or issues${NC}"
        echo -e "${YELLOW}Review the output above and fix any issues before pushing${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ GitGuardian scan passed${NC}\n"
else
    echo -e "${YELLOW}⚠️  GitGuardian CLI (ggshield) not installed${NC}"
    echo -e "${YELLOW}   Install with: ./scripts/setup-pre-commit.sh${NC}\n"
fi

# Step 4: Check if branch is ahead
LOCAL=$(git rev-parse $BRANCH 2>/dev/null)
REMOTE_REF="$REMOTE/$BRANCH"
if git show-ref --verify --quiet "refs/remotes/$REMOTE_REF" 2>/dev/null; then
    REMOTE_COMMIT=$(git rev-parse "$REMOTE_REF" 2>/dev/null)
    if [ "$LOCAL" = "$REMOTE_COMMIT" ]; then
        echo -e "${YELLOW}⚠️  No new commits to push${NC}"
        exit 0
    fi
fi

# Step 5: Show what will be pushed
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 3: Review Changes to Push${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if git show-ref --verify --quiet "refs/remotes/$REMOTE_REF" 2>/dev/null; then
    echo -e "${CYAN}Commits to push:${NC}"
    git log --oneline "$REMOTE_REF".."$BRANCH" 2>/dev/null || git log --oneline "$BRANCH" 2>/dev/null | head -5
    echo ""

    echo -e "${CYAN}Files changed:${NC}"
    git diff --stat "$REMOTE_REF".."$BRANCH" 2>/dev/null || git diff --stat HEAD~5..HEAD 2>/dev/null | head -10
    echo ""
else
    echo -e "${CYAN}This will be the first push of branch $BRANCH${NC}"
    echo ""
fi

# Step 6: Confirm push
echo -e "${YELLOW}Ready to push? (y/n)${NC}"
read -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Push cancelled${NC}"
    exit 0
fi

# Step 7: Safety check - prevent pushing to embabel organization
REMOTE_URL=$(git remote get-url "$REMOTE" 2>/dev/null || echo "")
if [[ "$REMOTE_URL" == *"embabel/"* ]] && [[ "$REMOTE_URL" != *"jmjava"* ]]; then
    echo -e "${RED}✗ SAFETY BLOCK: Cannot push to embabel organization${NC}"
    echo -e "${YELLOW}Remote URL: $REMOTE_URL${NC}"
    echo -e "${YELLOW}This script prevents accidental pushes to embabel repos${NC}"
    echo -e "${YELLOW}Make sure your 'origin' remote points to YOUR fork (jmjava/...), not embabel/${NC}"
    exit 1
fi

# Step 8: Push
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 4: Pushing to $REMOTE/$BRANCH${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if git push "$REMOTE" "$BRANCH"; then
    echo ""
    echo -e "${GREEN}✓ Successfully pushed to $REMOTE/$BRANCH${NC}"
    echo ""

    # Show PR creation suggestion if pushing to origin
    if [ "$REMOTE" = "origin" ]; then
        REPO_URL=$(git remote get-url origin 2>/dev/null | sed 's/\.git$//' | sed 's/git@github\.com:/https:\/\/github.com\//')
        if [[ "$REPO_URL" == *"github.com"* ]]; then
            echo -e "${CYAN}💡 Create a PR:${NC}"
            echo -e "   ${GREEN}gh pr create${NC}"
            echo -e "   Or visit: $REPO_URL/compare/$BRANCH"
            echo ""
        fi
    fi
else
    echo -e "${RED}✗ Push failed${NC}"
    exit 1
fi
