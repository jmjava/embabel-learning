#!/bin/bash
# Add convenient aliases to your shell
# Run: source ~/github/jmjava/embabel-learning/scripts/setup-aliases.sh

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
LEARNING_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/config-loader.sh"

ALIAS_FILE="$HOME/.bash_aliases"

# Determine alias section header (use org name or generic)
ALIAS_SECTION_HEADER="# ${UPSTREAM_ORG} Project Monitoring Aliases"

# Remove existing aliases section if it exists to prevent duplicates
if [ -f "$ALIAS_FILE" ]; then
    # Create a temp file without the aliases section
    TEMP_FILE=$(mktemp)
    
    # Remove lines from the section header to the last alias (gfetch)
    awk -v header="$ALIAS_SECTION_HEADER" '
        $0 == header { skip=1; next }
        skip && /^alias gfetch=/ { skip=0; next }
        skip { next }
        { print }
    ' "$ALIAS_FILE" > "$TEMP_FILE"
    
    # Replace original file
    mv "$TEMP_FILE" "$ALIAS_FILE"
    
    # Remove trailing blank lines
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$ALIAS_FILE" 2>/dev/null || true
fi

# Build repo-specific aliases dynamically
REPO_ALIASES=""
if [ -n "$MONITOR_REPOS" ]; then
    for repo in $MONITOR_REPOS; do
        # Create alias name: e{repo} where special chars are removed/underscored
        alias_name=$(echo "$repo" | sed 's/-/_/g')
        alias_name="e${alias_name}"
        REPO_ALIASES="${REPO_ALIASES}alias ${alias_name}='cd $BASE_DIR/$repo'\n"
    done
else
    # Generate aliases for common repos if MONITOR_REPOS not set
    # Keep backward compatibility with common names
    if [ -d "$BASE_DIR/guide" ]; then
        REPO_ALIASES="${REPO_ALIASES}alias eguide='cd $BASE_DIR/guide'\n"
    fi
    if [ -d "$BASE_DIR/embabel-agent" ] || [ -d "$BASE_DIR/${UPSTREAM_ORG}-agent" ]; then
        AGENT_DIR="$([ -d "$BASE_DIR/embabel-agent" ] && echo "$BASE_DIR/embabel-agent" || echo "$BASE_DIR/${UPSTREAM_ORG}-agent")"
        REPO_ALIASES="${REPO_ALIASES}alias eagent='cd $AGENT_DIR'\n"
    fi
fi

# Create or append to .bash_aliases
cat >> "$ALIAS_FILE" << EOF

${ALIAS_SECTION_HEADER}
alias em='$SCRIPT_DIR/monitor-embabel.sh'
alias esync='$SCRIPT_DIR/sync-upstream.sh all'
alias ecompare='$SCRIPT_DIR/compare-branches.sh all'
alias elist='$SCRIPT_DIR/list-embabel-repos.sh'
alias efork='$SCRIPT_DIR/fork-all-embabel.sh'
alias eclone='$SCRIPT_DIR/clone-embabel-repos.sh'
alias epr='$SCRIPT_DIR/view-pr.sh'
alias ecommit='$SCRIPT_DIR/explain-commit.sh'
alias esummarize='$SCRIPT_DIR/prepare-commit-summaries.sh'
alias eprimpact='$SCRIPT_DIR/analyze-pr-impact.sh'
alias emy='$SCRIPT_DIR/my-contributions.sh'
alias eprep='$SCRIPT_DIR/prep-for-discussion.sh'
alias ereview='$SCRIPT_DIR/review-my-pr.sh'
alias eactions='$SCRIPT_DIR/list-action-items.sh'
alias eweek='$SCRIPT_DIR/generate-weekly-notes.sh'
alias ecatchup='$SCRIPT_DIR/generate-catch-up.sh'
alias echecklist='$SCRIPT_DIR/generate-daily-checklist.sh'
alias esummary='$SCRIPT_DIR/get-embabel-summary.sh'
alias esyncstatus='$SCRIPT_DIR/check-sync-status.sh'
alias eforkurls='$SCRIPT_DIR/list-fork-urls.sh'
alias ereview='$SCRIPT_DIR/review-pr-workflow.sh'
alias epush='$SCRIPT_DIR/safe-push.sh'
alias ereset='$SCRIPT_DIR/reset-to-upstream.sh'
alias elearn='cd $LEARNING_DIR'
alias eworkspace='$SCRIPT_DIR/open-workspace.sh'
${REPO_ALIASES}
# Git shortcuts
alias gst='git status'
alias glog='git log --oneline --graph --decorate -20'
alias gfetch='git fetch --all --prune'

EOF

echo "✓ Aliases added to $ALIAS_FILE"
echo ""
echo "To use them now, run:"
echo "  source ~/.bash_aliases"
echo ""
echo "They'll be automatically loaded in new terminal sessions."
echo ""
echo "Aliases added:"
echo "  em         - Monitor ${UPSTREAM_ORG} projects"
echo "  esync      - Sync with upstream"
echo "  ecompare   - Compare with upstream"
echo "  elist      - List all ${UPSTREAM_ORG} repos and status"
echo "  efork      - Fork all ${UPSTREAM_ORG} repositories"
echo "  eclone     - Clone forked repositories"
echo "  epr        - View PR details"
echo "  ecommit    - Explain commit changes"
echo "  esummarize - Prepare commits for AI summarization"
echo "  eprimpact  - Analyze upstream changes affecting your PR"
echo "  emy        - Find all YOUR contributions"
echo "  eprep      - Prepare discussion brief for a PR"
echo "  ereview    - Quick review of your PR"
echo "  eactions   - List all actionable items to investigate"
echo "  eweek      - Generate weekly session notes"
echo "  ecatchup   - Generate catch-up summary (syncs repos first)"
echo "  echecklist - Generate daily learning checklist"
echo "  esummary   - Get summary of all ${UPSTREAM_ORG} repositories"
echo "  esyncstatus - Check repository sync status"
echo "  eforkurls  - List all your fork URLs"
echo "  epush      - Safe push with GitGuardian & pre-commit checks"
echo "  ereset     - Reset fork to match upstream (discards local changes)"
echo "  elearn     - cd to learning workspace"
echo "  eworkspace - Open multi-repo workspace in Cursor"
if [ -n "$MONITOR_REPOS" ]; then
    echo "  Repo aliases:"
    for repo in $MONITOR_REPOS; do
        alias_name=$(echo "$repo" | sed 's/-/_/g')
        echo "    e${alias_name} - cd to $repo repo"
    done
fi
echo "  gst        - git status"
echo "  glog       - pretty git log"
echo "  gfetch     - fetch from all remotes"
