#!/bin/bash
# Generate catch-up summary with current status and action items
# Usage: ./generate-catch-up.sh [last-session-date]

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
LEARNING_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/config-loader.sh"

SESSION_NOTES_DIR="$LEARNING_DIR/notes/session-notes"
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

# Create date-based folder
SESSION_DIR="$SESSION_NOTES_DIR/$CATCH_UP_DATE"
mkdir -p "$SESSION_DIR"

OUTPUT_FILE="$SESSION_DIR/catch-up.md"

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

# Step 1: Sync repos first
echo -e "${BLUE}Step 1: Syncing ${UPSTREAM_ORG} repositories...${NC}"
echo -e "${YELLOW}This may take a moment...${NC}"
cd "$LEARNING_DIR"
"$SCRIPT_DIR/sync-upstream.sh" all > /dev/null 2>&1 || echo -e "${YELLOW}Note: Some repos may need manual sync${NC}"
echo -e "${GREEN}✓ Sync complete${NC}\n"

# Extract current status
echo -e "${BLUE}Step 2: Gathering current status...${NC}"

# Get contributions
CONTRIBUTIONS=$(mktemp)
echo "### ✅ Contributions Made" > "$CONTRIBUTIONS"
echo "" >> "$CONTRIBUTIONS"

# Get your PRs from all configured repos
GITHUB_USER=$(gh api user -q .login 2>/dev/null || echo "$YOUR_GITHUB_USER")

# Determine which repos to check
if [ -n "$MONITOR_REPOS" ]; then
    REPOS_TO_CHECK="$MONITOR_REPOS"
else
    REPOS_TO_CHECK=$(gh repo list "$UPSTREAM_ORG" --limit 100 --json name --jq '.[].name' 2>/dev/null | head -10 | tr '\n' ' ')
    REPOS_TO_CHECK=$(echo "$REPOS_TO_CHECK" | xargs)
fi

for repo_name in $REPOS_TO_CHECK; do
    REPO_PRS=$(gh pr list --repo "${UPSTREAM_ORG}/$repo_name" --author "$GITHUB_USER" --state all --limit 10 --json number,title,state,createdAt,url 2>/dev/null || echo "[]")
    REPO_PR_COUNT=$(echo "$REPO_PRS" | jq '. | length' 2>/dev/null || echo "0")
    
    if [ "$REPO_PR_COUNT" -gt 0 ]; then
        echo "**$repo_name:**" >> "$CONTRIBUTIONS"
        echo "$REPO_PRS" | jq -r '.[] | "1. **PR #\(.number)** (\(.state)) - \(.title) (MERGED/OPEN \(.createdAt))"' >> "$CONTRIBUTIONS" 2>/dev/null || true
        echo "" >> "$CONTRIBUTIONS"
    fi
done

# Get repo status
REPO_STATUS=$(mktemp)
echo "### 📁 Repository Status" > "$REPO_STATUS"
echo "" >> "$REPO_STATUS"
echo "**Forked & Cloned:**" >> "$REPO_STATUS"

# Check which repos are forked/cloned
for repo_name in $REPOS_TO_CHECK; do
    repo_dir="$BASE_DIR/$repo_name"
    if [ -d "$repo_dir" ] && [ -d "$repo_dir/.git" ]; then
        echo "- ✅ $repo_name" >> "$REPO_STATUS"
    else
        echo "- ⏳ $repo_name" >> "$REPO_STATUS"
    fi
done

# Get upstream org summaries organized by date
EMBABEL_SUMMARY=$(mktemp)
echo "## 📅 ${UPSTREAM_ORG} Ecosystem Activity (by Date)" > "$EMBABEL_SUMMARY"
echo "" >> "$EMBABEL_SUMMARY"

# Today's date
TODAY=$(date +%Y-%m-%d)
echo "### $TODAY (Today)" >> "$EMBABEL_SUMMARY"
echo "" >> "$EMBABEL_SUMMARY"

# Get sync status
echo "**Sync Status:**" >> "$EMBABEL_SUMMARY"

for repo_name in $REPOS_TO_CHECK; do
    repo_dir="$BASE_DIR/$repo_name"
    if [ -d "$repo_dir" ] && [ -d "$repo_dir/.git" ]; then
        cd "$repo_dir" 2>/dev/null || continue
        if git remote | grep -q "upstream"; then
            git fetch upstream --quiet 2>/dev/null || true
            BEHIND=$(git rev-list --count HEAD..upstream/main 2>/dev/null || echo "0")
            if [ "$BEHIND" = "0" ]; then
                echo "- ✅ $repo_name: Synced" >> "$EMBABEL_SUMMARY"
            else
                echo "- ⚠️ $repo_name: $BEHIND commits behind" >> "$EMBABEL_SUMMARY"
            fi
        else
            echo "- ⚠️ $repo_name: No upstream configured" >> "$EMBABEL_SUMMARY"
        fi
    fi
done

echo "" >> "$EMBABEL_SUMMARY"
echo "**Activity Summary:**" >> "$EMBABEL_SUMMARY"
echo "" >> "$EMBABEL_SUMMARY"

