#!/bin/bash
# Fork all embabel repositories that haven't been forked yet
# This script checks which repos you already have and forks the rest

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

EMBABEL_ORG="embabel"
YOUR_USER="jmjava"
BASE_DIR="$HOME/github/jmjava"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Embabel Repository Fork Manager${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Get all embabel repos
echo -e "${YELLOW}📋 Fetching all repositories from $EMBABEL_ORG...${NC}"
ALL_EMBABEL_REPOS=$(gh repo list "$EMBABEL_ORG" --limit 100 --json name,isArchived --jq '.[] | select(.isArchived == false) | .name' | sort)

if [ -z "$ALL_EMBABEL_REPOS" ]; then
    echo -e "${RED}❌ Could not fetch repositories from $EMBABEL_ORG${NC}"
    exit 1
fi

REPO_COUNT=$(echo "$ALL_EMBABEL_REPOS" | wc -l)
echo -e "${GREEN}✓ Found $REPO_COUNT active repositories${NC}\n"

# Get repos you've already forked
echo -e "${YELLOW}📋 Checking your existing forks...${NC}"
FORKED_REPOS=$(gh repo list "$YOUR_USER" --fork --limit 100 --json name,parent --jq ".[] | select(.parent.owner.login == \"$EMBABEL_ORG\") | .name" | sort)

FORKED_COUNT=$(echo "$FORKED_REPOS" | grep -c . || echo "0")
echo -e "${GREEN}✓ You have already forked $FORKED_COUNT repositories${NC}\n"

# Find repos to fork
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Analysis${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

TO_FORK=()
ALREADY_FORKED=()

while IFS= read -r repo; do
    if echo "$FORKED_REPOS" | grep -q "^${repo}$"; then
        ALREADY_FORKED+=("$repo")
    else
        TO_FORK+=("$repo")
    fi
done <<< "$ALL_EMBABEL_REPOS"

echo -e "${GREEN}Already forked (${#ALREADY_FORKED[@]}):${NC}"
for repo in "${ALREADY_FORKED[@]}"; do
    echo "  ✓ $repo"
done
echo ""

echo -e "${YELLOW}To be forked (${#TO_FORK[@]}):${NC}"
for repo in "${TO_FORK[@]}"; do
    echo "  → $repo"
done
echo ""

if [ ${#TO_FORK[@]} -eq 0 ]; then
    echo -e "${GREEN}🎉 All repositories are already forked!${NC}"
    exit 0
fi

# Ask for confirmation
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}This will fork ${#TO_FORK[@]} repositories.${NC}"
read -p "Proceed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Cancelled.${NC}"
    exit 0
fi

# Fork each repo
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Forking repositories...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

FORKED=0
FAILED=0
FAILED_REPOS=()

for repo in "${TO_FORK[@]}"; do
    echo -e "${YELLOW}Forking $repo...${NC}"

    if gh repo fork "$EMBABEL_ORG/$repo" --clone=false; then
        echo -e "${GREEN}✓ Successfully forked $repo${NC}"
        FORKED=$((FORKED + 1))
    else
        echo -e "${RED}✗ Failed to fork $repo${NC}"
        FAILED=$((FAILED + 1))
        FAILED_REPOS+=("$repo")
    fi
    echo ""

    # Be nice to GitHub API
    sleep 1
done

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Successfully forked: $FORKED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}✗ Failed to fork: $FAILED${NC}"
    echo -e "${RED}Failed repositories:${NC}"
    for repo in "${FAILED_REPOS[@]}"; do
        echo -e "${RED}  - $repo${NC}"
    done
fi
echo ""

if [ $FORKED -gt 0 ]; then
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Next Steps:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "1. Clone the forked repositories you want to work with:"
    echo "   ./clone-embabel-repos.sh"
    echo ""
    echo "2. Set up upstream remotes:"
    echo "   ./setup-upstreams.sh"
    echo ""
    echo "3. Start monitoring:"
    echo "   ./monitor-embabel.sh"
    echo ""
fi

echo -e "${GREEN}✓ Done!${NC}"
