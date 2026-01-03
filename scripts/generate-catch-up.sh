#!/bin/bash
# Generate catch-up summary with current status and action items
# Usage: ./generate-catch-up.sh [last-session-date]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEARN_DIR="$(dirname "$SCRIPT_DIR")"
SESSION_NOTES_DIR="$LEARN_DIR/notes/session-notes"
TEMPLATE="$SESSION_NOTES_DIR/template-catch-up.md"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

CATCH_UP_DATE=$(date +%Y-%m-%d)
CURRENT_TIME=$(date +%H:%M:%S)
CURRENT_DATETIME=$(date '+%a %b %d %I:%M:%S %p %Z %Y')

if [ -n "$1" ]; then
    LAST_SESSION="$1"
else
    LAST_SESSION="~$(date -d "3 weeks ago" +%Y-%m-%d 2>/dev/null || date -v-3w +%Y-%m-%d 2>/dev/null || echo "unknown")"
fi

OUTPUT_FILE="$SESSION_NOTES_DIR/catch-up-$CATCH_UP_DATE.md"

# Check if file already exists
if [ -f "$OUTPUT_FILE" ]; then
    echo -e "${YELLOW}⚠️  File already exists: $OUTPUT_FILE${NC}"
    echo -e "${YELLOW}Overwrite? (y/n)${NC}"
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo -e "${GREEN}Generating catch-up summary for $CATCH_UP_DATE...${NC}"

# Extract current status
echo -e "${BLUE}Gathering current status...${NC}"

# Get contributions
CONTRIBUTIONS=$(mktemp)
echo "### ✅ Contributions Made" > "$CONTRIBUTIONS"
echo "" >> "$CONTRIBUTIONS"

# Get your PRs
MY_PRS=$(gh pr list --repo embabel/embabel-agent --author jmjava --state all --limit 10 --json number,title,state,createdAt,url 2>/dev/null || echo "[]")
AGENT_PR_COUNT=$(echo "$MY_PRS" | jq '. | length' 2>/dev/null || echo "0")

if [ "$AGENT_PR_COUNT" -gt 0 ]; then
    echo "**embabel-agent:**" >> "$CONTRIBUTIONS"
    echo "$MY_PRS" | jq -r '.[] | "1. **PR #\(.number)** (\(.state)) - \(.title) (MERGED/OPEN \(.createdAt))"' >> "$CONTRIBUTIONS" 2>/dev/null || true
    echo "" >> "$CONTRIBUTIONS"
fi

GUIDE_PRS=$(gh pr list --repo embabel/guide --author jmjava --state all --limit 10 --json number,title,state,createdAt,url 2>/dev/null || echo "[]")
GUIDE_PR_COUNT=$(echo "$GUIDE_PRS" | jq '. | length' 2>/dev/null || echo "0")

if [ "$GUIDE_PR_COUNT" -gt 0 ]; then
    echo "**guide:**" >> "$CONTRIBUTIONS"
    echo "$GUIDE_PRS" | jq -r '.[] | "1. **PR #\(.number)** (\(.state)) - \(.title) (MERGED/OPEN \(.createdAt))"' >> "$CONTRIBUTIONS" 2>/dev/null || true
    echo "" >> "$CONTRIBUTIONS"
fi

# Get repo status
REPO_STATUS=$(mktemp)
echo "### 📁 Repository Status" > "$REPO_STATUS"
echo "" >> "$REPO_STATUS"
echo "**Forked & Cloned:**" >> "$REPO_STATUS"

# Check which repos are forked/cloned
GUIDE_DIR="$HOME/github/jmjava/guide"
AGENT_DIR="$HOME/github/jmjava/embabel-agent"

if [ -d "$GUIDE_DIR" ]; then
    echo "- ✅ guide" >> "$REPO_STATUS"
else
    echo "- ⏳ guide" >> "$REPO_STATUS"
fi

if [ -d "$AGENT_DIR" ]; then
    echo "- ✅ embabel-agent" >> "$REPO_STATUS"
else
    echo "- ⏳ embabel-agent" >> "$REPO_STATUS"
fi