# Get summary for each repo using the new script
echo -e "${BLUE}Getting ${UPSTREAM_ORG} repository summaries...${NC}"
"$SCRIPT_DIR/get-embabel-summary.sh" all --no-color >> "$EMBABEL_SUMMARY" 2>/dev/null || {
    # Fallback if script fails - iterate over configured repos
    for repo_name in $REPOS_TO_CHECK; do
        echo "#### $repo_name" >> "$EMBABEL_SUMMARY"
        echo "" >> "$EMBABEL_SUMMARY"
        echo "- **Open PRs:**" >> "$EMBABEL_SUMMARY"
        REPO_OPEN=$(gh pr list --repo "${UPSTREAM_ORG}/$repo_name" --state open --limit 10 --json number,title,author,createdAt 2>/dev/null || echo "[]")
        REPO_COUNT=$(echo "$REPO_OPEN" | jq '. | length' 2>/dev/null || echo "0")
        if [ "$REPO_COUNT" -gt 0 ]; then
            echo "$REPO_OPEN" | jq -r '.[] | "  - PR #\(.number): \(.title) (\(.author.login), \(.createdAt))"' >> "$EMBABEL_SUMMARY" 2>/dev/null || echo "  (Unable to parse)" >> "$EMBABEL_SUMMARY"
        else
            echo "  None" >> "$EMBABEL_SUMMARY"
        fi
        echo "" >> "$EMBABEL_SUMMARY"
        echo "- **Recent Releases:**" >> "$EMBABEL_SUMMARY"
        REPO_RELEASES=$(gh release list --repo "${UPSTREAM_ORG}/$repo_name" --limit 3 --json tagName,publishedAt 2>/dev/null || echo "[]")
        REPO_REL_COUNT=$(echo "$REPO_RELEASES" | jq '. | length' 2>/dev/null || echo "0")
        if [ "$REPO_REL_COUNT" -gt 0 ]; then
            echo "$REPO_RELEASES" | jq -r '.[] | "  - \(.tagName) - Released \(.publishedAt)"' >> "$EMBABEL_SUMMARY" 2>/dev/null || echo "  (Unable to parse)" >> "$EMBABEL_SUMMARY"
        else
            echo "  None" >> "$EMBABEL_SUMMARY"
        fi
        echo "" >> "$EMBABEL_SUMMARY"
    done
}

# Get action items
ACTION_ITEMS=$(mktemp)
echo "## 🚨 Action Items" > "$ACTION_ITEMS"
echo "" >> "$ACTION_ITEMS"

# Check for repos needing sync
ACTION_COUNT=0
for repo_name in $REPOS_TO_CHECK; do
    repo_dir="$BASE_DIR/$repo_name"
    if [ -d "$repo_dir" ] && [ -d "$repo_dir/.git" ]; then
        cd "$repo_dir" 2>/dev/null || continue
        if git remote | grep -q "upstream"; then
            git fetch upstream --quiet 2>/dev/null || true
            BEHIND=$(git rev-list --count HEAD..upstream/main 2>/dev/null || echo "0")
            if [ "$BEHIND" != "0" ]; then
                ACTION_COUNT=$((ACTION_COUNT + 1))
                echo "### $ACTION_COUNT. Sync $repo_name Repository" >> "$ACTION_ITEMS"
                echo "" >> "$ACTION_ITEMS"
                echo "Your $repo_name fork has diverged from upstream:" >> "$ACTION_ITEMS"
                echo "" >> "$ACTION_ITEMS"
                echo "\`\`\`bash" >> "$ACTION_ITEMS"
                echo "cd $LEARNING_DIR" >> "$ACTION_ITEMS"
                echo "esync $repo_name" >> "$ACTION_ITEMS"
                echo "\`\`\`" >> "$ACTION_ITEMS"
                echo "" >> "$ACTION_ITEMS"
            fi
        fi
    fi
done

# Generate the catch-up file
cat > "$OUTPUT_FILE" << EOF
# 🎯 Embabel Learning - Catch-Up Summary

**Catch-Up Date:** $CATCH_UP_DATE
**Last Session:** $LAST_SESSION
**Generated:** $CURRENT_DATETIME

## 📊 Your Current Status

$(cat "$CONTRIBUTIONS")

$(cat "$REPO_STATUS")

$(cat "$EMBABEL_SUMMARY")

$(cat "$ACTION_ITEMS")

## 🎯 Recommended Next Steps

### Immediate (Today)

1. Review action items above
2. Sync repositories: \`esync\`
3. Update contribution tracking: \`emy --all\`

### This Week

1. Review new PRs: \`epr <repo-name> <PR_NUMBER>\`
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
rm -f "$CONTRIBUTIONS" "$REPO_STATUS" "$EMBABEL_SUMMARY" "$ACTION_ITEMS"

echo -e "${GREEN}✓ Catch-up summary generated: $OUTPUT_FILE${NC}"
echo -e "${YELLOW}Review and customize the file as needed.${NC}"
