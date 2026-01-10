#!/bin/bash
# Safety checks to prevent accidental commits/pushes to upstream organization
# Source this file in other scripts: source "$SCRIPT_DIR/safety-checks.sh"
#
# This script loads configuration automatically, but you can also source config-loader.sh first

# Load configuration if not already loaded
if [ -z "$UPSTREAM_ORG" ] || [ -z "$YOUR_GITHUB_USER" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
    source "$SCRIPT_DIR/config-loader.sh" 2>/dev/null || {
        # Fallback defaults if config-loader.sh is not available
        UPSTREAM_ORG="${UPSTREAM_ORG:-embabel}"
        YOUR_GITHUB_USER="${YOUR_GITHUB_USER:-jmjava}"
    }
fi

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Check if current directory is an upstream organization repo (not your fork)
check_upstream_repo() {
    if [ ! -d .git ]; then
        return 1  # Not a git repo
    fi

    # Check all remotes for upstream organization
    local remotes=$(git remote -v 2>/dev/null | grep -i "${UPSTREAM_ORG}/" | grep -v "${YOUR_GITHUB_USER}" || true)

    if [ -n "$remotes" ]; then
        # Check if origin points to upstream org (not your fork)
        local origin_url=$(git remote get-url origin 2>/dev/null || echo "")
        if [[ "$origin_url" == *"${UPSTREAM_ORG}/"* ]] && [[ "$origin_url" != *"${YOUR_GITHUB_USER}"* ]]; then
            return 0  # This is an upstream org repo
        fi

        # Check if we're in a directory that's clearly an upstream org repo
        local current_dir=$(pwd)
        if [[ "$current_dir" == *"/${UPSTREAM_ORG}-"* ]] || [[ "$current_dir" == *"/${BASE_DIR##*/}"* ]]; then
            # Double check - if upstream is org and origin is not your fork, it's upstream
            local upstream_url=$(git remote get-url upstream 2>/dev/null || echo "")
            if [[ "$upstream_url" == *"${UPSTREAM_ORG}/"* ]] && [[ "$origin_url" != *"${YOUR_GITHUB_USER}"* ]]; then
                return 0  # This is an upstream org repo
            fi
        fi
    fi

    return 1  # Not an upstream org repo
}

# Backward compatibility alias
check_embabel_repo() {
    check_upstream_repo "$@"
}

# Block commits in upstream organization repos
block_upstream_commit() {
    if check_upstream_repo; then
        echo -e "${RED}✗ SAFETY BLOCK: Cannot commit directly to ${UPSTREAM_ORG} organization repos${NC}"
        echo -e "${YELLOW}Current directory: $(pwd)${NC}"
        echo ""
        echo -e "${YELLOW}This workspace is configured for LEARNING ONLY:${NC}"
        echo -e "  • You can READ and SYNC FROM ${UPSTREAM_ORG} repos"
        echo -e "  • You CANNOT commit or push TO ${UPSTREAM_ORG} repos"
        echo ""
        echo -e "${GREEN}To contribute to ${UPSTREAM_ORG}:${NC}"
        echo -e "  1. Make sure 'origin' points to YOUR fork (${YOUR_GITHUB_USER}/...)"
        echo -e "  2. Commit to your fork"
        echo -e "  3. Create a PR from your fork to ${UPSTREAM_ORG}"
        echo ""
        echo -e "${YELLOW}To check your remotes:${NC}"
        echo -e "  git remote -v"
        echo ""
        return 1
    fi
    return 0
}

# Backward compatibility alias
block_embabel_commit() {
    block_upstream_commit "$@"
}

# Block pushes to upstream organization
block_upstream_push() {
    local remote=${1:-origin}
    local remote_url=$(git remote get-url "$remote" 2>/dev/null || echo "")

    if [[ "$remote_url" == *"${UPSTREAM_ORG}/"* ]] && [[ "$remote_url" != *"${YOUR_GITHUB_USER}"* ]]; then
        echo -e "${RED}✗ SAFETY BLOCK: Cannot push to ${UPSTREAM_ORG} organization${NC}"
        echo -e "${YELLOW}Remote: $remote${NC}"
        echo -e "${YELLOW}Remote URL: $remote_url${NC}"
        echo ""
        echo -e "${YELLOW}This workspace is configured for LEARNING ONLY:${NC}"
        echo -e "  • You can READ and SYNC FROM ${UPSTREAM_ORG} repos"
        echo -e "  • You CANNOT push TO ${UPSTREAM_ORG} repos"
        echo ""
        echo -e "${GREEN}To contribute to ${UPSTREAM_ORG}:${NC}"
        echo -e "  1. Make sure 'origin' points to YOUR fork (${YOUR_GITHUB_USER}/...)"
        echo -e "  2. Push to your fork"
        echo -e "  3. Create a PR from your fork to ${UPSTREAM_ORG}"
        echo ""
        echo -e "${YELLOW}To fix your remote:${NC}"
        echo -e "  git remote set-url origin git@github.com:${YOUR_GITHUB_USER}/REPO_NAME.git"
        echo ""
        return 1
    fi
    return 0
}

# Backward compatibility alias
block_embabel_push() {
    block_upstream_push "$@"
}

# Warn if in upstream org repo (for read-only operations)
warn_if_upstream_repo() {
    if check_upstream_repo; then
        echo -e "${YELLOW}⚠️  WARNING: You are in a ${UPSTREAM_ORG} organization repository${NC}"
        echo -e "${YELLOW}   This is a READ-ONLY operation. No commits will be made.${NC}"
        echo ""
        return 0
    fi
    return 1
}

# Backward compatibility alias
warn_if_embabel_repo() {
    warn_if_upstream_repo "$@"
}

# Check if remote is safe (points to your fork, not upstream org)
is_safe_remote() {
    local remote=${1:-origin}
    local remote_url=$(git remote get-url "$remote" 2>/dev/null || echo "")

    if [[ "$remote_url" == *"${UPSTREAM_ORG}/"* ]] && [[ "$remote_url" != *"${YOUR_GITHUB_USER}"* ]]; then
        return 1  # Not safe
    fi
    return 0  # Safe
}
