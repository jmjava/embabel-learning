#!/bin/bash
# Prepare commit information for AI summarization
# Usage: ./prepare-commit-summaries.sh <repo-name> [commit1] [commit2] ...
#        ./prepare-commit-summaries.sh guide  # Gets last 10 commits
#        ./prepare-commit-summaries.sh guide abc123 def456  # Specific commits

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
LEARNING_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
source "$SCRIPT_DIR/config-loader.sh"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <repo-name> [commit1] [commit2] ..."
    echo "       $0 <repo-name>  # Gets last 10 commits from upstream"
    echo "Example: $0 guide"
    echo "         $0 guide abc123 def456"
    exit 1
fi

REPO_NAME=$1
shift

REPO_DIR="$BASE_DIR/$REPO_NAME"
OUTPUT_DIR="$LEARNING_DIR/notes/commit-summaries"
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
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Determine commits to process
if [ $# -eq 0 ]; then
    # Get last 10 commits from upstream/main
    MAIN_BRANCH="upstream/main"
    if ! git show-ref --verify --quiet refs/remotes/upstream/main 2>/dev/null; then
        MAIN_BRANCH="upstream/master"
    fi
    COMMITS=($(git log --oneline -10 "$MAIN_BRANCH" 2>/dev/null | awk '{print $1}'))
    echo -e "${CYAN}Found ${#COMMITS[@]} recent commits from $MAIN_BRANCH${NC}"
else
    COMMITS=("$@")
    echo -e "${CYAN}Processing ${#COMMITS[@]} specified commit(s)${NC}"
fi

if [ ${#COMMITS[@]} -eq 0 ]; then
    echo -e "${YELLOW}No commits to process${NC}"
    exit 0
fi

# Generate timestamp for filename
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/${REPO}_commits_${TIMESTAMP}.md"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📝 Preparing Commit Summaries${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Write header
cat > "$OUTPUT_FILE" <<EOF
# Commit Summaries: $REPO

**Generated:** $(date)
**Repository:** $UPSTREAM_REPO
**Commits:** ${#COMMITS[@]}

---

EOF

# Process each commit
COMMIT_COUNT=0
for COMMIT_HASH in "${COMMITS[@]}"; do
    COMMIT_COUNT=$((COMMIT_COUNT + 1))
    
    # Check if commit exists
    if ! git cat-file -e "$COMMIT_HASH" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Commit $COMMIT_HASH not found, skipping...${NC}"
        continue
    fi
    
    echo -e "${GRAY}Processing commit $COMMIT_COUNT/${#COMMITS[@]}: ${COMMIT_HASH:0:8}...${NC}"
    
    # Get commit details
    COMMIT_MSG=$(git log -1 --pretty=format:"%s" "$COMMIT_HASH")
    COMMIT_AUTHOR=$(git log -1 --pretty=format:"%an <%ae>" "$COMMIT_HASH")
    COMMIT_DATE=$(git log -1 --pretty=format:"%ad" --date=format:"%Y-%m-%d %H:%M:%S" "$COMMIT_HASH")
    FULL_HASH=$(git rev-parse "$COMMIT_HASH")
    
    # Get file changes
    FILE_STAT=$(git show "$COMMIT_HASH" --stat --format="" 2>/dev/null)
    SHORT_STAT=$(git show "$COMMIT_HASH" --shortstat --format="" 2>/dev/null | tail -1)
    
    # Write commit section to file
    cat >> "$OUTPUT_FILE" <<EOF

## Commit $COMMIT_COUNT: ${COMMIT_HASH:0:8}

**Message:** $COMMIT_MSG  
**Author:** $COMMIT_AUTHOR  
**Date:** $COMMIT_DATE  
**Hash:** $FULL_HASH  
**Summary:** $SHORT_STAT

### Files Changed

\`\`\`
$FILE_STAT
\`\`\`

### File List

EOF
    
    # Add file breakdown
    git show "$COMMIT_HASH" --name-status --format="" 2>/dev/null | while read -r status file; do
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
            *)
                echo "- **$status:** \`$file\`" >> "$OUTPUT_FILE"
                ;;
        esac
    done
    
    # Add diff (limited size to avoid huge files)
    cat >> "$OUTPUT_FILE" <<EOF

### Code Changes

\`\`\`diff
EOF
    
    # Get diff (limit to first 200 lines to keep file manageable)
    git show "$COMMIT_HASH" --format="" 2>/dev/null | head -200 >> "$OUTPUT_FILE"
    
    cat >> "$OUTPUT_FILE" <<EOF
\`\`\`

---

EOF
    
    # If diff was truncated, note it
    DIFF_LINES=$(git show "$COMMIT_HASH" --format="" 2>/dev/null | wc -l)
    if [ "$DIFF_LINES" -gt 200 ]; then
        echo -e "${YELLOW}  ⚠️  Diff truncated (showing first 200 lines of $DIFF_LINES)${NC}"
        cat >> "$OUTPUT_FILE" <<EOF

*Note: Diff truncated (showing first 200 lines of $DIFF_LINES total)*

EOF
    fi
done

# Add footer with instructions
cat >> "$OUTPUT_FILE" <<EOF

---

## Instructions for AI Summary

Please provide a summary of the changes in the commits above. For each commit, explain:
1. The intent/purpose of the changes
2. Key parts of the code that were modified (what was adjusted and why)
3. Any important patterns, architectural decisions, or notable technical details

Focus on making the explanation clear and accessible, highlighting the most important changes.

EOF

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Commit summaries prepared!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${CYAN}Output file:${NC} $OUTPUT_FILE"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Open the file in Cursor: ${CYAN}code $OUTPUT_FILE${NC}"
echo -e "  2. Ask Cursor: ${CYAN}\"Can you summarize what changed in these commits?\"${NC}"
echo -e "  3. Or ask about specific commits: ${CYAN}\"What's the intent of commit ${COMMITS[0]:0:8}?\"${NC}"
echo ""