# Get what's changed
CHANGES=$(mktemp)
echo "## 🔄 What's Changed Since You Last Updated" > "$CHANGES"
echo "" >> "$CHANGES"

# Get recent releases
echo "### In embabel-agent" >> "$CHANGES"
echo "" >> "$CHANGES"
echo "**Recent Releases:**" >> "$CHANGES"
gh release list --repo embabel/embabel-agent --limit 3 --json tagName,publishedAt 2>/dev/null | jq -r '.[] | "- **\(.tagName)** - Released \(.publishedAt)"' >> "$CHANGES" 2>/dev/null || echo "- No recent releases" >> "$CHANGES"
echo "" >> "$CHANGES"

# Get open PRs
echo "**New Open PRs to Review:**" >> "$CHANGES"
gh pr list --repo embabel/embabel-agent --state open --limit 5 --json number,title,author 2>/dev/null | jq -r '.[] | "- **PR #\(.number)**: \(.title) (\(.author.login))"' >> "$CHANGES" 2>/dev/null || echo "- No new PRs" >> "$CHANGES"
echo "" >> "$CHANGES"

# Get action items
ACTION_ITEMS=$(mktemp)
echo "## 🚨 Action Items" > "$ACTION_ITEMS"
echo "" >> "$ACTION_ITEMS"

# Check for repos needing sync
if [ -d "$GUIDE_DIR" ]; then
    cd "$GUIDE_DIR"
    if git remote | grep -q "upstream"; then
        git fetch upstream --quiet 2>/dev/null || true
        BEHIND=$(git rev-list --count HEAD..upstream/main 2>/dev/null || echo "0")
        if [ "$BEHIND" != "0" ]; then
            echo "### 1. Sync guide Repository" >> "$ACTION_ITEMS"
            echo "" >> "$ACTION_ITEMS"
            echo "Your guide fork has diverged from upstream:" >> "$ACTION_ITEMS"
            echo "" >> "$ACTION_ITEMS"
            echo "\`\`\`bash" >> "$ACTION_ITEMS"
            echo "cd ~/github/jmjava/embabel-learning" >> "$ACTION_ITEMS"
            echo "esync guide" >> "$ACTION_ITEMS"
            echo "\`\`\`" >> "$ACTION_ITEMS"
            echo "" >> "$ACTION_ITEMS"
        fi
    fi
fi

# Generate the catch-up file
cat > "$OUTPUT_FILE" << EOF
# 🎯 Embabel Learning - Catch-Up Summary

**Catch-Up Date:** $CATCH_UP_DATE
**Last Session:** $LAST_SESSION
**Generated:** $CURRENT_DATETIME

## 📊 Your Current Status

$(cat "$CONTRIBUTIONS")

$(cat "$REPO_STATUS")

$(cat "$CHANGES")

$(cat "$ACTION_ITEMS")

## 🎯 Recommended Next Steps

### Immediate (Today)

1. Review action items above
2. Sync repositories: \`esync\`
3. Update contribution tracking: \`emy --all\`

### This Week

1. Review new PRs: \`epr agent <PR_NUMBER>\`
2. Explore recent changes
3. Daily monitoring: \`em\`

### This Month

1. Find your next contribution
2. Deep dive into a component
3. Document your learning

## 📖 Key Resources

- \`README.md\` - Project overview
- \`docs/QUICKSTART.md\` - Quick start guide
- \`docs/EMBABEL-WORKFLOW.md\` - Complete workflow
- \`notes/my-contributions/\` - Your contribution history

## 💡 Pro Tips

1. Run \`em\` every morning - Takes 30 seconds, keeps you informed
2. Use GitLens in Cursor - See code history and understand changes
3. Take notes - Document what you learn in \`notes/\`
4. Review PRs regularly - Best way to learn how experienced devs work

---

**Questions or need help?** Check the docs or review your notes. You've got this! 🚀
EOF

# Cleanup
rm -f "$CONTRIBUTIONS" "$REPO_STATUS" "$CHANGES" "$ACTION_ITEMS"

echo -e "${GREEN}✓ Catch-up summary generated: $OUTPUT_FILE${NC}"
echo -e "${YELLOW}Review and customize the file as needed.${NC}"
