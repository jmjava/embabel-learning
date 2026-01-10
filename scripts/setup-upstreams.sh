#!/bin/bash
# Set up upstream remotes for all cloned upstream organization repos
# This allows you to track changes from the original organization repositories

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
LEARNING_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/config-loader.sh"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Upstream Remote Setup Manager${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Find all cloned upstream org repos
echo -e "${YELLOW}📋 Finding cloned ${UPSTREAM_ORG} repositories...${NC}"
CLONED_REPOS=()

for dir in "$BASE_DIR"/*/; do
    if [ -d "$dir/.git" ]; then
        repo_name=$(basename "$dir")
        cd "$dir"

        # Check if it's a fork of upstream org
        if gh repo view "$YOUR_GITHUB_USER/$repo_name" --json parent --jq '.parent.owner.login' 2>/dev/null | grep -q "$UPSTREAM_ORG"; then
            CLONED_REPOS+=("$repo_name")
        fi
    fi
done

if [ ${#CLONED_REPOS[@]} -eq 0 ]; then
    echo -e "${RED}❌ No cloned ${UPSTREAM_ORG} repositories found${NC}"
    echo "Run $SCRIPT_DIR/clone-embabel-repos.sh first"
    exit 1
fi

echo -e "${GREEN}✓ Found ${#CLONED_REPOS[@]} cloned ${UPSTREAM_ORG} repositories${NC}\n"

# Set up upstreams
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Setting up upstream remotes...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

CONFIGURED=0
ALREADY_SET=0
FAILED=0

for repo in "${CLONED_REPOS[@]}"; do
    cd "$BASE_DIR/$repo"

    echo -e "${YELLOW}Processing $repo...${NC}"

    # Check if upstream already exists
    if git remote | grep -q "^upstream$"; then
        CURRENT_UPSTREAM=$(git remote get-url upstream 2>/dev/null || echo "")
        EXPECTED_UPSTREAM="git@github.com:${UPSTREAM_ORG}/$repo.git"

        if [ "$CURRENT_UPSTREAM" = "$EXPECTED_UPSTREAM" ]; then
            echo -e "${BLUE}⊝ Upstream already configured correctly${NC}"
            ALREADY_SET=$((ALREADY_SET + 1))
        else
            echo -e "${YELLOW}⚠️  Upstream exists but points to: $CURRENT_UPSTREAM${NC}"
            echo -e "${YELLOW}   Updating to: $EXPECTED_UPSTREAM${NC}"
            git remote remove upstream
            git remote add upstream "$EXPECTED_UPSTREAM"
            echo -e "${GREEN}✓ Updated upstream${NC}"
            CONFIGURED=$((CONFIGURED + 1))
        fi
    else
        # Add upstream
        if git remote add upstream "git@github.com:${UPSTREAM_ORG}/$repo.git"; then
            echo -e "${GREEN}✓ Added upstream remote${NC}"
            CONFIGURED=$((CONFIGURED + 1))
        else
            echo -e "${RED}✗ Failed to add upstream${NC}"
            FAILED=$((FAILED + 1))
        fi
    fi

    # Fetch from upstream
    echo -e "${YELLOW}  Fetching from upstream...${NC}"
    if git fetch upstream --quiet 2>/dev/null; then
        echo -e "${GREEN}  ✓ Fetched upstream changes${NC}"
    else
        echo -e "${RED}  ⚠️  Could not fetch from upstream (check SSH access)${NC}"
    fi

    echo ""
done

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Newly configured: $CONFIGURED${NC}"
echo -e "${BLUE}⊝ Already configured: $ALREADY_SET${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}✗ Failed: $FAILED${NC}"
fi
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Next Steps:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1. Monitor all repositories:"
echo "   $SCRIPT_DIR/monitor-embabel.sh"
echo ""
echo "2. Sync a specific repository with upstream:"
echo "   $SCRIPT_DIR/sync-upstream.sh <repo-name>"
echo ""
echo "3. Compare your changes with upstream:"
echo "   $SCRIPT_DIR/compare-branches.sh all"
echo ""

echo -e "${GREEN}✓ Done!${NC}"
