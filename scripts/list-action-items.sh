#!/bin/bash
# List all actionable items from various sources
# Aggregates: PRs to review, repos to sync, releases to check, etc.

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
LEARNING_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/config-loader.sh"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}📋 Action Items for Investigation${NC}"
echo -e "${GREEN}========================================${NC}\n"

ACTION_COUNT=0

# Function to add action item
add_action() {
    ACTION_COUNT=$((ACTION_COUNT + 1))
    echo -e "${CYAN}[$ACTION_COUNT]${NC} $1"
    return 0
}

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔄 Repositories Needing Sync${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
LEARNING_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/config-loader.sh"

check_repo_sync() {
    local repo_dir=$1
    local repo_name=$2

    if [ ! -d "$repo_dir" ]; then
        return
    fi

    cd "$repo_dir" 2>/dev/null || return

    if git remote | grep -q "upstream"; then
        git fetch upstream --quiet 2>/dev/null || true
        UPSTREAM=$(git rev-parse upstream/main 2>/dev/null || git rev-parse upstream/master 2>/dev/null || echo "")
        LOCAL=$(git rev-parse @ 2>/dev/null)

        if [ -n "$UPSTREAM" ] && [ "$LOCAL" != "$UPSTREAM" ]; then
            BEHIND=$(git rev-list --count HEAD..upstream/main 2>/dev/null || git rev-list --count HEAD..upstream/master 2>/dev/null || echo "?")
            AHEAD=$(git rev-list --count upstream/main..HEAD 2>/dev/null || git rev-list --count upstream/master..HEAD 2>/dev/null || echo "?")

            if [ "$BEHIND" != "0" ] || [ "$AHEAD" != "0" ]; then
                if [ "$BEHIND" != "0" ]; then
                    add_action "Sync $repo_name: $BEHIND commits behind upstream"
                    echo -e "   ${YELLOW}Command:${NC} esync $repo_name"
                    echo -e "   ${YELLOW}Or:${NC} cd $repo_dir && git pull upstream main"
                    echo ""
                fi
                if [ "$AHEAD" != "0" ]; then
                    echo -e "   ${YELLOW}⚠️  You have $AHEAD unpushed commits${NC}"
                    git log --oneline upstream/main..HEAD 2>/dev/null | head -3 | sed 's/^/      /' || true
                    echo ""
                fi
            fi
        fi
    fi
}

# Check all configured repos or auto-detect
if [ -n "$MONITOR_REPOS" ]; then
    REPOS_TO_CHECK="$MONITOR_REPOS"
else
    REPOS_TO_CHECK=$(find "$BASE_DIR" -maxdepth 1 -type d -not -path "$BASE_DIR" 2>/dev/null | \
        xargs -I {} basename {} | \
        head -"${MAX_MONITOR_REPOS:-10}" | \
        tr '\n' ' ')
fi

for repo_name in $REPOS_TO_CHECK; do
    repo_dir="$BASE_DIR/$repo_name"
    if [ -d "$repo_dir" ] && [ -d "$repo_dir/.git" ]; then
        check_repo_sync "$repo_dir" "$repo_name"
    fi
done

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 Open PRs to Review${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Check PRs from all configured repos
TOTAL_PR_COUNT=0
for repo_name in $REPOS_TO_CHECK; do
    REPO_PRS=$(gh pr list --repo "${UPSTREAM_ORG}/$repo_name" --state open --limit 20 --json number,title,author,createdAt,url 2>/dev/null || echo "[]")
    REPO_PR_COUNT=$(echo "$REPO_PRS" | jq '. | length' 2>/dev/null || echo "0")

    if [ "$REPO_PR_COUNT" -gt 0 ]; then
        echo -e "${GREEN}$repo_name: $REPO_PR_COUNT open PR(s)${NC}\n"
        echo "$REPO_PRS" | jq -r '.[] | "\(.number)|\(.title)|\(.author.login)|\(.createdAt)|\(.url)"' 2>/dev/null | while IFS='|' read -r num title author created url; do
            add_action "Review PR #$num: $title (by $author)" || true
            echo -e "   ${YELLOW}Created:${NC} $created"
            echo -e "   ${YELLOW}View:${NC} epr $repo_name $num"
            echo -e "   ${YELLOW}URL:${NC} $url"
            echo ""
        done
        TOTAL_PR_COUNT=$((TOTAL_PR_COUNT + REPO_PR_COUNT))
    fi
done

if [ "$TOTAL_PR_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✓ No open PRs to review${NC}\n"
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🏷️  Recent Releases to Check${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Check releases from all configured repos
for repo_name in $REPOS_TO_CHECK; do
    REPO_RELEASES=$(gh release list --repo "${UPSTREAM_ORG}/$repo_name" --limit 3 --json tagName,publishedAt,url 2>/dev/null || echo "[]")
    REPO_RELEASE_COUNT=$(echo "$REPO_RELEASES" | jq '. | length' 2>/dev/null || echo "0")

    if [ "$REPO_RELEASE_COUNT" -gt 0 ]; then
        echo "$REPO_RELEASES" | jq -r '.[] | "\(.tagName)|\(.publishedAt)|\(.url)"' 2>/dev/null | while IFS='|' read -r tag published url; do
            # Check if release is recent (within last 30 days)
            PUBLISHED_EPOCH=$(date -d "$published" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$published" +%s 2>/dev/null || echo "0")
            NOW_EPOCH=$(date +%s)
            DAYS_AGO=$(( (NOW_EPOCH - PUBLISHED_EPOCH) / 86400 ))

            if [ "$DAYS_AGO" -lt 30 ]; then
                add_action "Check release $tag in $repo_name (published $DAYS_AGO days ago)"
                echo -e "   ${YELLOW}URL:${NC} $url"
                echo ""
            fi
        done
    fi
done

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📝 Recent Commits to Review${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

check_recent_commits() {
    local repo_dir=$1
    local repo_name=$2

    if [ ! -d "$repo_dir" ]; then
        return
    fi

    cd "$repo_dir" 2>/dev/null || return

    if git remote | grep -q "upstream"; then
        git fetch upstream --quiet 2>/dev/null || true
        UPSTREAM=$(git rev-parse upstream/main 2>/dev/null || git rev-parse upstream/master 2>/dev/null || echo "")
        LOCAL=$(git rev-parse @ 2>/dev/null)

        if [ -n "$UPSTREAM" ] && [ "$LOCAL" != "$UPSTREAM" ]; then
            BEHIND=$(git rev-list --count HEAD..upstream/main 2>/dev/null || git rev-list --count HEAD..upstream/master 2>/dev/null || echo "0")

            if [ "$BEHIND" -gt 0 ] && [ "$BEHIND" -lt 20 ]; then
                echo -e "${GREEN}$repo_name: $BEHIND new commit(s) in upstream${NC}"
                git log --oneline HEAD..upstream/main 2>/dev/null | head -5 | sed 's/^/   /' || git log --oneline HEAD..upstream/master 2>/dev/null | head -5 | sed 's/^/   /' || true
                echo ""
            fi
        fi
    fi
}

for repo_name in $REPOS_TO_CHECK; do
    repo_dir="$BASE_DIR/$repo_name"
    if [ -d "$repo_dir" ] && [ -d "$repo_dir/.git" ]; then
        check_recent_commits "$repo_dir" "$repo_name"
    fi
done

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${GREEN}Total Action Items: $ACTION_COUNT${NC}\n"

if [ "$ACTION_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✓ All caught up! No action items at this time.${NC}"
else
    echo -e "${YELLOW}Quick Commands:${NC}"
    echo -e "  ${CYAN}em${NC}          - Monitor all projects"
    echo -e "  ${CYAN}elist${NC}       - List all repos and status"
    echo -e "  ${CYAN}esync${NC}       - Sync repositories"
    echo -e "  ${CYAN}epr agent <#>{NC} - View specific PR"
    echo -e "  ${CYAN}emy${NC}         - Your contributions"
fi

echo ""
