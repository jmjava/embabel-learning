#!/bin/bash
# Check sync status and provide clear instructions to fix
# Usage: ./check-sync-status.sh [guide|agent|all]

set -e

GUIDE_DIR="$HOME/github/jmjava/guide"
AGENT_DIR="$HOME/github/jmjava/embabel-agent"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

check_repo() {
    local repo_dir=$1
    local repo_name=$2

    if [ ! -d "$repo_dir" ]; then
        echo -e "${RED}✗ $repo_name: Not cloned${NC}"
        echo -e "   ${YELLOW}Run:${NC} cd ~/github/jmjava && git clone git@github.com:jmjava/$repo_name.git"
        echo ""
        return
    fi

    cd "$repo_dir"

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📦 Repository: $repo_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    # Check current branch
    local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    echo -e "${CYAN}Current branch:${NC} $current_branch"

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Uncommitted changes detected:${NC}"
        git status --short | head -5
        echo -e "${YELLOW}   Fix:${NC} git stash (to save) or git commit (to commit)"
        echo ""
    fi

    # Check remotes
    if ! git remote | grep -q "upstream"; then
        echo -e "${RED}✗ Upstream remote not configured${NC}"
        echo -e "   ${YELLOW}Fix:${NC} git remote add upstream git@github.com:embabel/$repo_name.git"
        echo ""
        return
    fi

    # Fetch latest
    echo -e "${YELLOW}Fetching latest from remotes...${NC}"
    git fetch upstream --quiet 2>/dev/null || echo "  ⚠️  Could not fetch upstream"
    git fetch origin --quiet 2>/dev/null || echo "  ⚠️  Could not fetch origin"

    # Find main branch
    local main_branch=""
    if git show-ref --verify --quiet refs/remotes/upstream/main 2>/dev/null; then
        main_branch="main"
    elif git show-ref --verify --quiet refs/remotes/upstream/master 2>/dev/null; then
        main_branch="master"
    else
        echo -e "${RED}✗ Could not find upstream main/master branch${NC}"
        echo ""
        return
    fi

    # Compare with upstream
    local LOCAL=$(git rev-parse HEAD 2>/dev/null)
    local UPSTREAM=$(git rev-parse upstream/$main_branch 2>/dev/null)
    local ORIGIN=$(git rev-parse origin/$current_branch 2>/dev/null || echo "")

    if [ -z "$LOCAL" ] || [ -z "$UPSTREAM" ]; then
        echo -e "${RED}✗ Could not determine commit status${NC}"
        echo ""
        return
    fi

    # Check if behind upstream
    local BEHIND=$(git rev-list --count HEAD..upstream/$main_branch 2>/dev/null || echo "0")
    local AHEAD=$(git rev-list --count upstream/$main_branch..HEAD 2>/dev/null || echo "0")

    # Check if origin is different
    local ORIGIN_BEHIND=""
    local ORIGIN_AHEAD=""
    if [ -n "$ORIGIN" ]; then
        ORIGIN_BEHIND=$(git rev-list --count HEAD..origin/$current_branch 2>/dev/null || echo "0")
        ORIGIN_AHEAD=$(git rev-list --count origin/$current_branch..HEAD 2>/dev/null || echo "0")
    fi

    # Status summary
    echo ""
    echo -e "${CYAN}Sync Status:${NC}"

    if [ "$BEHIND" = "0" ] && [ "$AHEAD" = "0" ]; then
        echo -e "  ${GREEN}✓ In sync with upstream/$main_branch${NC}"
    else
        if [ "$BEHIND" != "0" ]; then
            echo -e "  ${RED}✗ $BEHIND commits behind upstream/$main_branch${NC}"
        fi
        if [ "$AHEAD" != "0" ]; then
            echo -e "  ${YELLOW}⚠️  $AHEAD commits ahead of upstream/$main_branch${NC}"
            echo -e "     ${CYAN}Your local commits:${NC}"
            git log --oneline upstream/$main_branch..HEAD 2>/dev/null | head -3 | sed 's/^/       /' || true
        fi
    fi

    if [ -n "$ORIGIN" ]; then
        if [ "$ORIGIN_BEHIND" != "0" ] || [ "$ORIGIN_AHEAD" != "0" ]; then
            echo -e "  ${YELLOW}⚠️  Origin differs from local${NC}"
            if [ "$ORIGIN_BEHIND" != "0" ]; then
                echo -e "     ${YELLOW}Origin is $ORIGIN_BEHIND commits behind your local${NC}"
            fi
            if [ "$ORIGIN_AHEAD" != "0" ]; then
                echo -e "     ${YELLOW}Origin is $ORIGIN_AHEAD commits ahead of your local${NC}"
            fi
        else
            echo -e "  ${GREEN}✓ In sync with origin/$current_branch${NC}"
        fi
    fi

    echo ""

    # Provide fix commands
    if [ "$BEHIND" != "0" ] || [ "$AHEAD" != "0" ]; then
        echo -e "${CYAN}To Fix:${NC}"

        if [ "$BEHIND" != "0" ]; then
            echo -e "  ${YELLOW}1. Sync with upstream:${NC}"
            echo -e "     ${GREEN}esync $repo_name${NC}"
            echo -e "     ${GREEN}Or:${NC} cd $repo_dir && git pull upstream $main_branch"
            echo ""
        fi

        if [ "$AHEAD" != "0" ]; then
            echo -e "  ${YELLOW}2. Your local commits (decide what to do):${NC}"
            echo -e "     ${CYAN}Option A:${NC} Keep and push to origin (use epush for safety)"
            echo -e "              epush"
            echo -e "              ${YELLOW}Or:${NC} git push origin $current_branch (after verifying remote)"
            echo -e "     ${CYAN}Option B:${NC} Discard local commits"
            echo -e "              git reset --hard upstream/$main_branch"
            echo ""
        fi
    fi

    # IDE refresh suggestion
    if [ "$BEHIND" != "0" ] || [ "$AHEAD" != "0" ]; then
        echo -e "${CYAN}After syncing, refresh your IDE:${NC}"
        echo -e "  ${GREEN}1.${NC} Close and reopen the repo folder in Cursor"
        echo -e "  ${GREEN}2.${NC} Or run: ${CYAN}cd $repo_dir && git fetch --all --prune${NC}"
        echo -e "  ${GREEN}3.${NC} Reload window: ${CYAN}Cmd/Ctrl+Shift+P → 'Developer: Reload Window'${NC}"
        echo ""
    fi
}

case "${1:-all}" in
    guide)
        check_repo "$GUIDE_DIR" "guide"
        ;;
    agent)
        check_repo "$AGENT_DIR" "embabel-agent"
        ;;
    all)
        check_repo "$GUIDE_DIR" "guide"
        echo ""
        check_repo "$AGENT_DIR" "embabel-agent"
        ;;
    *)
        echo "Usage: $0 [guide|agent|all]"
        exit 1
        ;;
esac

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Check complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
