# 📝 Session Notes & Action Items Guide

This guide explains how to use the automated session notes and action item tracking scripts.

## 🚀 Quick Start

### List All Action Items

```bash
eactions
# Or: ./scripts/list-action-items.sh
```

This shows you:
- Repositories needing sync
- Open PRs to review
- Recent releases to check
- Recent commits to review

### Generate Weekly Notes

```bash
eweek
# Or: ./scripts/generate-weekly-notes.sh [YYYY-MM-DD]
```

Creates a weekly notes file in `notes/session-notes/week-YYYY-MM-DD.md` with:
- Pre-filled dates for the week
- Open PRs table
- Repos needing sync
- Recent releases
- Daily activity templates

### Generate Catch-Up Summary

```bash
ecatchup [last-session-date]
# Or: ./scripts/generate-catch-up.sh [last-session-date]
```

Creates a catch-up summary in `notes/session-notes/catch-up-YYYY-MM-DD.md` with:
- Your current contributions
- Repository status
- What's changed since last session
- Action items
- Recommended next steps

## 📋 Action Items Script (`eactions`)

### What It Does

The `list-action-items.sh` script aggregates actionable items from multiple sources:

1. **Repositories Needing Sync**
   - Checks if your fork is behind upstream
   - Shows how many commits behind/ahead
   - Lists unpushed commits
   - Provides sync commands

2. **Open PRs to Review**
   - Lists all open PRs in embabel repos
   - Shows PR number, title, author, creation date
   - Provides quick view commands

3. **Recent Releases**
   - Lists releases from the last 30 days
   - Shows tag name and publication date
   - Provides links to release notes

4. **Recent Commits**
   - Shows new commits in upstream you don't have
   - Helps identify what's changed

### Usage Examples

```bash
# List all action items
eactions

# Output shows numbered items like:
# [1] Sync guide: 28 commits behind upstream
# [2] Review PR #1223: Updated per action retry...
# [3] Review PR #1219: Thinking blocks support...
```

### Integration with Other Scripts

```bash
# Morning routine
eactions          # See what needs attention
em                # Monitor all projects
eweek             # Generate/update weekly notes
```

## 📅 Weekly Notes Script (`eweek`)

### What It Does

Automatically generates a weekly session notes file with:

- **Pre-filled dates** for the week (Monday-Sunday)
- **Open PRs table** with current PRs to review
- **Repos needing sync** with commands
- **Recent releases** to check
- **Daily activity templates** for each day

### Usage

```bash
# Generate for current week
eweek

# Generate for specific week (Monday date)
eweek 2026-01-06
```

### Output

Creates: `notes/session-notes/week-YYYY-MM-DD.md`

The file includes:
- Week dates (Monday-Sunday)
- Goals section
- Daily activity templates
- PRs to review (auto-filled)
- Repos needing sync (auto-filled)
- Recent releases (auto-filled)
- Sections for learnings, accomplishments, etc.

### Workflow

1. **Start of week:**
   ```bash
   eweek  # Generate notes for the week
   ```

2. **During week:**
   - Edit the file daily to fill in activities
   - Update PRs reviewed table
   - Track learnings and blockers

3. **End of week:**
   - Fill in metrics
   - Write week summary
   - Plan next week's focus

## 🎯 Catch-Up Summary Script (`ecatchup`)

### What It Does

Generates a comprehensive catch-up summary when returning after a break:

- **Your contributions** (PRs you've created)
- **Repository status** (what's forked/cloned)
- **What's changed** (releases, new PRs, commits)
- **Action items** (repos to sync, PRs to review)
- **Recommended next steps** (immediate, this week, this month)

### Usage

```bash
# Generate with default "3 weeks ago"
ecatchup

# Specify last session date
ecatchup 2025-12-15
```

### Output

Creates: `notes/session-notes/catch-up-YYYY-MM-DD.md`

### When to Use

- After a break (few days, weeks, or months)
- When you want a comprehensive status update
- Before planning your next learning session
- When you need to catch up on what's changed

## 💡 Best Practices

### Daily Routine

```bash
# Morning (2 minutes)
eactions  # See what needs attention
em        # Quick monitoring check

# If starting new week
eweek     # Generate weekly notes
```

### Weekly Routine

```bash
# Start of week
eweek     # Generate weekly notes

# During week
# Edit notes/session-notes/week-YYYY-MM-DD.md daily

# End of week
# Fill in metrics and summary
```

### After a Break

```bash
# Generate catch-up summary
ecatchup [last-session-date]

# Review action items
eactions

# Sync repositories
esync

# Update contributions
emy --all
```

## 🔧 Customization

### Modify Templates

Edit the templates in `notes/session-notes/`:
- `template-weekly-notes.md` - Weekly notes template
- `template-catch-up.md` - Catch-up summary template

### Add More Repos

Edit the scripts to include more repositories:
- `list-action-items.sh` - Add repo checks
- `generate-weekly-notes.sh` - Add repo PRs
- `generate-catch-up.sh` - Add repo status

## 📊 Example Workflow

### Monday Morning

```bash
# 1. See what needs attention
eactions

# Output:
# [1] Sync guide: 5 commits behind
# [2] Review PR #1234: New feature
# [3] Check release v0.3.2

# 2. Generate weekly notes
eweek

# 3. Start working
# - Sync repos: esync guide
# - Review PR: epr agent 1234
# - Fill in Monday activities in weekly notes
```

### After a 2-Week Break

```bash
# 1. Generate catch-up summary
ecatchup 2025-12-20

# 2. Review action items
eactions

# 3. Sync everything
esync

# 4. Update contributions
emy --all

# 5. Review catch-up summary
cat notes/session-notes/catch-up-2026-01-03.md
```

## 🎯 Tips

1. **Run `eactions` first** - Always start by seeing what needs attention
2. **Use weekly notes consistently** - Fill them in daily for best results
3. **Generate catch-up after breaks** - Don't try to remember everything
4. **Link to PRs and issues** - Include URLs in your notes
5. **Track metrics** - Fill in the metrics section to see progress

## 📚 Related Documentation

- `README.md` - Project overview
- `docs/QUICKSTART.md` - Quick start guide
- `docs/EMBABEL-WORKFLOW.md` - Complete workflow
- `notes/session-notes/README.md` - Session notes directory guide

---

**Happy learning!** 🚀
