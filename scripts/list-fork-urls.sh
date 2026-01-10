#!/bin/bash
# List all your fork URLs (origin remotes)
# Usage: ./list-fork-urls.sh

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
LEARNING_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/config-loader.sh"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}📋 Your Fork URLs${NC}"
echo -e "${GREEN}========================================${NC}\n"

FORK_COUNT=0
NO_FORK_COUNT=0

for repo_dir in "$BASE_DIR"/*/; do
    if [ ! -d "$repo_dir/.git" ]; then
        continue
    fi

    repo_name=$(basename "$repo_dir")
    cd "$repo_dir" 2>/dev/null || continue

    # Get origin URL
    origin_url=$(git remote get-url origin 2>/dev/null || echo "")
    
    if [ -z "$origin_url" ]; then
        continue
    fi

    # Check if it's a fork (points to your GitHub username)
    if [[ "$origin_url" == *"${YOUR_GITHUB_USER}"* ]]; then
        FORK_COUNT=$((FORK_COUNT + 1))
        
        # Get upstream URL if configured
        upstream_url=$(git remote get-url upstream 2>/dev/null || echo "")
        
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}📦 $repo_name${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}Your Fork (origin):${NC}"
        echo -e "  $origin_url"
        
        if [ -n "$upstream_url" ]; then
            echo -e "${YELLOW}Upstream:${NC}"
            echo -e "  $upstream_url"
        else
            echo -e "${YELLOW}Upstream:${NC} Not configured"
        fi
        
        # Get current branch
        current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        echo -e "${CYAN}Current branch:${NC} $current_branch"
        echo ""
    else
        NO_FORK_COUNT=$((NO_FORK_COUNT + 1))
        echo -e "${YELLOW}⚠️  $repo_name:${NC} origin points to $origin_url (not your fork)"
        echo ""
    fi
done

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Your forks: $FORK_COUNT${NC}"
if [ "$NO_FORK_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Not your forks: $NO_FORK_COUNT${NC}"
fi
echo ""

