#!/bin/bash
# List all embabel repositories and show their status
# Shows which are forked, cloned, and have upstream configured

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[0;90m'
NC='\033[0m'

YOUR_USER="jmjava"
EMBABEL_ORG="embabel"
BASE_DIR="$HOME/github/jmjava"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Embabel Repository Status${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Get all embabel repos
echo -e "${YELLOW}📋 Fetching embabel repositories...${NC}"
ALL_REPOS=$(gh repo list "$EMBABEL_ORG" --limit 100 --json name,description,stargazerCount,pushedAt,isArchived --jq '.[] | select(.isArchived == false) | @json' | sort)

if [ -z "$ALL_REPOS" ]; then
    echo -e "${RED}❌ Could not fetch repositories${NC}"
    exit 1
fi

# Get your forks
FORKED_REPOS=$(gh repo list "$YOUR_USER" --fork --limit 100 --json name,parent --jq ".[] | select(.parent.owner.login == \"$EMBABEL_ORG\") | .name")

echo -e "${GREEN}✓ Analysis complete${NC}\n"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Repository Status${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

TOTAL=0
FORKED_COUNT=0
CLONED_COUNT=0
UPSTREAM_COUNT=0

# Status symbols
# ✓ = Forked, Cloned, Upstream configured
# ⊕ = Forked, Cloned, No upstream
# ⊙ = Forked, Not cloned
# ○ = Not forked

printf "%-30s %-8s %-8s %-10s %s\n" "Repository" "Forked" "Cloned" "Upstream" "Stars"
echo "────────────────────────────────────────────────────────────────────"

while IFS= read -r repo_json; do
    repo_name=$(echo "$repo_json" | jq -r '.name')
    stars=$(echo "$repo_json" | jq -r '.stargazerCount')
    description=$(echo "$repo_json" | jq -r '.description // "No description"')

    TOTAL=$((TOTAL + 1))

    # Check if forked
    if echo "$FORKED_REPOS" | grep -q "^${repo_name}$"; then
        forked="${GREEN}✓${NC}"
        FORKED_COUNT=$((FORKED_COUNT + 1))
    else
        forked="${GRAY}○${NC}"
    fi

    # Check if cloned
    if [ -d "$BASE_DIR/$repo_name" ]; then
        cloned="${GREEN}✓${NC}"
        CLONED_COUNT=$((CLONED_COUNT + 1))

        # Check if upstream is configured
        cd "$BASE_DIR/$repo_name"
        if git remote | grep -q "^upstream$"; then
            upstream="${GREEN}✓${NC}"
            UPSTREAM_COUNT=$((UPSTREAM_COUNT + 1))
        else
            upstream="${GRAY}○${NC}"
        fi
    else
        cloned="${GRAY}○${NC}"
        upstream="${GRAY}○${NC}"
    fi

    printf "%-30s %-8s %-8s %-10s %s\n" "$repo_name" "$forked" "$cloned" "$upstream" "⭐ $stars"

done <<< "$ALL_REPOS"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Total repositories: $TOTAL"
echo -e "${GREEN}✓ Forked: $FORKED_COUNT${NC}"
echo -e "${GREEN}✓ Cloned: $CLONED_COUNT${NC}"
echo -e "${GREEN}✓ Upstream configured: $UPSTREAM_COUNT${NC}"
echo ""

NOT_FORKED=$((TOTAL - FORKED_COUNT))
if [ $NOT_FORKED -gt 0 ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}You have $NOT_FORKED repositories not yet forked${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "Run: ./fork-all-embabel.sh"
    echo ""
fi

NOT_CLONED=$((FORKED_COUNT - CLONED_COUNT))
if [ $NOT_CLONED -gt 0 ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}You have $NOT_CLONED forked repos not yet cloned${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "Run: ./clone-embabel-repos.sh"
    echo ""
fi

NO_UPSTREAM=$((CLONED_COUNT - UPSTREAM_COUNT))
if [ $NO_UPSTREAM -gt 0 ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}You have $NO_UPSTREAM cloned repos without upstream${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "Run: ./setup-upstreams.sh"
    echo ""
fi

# Show interesting repos
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🌟 Most Starred Repositories${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo "$ALL_REPOS" | jq -r '[.] | sort_by(-.stargazerCount) | .[:5] | .[] | "\(.name) - ⭐ \(.stargazerCount) - \(.description // "No description")"' | head -5

echo ""
echo -e "${GREEN}✓ Done!${NC}"
