#!/bin/bash
# Run this script to set up all aliases
# Usage: bash ~/github/jmjava/embabel-learning/SETUP-ALIASES-NOW.sh

echo "Setting up embabel aliases..."

# Add aliases to .bash_aliases
cat >> ~/.bash_aliases << 'ALIASES_EOF'

# ========================================
# Embabel Project Monitoring Aliases
# ========================================
alias em='~/github/jmjava/embabel-learning/scripts/monitor-embabel.sh'
alias esync='~/github/jmjava/embabel-learning/scripts/sync-upstream.sh all'
alias ecompare='~/github/jmjava/embabel-learning/scripts/compare-branches.sh all'
alias elist='~/github/jmjava/embabel-learning/scripts/list-embabel-repos.sh'
alias efork='~/github/jmjava/embabel-learning/scripts/fork-all-embabel.sh'
alias eclone='~/github/jmjava/embabel-learning/scripts/clone-embabel-repos.sh'
alias epr='~/github/jmjava/embabel-learning/scripts/view-pr.sh'

# Contribution Tracking Aliases
alias emy='~/github/jmjava/embabel-learning/scripts/my-contributions.sh'
alias eprep='~/github/jmjava/embabel-learning/scripts/prep-for-discussion.sh'
alias ereview='~/github/jmjava/embabel-learning/scripts/review-my-pr.sh'

# Navigation Aliases
alias eguide='cd ~/github/jmjava/guide'
alias eagent='cd ~/github/jmjava/embabel-agent'
alias elearn='cd ~/github/jmjava/embabel-learning'

# Git shortcuts
alias gst='git status'
alias glog='git log --oneline --graph --decorate -20'
alias gfetch='git fetch --all --prune'

ALIASES_EOF

echo ""
echo "✓ Aliases added to ~/.bash_aliases"
echo ""
echo "================================================"
echo "IMPORTANT: Run this command to activate aliases:"
echo "================================================"
echo ""
echo "  source ~/.bash_aliases"
echo ""
echo "Or open a new terminal window."
echo ""
echo "Available aliases:"
echo "  em         - Monitor embabel projects"
echo "  esync      - Sync with upstream"
echo "  ecompare   - Compare with upstream"
echo "  elist      - List all embabel repos and status"
echo "  efork      - Fork all embabel repositories"
echo "  eclone     - Clone forked repositories"
echo "  epr        - View PR details"
echo "  emy        - Find all YOUR contributions ✨"
echo "  eprep      - Prepare discussion brief ✨"
echo "  ereview    - Quick review of your PR ✨"
echo "  eguide     - cd to guide repo"
echo "  eagent     - cd to embabel-agent repo"
echo "  elearn     - cd to embabel-learning"
echo "  gst        - git status"
echo "  glog       - pretty git log"
echo "  gfetch     - fetch from all remotes"
echo ""
echo "================================================"
echo "Test an alias:"
echo "================================================"
echo ""
echo "  source ~/.bash_aliases && elist"
echo ""

