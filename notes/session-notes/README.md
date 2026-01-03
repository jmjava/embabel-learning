# 📝 Session Notes

This directory contains weekly session notes and catch-up summaries for your Embabel learning journey.

## Structure

```
session-notes/
├── README.md                    # This file
├── checklist-YYYY-MM-DD.md     # Daily learning checklists (track progress)
├── catch-up-YYYY-MM-DD.md       # Catch-up summaries (when returning after a break)
├── week-YYYY-MM-DD.md           # Weekly session notes
├── template-weekly-notes.md     # Template for creating new weekly notes
└── template-catch-up.md         # Template for catch-up summaries
```

## Naming Convention

- **Daily checklists:** `checklist-YYYY-MM-DD.md` (e.g., `checklist-2026-01-03.md`)
- **Catch-up summaries:** `catch-up-YYYY-MM-DD.md` (e.g., `catch-up-2026-01-03.md`)
- **Weekly notes:** `week-YYYY-MM-DD.md` (use the Monday date of that week)

## Usage

### Creating Daily Checklists

**Generate a daily learning checklist based on the workflow guide:**

```bash
# Generate for today
echecklist

# Generate for specific date
echecklist 2026-01-04
```

This creates `checklist-YYYY-MM-DD.md` with:

- ✅ Learning goals from EMBABEL-WORKFLOW.md (Week 1-4+)
- ✅ Daily activity tracking
- ✅ Progress summary
- ✅ Notes & insights section

**Workflow:**

1. Morning: Run `echecklist` to generate today's checklist
2. Throughout day: Check off items as you complete them
3. End of day: Fill in progress summary and notes

### Creating Weekly Notes

1. Copy the template:

   ```bash
   cp template-weekly-notes.md week-$(date +%Y-%m-%d).md
   ```

2. Fill in your activities, learnings, and plans for the week

3. Update at the end of each day or week

### Creating Catch-Up Summaries

When returning after a break (like after a few weeks), create a catch-up summary:

1. Run the catch-up script (if available) or manually create:

   ```bash
   # Review what's changed
   cd ~/github/jmjava/embabel-learning
   em  # Monitor changes
   emy --all  # Your contributions

   # Create catch-up summary
   cp template-catch-up.md catch-up-$(date +%Y-%m-%d).md
   ```

2. Fill in:
   - What changed since last session
   - New PRs to review
   - Action items
   - Learning opportunities

## Current Files

- `checklist-2026-01-03.md` - Today's learning checklist
- `catch-up-2026-01-03.md` - Catch-up after ~3 week break

## Tips

- **Be consistent:** Update notes regularly (daily or weekly)
- **Be specific:** Include PR numbers, file names, commands you ran
- **Track progress:** Note what you learned, what confused you, what's next
- **Link to resources:** Reference PRs, issues, documentation you found helpful

---

**Happy learning!** 🚀
