#!/bin/bash
# Add convenient aliases to your shell
# Run: source ~/github/jmjava/embabel-learning/scripts/setup-aliases.sh

ALIAS_FILE="$HOME/.bash_aliases"
SCRIPT_DIR="$HOME/github/jmjava/embabel-learning/scripts"

# Create or append to .bash_aliases
cat >> "$ALIAS_FILE" << EOF

# Embabel Project Monitoring Aliases
alias em='$SCRIPT_DIR/monitor-embabel.sh'
alias esync='$SCRIPT_DIR/sync-upstream.sh all'
alias ecompare='$SCRIPT_DIR/compare-branches.sh all'
alias elist='$SCRIPT_DIR/list-embabel-repos.sh'
alias efork='$SCRIPT_DIR/fork-all-embabel.sh'
alias eclone='$SCRIPT_DIR/clone-embabel-repos.sh'
alias epr='$SCRIPT_DIR/view-pr.sh'
alias emy='$SCRIPT_DIR/my-contributions.sh'
alias eprep='$SCRIPT_DIR/prep-for-discussion.sh'
alias ereview='$SCRIPT_DIR/review-my-pr.sh'
alias eactions='$SCRIPT_DIR/list-action-items.sh'
alias eweek='$SCRIPT_DIR/generate-weekly-notes.sh'
alias ecatchup='$SCRIPT_DIR/generate-catch-up.sh'
alias echecklist='$SCRIPT_DIR/generate-daily-checklist.sh'
alias esyncstatus='$SCRIPT_DIR/check-sync-status.sh'
alias ereview='$SCRIPT_DIR/review-pr-workflow.sh'
alias epush='$SCRIPT_DIR/safe-push.sh'
alias eguide='cd ~/github/jmjava/guide'
alias eagent='cd ~/github/jmjava/embabel-agent'
alias elearn='cd ~/github/jmjava/embabel-learning'
alias eworkspace='$SCRIPT_DIR/open-workspace.sh'

# Git shortcuts for embabel work
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
echo "  em         - Monitor embabel projects"
echo "  esync      - Sync with upstream"
echo "  ecompare   - Compare with upstream"
echo "  elist      - List all embabel repos and status"
echo "  efork      - Fork all embabel repositories"
echo "  eclone     - Clone forked repositories"
echo "  epr        - View PR details"
echo "  emy        - Find all YOUR contributions"
echo "  eprep      - Prepare discussion brief for a PR"
echo "  ereview    - Quick review of your PR"
echo "  eactions   - List all actionable items to investigate"
echo "  eweek      - Generate weekly session notes"
echo "  ecatchup   - Generate catch-up summary"
echo "  echecklist - Generate daily learning checklist"
echo "  esyncstatus - Check repository sync status"
echo "  ereview    - Step-by-step PR review workflow"
echo "  epush      - Safe push with GitGuardian & pre-commit checks"
echo "  eguide     - cd to guide repo"
echo "  eagent     - cd to embabel-agent repo"
echo "  elearn     - cd to embabel-learning"
echo "  eworkspace - Open multi-repo workspace in Cursor"
echo "  gst        - git status"
echo "  glog       - pretty git log"
echo "  gfetch     - fetch from all remotes"

