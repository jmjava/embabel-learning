#!/bin/bash
# Generate weekly session notes with auto-filled actionable items
# Usage: ./generate-weekly-notes.sh [YYYY-MM-DD] (optional: Monday date of week)

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
LEARNING_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/config-loader.sh"

SESSION_NOTES_DIR="$LEARNING_DIR/notes/session-notes"
TEMPLATE="$SESSION_NOTES_DIR/template-weekly-notes.md"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get week start date (Monday)
if [ -n "$1" ]; then
    WEEK_START="$1"
else
    # Get Monday of current week
    WEEK_START=$(date -d "last Monday" +%Y-%m-%d 2>/dev/null || date -v-Mon +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)
fi

WEEK_END=$(date -d "$WEEK_START + 6 days" +%Y-%m-%d 2>/dev/null || date -j -v+6d -f "%Y-%m-%d" "$WEEK_START" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)
# Create date-based folder (use Monday's date)
SESSION_DIR="$SESSION_NOTES_DIR/$WEEK_START"
mkdir -p "$SESSION_DIR"

OUTPUT_FILE="$SESSION_DIR/weekly-notes.md"
CURRENT_DATE=$(date +%Y-%m-%d)
CURRENT_TIME=$(date +%H:%M)

# Check if file already exists
if [ -f "$OUTPUT_FILE" ]; then
    echo -e "${YELLOW}⚠️  File already exists: $OUTPUT_FILE${NC}"
    echo -e "${YELLOW}Update existing file? (y/n)${NC}"
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

echo -e "${GREEN}Generating weekly notes for week of $WEEK_START...${NC}"

# Extract actionable items
echo -e "${BLUE}Extracting actionable items...${NC}"

# Get open PRs to review
OPEN_PRS=$(mktemp)
echo "## 🔍 Open PRs to Review" > "$OPEN_PRS"
echo "" >> "$OPEN_PRS"

# Check PRs from all configured repos
# Determine which repos to check
if [ -n "$MONITOR_REPOS" ]; then
    REPOS_TO_CHECK="$MONITOR_REPOS"
else
    REPOS_TO_CHECK=$(gh repo list "$UPSTREAM_ORG" --limit 100 --json name --jq '.[].name' 2>/dev/null | head -10 | tr '\n' ' ')
    REPOS_TO_CHECK=$(echo "$REPOS_TO_CHECK" | xargs)
fi

for repo_name in $REPOS_TO_CHECK; do
    if gh pr list --repo "${UPSTREAM_ORG}/$repo_name" --state open --limit 10 --json number,title,author,createdAt 2>/dev/null | jq -r ".[] | \"| \(.number) | $repo_name | \(.title) | OPEN | \(.author.login) - \(.createdAt) |\"" >> "$OPEN_PRS" 2>/dev/null; then
        echo "  ✓ Found PRs in $repo_name"
    fi
done

# Get repos that need syncing
SYNC_ITEMS=$(mktemp)
echo "## 🔄 Repos Needing Sync" > "$SYNC_ITEMS"
echo "" >> "$SYNC_ITEMS"

check_repo_sync() {
    local repo_dir=$1
    local repo_name=$2

    if [ ! -d "$repo_dir" ]; then
        return
    fi

    cd "$repo_dir" 2>/dev/null || return

    # Check if diverged
    if git remote | grep -q "upstream"; then
        git fetch upstream --quiet 2>/dev/null || true
        LOCAL=$(git rev-parse @ 2>/dev/null)
        REMOTE=$(git rev-parse @{u} 2>/dev/null)
        UPSTREAM=$(git rev-parse upstream/main 2>/dev/null || git rev-parse upstream/master 2>/dev/null || echo "")

        if [ -n "$UPSTREAM" ] && [ "$LOCAL" != "$UPSTREAM" ]; then
            BEHIND=$(git rev-list --count HEAD..upstream/main 2>/dev/null || git rev-list --count HEAD..upstream/master 2>/dev/null || echo "?")
            AHEAD=$(git rev-list --count upstream/main..HEAD 2>/dev/null || git rev-list --count upstream/master..HEAD 2>/dev/null || echo "?")

            if [ "$BEHIND" != "0" ] || [ "$AHEAD" != "0" ]; then
                echo "- **$repo_name**: $BEHIND commits behind, $AHEAD commits ahead" >> "$SYNC_ITEMS"
                echo "  Run: \`esync $repo_name\` or \`cd $repo_dir && git pull upstream main\`" >> "$SYNC_ITEMS"
            fi
        fi
    fi
}

