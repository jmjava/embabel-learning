#!/bin/bash
# Sync your fork with upstream changes (READ-ONLY from embabel)
# Usage: ./sync-upstream.sh [guide|agent|all] [--reset|--replace]
#
# SAFETY: This script only PULLS from embabel, never PUSHES to it
# --reset or --replace: Hard reset to upstream instead of merging (discards local changes)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/safety-checks.sh"

GUIDE_DIR="$HOME/github/jmjava/guide"
AGENT_DIR="$HOME/github/jmjava/embabel-agent"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Parse arguments
RESET_MODE=false
REPO_ARG=""
for arg in "$@"; do
    case "$arg" in
        --reset|--replace)
            RESET_MODE=true
            ;;
        guide|agent|all)
            REPO_ARG="$arg"
            ;;
        *)
            ;;
    esac
done

# Default to "all" if no repo specified
REPO_ARG="${REPO_ARG:-all}"

sync_repo() {
    local repo_dir=$1
    local repo_name=$2
    local reset_mode=${3:-false}

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

    # SAFETY: Block if origin points to embabel (should point to jmjava fork)
    local origin_url=$(git remote get-url origin 2>/dev/null || echo "")
    if [[ "$origin_url" == *"embabel/"* ]] && [[ "$origin_url" != *"jmjava"* ]]; then
        echo -e "${RED}✗ SAFETY BLOCK: 'origin' remote points to embabel organization${NC}"
        echo -e "${YELLOW}Remote URL: $origin_url${NC}"
        echo -e "${YELLOW}This script is for syncing YOUR FORK, not embabel directly${NC}"
        echo ""
        echo -e "${GREEN}To fix:${NC}"
        echo -e "  git remote set-url origin git@github.com:jmjava/$repo_name.git"
        echo ""
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

    # Handle reset mode
    if [ "$reset_mode" = "true" ]; then
        # Check for uncommitted changes
        if ! git diff-index --quiet HEAD --; then
            echo -e "${YELLOW}⚠️  You have uncommitted changes${NC}"
            git status --short | head -5
            echo ""
            echo -e "${YELLOW}These will be LOST. Continue? (y/n)${NC}"
            read -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}Cancelled.${NC}"
                return
            fi
        fi

        # Show what will be lost
        local ahead=$(git rev-list --count upstream/$main_branch..HEAD 2>/dev/null || echo "0")
        if [ "$ahead" != "0" ]; then
            echo -e "${YELLOW}⚠️  You have $ahead local commit(s) that will be LOST:${NC}"
            git log --oneline upstream/$main_branch..HEAD | head -5
            echo ""
        fi

        echo -e "${RED}⚠️  WARNING: This will discard ALL local changes and commits${NC}"
        echo -e "${YELLOW}Your branch will be reset to match upstream/$main_branch exactly${NC}"
        echo ""
        echo -e "${YELLOW}Type 'RESET' to confirm:${NC}"
        read -r CONFIRM
        if [ "$CONFIRM" != "RESET" ]; then
            echo -e "${YELLOW}Cancelled.${NC}"
            return
        fi

        # Reset to upstream
        echo -e "${YELLOW}Resetting to upstream/$main_branch...${NC}"
        git reset --hard upstream/$main_branch
        echo -e "${GREEN}✓ Successfully reset to upstream/$main_branch${NC}"

        # Check if there are commits to push
        local commits_ahead=$(git rev-list --count origin/$current_branch..HEAD 2>/dev/null || echo "0")
        if [ "$commits_ahead" -eq 0 ]; then
            echo -e "${BLUE}ℹ️  Branch is already up-to-date with origin${NC}"
        else
            # Show what origin points to
            ORIGIN_URL=$(git remote get-url origin 2>/dev/null || echo "")
            if [[ "$ORIGIN_URL" == *"jmjava"* ]]; then
                ORIGIN_DESC="your fork (jmjava/$repo_name)"
            else
                ORIGIN_DESC="origin ($ORIGIN_URL)"
            fi

            # Offer to force push
            echo ""
            echo -e "${YELLOW}Force push reset to $ORIGIN_DESC? (y/n)${NC}"
            echo -e "${CYAN}Note: This will overwrite your fork on GitHub${NC}"
            read -p "> " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # Safety check before force push
                if ! block_embabel_push origin; then
                    return 1
                fi
                git push origin "$current_branch" --force
                echo -e "${GREEN}✓ Force pushed to origin/$current_branch${NC}"
            fi
        fi
        echo ""
        return 0
    fi

    # Normal merge mode
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        echo -e "${RED}⚠️  You have uncommitted changes. Please commit or stash them first.${NC}"
        git status --short
        return 1
    fi

    echo -e "${YELLOW}Merging upstream/$main_branch into $current_branch...${NC}"

    # Merge upstream changes
    if git merge upstream/$main_branch --no-edit; then
        echo -e "${GREEN}✓ Successfully synced with upstream/$main_branch${NC}"

        # Check if there are commits to push
        local commits_ahead=$(git rev-list --count origin/$current_branch..HEAD 2>/dev/null || echo "0")

        if [ "$commits_ahead" -eq 0 ]; then
            echo -e "${BLUE}ℹ️  Branch is already up-to-date with origin${NC}"
        else
            # Show what origin points to
            ORIGIN_URL=$(git remote get-url origin 2>/dev/null || echo "")
            if [[ "$ORIGIN_URL" == *"jmjava"* ]]; then
                ORIGIN_DESC="your fork (jmjava/$repo_name)"
            else
                ORIGIN_DESC="origin ($ORIGIN_URL)"
            fi

            # Offer to push
            echo ""
            echo -e "${YELLOW}Push synced changes to $ORIGIN_DESC? (y/n)${NC}"
            echo -e "${CYAN}Note: This pushes to YOUR fork, not to embabel${NC}"
            read -p "> " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # Use safe push if available (with safety check for embabel)
                if command -v epush &> /dev/null || [ -f "$HOME/github/jmjava/embabel-learning/scripts/safe-push.sh" ]; then
                    echo -e "${YELLOW}Using safe push (with security checks)...${NC}"
                    "$HOME/github/jmjava/embabel-learning/scripts/safe-push.sh" "$current_branch" origin
                else
                    # Safety check before direct push (using safety-checks.sh)
                    if ! block_embabel_push origin; then
                        return 1
                    fi
                    git push origin "$current_branch"
                    echo -e "${GREEN}✓ Pushed to origin/$current_branch${NC}"
                    echo -e "${YELLOW}💡 Tip: Use 'epush' for security checks before pushing${NC}"
                fi
            fi
        fi
    else
        echo -e "${RED}⚠️  Merge conflicts detected. Resolve them and then run:${NC}"
        echo "  git merge --continue"
        return 1
    fi

    echo ""
}

case "$REPO_ARG" in
    guide)
        sync_repo "$GUIDE_DIR" "guide" "$RESET_MODE"
        ;;
    agent)
        sync_repo "$AGENT_DIR" "embabel-agent" "$RESET_MODE"
        ;;
    all)
        sync_repo "$GUIDE_DIR" "guide" "$RESET_MODE"
        echo ""
        sync_repo "$AGENT_DIR" "embabel-agent" "$RESET_MODE"
        ;;
    *)
        echo "Usage: $0 [guide|agent|all] [--reset|--replace]"
        echo ""
        echo "Options:"
        echo "  --reset, --replace    Hard reset to upstream (discards local changes)"
        echo "                       Without this flag, merges upstream changes"
        exit 1
        ;;
esac

echo -e "${GREEN}✓ Sync complete!${NC}"
