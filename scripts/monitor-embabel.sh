#!/bin/bash
# Embabel Project Change Monitor
# Run this daily/weekly to see what's new

set -e

GUIDE_DIR="$HOME/github/jmjava/guide"
AGENT_DIR="$HOME/github/jmjava/embabel-agent"
DICE_DIR="$HOME/github/jmjava/dice"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Embabel Project Change Monitor${NC}"
echo -e "${GREEN}========================================${NC}\n"

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

# Monitor guide repo
if [ -d "$GUIDE_DIR" ]; then
    monitor_repo "$GUIDE_DIR" "guide" "embabel" "guide"
else
    echo "⚠️  Guide directory not found: $GUIDE_DIR"
fi

# Monitor embabel-agent repo
if [ -d "$AGENT_DIR" ]; then
    monitor_repo "$AGENT_DIR" "embabel-agent" "embabel" "embabel-agent"
else
    echo "⚠️  Embabel-agent directory not found: $AGENT_DIR"
fi

# Monitor dice repo
if [ -d "$DICE_DIR" ]; then
    monitor_repo "$DICE_DIR" "dice" "embabel" "dice"
else
    echo "⚠️  Dice directory not found: $DICE_DIR"
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Monitoring complete!${NC}"
echo -e "${GREEN}========================================${NC}"
