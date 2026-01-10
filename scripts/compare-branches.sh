#!/bin/bash
# Compare your fork with upstream to see what's different
# Usage: ./compare-branches.sh [repo-name|all]

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
LEARNING_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/config-loader.sh"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

compare_repo() {
    local repo_dir=$1
    local repo_name=$2
    local upstream_repo="${UPSTREAM_ORG}/$repo_name"

    cd "$repo_dir"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🔍 Comparing: $repo_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    # Fetch latest
    echo -e "${YELLOW}Fetching latest changes...${NC}"
    git fetch upstream 2>/dev/null || git fetch origin
    git fetch origin

    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    echo "Current branch: $current_branch"
    echo ""

    # Find upstream main branch
    local main_branch=""
    if git show-ref --verify --quiet refs/remotes/upstream/main; then
        main_branch="upstream/main"
    elif git show-ref --verify --quiet refs/remotes/upstream/master; then
        main_branch="upstream/master"
    else
        main_branch="origin/main"
    fi

    # Show commits in upstream not in your branch
    echo -e "${YELLOW}📥 Commits in $main_branch not in your branch:${NC}"
    git log --oneline --graph --decorate $current_branch..$main_branch | head -20
    echo ""

    # Show your commits not in upstream
    echo -e "${YELLOW}📤 Your commits not in $main_branch:${NC}"
    git log --oneline --graph --decorate $main_branch..$current_branch | head -20
    echo ""

    # Show file differences summary
    echo -e "${YELLOW}📝 Files changed between your branch and $main_branch:${NC}"
    git diff --stat $main_branch..$current_branch
    echo ""

    # Summary
    local ahead=$(git rev-list --count $main_branch..$current_branch 2>/dev/null || echo "0")
    local behind=$(git rev-list --count $current_branch..$main_branch 2>/dev/null || echo "0")

    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Summary: $ahead commits ahead, $behind commits behind${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Main logic
REPO_ARG="${1:-all}"

if [ "$REPO_ARG" = "all" ]; then
    # Compare all configured repos or auto-detect
    if [ -n "$MONITOR_REPOS" ]; then
        REPOS_TO_COMPARE="$MONITOR_REPOS"
    else
        # Auto-detect from cloned repos
        REPOS_TO_COMPARE=$(find "$BASE_DIR" -maxdepth 1 -type d -not -path "$BASE_DIR" | \
            xargs -I {} basename {} | \
            grep -v "^\." | \
            head -"${MAX_MONITOR_REPOS:-10}" | \
            tr '\n' ' ')
        REPOS_TO_COMPARE=$(echo "$REPOS_TO_COMPARE" | xargs)  # Trim whitespace
    fi

    if [ -z "$REPOS_TO_COMPARE" ]; then
        echo -e "${RED}❌ No repositories found to compare${NC}"
        echo "Set MONITOR_REPOS in config.sh or specify a repo name"
        exit 1
    fi

    for repo_name in $REPOS_TO_COMPARE; do
        repo_dir="$BASE_DIR/$repo_name"
        if [ -d "$repo_dir" ] && [ -d "$repo_dir/.git" ]; then
            compare_repo "$repo_dir" "$repo_name"
            echo ""
        fi
    done
else
    # Compare specific repo
    repo_name="$REPO_ARG"
    repo_dir="$BASE_DIR/$repo_name"

    if [ ! -d "$repo_dir" ] || [ ! -d "$repo_dir/.git" ]; then
        echo -e "${RED}❌ Repository not found: $repo_dir${NC}"
        exit 1
    fi

    compare_repo "$repo_dir" "$repo_name"
fi