# Check all configured repos
for repo_name in $REPOS_TO_CHECK; do
    repo_dir="$BASE_DIR/$repo_name"
    if [ -d "$repo_dir" ] && [ -d "$repo_dir/.git" ]; then
        check_repo_sync "$repo_dir" "$repo_name"
    fi
done

# Get recent releases
RELEASES=$(mktemp)
echo "## 🏷️  Recent Releases to Check" > "$RELEASES"
echo "" >> "$RELEASES"

# Check releases from all configured repos
for repo_name in $REPOS_TO_CHECK; do
    if gh release list --repo "${UPSTREAM_ORG}/$repo_name" --limit 3 --json tagName,publishedAt 2>/dev/null | jq -r ".[] | \"- **\(.tagName)** in $repo_name - Published: \(.publishedAt)\"" >> "$RELEASES" 2>/dev/null; then
        echo "  ✓ Found recent releases in $repo_name"
    fi
done

# Generate the weekly notes file
cat > "$OUTPUT_FILE" << EOF
# 📅 Weekly Session Notes

**Week of:** $WEEK_START (Monday)
**Week Ending:** $WEEK_END (Sunday)
**Last Updated:** $CURRENT_DATE $CURRENT_TIME

## 🎯 Goals for This Week

- [ ] Review open PRs in ${UPSTREAM_ORG} repos
- [ ] Sync repositories with upstream
- [ ] Explore recent changes and releases
- [ ] Continue learning ${UPSTREAM_ORG} architecture

## 📝 Daily Activities

### Monday ($WEEK_START)

**What I did:**

-

**What I learned:**

-

**Questions/Blockers:**

-

**Next steps:**

-

### Tuesday ($(date -d "$WEEK_START + 1 day" +%Y-%m-%d 2>/dev/null || date -j -v+1d -f "%Y-%m-%d" "$WEEK_START" +%Y-%m-%d 2>/dev/null || echo "YYYY-MM-DD"))

**What I did:**

-

**What I learned:**

-

**Questions/Blockers:**

-

**Next steps:**

-

### Wednesday ($(date -d "$WEEK_START + 2 days" +%Y-%m-%d 2>/dev/null || date -j -v+2d -f "%Y-%m-%d" "$WEEK_START" +%Y-%m-%d 2>/dev/null || echo "YYYY-MM-DD"))

**What I did:**

-

**What I learned:**

-

**Questions/Blockers:**

-

**Next steps:**

-

### Thursday ($(date -d "$WEEK_START + 3 days" +%Y-%m-%d 2>/dev/null || date -j -v+3d -f "%Y-%m-%d" "$WEEK_START" +%Y-%m-%d 2>/dev/null || echo "YYYY-MM-DD"))

**What I did:**

-

**What I learned:**

-

**Questions/Blockers:**

-

**Next steps:**

-

### Friday ($(date -d "$WEEK_START + 4 days" +%Y-%m-%d 2>/dev/null || date -j -v+4d -f "%Y-%m-%d" "$WEEK_START" +%Y-%m-%d 2>/dev/null || echo "YYYY-MM-DD"))

**What I did:**

-

**What I learned:**

-

**Questions/Blockers:**

-

**Next steps:**

-

$(cat "$OPEN_PRS")

| PR # | Repo | Title | Status | Notes |
| ---- | ---- | ----- | ------ | ----- |
$(for repo_name in $REPOS_TO_CHECK; do
    gh pr list --repo "${UPSTREAM_ORG}/$repo_name" --state open --limit 10 --json number,title,author,createdAt 2>/dev/null | \
    jq -r ".[] | \"| \(.number) | $repo_name | \(.title) | OPEN | \(.author.login) |\"" || echo ""
done)

$(cat "$RELEASES")

$(cat "$SYNC_ITEMS")

## 💡 Key Learnings

-

## 🐛 Issues Encountered

-

## ✅ Accomplishments

-

## 📚 Resources Found

-

## 🎯 Next Week's Focus

-

## 📊 Metrics

- **PRs reviewed:**
- **PRs submitted:**
- **Commits made:**
- **Repos synced:**
- **Time spent:**

---

**Week Summary:**

EOF

# Cleanup temp files
rm -f "$OPEN_PRS" "$SYNC_ITEMS" "$RELEASES"

echo -e "${GREEN}✓ Weekly notes generated: $OUTPUT_FILE${NC}"
echo -e "${YELLOW}Edit the file to fill in your activities and learnings.${NC}"
