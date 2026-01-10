#!/bin/bash
# Upstream Organization Project Change Monitor
# Run this daily/weekly to see what's new

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
LEARNING_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/config-loader.sh"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}${UPSTREAM_ORG} Project Change Monitor${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Determine which repos to monitor
if [ -n "$MONITOR_REPOS" ]; then
    # Use configured list
    REPOS_TO_MONITOR="$MONITOR_REPOS"
else
    # Auto-detect from cloned repos in BASE_DIR
    echo -e "${YELLOW}📋 Auto-detecting repositories to monitor...${NC}"
    REPOS_TO_MONITOR=$(find "$BASE_DIR" -maxdepth 1 -type d -not -path "$BASE_DIR" | \
        xargs -I {} basename {} | \
        head -"${MAX_MONITOR_REPOS:-10}" | \
        tr '\n' ' ')
    REPOS_TO_MONITOR=$(echo "$REPOS_TO_MONITOR" | xargs)  # Trim whitespace
    if [ -z "$REPOS_TO_MONITOR" ]; then
        echo -e "${YELLOW}⚠️  No repositories found to monitor${NC}"
        echo "Set MONITOR_REPOS in config.sh or clone repositories to $BASE_DIR"
        exit 0
    fi
    echo -e "${GREEN}✓ Found repositories: $REPOS_TO_MONITOR${NC}\n"
fi

# Function to monitor a repo
monitor_repo() {
    local repo_dir=$1
    local repo_name=$2
    local upstream_owner=$3
    local upstream_repo=$4

    cd "$repo_dir"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📦 Repository: $repo_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    # 1. Fetch all changes from upstream
    echo -e "${YELLOW}🔄 Fetching upstream changes...${NC}"
    if git remote | grep -q "upstream"; then
        git fetch upstream --quiet
        echo "✓ Upstream fetched"
    else
        echo "⚠️  No upstream remote configured"
    fi

    # Fetch origin too
    git fetch origin --quiet
    echo "✓ Origin fetched"
    echo ""

    # 2. Show open PRs in upstream
    echo -e "${YELLOW}📋 Open Pull Requests in upstream:${NC}"
    gh pr list --repo "$upstream_owner/$upstream_repo" --limit 10 || echo "Unable to fetch PRs"
    echo ""

    # 3. Show recent releases
    echo -e "${YELLOW}🏷️  Recent Releases:${NC}"
    gh release list --repo "$upstream_owner/$upstream_repo" --limit 5 || echo "No releases found"
    echo ""

    # 4. Show commits on upstream main that you don't have
    echo -e "${YELLOW}📝 New commits in upstream (last 10):${NC}"
    if git remote | grep -q "upstream"; then
        git log --oneline --graph --decorate -10 upstream/main || \
        git log --oneline --graph --decorate -10 upstream/master || \
        echo "Could not find upstream main/master branch"
    fi
    echo ""

    # 5. Show your local changes not pushed
    echo -e "${YELLOW}🔧 Your unpushed commits:${NC}"
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    git log --oneline origin/$current_branch..$current_branch 2>/dev/null || echo "No unpushed commits"
    echo ""

    echo ""
}

# Monitor each configured repo
MONITORED_COUNT=0
for repo_name in $REPOS_TO_MONITOR; do
    repo_dir="$BASE_DIR/$repo_name"
    if [ -d "$repo_dir" ] && [ -d "$repo_dir/.git" ]; then
        monitor_repo "$repo_dir" "$repo_name" "$UPSTREAM_ORG" "$repo_name"
        MONITORED_COUNT=$((MONITORED_COUNT + 1))
    else
        echo -e "${YELLOW}⚠️  Repository directory not found or not a git repo: $repo_dir${NC}"
    fi
done

if [ $MONITORED_COUNT -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No repositories were monitored${NC}"
    echo "Check that repositories exist in $BASE_DIR or update MONITOR_REPOS in config.sh"
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Monitoring complete! (monitored $MONITORED_COUNT repositories)${NC}"
echo -e "${GREEN}========================================${NC}"
