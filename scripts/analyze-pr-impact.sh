#!/bin/bash
# Analyze upstream changes that might affect your PR
# Usage: ./analyze-pr-impact.sh <repo-name> <PR_NUMBER>
# Example: ./analyze-pr-impact.sh guide 123

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
LEARNING_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/config-loader.sh"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <repo-name> <PR_NUMBER>"
    echo "Example: $0 guide 123"
    exit 1
fi

REPO_NAME=$1
PR_NUM=$2

REPO_DIR="$BASE_DIR/$REPO_NAME"
OUTPUT_DIR="$LEARNING_DIR/notes/pr-impact-analysis"
UPSTREAM_REPO="${UPSTREAM_ORG}/$REPO_NAME"

if [ ! -d "$REPO_DIR" ] || [ ! -d "$REPO_DIR/.git" ]; then
    echo -e "${RED}❌ Repository not found: $REPO_DIR${NC}"
    echo "Make sure the repository is cloned to $BASE_DIR"
    exit 1
fi

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

cd "$REPO_DIR"

# Fetch latest
echo -e "${GRAY}Fetching latest changes...${NC}"
git fetch upstream 2>/dev/null || git fetch origin 2>/dev/null
git fetch origin 2>/dev/null || true
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Get PR information
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 Analyzing PR Impact${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

PR_INFO=$(gh pr view "$PR_NUM" --repo "$UPSTREAM_REPO" --json title,state,baseRefName,headRefName,headRepositoryOwner,createdAt,mergedAt,author,additions,deletions,files 2>/dev/null)

if [ -z "$PR_INFO" ] || [ "$PR_INFO" = "null" ]; then
    echo -e "${RED}Error: Could not fetch PR #$PR_NUM${NC}"
    exit 1
fi

PR_TITLE=$(echo "$PR_INFO" | jq -r .title)
PR_STATE=$(echo "$PR_INFO" | jq -r .state)
PR_BASE=$(echo "$PR_INFO" | jq -r .baseRefName)
PR_HEAD=$(echo "$PR_INFO" | jq -r .headRefName)
PR_HEAD_OWNER=$(echo "$PR_INFO" | jq -r .headRepositoryOwner.login)
PR_CREATED=$(echo "$PR_INFO" | jq -r .createdAt)
PR_MERGED=$(echo "$PR_INFO" | jq -r .mergedAt)
PR_AUTHOR=$(echo "$PR_INFO" | jq -r .author.login)
PR_ADDITIONS=$(echo "$PR_INFO" | jq -r .additions)
PR_DELETIONS=$(echo "$PR_INFO" | jq -r .deletions)
PR_MERGED_DATE="${PR_MERGED:-$PR_CREATED}"

echo -e "${CYAN}PR:${NC} #$PR_NUM - $PR_TITLE"
echo -e "${CYAN}Base:${NC} $PR_BASE"
echo -e "${CYAN}Head:${NC} $PR_HEAD_OWNER:$PR_HEAD"
echo ""

# Generate output filename
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/${REPO}_pr${PR_NUM}_impact_${TIMESTAMP}.md"

# Find upstream main branch
MAIN_BRANCH="main"
if ! git show-ref --verify --quiet refs/remotes/upstream/main 2>/dev/null; then
    MAIN_BRANCH="master"
fi
UPSTREAM_BRANCH="upstream/$MAIN_BRANCH"

# Get PR files
PR_FILES=$(echo "$PR_INFO" | jq -r '.files[].path' | sort)

# Write header
cat > "$OUTPUT_FILE" <<EOF
# PR Impact Analysis: #$PR_NUM

**PR Title:** $PR_TITLE
**Repository:** $UPSTREAM_REPO
**State:** $PR_STATE
**Base Branch:** $PR_BASE
**Head Branch:** $PR_HEAD_OWNER:$PR_HEAD
**Created:** $PR_CREATED
**Author:** $PR_AUTHOR
**PR Changes:** +$PR_ADDITIONS / -$PR_DELETIONS lines

**Generated:** $(date)

---

## Your PR Changes

### Files Modified in PR

EOF

# Add PR files
echo "$PR_FILES" | while read -r file; do
    if [ -n "$file" ]; then
        FILE_INFO=$(echo "$PR_INFO" | jq -r ".files[] | select(.path == \"$file\") | \"\(.additions)/\(.deletions)\"")
        ADDITIONS=$(echo "$FILE_INFO" | cut -d'/' -f1)
        DELETIONS=$(echo "$FILE_INFO" | cut -d'/' -f2)
        echo "- \`$file\` (+$ADDITIONS/-$DELETIONS)" >> "$OUTPUT_FILE"
    fi
done

cat >> "$OUTPUT_FILE" <<EOF

---

## Upstream Changes Since PR ${PR_STATE}

EOF

if [ "$PR_STATE" = "MERGED" ]; then
    echo "**Note:** This PR has been merged. Showing changes in upstream since the merge date." >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
else
    echo "**Note:** This PR is ${PR_STATE}. Showing changes in upstream since PR was created." >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# For merged PRs, we want to see what changed since the merge
# For open PRs, we want to see what changed since the PR base
if [ "$PR_STATE" = "MERGED" ]; then
    # Try to find the merge commit
    MERGE_BASE=$(git log --grep="Merge pull request #$PR_NUM" --oneline "$UPSTREAM_BRANCH" 2>/dev/null | head -1 | awk '{print $1}' || echo "")
    if [ -z "$MERGE_BASE" ]; then
        # Fallback: use the merge date to approximate
        MERGE_BASE=$(git log --until="$PR_MERGED_DATE" --oneline "$UPSTREAM_BRANCH" 2>/dev/null | head -1 | awk '{print $1}' || echo "")
    fi
else
    # For open PRs, use the merge base with the base branch
    MERGE_BASE=$(git merge-base "$UPSTREAM_BRANCH" "upstream/$PR_BASE" 2>/dev/null || git rev-parse "$UPSTREAM_BRANCH" 2>/dev/null || echo "")
fi

if [ -n "$MERGE_BASE" ]; then
    # Get commits in upstream/main since the merge base
    COMMITS=$(git log --oneline "$MERGE_BASE..$UPSTREAM_BRANCH" 2>/dev/null | head -20)
    COMMIT_COUNT=$(git rev-list --count "$MERGE_BASE..$UPSTREAM_BRANCH" 2>/dev/null || echo "0")

    cat >> "$OUTPUT_FILE" <<EOF

**Commits in $UPSTREAM_BRANCH since PR base:** $COMMIT_COUNT

\`\`\`
$COMMITS
\`\`\`

EOF

    # Get files changed in upstream
    UPSTREAM_FILES=$(git diff --name-only "$MERGE_BASE..$UPSTREAM_BRANCH" 2>/dev/null | sort)

    if [ -n "$UPSTREAM_FILES" ]; then
        cat >> "$OUTPUT_FILE" <<EOF

### Files Changed in Upstream

EOF

        echo "$UPSTREAM_FILES" | while read -r file; do
            if [ -n "$file" ]; then
                echo "- \`$file\`" >> "$OUTPUT_FILE"
            fi
        done

        cat >> "$OUTPUT_FILE" <<EOF

---

## Overlapping Files Analysis

### Files Modified in Both PR and Upstream

EOF

        # Find overlapping files
        OVERLAPPING_FILES=$(comm -12 <(echo "$PR_FILES") <(echo "$UPSTREAM_FILES") 2>/dev/null || echo "")

        if [ -n "$OVERLAPPING_FILES" ]; then
            if [ "$PR_STATE" = "MERGED" ]; then
                echo "**Note:** These files were changed in your PR and have been modified again in upstream since the merge:" >> "$OUTPUT_FILE"
                echo "" >> "$OUTPUT_FILE"
            else
                echo "**Note:** These files are changed in both your PR and upstream - potential merge conflicts:" >> "$OUTPUT_FILE"
                echo "" >> "$OUTPUT_FILE"
            fi
            echo "$OVERLAPPING_FILES" | while read -r file; do
                if [ -n "$file" ]; then
                    if [ "$PR_STATE" = "MERGED" ]; then
                        echo "- 📝 \`$file\` - Modified again in upstream since merge" >> "$OUTPUT_FILE"
                    else
                        echo "- ⚠️ \`$file\` - **Potential conflict!**" >> "$OUTPUT_FILE"
                    fi
                fi
            done
        else
            if [ "$PR_STATE" = "MERGED" ]; then
                echo "- ✅ No overlapping files - your PR's files haven't been modified since merge" >> "$OUTPUT_FILE"
            else
                echo "- ✅ No overlapping files - no direct conflicts detected" >> "$OUTPUT_FILE"
            fi
        fi

        cat >> "$OUTPUT_FILE" <<EOF

---

## Detailed Upstream Commits

EOF

        # Get detailed commit information
        COMMIT_INDEX=0
        git log --oneline "$MERGE_BASE..$UPSTREAM_BRANCH" 2>/dev/null | head -10 | while read -r commit_line; do
            COMMIT_INDEX=$((COMMIT_INDEX + 1))
            COMMIT_HASH=$(echo "$commit_line" | awk '{print $1}')
            COMMIT_MSG=$(echo "$commit_line" | cut -d' ' -f2-)

            if [ -n "$COMMIT_HASH" ]; then
                COMMIT_AUTHOR=$(git log -1 --pretty=format:"%an" "$COMMIT_HASH" 2>/dev/null || echo "Unknown")
                COMMIT_DATE=$(git log -1 --pretty=format:"%ad" --date=format:"%Y-%m-%d" "$COMMIT_HASH" 2>/dev/null || echo "Unknown")
                COMMIT_STAT=$(git show "$COMMIT_HASH" --stat --format="" 2>/dev/null | tail -1 || echo "")

                cat >> "$OUTPUT_FILE" <<EOF

### Commit $COMMIT_INDEX: ${COMMIT_HASH:0:8}

**Message:** $COMMIT_MSG
**Author:** $COMMIT_AUTHOR
**Date:** $COMMIT_DATE
**Summary:** $COMMIT_STAT

**Files Changed:**
EOF

                git show "$COMMIT_HASH" --name-status --format="" 2>/dev/null | while read -r status file; do
                    if [ -n "$file" ]; then
                        case "$status" in
                            A)
                                echo "- **Added:** \`$file\`" >> "$OUTPUT_FILE"
                                ;;
                            M)
                                echo "- **Modified:** \`$file\`" >> "$OUTPUT_FILE"
                                ;;
                            D)
                                echo "- **Deleted:** \`$file\`" >> "$OUTPUT_FILE"
                                ;;
                            R*)
                                OLD_FILE=$(echo "$status" | cut -f2)
                                NEW_FILE="$file"
                                echo "- **Renamed:** \`$OLD_FILE\` → \`$NEW_FILE\`" >> "$OUTPUT_FILE"
                                ;;
                        esac
                    fi
                done

                cat >> "$OUTPUT_FILE" <<EOF

EOF
            fi
        done
    else
        echo "No files changed in upstream since PR base." >> "$OUTPUT_FILE"
    fi
else
    echo "Could not determine merge base. Showing all recent commits in upstream." >> "$OUTPUT_FILE"
fi

# Add footer with instructions
cat >> "$OUTPUT_FILE" <<EOF

---

## Instructions for AI Analysis

Please analyze the changes above and explain:
EOF

if [ "$PR_STATE" = "MERGED" ]; then
    cat >> "$OUTPUT_FILE" <<EOF
1. **Post-merge changes**: What has changed in upstream since this PR was merged?
2. **Overlapping files**: Have any files from this PR been modified again? What are the implications?
3. **Impact assessment**: Do the upstream changes affect or complement the changes from this PR?
4. **Related changes**: Are the new upstream changes related to this PR's purpose?

Focus on understanding how the codebase has evolved since this PR was merged.
EOF
else
    cat >> "$OUTPUT_FILE" <<EOF
1. **Potential conflicts**: Are there overlapping files that might cause merge conflicts?
2. **Impact assessment**: How might the upstream changes affect this PR?
3. **Recommendations**: Should the PR be updated/rebased? Are there any compatibility concerns?
4. **Related changes**: Are the upstream changes related to the PR's purpose? Do they complement or conflict?

Focus on actionable insights to help determine if the PR needs to be updated before merging.
EOF
fi

EOF

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ PR impact analysis prepared!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${CYAN}Output file:${NC} $OUTPUT_FILE"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Open the file in Cursor: ${CYAN}code $OUTPUT_FILE${NC}"
echo -e "  2. Ask Cursor: ${CYAN}\"What upstream changes might affect this PR?\"${NC}"
echo -e "  3. Or ask: ${CYAN}\"Are there any conflicts or compatibility issues?\"${NC}"
echo ""
