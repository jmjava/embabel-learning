#!/bin/bash
# Safety checks to prevent accidental commits/pushes to embabel organization
# Source this file in other scripts: source "$SCRIPT_DIR/safety-checks.sh"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Check if current directory is an embabel organization repo
check_embabel_repo() {
    if [ ! -d .git ]; then
        return 1  # Not a git repo
    fi

    # Check all remotes for embabel organization
    local remotes=$(git remote -v 2>/dev/null | grep -i "embabel/" | grep -v "jmjava" || true)

    if [ -n "$remotes" ]; then
        # Check if origin points to embabel (not jmjava fork)
        local origin_url=$(git remote get-url origin 2>/dev/null || echo "")
        if [[ "$origin_url" == *"embabel/"* ]] && [[ "$origin_url" != *"jmjava"* ]]; then
            return 0  # This is an embabel repo
        fi

        # Check if we're in a directory that's clearly an embabel repo
        local current_dir=$(pwd)
        if [[ "$current_dir" == *"/embabel-"* ]] || [[ "$current_dir" == *"/guide"* ]]; then
            # Double check - if upstream is embabel and origin is not jmjava, it's embabel
            local upstream_url=$(git remote get-url upstream 2>/dev/null || echo "")
            if [[ "$upstream_url" == *"embabel/"* ]] && [[ "$origin_url" != *"jmjava"* ]]; then
                return 0  # This is an embabel repo
            fi
        fi
    fi

    return 1  # Not an embabel repo
}

# Block commits in embabel repos
block_embabel_commit() {
    if check_embabel_repo; then
        echo -e "${RED}✗ SAFETY BLOCK: Cannot commit directly to embabel organization repos${NC}"
        echo -e "${YELLOW}Current directory: $(pwd)${NC}"
        echo ""
        echo -e "${YELLOW}This workspace is configured for LEARNING ONLY:${NC}"
        echo -e "  • You can READ and SYNC FROM embabel repos"
        echo -e "  • You CANNOT commit or push TO embabel repos"
        echo ""
        echo -e "${GREEN}To contribute to embabel:${NC}"
        echo -e "  1. Make sure 'origin' points to YOUR fork (jmjava/...)"
        echo -e "  2. Commit to your fork"
        echo -e "  3. Create a PR from your fork to embabel"
        echo ""
        echo -e "${YELLOW}To check your remotes:${NC}"
        echo -e "  git remote -v"
        echo ""
        return 1
    fi
    return 0
}

# Block pushes to embabel organization
block_embabel_push() {
    local remote=${1:-origin}
    local remote_url=$(git remote get-url "$remote" 2>/dev/null || echo "")

    if [[ "$remote_url" == *"embabel/"* ]] && [[ "$remote_url" != *"jmjava"* ]]; then
        echo -e "${RED}✗ SAFETY BLOCK: Cannot push to embabel organization${NC}"
        echo -e "${YELLOW}Remote: $remote${NC}"
        echo -e "${YELLOW}Remote URL: $remote_url${NC}"
        echo ""
        echo -e "${YELLOW}This workspace is configured for LEARNING ONLY:${NC}"
        echo -e "  • You can READ and SYNC FROM embabel repos"
        echo -e "  • You CANNOT push TO embabel repos"
        echo ""
        echo -e "${GREEN}To contribute to embabel:${NC}"
        echo -e "  1. Make sure 'origin' points to YOUR fork (jmjava/...)"
        echo -e "  2. Push to your fork"
        echo -e "  3. Create a PR from your fork to embabel"
        echo ""
        echo -e "${YELLOW}To fix your remote:${NC}"
        echo -e "  git remote set-url origin git@github.com:jmjava/REPO_NAME.git"
        echo ""
        return 1
    fi
    return 0
}

# Warn if in embabel repo (for read-only operations)
warn_if_embabel_repo() {
    if check_embabel_repo; then
        echo -e "${YELLOW}⚠️  WARNING: You are in an embabel organization repository${NC}"
        echo -e "${YELLOW}   This is a READ-ONLY operation. No commits will be made.${NC}"
        echo ""
        return 0
    fi
    return 1
}

# Check if remote is safe (points to jmjava, not embabel)
is_safe_remote() {
    local remote=${1:-origin}
    local remote_url=$(git remote get-url "$remote" 2>/dev/null || echo "")

    if [[ "$remote_url" == *"embabel/"* ]] && [[ "$remote_url" != *"jmjava"* ]]; then
        return 1  # Not safe
    fi
    return 0  # Safe
}
