#!/bin/bash
# Prepare a discussion brief for a specific PR
# Creates a formatted document you can reference during discussions

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ $# -lt 2 ]; then
    echo "Usage: $0 <repo> <pr_number>"
    echo "Example: $0 guide 123"
    exit 1
fi

REPO=$1
PR_NUM=$2
EMBABEL_ORG="embabel"
UPSTREAM_REPO="$EMBABEL_ORG/$REPO"
OUTPUT_DIR="$HOME/github/jmjava/embabel-learning/notes/discussions"

mkdir -p "$OUTPUT_DIR"

OUTPUT_FILE="$OUTPUT_DIR/${REPO}_PR${PR_NUM}_brief.md"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Creating Discussion Brief${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${CYAN}Generating brief for PR #$PR_NUM in $REPO...${NC}\n"

# Create the brief
cat > "$OUTPUT_FILE" << 'HEADER'
# Discussion Brief

HEADER

# Add PR details
echo "## PR Information" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Repository:** $UPSTREAM_REPO" >> "$OUTPUT_FILE"
echo "**PR Number:** #$PR_NUM" >> "$OUTPUT_FILE"

# Get PR data
gh pr view "$PR_NUM" --repo "$UPSTREAM_REPO" --json title,state,url,createdAt,additions,deletions,author >> "$OUTPUT_FILE.json"

TITLE=$(jq -r .title < "$OUTPUT_FILE.json")
STATE=$(jq -r .state < "$OUTPUT_FILE.json")
URL=$(jq -r .url < "$OUTPUT_FILE.json")
CREATED=$(jq -r .createdAt < "$OUTPUT_FILE.json")
ADDITIONS=$(jq -r .additions < "$OUTPUT_FILE.json")
DELETIONS=$(jq -r .deletions < "$OUTPUT_FILE.json")
AUTHOR=$(jq -r .author.login < "$OUTPUT_FILE.json")

rm "$OUTPUT_FILE.json"

echo "**Title:** $TITLE" >> "$OUTPUT_FILE"
echo "**Status:** $STATE" >> "$OUTPUT_FILE"
echo "**Author:** $AUTHOR" >> "$OUTPUT_FILE"
echo "**Created:** $CREATED" >> "$OUTPUT_FILE"
echo "**URL:** $URL" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Summary stats
echo "## Changes Summary" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "- **Lines Added:** $ADDITIONS" >> "$OUTPUT_FILE"
echo "- **Lines Removed:** $DELETIONS" >> "$OUTPUT_FILE"

FILES_COUNT=$(gh pr view "$PR_NUM" --repo "$UPSTREAM_REPO" --json files -q '.files | length')
echo "- **Files Changed:** $FILES_COUNT" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Description
echo "## Description" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
gh pr view "$PR_NUM" --repo "$UPSTREAM_REPO" --json body -q .body >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Files changed with details
echo "## Files Modified" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
gh pr view "$PR_NUM" --repo "$UPSTREAM_REPO" --json files -q '.files[] | "### `\(.path)`\n\n- **Additions:** +\(.additions)\n- **Deletions:** -\(.deletions)\n"' >> "$OUTPUT_FILE"

# Key changes section (for you to fill in)
echo "## Key Technical Changes" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "> **Note:** Fill this in with your own summary of the main technical changes" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "1. " >> "$OUTPUT_FILE"
echo "2. " >> "$OUTPUT_FILE"
echo "3. " >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Rationale section
echo "## Rationale / Why These Changes?" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "> **Note:** Fill this in with the reasoning behind your changes" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "- " >> "$OUTPUT_FILE"
echo "- " >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Testing section
echo "## Testing Done" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "> **Note:** Document how you tested these changes" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "- [ ] " >> "$OUTPUT_FILE"
echo "- [ ] " >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Discussion points
echo "## Key Discussion Points" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "> **Note:** Anticipate questions and prepare answers" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "### Potential Questions:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Q: Why did you approach it this way?**" >> "$OUTPUT_FILE"
echo "A: " >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Q: Did you consider alternative approaches?**" >> "$OUTPUT_FILE"
echo "A: " >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Q: How does this impact existing functionality?**" >> "$OUTPUT_FILE"
echo "A: " >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Review comments
echo "## Review Comments & Responses" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
gh pr view "$PR_NUM" --repo "$UPSTREAM_REPO" --comments >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Code snippets
echo "## Important Code Snippets" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "> **Note:** Add key code snippets here for quick reference" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "// Add important code snippets here" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Action items
echo "## Follow-up Actions" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "- [ ] " >> "$OUTPUT_FILE"
echo "- [ ] " >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Quick reference
echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "## Quick Reference" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**View PR in browser:**" >> "$OUTPUT_FILE"
echo '```bash' >> "$OUTPUT_FILE"
echo "gh pr view $PR_NUM --repo $UPSTREAM_REPO --web" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**View diff:**" >> "$OUTPUT_FILE"
echo '```bash' >> "$OUTPUT_FILE"
echo "gh pr diff $PR_NUM --repo $UPSTREAM_REPO" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Checkout locally:**" >> "$OUTPUT_FILE"
echo '```bash' >> "$OUTPUT_FILE"
echo "cd ~/github/jmjava/$REPO" >> "$OUTPUT_FILE"
echo "gh pr checkout $PR_NUM --repo $UPSTREAM_REPO" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"

echo -e "${GREEN}✓ Discussion brief created!${NC}\n"
echo -e "${CYAN}File: $OUTPUT_FILE${NC}\n"

echo -e "${YELLOW}Next steps:${NC}"
echo "1. Open the brief: cursor $OUTPUT_FILE"
echo "2. Fill in the 'Note' sections with your explanations"
echo "3. Review the code changes"
echo "4. Prepare answers to potential questions"
echo ""
echo -e "${GREEN}You're now ready for discussions about PR #$PR_NUM!${NC}"
