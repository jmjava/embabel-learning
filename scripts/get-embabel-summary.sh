#!/bin/bash
# Get comprehensive summary of all upstream organization repositories
# Usage: ./get-embabel-summary.sh [repo-name] or all [--no-color]

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
LEARNING_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/config-loader.sh"

# Check for no-color flag
NO_COLOR=false
if [[ "$*" == *"--no-color"* ]]; then
    NO_COLOR=true
    GREEN=""
    BLUE=""
    YELLOW=""
    CYAN=""
    NC=""
else
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'
fi

get_repo_summary() {
    local repo_name=$1
    local repo_dir="$BASE_DIR/$repo_name"
    local upstream_repo="${UPSTREAM_ORG}/$repo_name"
    
    if [ ! -d "$repo_dir" ]; then
        echo "⚠️  $repo_name: Not cloned locally"
        return
    fi
    
    cd "$repo_dir" 2>/dev/null || return
    
    if [ "$NO_COLOR" = false ]; then
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}📦 $repo_name${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    else
        echo "#### $repo_name"
        echo ""
    fi
    
    # Sync status (only show in interactive mode)
    if [ "$NO_COLOR" = false ]; then
        if git remote | grep -q "upstream"; then
            git fetch upstream --quiet 2>/dev/null || true
            MAIN_BRANCH=$(git rev-parse --abbrev-ref upstream/main 2>/dev/null || git rev-parse --abbrev-ref upstream/master 2>/dev/null || echo "main")
            
            LOCAL=$(git rev-parse HEAD 2>/dev/null)
            UPSTREAM=$(git rev-parse "upstream/$MAIN_BRANCH" 2>/dev/null || echo "")
            
            if [ -n "$UPSTREAM" ] && [ "$LOCAL" != "$UPSTREAM" ]; then
                BEHIND=$(git rev-list --count HEAD.."upstream/$MAIN_BRANCH" 2>/dev/null || echo "0")
                AHEAD=$(git rev-list --count "upstream/$MAIN_BRANCH"..HEAD 2>/dev/null || echo "0")
                
                if [ "$BEHIND" -gt 0 ]; then
                    echo -e "${YELLOW}⚠️  Sync Status: $BEHIND commits behind upstream${NC}"
                fi
                if [ "$AHEAD" -gt 0 ]; then
                    echo -e "${GREEN}✓ Local: $AHEAD commits ahead${NC}"
                fi
            else
                echo -e "${GREEN}✓ Sync Status: Up to date${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  No upstream remote configured${NC}"
        fi
    fi
    
    # Open PRs
    echo ""
    if [ "$NO_COLOR" = false ]; then
        echo -e "${CYAN}📋 Open PRs:${NC}"
    else
        echo "- **Open PRs:**"
    fi
    OPEN_PRS=$(gh pr list --repo "$upstream_repo" --state open --limit 10 --json number,title,author,createdAt,url 2>/dev/null || echo "[]")
    PR_COUNT=$(echo "$OPEN_PRS" | jq '. | length' 2>/dev/null || echo "0")
    
    if [ "$PR_COUNT" -gt 0 ]; then
        if [ "$NO_COLOR" = false ]; then
            echo "$OPEN_PRS" | jq -r '.[] | "  • PR #\(.number): \(.title) (by \(.author.login), \(.createdAt))"' 2>/dev/null || echo "  (Unable to parse PRs)"
        else
            echo "$OPEN_PRS" | jq -r '.[] | "  - PR #\(.number): \(.title) (\(.author.login), \(.createdAt))"' 2>/dev/null || echo "  (Unable to parse PRs)"
        fi
    else
        echo "  None"
    fi
    
    # Recent releases
    echo ""
    if [ "$NO_COLOR" = false ]; then
        echo -e "${CYAN}🏷️  Recent Releases:${NC}"
    else
        echo "- **Recent Releases:**"
    fi
    RELEASES=$(gh release list --repo "$upstream_repo" --limit 3 --json tagName,publishedAt,url 2>/dev/null || echo "[]")
    RELEASE_COUNT=$(echo "$RELEASES" | jq '. | length' 2>/dev/null || echo "0")
    
    if [ "$RELEASE_COUNT" -gt 0 ]; then
        if [ "$NO_COLOR" = false ]; then
            echo "$RELEASES" | jq -r '.[] | "  • \(.tagName) - Published: \(.publishedAt)"' 2>/dev/null || echo "  (Unable to parse releases)"
        else
            echo "$RELEASES" | jq -r '.[] | "  - \(.tagName) - Released \(.publishedAt)"' 2>/dev/null || echo "  (Unable to parse releases)"
        fi
    else
        echo "  None"
    fi
    
    # Recent commits (last 5)
    echo ""
    if [ "$NO_COLOR" = false ]; then
        echo -e "${CYAN}📝 Recent Commits (upstream):${NC}"
    else
        echo "- **Recent Commits:**"
    fi
    if git remote | grep -q "upstream"; then
        MAIN_BRANCH=$(git rev-parse --abbrev-ref upstream/main 2>/dev/null || git rev-parse --abbrev-ref upstream/master 2>/dev/null || echo "main")
        git log --oneline "upstream/$MAIN_BRANCH" -5 2>/dev/null | sed 's/^/  - /' || echo "  (Unable to fetch commits)"
    else
        echo "  (No upstream configured)"
    fi
    
    echo ""
}

# Main execution
if [ "$1" = "all" ] || [ -z "$1" ]; then
    # Focus on main repos for catch-up summaries
    MAIN_REPOS=("guide" "embabel-agent")
    
    for repo_name in "${MAIN_REPOS[@]}"; do
        get_repo_summary "$repo_name"
    done
    
    # Optionally include other repos if not in no-color mode (interactive use)
    if [ "$NO_COLOR" = false ]; then
        # Get other embabel repos
        REPOS=$(gh repo list embabel --limit 50 --json name 2>/dev/null | jq -r '.[].name' 2>/dev/null || echo "")
        
        if [ -n "$REPOS" ]; then
            echo "$REPOS" | while read -r repo_name; do
                # Skip main repos already shown
                if [[ "$repo_name" != "guide" ]] && [[ "$repo_name" != "embabel-agent" ]]; then
                    get_repo_summary "$repo_name"
                fi
            done
        fi
    fi
else
    get_repo_summary "$1"
fi

