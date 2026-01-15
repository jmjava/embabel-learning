#!/bin/bash
# Clone all your forked upstream organization repositories
# Usage: ./clone-embabel-repos.sh [all|selective]

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
echo -e "${GREEN}${UPSTREAM_ORG} Repository Clone Manager${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Get your forked upstream org repos
echo -e "${YELLOW}📋 Fetching your ${UPSTREAM_ORG} forks...${NC}"
FORKED_REPOS=$(gh repo list "$YOUR_GITHUB_USER" --fork --limit 100 --json name,parent --jq ".[] | select(.parent.owner.login == \"$UPSTREAM_ORG\") | .name" | sort)

if [ -z "$FORKED_REPOS" ]; then
    echo -e "${RED}❌ No ${UPSTREAM_ORG} forks found${NC}"
    echo "Run $SCRIPT_DIR/fork-all-embabel.sh first"
    exit 1
fi

REPO_COUNT=$(echo "$FORKED_REPOS" | wc -l)
echo -e "${GREEN}✓ Found $REPO_COUNT forked repositories${NC}\n"

# Check which are already cloned
echo -e "${YELLOW}📋 Checking which repos are already cloned...${NC}"
ALREADY_CLONED=()
TO_CLONE=()

while IFS= read -r repo; do
    if [ -d "$BASE_DIR/$repo" ]; then
        ALREADY_CLONED+=("$repo")
    else
        TO_CLONE+=("$repo")
    fi
done <<< "$FORKED_REPOS"

echo -e "${GREEN}Already cloned (${#ALREADY_CLONED[@]}):${NC}"
for repo in "${ALREADY_CLONED[@]}"; do
    echo "  ✓ $repo"
done
echo ""

echo -e "${YELLOW}To be cloned (${#TO_CLONE[@]}):${NC}"
for repo in "${TO_CLONE[@]}"; do
    echo "  → $repo"
done
echo ""

if [ ${#TO_CLONE[@]} -eq 0 ]; then
    echo -e "${GREEN}🎉 All repositories are already cloned!${NC}"
    exit 0
fi

# Ask for confirmation
MODE="${1:-selective}"
if [ "$MODE" = "all" ]; then
    CLONE_ALL=true
else
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Clone all ${#TO_CLONE[@]} repositories? (y/n)${NC}"
    echo -e "${BLUE}(Or run with 'all' argument to skip prompts)${NC}"
    read -p "> " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        CLONE_ALL=true
    else
        CLONE_ALL=false
    fi
fi

# Clone repos
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Cloning repositories...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

cd "$BASE_DIR"
CLONED=0
SKIPPED=0

for repo in "${TO_CLONE[@]}"; do
    if [ "$CLONE_ALL" = false ]; then
        echo -e "${YELLOW}Clone $repo? (y/n/q)${NC}"
        read -p "> " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Qq]$ ]]; then
            echo "Quit requested"
            break
        elif [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}⊝ Skipped $repo${NC}\n"
            SKIPPED=$((SKIPPED + 1))
            continue
        fi
    fi

    echo -e "${YELLOW}Cloning $repo...${NC}"
    if gh repo clone "$YOUR_GITHUB_USER/$repo"; then
        echo -e "${GREEN}✓ Successfully cloned $repo${NC}"
        CLONED=$((CLONED + 1))
    else
        echo -e "${RED}✗ Failed to clone $repo${NC}"
    fi
    echo ""
done

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Successfully cloned: $CLONED${NC}"
if [ $SKIPPED -gt 0 ]; then
    echo -e "${BLUE}⊝ Skipped: $SKIPPED${NC}"
fi
echo ""

if [ $CLONED -gt 0 ]; then
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Next Step:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Set up upstream remotes for all cloned repos:"
    echo "  $SCRIPT_DIR/setup-upstreams.sh"
    echo ""
fi

echo -e "${GREEN}✓ Done!${NC}"
