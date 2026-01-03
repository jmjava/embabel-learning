#!/bin/bash
# Compare your fork with upstream to see what's different
# Usage: ./compare-branches.sh [guide|agent]

set -e

GUIDE_DIR="$HOME/github/jmjava/guide"
AGENT_DIR="$HOME/github/jmjava/embabel-agent"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

compare_repo() {
    local repo_dir=$1
    local repo_name=$2
    local upstream_repo=$3
    
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

case "${1:-all}" in
    guide)
        compare_repo "$GUIDE_DIR" "guide" "embabel/guide"
        ;;
    agent)
        compare_repo "$AGENT_DIR" "embabel-agent" "embabel/embabel-agent"
        ;;
    all)
        compare_repo "$GUIDE_DIR" "guide" "embabel/guide"
        echo ""
        compare_repo "$AGENT_DIR" "embabel-agent" "embabel/embabel-agent"
        ;;
    *)
        echo "Usage: $0 [guide|agent|all]"
        exit 1
        ;;
esac

