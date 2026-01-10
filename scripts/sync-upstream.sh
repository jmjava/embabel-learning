#!/bin/bash
# Sync your fork with upstream changes (READ-ONLY from upstream organization)
# Usage: ./sync-upstream.sh [repo-name|all]
#
# SAFETY: This script only PULLS from upstream org, never PUSHES to it

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
LEARNING_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/config-loader.sh"
source "$SCRIPT_DIR/safety-checks.sh"

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
        echo "  git remote add upstream git@github.com:${UPSTREAM_ORG}/$repo_name.git"
        return 1
    fi

    # Get current branch
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    echo "Current branch: $current_branch"

    # SAFETY: Block if origin points to upstream org (should point to your fork)
    local origin_url=$(git remote get-url origin 2>/dev/null || echo "")
    if [[ "$origin_url" == *"${UPSTREAM_ORG}/"* ]] && [[ "$origin_url" != *"${YOUR_GITHUB_USER}"* ]]; then
        echo -e "${RED}✗ SAFETY BLOCK: 'origin' remote points to ${UPSTREAM_ORG} organization${NC}"
        echo -e "${YELLOW}Remote URL: $origin_url${NC}"
        echo -e "${YELLOW}This script is for syncing YOUR FORK, not ${UPSTREAM_ORG} directly${NC}"
        echo ""
        echo -e "${GREEN}To fix:${NC}"
        echo -e "  git remote set-url origin git@github.com:${YOUR_GITHUB_USER}/$repo_name.git"
        echo ""
        return 1
    fi

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

        # Show what origin points to
        ORIGIN_URL=$(git remote get-url origin 2>/dev/null || echo "")
        if [[ "$ORIGIN_URL" == *"${YOUR_GITHUB_USER}"* ]]; then
            ORIGIN_DESC="your fork (${YOUR_GITHUB_USER}/$repo_name)"
        else
            ORIGIN_DESC="origin ($ORIGIN_URL)"
        fi

        # Offer to push
        echo ""
        echo -e "${YELLOW}Push synced changes to $ORIGIN_DESC? (y/n)${NC}"
        echo -e "${CYAN}Note: This pushes to YOUR fork, not to ${UPSTREAM_ORG}${NC}"
        read -p "> " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Use safe push if available (with safety check for upstream org)
            if command -v epush &> /dev/null || [ -f "$SCRIPT_DIR/safe-push.sh" ]; then
                echo -e "${YELLOW}Using safe push (with security checks)...${NC}"
                "$SCRIPT_DIR/safe-push.sh" "$current_branch" origin
            else
                # Safety check before direct push (using safety-checks.sh)
                if ! block_upstream_push origin; then
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

# Main logic
REPO_ARG="${1:-all}"

if [ "$REPO_ARG" = "all" ]; then
    # Sync all configured repos or auto-detect
    if [ -n "$MONITOR_REPOS" ]; then
        REPOS_TO_SYNC="$MONITOR_REPOS"
    else
        # Auto-detect from cloned repos
        REPOS_TO_SYNC=$(find "$BASE_DIR" -maxdepth 1 -type d -not -path "$BASE_DIR" | \
            xargs -I {} basename {} | \
            grep -v "^\." | \
            head -"${MAX_MONITOR_REPOS:-10}" | \
            tr '\n' ' ')
        REPOS_TO_SYNC=$(echo "$REPOS_TO_SYNC" | xargs)  # Trim whitespace
    fi

    if [ -z "$REPOS_TO_SYNC" ]; then
        echo -e "${RED}❌ No repositories found to sync${NC}"
        echo "Set MONITOR_REPOS in config.sh or specify a repo name"
        exit 1
    fi

    SYNC_COUNT=0
    for repo_name in $REPOS_TO_SYNC; do
        repo_dir="$BASE_DIR/$repo_name"
        if [ -d "$repo_dir" ] && [ -d "$repo_dir/.git" ]; then
            sync_repo "$repo_dir" "$repo_name"
            SYNC_COUNT=$((SYNC_COUNT + 1))
        else
            echo -e "${YELLOW}⚠️  Skipping $repo_name (not found or not a git repo)${NC}"
        fi
        echo ""
    done

    if [ $SYNC_COUNT -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No repositories were synced${NC}"
    fi
else
    # Sync specific repo
    repo_name="$REPO_ARG"
    repo_dir="$BASE_DIR/$repo_name"

    if [ ! -d "$repo_dir" ] || [ ! -d "$repo_dir/.git" ]; then
        echo -e "${RED}❌ Repository not found: $repo_dir${NC}"
        echo "Make sure the repository is cloned to $BASE_DIR"
        exit 1
    fi

    sync_repo "$repo_dir" "$repo_name"
fi

echo -e "${GREEN}✓ Sync complete!${NC}"
