#!/bin/bash
# Reset your fork to match upstream exactly (discards local changes)
# Usage: ./reset-to-upstream.sh [repo-name|all]

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
CYAN='\033[0;36m'
NC='\033[0m'

reset_repo() {
    local repo_dir=$1
    local repo_name=$2

    if [ ! -d "$repo_dir" ]; then
        echo -e "${RED}✗ $repo_name: Not cloned${NC}"
        return
    fi

    cd "$repo_dir"

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🔄 Resetting: $repo_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    # Check current branch
    local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    echo -e "${CYAN}Current branch:${NC} $current_branch"

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
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

    # Check if upstream is configured
    if ! git remote | grep -q "upstream"; then
        echo -e "${RED}✗ Upstream remote not configured${NC}"
        echo -e "   ${YELLOW}Run:${NC} git remote add upstream git@github.com:${UPSTREAM_ORG}/$repo_name.git"
        return
    fi

    # Fetch upstream
    echo -e "${YELLOW}Fetching upstream...${NC}"
    git fetch upstream

    # Find main branch
    local main_branch=""
    if git show-ref --verify --quiet refs/remotes/upstream/main; then
        main_branch="main"
    elif git show-ref --verify --quiet refs/remotes/upstream/master; then
        main_branch="master"
    else
        echo -e "${RED}Could not find upstream main or master branch${NC}"
        return
    fi

    # Show what will be lost
    local ahead=$(git rev-list --count upstream/$main_branch..HEAD 2>/dev/null || echo "0")
    if [ "$ahead" != "0" ]; then
        echo -e "${YELLOW}⚠️  You have $ahead local commit(s) that will be LOST:${NC}"
        git log --oneline upstream/$main_branch..HEAD | head -5
        echo ""
    fi

    # Confirm
    echo -e "${RED}⚠️  WARNING: This will discard ALL local changes and commits${NC}"
    echo -e "${YELLOW}Your fork will be reset to match upstream/$main_branch exactly${NC}"
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

    # Clean untracked files (optional)
    echo -e "${YELLOW}Clean untracked files? (y/n)${NC}"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git clean -fd
        echo -e "${GREEN}✓ Untracked files cleaned${NC}"
    fi

    echo -e "${GREEN}✓ Successfully reset to upstream/$main_branch${NC}"
    echo ""

    # Offer to force push to origin (to update your fork)
    echo -e "${YELLOW}Update your fork on GitHub? (y/n)${NC}"
    echo -e "${CYAN}This will force push to origin, overwriting your fork${NC}"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Safety check - make sure origin points to your fork
        local origin_url=$(git remote get-url origin 2>/dev/null || echo "")
        if [[ "$origin_url" == *"${UPSTREAM_ORG}/"* ]] && [[ "$origin_url" != *"${YOUR_GITHUB_USER}"* ]]; then
            echo -e "${RED}✗ SAFETY BLOCK: Cannot push to ${UPSTREAM_ORG} organization${NC}"
            echo -e "${YELLOW}Remote URL: $origin_url${NC}"
            return
        fi

        echo -e "${YELLOW}Force pushing to origin/$current_branch...${NC}"
        git push origin "$current_branch" --force
        echo -e "${GREEN}✓ Fork updated on GitHub${NC}"
    fi

    echo ""
}

# Main logic
REPO_ARG="${1:-all}"

if [ "$REPO_ARG" = "all" ]; then
    # Reset all configured repos or auto-detect
    if [ -n "$MONITOR_REPOS" ]; then
        REPOS_TO_RESET="$MONITOR_REPOS"
    else
        # Auto-detect from cloned repos
        REPOS_TO_RESET=$(find "$BASE_DIR" -maxdepth 1 -type d -not -path "$BASE_DIR" | \
            xargs -I {} basename {} | \
            grep -v "^\." | \
            head -"${MAX_MONITOR_REPOS:-10}" | \
            tr '\n' ' ')
        REPOS_TO_RESET=$(echo "$REPOS_TO_RESET" | xargs)  # Trim whitespace
    fi

    if [ -z "$REPOS_TO_RESET" ]; then
        echo -e "${RED}❌ No repositories found to reset${NC}"
        echo "Set MONITOR_REPOS in config.sh or specify a repo name"
        exit 1
    fi

    for repo_name in $REPOS_TO_RESET; do
        repo_dir="$BASE_DIR/$repo_name"
        if [ -d "$repo_dir" ] && [ -d "$repo_dir/.git" ]; then
            reset_repo "$repo_dir" "$repo_name"
            echo ""
        fi
    done
else
    # Reset specific repo
    repo_name="$REPO_ARG"
    repo_dir="$BASE_DIR/$repo_name"

    if [ ! -d "$repo_dir" ] || [ ! -d "$repo_dir/.git" ]; then
        echo -e "${RED}❌ Repository not found: $repo_dir${NC}"
        exit 1
    fi

    reset_repo "$repo_dir" "$repo_name"
fi

echo -e "${GREEN}✓ Reset complete!${NC}"
