#!/bin/bash
# Setup git remote for embabel-learning repo
# Usage: ./setup-git-remote.sh [your-github-username]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEARN_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd "$LEARN_DIR"

if [ ! -d .git ]; then
    echo -e "${RED}Error: Not a git repository${NC}"
    echo "Run: git init"
    exit 1
fi

# Get GitHub username
if [ -n "$1" ]; then
    GITHUB_USER="$1"
else
    # Try to get from git config or GitHub CLI
    GITHUB_USER=$(git config user.name 2>/dev/null || gh api user --jq .login 2>/dev/null || echo "")

    if [ -z "$GITHUB_USER" ]; then
        echo -e "${YELLOW}Enter your GitHub username:${NC}"
        read -r GITHUB_USER
    else
        echo -e "${BLUE}Detected GitHub user: $GITHUB_USER${NC}"
        echo -e "${YELLOW}Is this correct? (y/n)${NC}"
        read -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Enter your GitHub username:${NC}"
            read -r GITHUB_USER
        fi
    fi
fi

REPO_NAME="embabel-learning"
REMOTE_URL="git@github.com:$GITHUB_USER/$REPO_NAME.git"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setting up Git Remote${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}Repository:${NC} $REPO_NAME"
echo -e "${BLUE}GitHub User:${NC} $GITHUB_USER"
echo -e "${BLUE}Remote URL:${NC} $REMOTE_URL"
echo ""

# Check if remote already exists
if git remote | grep -q "origin"; then
    CURRENT_URL=$(git remote get-url origin)
    echo -e "${YELLOW}⚠️  Remote 'origin' already exists:${NC}"
    echo -e "   $CURRENT_URL"
    echo ""

    if [[ "$CURRENT_URL" == *"embabel/"* ]] && [[ "$CURRENT_URL" != *"jmjava"* ]]; then
        echo -e "${RED}✗ SAFETY: Current remote points to embabel organization!${NC}"
        echo -e "${YELLOW}This is blocked for safety.${NC}"
        echo ""
        echo -e "${YELLOW}Update remote? (y/n)${NC}"
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git remote set-url origin "$REMOTE_URL"
            echo -e "${GREEN}✓ Remote updated${NC}"
        else
            echo "Cancelled."
            exit 0
        fi
    elif [[ "$CURRENT_URL" == "$REMOTE_URL" ]]; then
        echo -e "${GREEN}✓ Remote is already correctly configured${NC}"
    else
        echo -e "${YELLOW}Update remote to $REMOTE_URL? (y/n)${NC}"
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git remote set-url origin "$REMOTE_URL"
            echo -e "${GREEN}✓ Remote updated${NC}"
        else
            echo "Keeping existing remote."
        fi
    fi
else
    echo -e "${YELLOW}Add remote 'origin'? (y/n)${NC}"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git remote add origin "$REMOTE_URL"
        echo -e "${GREEN}✓ Remote added${NC}"
    else
        echo "Cancelled."
        exit 0
    fi
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Remote Configuration${NC}"
echo -e "${GREEN}========================================${NC}\n"

git remote -v

echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo -e "  1. Create the repository on GitHub:"
echo -e "     ${CYAN}Visit: https://github.com/new${NC}"
echo -e "     ${CYAN}Name: embabel-learning${NC}"
echo -e "     ${CYAN}Don't initialize with README (we already have one)${NC}"
echo ""
echo -e "  2. Add and commit your files:"
echo -e "     ${GREEN}git add .${NC}"
echo -e "     ${GREEN}git commit -m 'Initial commit: Embabel learning workspace'${NC}"
echo ""
echo -e "  3. Push safely with checks:"
echo -e "     ${GREEN}epush${NC}"
echo ""
