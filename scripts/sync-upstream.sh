#!/bin/bash
# Sync your fork with upstream changes
# Usage: ./sync-upstream.sh [guide|agent|all]

set -e

GUIDE_DIR="$HOME/github/jmjava/guide"
AGENT_DIR="$HOME/github/jmjava/embabel-agent"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

sync_repo() {
    local repo_dir=$1
    local repo_name=$2

    cd "$repo_dir"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🔄 Syncing: $repo_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    # Check if upstream is configured
    if ! git remote | grep -q "upstream"; then
        echo -e "${RED}⚠️  No upstream remote configured!${NC}"
        echo "Run this command to add it:"
        echo "  git remote add upstream git@github.com:embabel/$repo_name.git"
        return 1
    fi

    # Get current branch
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    echo "Current branch: $current_branch"

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        echo -e "${RED}⚠️  You have uncommitted changes. Please commit or stash them first.${NC}"
        git status --short
        return 1
    fi

    # Fetch upstream
    echo -e "${YELLOW}Fetching upstream...${NC}"
    git fetch upstream

    # Try to find the main branch (could be main or master)
    local main_branch=""
    if git show-ref --verify --quiet refs/remotes/upstream/main; then
        main_branch="main"
    elif git show-ref --verify --quiet refs/remotes/upstream/master; then
        main_branch="master"
    else
        echo -e "${RED}Could not find upstream main or master branch${NC}"
        return 1
    fi

    echo -e "${YELLOW}Merging upstream/$main_branch into $current_branch...${NC}"

    # Merge upstream changes
    if git merge upstream/$main_branch --no-edit; then
        echo -e "${GREEN}✓ Successfully synced with upstream/$main_branch${NC}"

        # Offer to push
        echo ""
        read -p "Push changes to origin? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Use safe push if available (with safety check for embabel)
            if command -v epush &> /dev/null || [ -f "$HOME/github/jmjava/embabel-learning/scripts/safe-push.sh" ]; then
                echo -e "${YELLOW}Using safe push (with security checks)...${NC}"
                "$HOME/github/jmjava/embabel-learning/scripts/safe-push.sh" "$current_branch" origin
            else
                # Safety check before direct push
                REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
                if [[ "$REMOTE_URL" == *"embabel/"* ]] && [[ "$REMOTE_URL" != *"jmjava"* ]]; then
                    echo -e "${RED}✗ SAFETY BLOCK: Cannot push to embabel organization${NC}"
                    echo -e "${YELLOW}Remote URL: $REMOTE_URL${NC}"
                    echo -e "${YELLOW}Make sure your 'origin' remote points to YOUR fork (jmjava/...), not embabel/${NC}"
                    return 1
                fi
                git push origin "$current_branch"
                echo -e "${GREEN}✓ Pushed to origin/$current_branch${NC}"
                echo -e "${YELLOW}💡 Tip: Use 'epush' for security checks before pushing${NC}"
            fi
        fi
    else
        echo -e "${RED}⚠️  Merge conflicts detected. Resolve them and then run:${NC}"
        echo "  git merge --continue"
        return 1
    fi

    echo ""
}

case "${1:-all}" in
    guide)
        sync_repo "$GUIDE_DIR" "guide"
        ;;
    agent)
        sync_repo "$AGENT_DIR" "embabel-agent"
        ;;
    all)
        sync_repo "$GUIDE_DIR" "guide"
        echo ""
        sync_repo "$AGENT_DIR" "embabel-agent"
        ;;
    *)
        echo "Usage: $0 [guide|agent|all]"
        exit 1
        ;;
esac

echo -e "${GREEN}✓ Sync complete!${NC}"
