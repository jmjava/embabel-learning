#!/bin/bash
# Generate daily learning checklist based on EMBABEL-WORKFLOW.md
# Usage: ./generate-daily-checklist.sh [YYYY-MM-DD]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEARN_DIR="$(dirname "$SCRIPT_DIR")"
SESSION_NOTES_DIR="$LEARN_DIR/notes/session-notes"
WORKFLOW_GUIDE="$LEARN_DIR/docs/EMBABEL-WORKFLOW.md"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get date
if [ -n "$1" ]; then
    CHECKLIST_DATE="$1"
else
    CHECKLIST_DATE=$(date +%Y-%m-%d)
fi

# Create date-based folder
SESSION_DIR="$SESSION_NOTES_DIR/$CHECKLIST_DATE"
mkdir -p "$SESSION_DIR"

OUTPUT_FILE="$SESSION_DIR/checklist.md"
CURRENT_TIME=$(date +%H:%M)

echo -e "${GREEN}Generating daily learning checklist for $CHECKLIST_DATE...${NC}"

# Extract learning goals from workflow guide
cat > "$OUTPUT_FILE" << 'EOF'
# 📋 Daily Learning Checklist

**Date:** CHECKLIST_DATE_PLACEHOLDER
**Generated:** GENERATED_TIME_PLACEHOLDER

> Based on learning path from [EMBABEL-WORKFLOW.md](../docs/EMBABEL-WORKFLOW.md)

## 🎯 Today's Learning Goals

### Week 1: Get Familiar

- [ ] Run both projects locally
  - [ ] guide project
  - [ ] embabel-agent project
- [ ] Read all README files
  - [ ] guide/README.md
  - [ ] embabel-agent/README.md
  - [ ] embabel-learning/README.md
- [ ] Look at recent PRs to understand common changes
  - [ ] List open PRs: `gh pr list --repo embabel/guide`
  - [ ] List open PRs: `gh pr list --repo embabel/embabel-agent`
  - [ ] Review at least 2 PRs: `ereview agent <PR_NUMBER>`
- [ ] Find the main entry points
  - [ ] Find Application.kt files in guide
  - [ ] Find Application.kt files in embabel-agent
  - [ ] Understand project structure

### Week 2: Understand Structure

- [ ] Use GitLens to identify "hot" files
  - [ ] Open GitLens "File Heatmap"
  - [ ] Identify most frequently changed files
- [ ] Read those files thoroughly
  - [ ] Take notes on key components
- [ ] Create a diagram of how components connect
- [ ] Run tests locally
  - [ ] guide tests
  - [ ] embabel-agent tests
- [ ] Make a tiny change and see what breaks

### Week 3: Start Contributing

- [ ] Find "good first issue" labels
  - [ ] Search GitHub for issues with "good first issue"
- [ ] Analyze how similar issues were fixed
  - [ ] Look at closed PRs for similar issues
- [ ] Make your first PR
- [ ] Learn from code review feedback

### Week 4+: Deep Dive

- [ ] Pick a component to become expert in
- [ ] Read all related PRs for that component
- [ ] Review PRs that touch your component
- [ ] Help others with questions about it

## 📝 Daily Activities

**What I did today:**
-

**What I learned:**
-

**Questions/Blockers:**
-

**Files I explored:**
-

**PRs I reviewed:**
-

## ✅ Progress Summary

**Completed today:**
-

**Still working on:**
-

**Next session focus:**
-

## 💡 Notes & Insights

-

---

**End of day reflection:**
EOF

# Replace placeholders
sed -i "s/CHECKLIST_DATE_PLACEHOLDER/$CHECKLIST_DATE/g" "$OUTPUT_FILE"
sed -i "s/GENERATED_TIME_PLACEHOLDER/$CURRENT_TIME/g" "$OUTPUT_FILE"

echo -e "${GREEN}✓ Daily checklist generated: $OUTPUT_FILE${NC}"
echo -e "${YELLOW}Edit the file to track your progress throughout the day.${NC}"
