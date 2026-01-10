#!/bin/bash
# Explain changes in a specific commit
# Usage: ./explain-commit.sh <repo-name> <COMMIT_HASH>
# Example: ./explain-commit.sh guide abc1234

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
LEARNING_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/config-loader.sh"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <repo-name> <COMMIT_HASH>"
    echo "Example: $0 guide abc1234"
    echo ""
    echo "You can use a full or partial commit hash"
    exit 1
fi

REPO_NAME=$1
COMMIT_HASH=$2

REPO_DIR="$BASE_DIR/$REPO_NAME"
UPSTREAM_REPO="${UPSTREAM_ORG}/$REPO_NAME"

if [ ! -d "$REPO_DIR" ] || [ ! -d "$REPO_DIR/.git" ]; then
    echo -e "${RED}❌ Repository not found: $REPO_DIR${NC}"
    echo "Make sure the repository is cloned to $BASE_DIR"
    exit 1
fi

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

cd "$REPO_DIR"

# Fetch latest to ensure we have the commit
echo -e "${GRAY}Fetching latest changes...${NC}"
git fetch upstream 2>/dev/null || git fetch origin 2>/dev/null
echo ""

# Check if commit exists
if ! git cat-file -e "$COMMIT_HASH" 2>/dev/null; then
    echo -e "${RED}Error: Commit $COMMIT_HASH not found in local repository${NC}"
    echo -e "${YELLOW}Try fetching first: git fetch upstream${NC}"
    exit 1
fi

# Get commit details
COMMIT_MSG=$(git log -1 --pretty=format:"%s" "$COMMIT_HASH")
COMMIT_AUTHOR=$(git log -1 --pretty=format:"%an <%ae>" "$COMMIT_HASH")
COMMIT_DATE=$(git log -1 --pretty=format:"%ad" --date=format:"%Y-%m-%d %H:%M:%S" "$COMMIT_HASH")
FULL_HASH=$(git rev-parse "$COMMIT_HASH")

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📝 Commit Explanation${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Commit header
echo -e "${CYAN}Commit:${NC} $COMMIT_MSG"
echo -e "${CYAN}Hash:${NC}   $FULL_HASH"
echo -e "${CYAN}Author:${NC} $COMMIT_AUTHOR"
echo -e "${CYAN}Date:${NC}   $COMMIT_DATE"
echo ""

# File changes summary
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📊 Files Changed${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

git show "$COMMIT_HASH" --stat --format=""
echo ""

# Detailed file breakdown
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📁 Files Breakdown${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

git show "$COMMIT_HASH" --name-status --format="" | while read -r status file; do
    case "$status" in
        A)
            echo -e "  ${GREEN}+ Added:${NC}   $file"
            ;;
        M)
            echo -e "  ${YELLOW}~ Modified:${NC} $file"
            ;;
        D)
            echo -e "  ${RED}- Deleted:${NC}  $file"
            ;;
        R*)
            OLD_FILE=$(echo "$status" | cut -f2)
            NEW_FILE="$file"
            echo -e "  ${CYAN}→ Renamed:${NC} $OLD_FILE → $NEW_FILE"
            ;;
        *)
            echo -e "  ${GRAY}? $status:${NC} $file"
            ;;
    esac
done
echo ""

# Key changes summary (more friendly than full diff)
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🔍 Key Changes${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Show a concise diff summary (no pager)
echo -e "${GRAY}Summary of code changes:${NC}\n"
git show "$COMMIT_HASH" --format="" --stat
echo ""
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GRAY}💡 To see full diff, run: git show $COMMIT_HASH${NC}"
echo -e "${GRAY}💡 Or copy the commit info above and ask Cursor to explain the changes${NC}"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}💡 Quick Reference${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Get stats
STATS=$(git show "$COMMIT_HASH" --shortstat --format="" | tail -1)
echo -e "${CYAN}Summary:${NC} $STATS"
echo ""

# Show parent commit if available
PARENT=$(git rev-parse "$COMMIT_HASH^" 2>/dev/null || echo "")
if [ -n "$PARENT" ]; then
    PARENT_MSG=$(git log -1 --pretty=format:"%s" "$PARENT")
    echo -e "${CYAN}Parent commit:${NC} ${PARENT:0:8} - $PARENT_MSG"
    echo ""
fi

# Show branch info
BRANCHES=$(git branch -a --contains "$COMMIT_HASH" 2>/dev/null | head -5 | sed 's/^/  /')
if [ -n "$BRANCHES" ]; then
    echo -e "${CYAN}Contained in branches:${NC}"
    echo "$BRANCHES"
    echo ""
fi

echo -e "${GRAY}View on GitHub:${NC}"
echo -e "  gh browse --commit $COMMIT_HASH --repo $UPSTREAM_REPO"
echo ""
echo -e "${GRAY}Compare with parent:${NC}"
echo -e "  git diff ${COMMIT_HASH}^..${COMMIT_HASH}"
echo ""
echo -e "${GRAY}Show specific file:${NC}"
echo -e "  git show $COMMIT_HASH -- <file_path>"
echo ""
