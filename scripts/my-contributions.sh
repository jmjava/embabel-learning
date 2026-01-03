#!/bin/bash
# Find and analyze YOUR PRs and contributions across embabel repositories
# Usage: ./my-contributions.sh [repo_name] [--all]

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

YOUR_USER="jmjava"
EMBABEL_ORG="embabel"
BASE_DIR="$HOME/github/jmjava"
OUTPUT_DIR="$BASE_DIR/embabel-learning/notes/my-contributions"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Your Embabel Contributions${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Get GitHub username
GITHUB_USER=$(gh api user -q .login 2>/dev/null || echo "$YOUR_USER")

echo -e "${CYAN}Analyzing contributions by: $GITHUB_USER${NC}\n"

# Function to analyze a repo
analyze_repo() {
    local repo_name=$1
    local repo_path="$BASE_DIR/$repo_name"
    local upstream_repo="$EMBABEL_ORG/$repo_name"

    if [ ! -d "$repo_path" ]; then
        echo -e "${GRAY}⊝ $repo_name not cloned locally${NC}"
        return
    fi

    cd "$repo_path"

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📦 Repository: $repo_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    # 1. Find PRs you've created
    echo -e "${YELLOW}📋 Your Pull Requests:${NC}"
    PRS=$(gh pr list --repo "$upstream_repo" --author "$GITHUB_USER" --state all --json number,title,state,createdAt,url --limit 100 2>/dev/null)

    if [ -z "$PRS" ] || [ "$PRS" = "[]" ]; then
        echo -e "${GRAY}  No PRs found${NC}"
    else
        PR_COUNT=$(echo "$PRS" | jq '. | length')
        echo -e "${GREEN}  Found $PR_COUNT PR(s)${NC}\n"

        # Create detailed report for each PR
        echo "$PRS" | jq -r '.[] | "\(.number)|\(.state)|\(.title)|\(.createdAt)|\(.url)"' | while IFS='|' read -r number state title created_at url; do
            echo -e "${CYAN}PR #$number${NC} - ${state^^}"
            echo -e "  Title: $title"
            echo -e "  Created: $created_at"
            echo -e "  URL: $url"

            # Get PR details and save to file
            PR_FILE="$OUTPUT_DIR/${repo_name}_PR${number}.md"
            echo "# PR #$number: $title" > "$PR_FILE"
            echo "" >> "$PR_FILE"
            echo "**Repository:** $upstream_repo" >> "$PR_FILE"
            echo "**Status:** $state" >> "$PR_FILE"
            echo "**Created:** $created_at" >> "$PR_FILE"
            echo "**URL:** $url" >> "$PR_FILE"
            echo "" >> "$PR_FILE"

            # Get PR description
            echo "## Description" >> "$PR_FILE"
            gh pr view "$number" --repo "$upstream_repo" --json body -q .body >> "$PR_FILE" 2>/dev/null || echo "No description" >> "$PR_FILE"
            echo "" >> "$PR_FILE"

            # Get files changed
            echo "## Files Changed" >> "$PR_FILE"
            gh pr view "$number" --repo "$upstream_repo" --json files -q '.files[] | "- `\(.path)` (+\(.additions)/-\(.deletions))"' >> "$PR_FILE" 2>/dev/null
            echo "" >> "$PR_FILE"

            # Get the diff
            echo "## Code Changes" >> "$PR_FILE"
            echo '```diff' >> "$PR_FILE"
            gh pr diff "$number" --repo "$upstream_repo" >> "$PR_FILE" 2>/dev/null || echo "Could not fetch diff" >> "$PR_FILE"
            echo '```' >> "$PR_FILE"
            echo "" >> "$PR_FILE"

            # Get comments/reviews
            echo "## Reviews & Comments" >> "$PR_FILE"
            gh pr view "$number" --repo "$upstream_repo" --comments >> "$PR_FILE" 2>/dev/null

            echo -e "  ${GREEN}✓ Saved to: $PR_FILE${NC}"

            # Show summary of changes
            FILES_CHANGED=$(gh pr view "$number" --repo "$upstream_repo" --json files -q '.files | length' 2>/dev/null || echo "0")
            ADDITIONS=$(gh pr view "$number" --repo "$upstream_repo" --json additions -q .additions 2>/dev/null || echo "0")
            DELETIONS=$(gh pr view "$number" --repo "$upstream_repo" --json deletions -q .deletions 2>/dev/null || echo "0")

            echo -e "  Changes: ${GREEN}+$ADDITIONS${NC} ${RED}-$DELETIONS${NC} across $FILES_CHANGED file(s)"
            echo ""
        done
    fi

    # 2. Find your commits (that might not be in PRs yet)
    echo -e "${YELLOW}📝 Your Unpushed/Unmerged Commits:${NC}"

    # Get current branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

    # Check for commits by you on current branch
    YOUR_COMMITS=$(git log --author="$GITHUB_USER" --oneline --all --not --remotes=upstream -n 20 2>/dev/null || echo "")

    if [ -z "$YOUR_COMMITS" ]; then
        echo -e "${GRAY}  No unpushed commits found${NC}"
    else
        echo "$YOUR_COMMITS" | while read -r commit; do
            commit_hash=$(echo "$commit" | awk '{print $1}')
            commit_msg=$(echo "$commit" | cut -d' ' -f2-)
            echo -e "  ${CYAN}$commit_hash${NC} $commit_msg"

            # Get detailed diff for this commit
            COMMIT_FILE="$OUTPUT_DIR/${repo_name}_commit_${commit_hash}.md"
            echo "# Commit: $commit_msg" > "$COMMIT_FILE"
            echo "" >> "$COMMIT_FILE"
            echo "**Repository:** $repo_name" >> "$COMMIT_FILE"
            echo "**Commit Hash:** $commit_hash" >> "$COMMIT_FILE"
            echo "**Branch:** $current_branch" >> "$COMMIT_FILE"
            echo "" >> "$COMMIT_FILE"

            echo "## Commit Details" >> "$COMMIT_FILE"
            git show "$commit_hash" --stat >> "$COMMIT_FILE" 2>/dev/null
            echo "" >> "$COMMIT_FILE"

            echo "## Full Diff" >> "$COMMIT_FILE"
            echo '```diff' >> "$COMMIT_FILE"
            git show "$commit_hash" >> "$COMMIT_FILE" 2>/dev/null
            echo '```' >> "$COMMIT_FILE"
        done

        echo -e "  ${GREEN}✓ Commit details saved to $OUTPUT_DIR${NC}"
    fi

    echo ""
}

# Function to create summary document
create_summary() {
    SUMMARY_FILE="$OUTPUT_DIR/SUMMARY.md"

    echo "# My Embabel Contributions Summary" > "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
    echo "Generated: $(date)" >> "$SUMMARY_FILE"
    echo "Author: $GITHUB_USER" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"

    echo "## Overview" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"

    # Count PRs
    TOTAL_PRS=0
    OPEN_PRS=0
    MERGED_PRS=0

    for repo in "$BASE_DIR"/*/; do
        if [ -d "$repo/.git" ]; then
            repo_name=$(basename "$repo")
            cd "$repo"

            # Check if it's an embabel repo
            if gh repo view "$YOUR_USER/$repo_name" --json parent --jq '.parent.owner.login' 2>/dev/null | grep -q "$EMBABEL_ORG"; then
                # Count PRs
                PR_DATA=$(gh pr list --repo "$EMBABEL_ORG/$repo_name" --author "$GITHUB_USER" --state all --json state --limit 100 2>/dev/null || echo "[]")
                if [ "$PR_DATA" != "[]" ]; then
                    REPO_TOTAL=$(echo "$PR_DATA" | jq '. | length')
                    REPO_OPEN=$(echo "$PR_DATA" | jq '[.[] | select(.state == "OPEN")] | length')
                    REPO_MERGED=$(echo "$PR_DATA" | jq '[.[] | select(.state == "MERGED")] | length')

                    TOTAL_PRS=$((TOTAL_PRS + REPO_TOTAL))
                    OPEN_PRS=$((OPEN_PRS + REPO_OPEN))
                    MERGED_PRS=$((MERGED_PRS + REPO_MERGED))

                    echo "### $repo_name" >> "$SUMMARY_FILE"
                    echo "- Total PRs: $REPO_TOTAL" >> "$SUMMARY_FILE"
                    echo "- Open: $REPO_OPEN" >> "$SUMMARY_FILE"
                    echo "- Merged: $REPO_MERGED" >> "$SUMMARY_FILE"
                    echo "" >> "$SUMMARY_FILE"
                fi
            fi
        fi
    done

    # Add totals at the top
    sed -i "/## Overview/a\\
\\
**Total Statistics:**\\
- Total Pull Requests: $TOTAL_PRS\\
- Open PRs: $OPEN_PRS\\
- Merged PRs: $MERGED_PRS\\
" "$SUMMARY_FILE"

    echo "## Detailed Reports" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
    echo "Individual PR and commit reports are saved in:" >> "$SUMMARY_FILE"
    echo "\`$OUTPUT_DIR\`" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"

    # List all saved files
    echo "### Saved Files" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
    for file in "$OUTPUT_DIR"/*.md; do
        if [ -f "$file" ] && [ "$(basename "$file")" != "SUMMARY.md" ]; then
            echo "- $(basename "$file")" >> "$SUMMARY_FILE"
        fi
    done

    echo "" >> "$SUMMARY_FILE"
    echo "## Quick Reference for Discussions" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
    echo "When someone asks about your contributions:" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
    echo "1. Reference the specific PR number and repository" >> "$SUMMARY_FILE"
    echo "2. Open the corresponding markdown file for details" >> "$SUMMARY_FILE"
    echo "3. Review the code changes and rationale" >> "$SUMMARY_FILE"
    echo "4. Note any review comments and your responses" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"

    echo -e "${GREEN}✓ Summary created: $SUMMARY_FILE${NC}\n"
}

# Main execution
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [repo_name] [--all]"
    echo ""
    echo "Options:"
    echo "  repo_name    Analyze specific repository (e.g., 'guide', 'embabel-agent')"
    echo "  --all        Analyze all cloned embabel repositories"
    echo "  (no args)    Interactive mode - choose repositories"
    echo ""
    echo "Output:"
    echo "  Detailed reports saved to: $OUTPUT_DIR"
    echo ""
    exit 0
fi

if [ -n "$1" ] && [ "$1" != "--all" ]; then
    # Analyze specific repo
    analyze_repo "$1"
elif [ "$1" = "--all" ]; then
    # Analyze all repos
    for repo in "$BASE_DIR"/*/; do
        if [ -d "$repo/.git" ]; then
            repo_name=$(basename "$repo")
            cd "$repo"

            # Check if it's an embabel fork
            if gh repo view "$YOUR_USER/$repo_name" --json parent --jq '.parent.owner.login' 2>/dev/null | grep -q "$EMBABEL_ORG"; then
                analyze_repo "$repo_name"
            fi
        fi
    done
else
    # Interactive mode - show repos and let user choose
    echo -e "${YELLOW}Available embabel repositories:${NC}\n"

    REPOS=()
    for repo in "$BASE_DIR"/*/; do
        if [ -d "$repo/.git" ]; then
            repo_name=$(basename "$repo")
            cd "$repo"

            if gh repo view "$YOUR_USER/$repo_name" --json parent --jq '.parent.owner.login' 2>/dev/null | grep -q "$EMBABEL_ORG"; then
                REPOS+=("$repo_name")
            fi
        fi
    done

    if [ ${#REPOS[@]} -eq 0 ]; then
        echo -e "${RED}No embabel repositories found${NC}"
        exit 1
    fi

    PS3=$'\n'"Select repository (or 'a' for all): "
    REPOS+=("All repositories")

    select repo in "${REPOS[@]}"; do
        if [ "$repo" = "All repositories" ]; then
            for r in "${REPOS[@]}"; do
                if [ "$r" != "All repositories" ]; then
                    analyze_repo "$r"
                fi
            done
            break
        elif [ -n "$repo" ]; then
            analyze_repo "$repo"
            break
        fi
    done
fi

# Create summary
create_summary

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Analysis Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${CYAN}Your contribution reports are saved in:${NC}"
echo -e "  $OUTPUT_DIR"
echo ""
echo -e "${CYAN}Quick commands:${NC}"
echo -e "  View summary:      cat $OUTPUT_DIR/SUMMARY.md"
echo -e "  List all reports:  ls -lh $OUTPUT_DIR/"
echo -e "  Open in editor:    cursor $OUTPUT_DIR/"
echo ""
echo -e "${YELLOW}💡 Tip: Review these files before discussions about your PRs!${NC}"
