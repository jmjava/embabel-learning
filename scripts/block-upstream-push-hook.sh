#!/bin/bash
# Pre-push hook to block pushes to upstream organization
# This is called by pre-commit framework on pre-push stage
# Git push passes: local_ref local_sha remote_ref remote_sha via stdin

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
    exit 0  # Not in a git repo, skip
fi

SCRIPT_DIR="$REPO_ROOT/scripts"
LEARNING_DIR="$REPO_ROOT"

# Load configuration
if [ -f "$SCRIPT_DIR/config-loader.sh" ]; then
    source "$SCRIPT_DIR/config-loader.sh" >/dev/null 2>&1
fi

# Load safety checks
if [ ! -f "$SCRIPT_DIR/safety-checks.sh" ]; then
    exit 0  # Safety checks not available, skip
fi

source "$SCRIPT_DIR/safety-checks.sh" >/dev/null 2>&1 || exit 0

# For pre-push hooks, git passes stdin with format: local_ref local_sha remote_ref remote_sha
# The remote_ref format is: refs/heads/<branch> when pushing
# We need to determine which remote is being pushed to
# Strategy: Check all remotes and validate each one

# Get the remote being pushed to from stdin or default to origin
# Read stdin if available (from git push)
remote_to_check=""
if [ -t 0 ]; then
    # No stdin (running manually or via pre-commit test), check all remotes
    # Get default push remote
    remote_to_check=$(git config --get push.remote 2>/dev/null || git config --get branch.$(git rev-parse --abbrev-ref HEAD 2>/dev/null).remote 2>/dev/null || echo "origin")
else
    # stdin available (actual git push), read from it
    while read local_ref local_sha remote_ref remote_sha; do
        # Extract remote name from remote_ref
        # Format is: refs/heads/<branch> or refs/remotes/<remote>/<branch>
        if [[ "$remote_ref" == refs/remotes/* ]]; then
            # Extract remote from refs/remotes/origin/branch -> origin
            remote_to_check=$(echo "$remote_ref" | sed 's|refs/remotes/||' | cut -d'/' -f1)
        elif [[ "$remote_ref" == refs/heads/* ]]; then
            # For refs/heads/branch, get remote from git config
            # Git passes this when pushing, but remote name is in the command line
            # We need to check all remotes to see which one matches
            remote_to_check=$(git config --get push.remote 2>/dev/null || git config --get branch.$(git rev-parse --abbrev-ref HEAD 2>/dev/null).remote 2>/dev/null || echo "origin")
        else
            remote_to_check="origin"
        fi

        # Validate this remote
        if [ -n "$remote_to_check" ] && [ "$remote_to_check" != "refs/remotes" ] && [ "$remote_to_check" != "refs/heads" ]; then
            if ! block_upstream_push "$remote_to_check"; then
                exit 1
            fi
        fi
    done

    # If we didn't read anything, check default remote
    if [ -z "$remote_to_check" ]; then
        remote_to_check="origin"
    fi
fi

# Final check on the determined remote
if [ -n "$remote_to_check" ] && [ "$remote_to_check" != "refs/remotes" ] && [ "$remote_to_check" != "refs/heads" ]; then
    if ! block_upstream_push "$remote_to_check"; then
        exit 1
    fi
fi

exit 0
