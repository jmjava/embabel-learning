# 📝 Session Notes

This directory contains weekly session notes and catch-up summaries for your Embabel learning journey.

## Structure

```
session-notes/
├── README.md                    # This file
├── template-weekly-notes.md     # Template for creating new weekly notes
├── template-catch-up.md         # Template for catch-up summaries
└── YYYY-MM-DD/                  # Each session has its own folder
    ├── checklist.md             # Daily learning checklist
    ├── catch-up.md              # Catch-up summary
    └── weekly-notes.md          # Weekly session notes (if applicable)
```

## Naming Convention

- **Session folders:** `YYYY-MM-DD/` (e.g., `2026-01-03/`)
- **Daily checklists:** `YYYY-MM-DD/checklist.md`
- **Catch-up summaries:** `YYYY-MM-DD/catch-up.md`
- **Weekly notes:** `YYYY-MM-DD/weekly-notes.md` (use the Monday date of that week)

## Usage

### Creating Daily Checklists

**Generate a daily learning checklist based on the workflow guide:**

```bash
# Generate for today
echecklist

# Generate for specific date
echecklist 2026-01-04
```

This creates `YYYY-MM-DD/checklist.md` with:

- ✅ Learning goals from EMBABEL-WORKFLOW.md (Week 1-4+)
- ✅ Daily activity tracking
- ✅ Progress summary
- ✅ Notes & insights section

**Workflow:**

1. Morning: Run `echecklist` to generate today's checklist
2. Throughout day: Check off items as you complete them
3. End of day: Fill in progress summary and notes

### Creating Weekly Notes

**Generate weekly session notes:**

```bash
# Generate for current week
eweek

# Generate for specific week (Monday date)
eweek 2026-01-06
```

This creates `YYYY-MM-DD/weekly-notes.md` (using Monday's date).

### Creating Catch-Up Summaries

**Generate catch-up summary (syncs repos first):**

```bash
# Generate for today
ecatchup

# Generate with specific last session date
ecatchup 2025-12-20
```

This creates `YYYY-MM-DD/catch-up.md` and:

- Syncs all embabel repositories
- Gets comprehensive embabel summaries
- Organizes activity by date

## Current Sessions

- `2026-01-03/` - Today's session
  - `checklist.md` - Daily learning checklist
  - `catch-up.md` - Catch-up summary

## Tips

- **Be consistent:** Update notes regularly (daily or weekly)
- **Be specific:** Include PR numbers, file names, commands you ran
- **Track progress:** Note what you learned, what confused you, what's next
- **Link to resources:** Reference PRs, issues, documentation you found helpful

---

**Happy learning!** 🚀
