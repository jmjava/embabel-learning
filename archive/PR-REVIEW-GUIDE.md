# 📋 PR Review Guide - Keeping Your IDE in Sync

This guide explains how to review PRs and keep your IDE (Cursor) in sync with your repositories.

## 🎯 The Problem

When reviewing PRs, your IDE can show outdated information because:
- Your local repository is behind upstream
- Git remotes aren't fetched
- IDE cache is stale
- You're on the wrong branch

## ✅ The Solution: Step-by-Step Workflow

### Quick Check: Are You In Sync?

```bash
# Check sync status for all repos
./scripts/check-sync-status.sh all

# Or check specific repo
./scripts/check-sync-status.sh guide
./scripts/check-sync-status.sh agent
```

This shows you:
- ✅ If you're in sync
- ⚠️ How many commits behind/ahead
- 🔧 Exact commands to fix it

### Complete PR Review Workflow

Use the automated workflow script:

```bash
./scripts/review-pr-workflow.sh agent 1223
```

This script:
1. ✅ Checks if repo is in sync
2. ✅ Syncs automatically if needed
3. ✅ Shows PR information
4. ✅ Lists files changed
5. ✅ Offers to checkout PR locally
6. ✅ Shows diff
7. ✅ Provides next steps

## 📖 Manual Workflow (Step-by-Step)

### Step 1: Check Sync Status

**Before reviewing any PR, always check sync status:**

```bash
cd ~/github/jmjava/embabel-learning
./scripts/check-sync-status.sh all
```

**What to look for:**
- ✅ "In sync" = Good to go
- ⚠️ "X commits behind" = Need to sync
- ⚠️ "X commits ahead" = You have local changes

### Step 2: Sync If Needed

**If you're behind upstream:**

```bash
# Option 1: Use the sync script
esync guide
esync agent

# Option 2: Manual sync
cd ~/github/jmjava/guide
git fetch upstream
git merge upstream/main
```

**If you have uncommitted changes:**
```bash
# Option 1: Stash them
git stash

# Option 2: Commit them
git commit -am "Your message"
```

### Step 3: Refresh Your IDE

**After syncing, refresh Cursor:**

1. **Reload Window:**
   - `Cmd/Ctrl+Shift+P` → "Developer: Reload Window"

2. **Or close and reopen:**
   - Close the repo folder
   - Reopen it in Cursor

3. **Or fetch in IDE:**
   - Open terminal in Cursor
   - Run: `git fetch --all --prune`

### Step 4: Review the PR

**Option A: Review on GitHub (Easiest)**
```bash
# Get PR URL
gh pr view 1223 --repo embabel/embabel-agent --web
```

**Option B: Review Locally (Better for testing)**
```bash
# Use the workflow script
./scripts/review-pr-workflow.sh agent 1223

# Or manually:
cd ~/github/jmjava/embabel-agent
gh pr checkout 1223 --repo embabel/embabel-agent
```

**After checking out:**
- Your IDE will show the PR changes
- You can test the changes
- You can see the diff in GitLens

### Step 5: Return to Your Branch

**After reviewing:**

```bash
# Return to main
git checkout main

# Or return to your working branch
git checkout your-branch-name
```

**Refresh IDE again:**
- Reload window or reopen folder

## 🔄 Daily Sync Routine

**Every morning (2 minutes):**

```bash
# 1. Check what needs attention
eactions

# 2. Check sync status
./scripts/check-sync-status.sh all

# 3. Sync if needed
esync

# 4. Refresh IDE
# (Reload window in Cursor)
```

## 🐛 Common Issues & Fixes

### Issue 1: IDE Shows Wrong Branch

**Symptoms:**
- IDE shows files that don't exist
- GitLens shows wrong commits
- Terminal shows different branch than IDE

**Fix:**
```bash
# 1. Check what branch you're on
git branch

# 2. Checkout the right branch
git checkout main

# 3. Refresh IDE
# Reload window or reopen folder
```

### Issue 2: IDE Shows Outdated Files

**Symptoms:**
- Files show old content
- Changes you made aren't visible
- GitLens shows stale history

**Fix:**
```bash
# 1. Fetch latest
git fetch --all --prune

# 2. Check if you're behind
git status

# 3. Sync if needed
esync guide  # or agent

# 4. Refresh IDE
# Reload window
```

### Issue 3: Can't See PR Changes

**Symptoms:**
- PR checkout doesn't show changes
- IDE still shows main branch

**Fix:**
```bash
# 1. Verify you're on PR branch
git branch
# Should show something like: pr/1223

# 2. If not, checkout again
gh pr checkout 1223 --repo embabel/embabel-agent

# 3. Force refresh IDE
# Close and reopen the repo folder
```

### Issue 4: Merge Conflicts When Syncing

**Symptoms:**
- `esync` fails with conflicts
- Can't merge upstream changes

**Fix:**
```bash
# 1. See what's conflicting
git status

# 2. Resolve conflicts in your editor
# (Cursor will highlight conflicts)

# 3. After resolving:
git add .
git merge --continue

# 4. Or abort if you want to start over:
git merge --abort
```

## 💡 Pro Tips

### 1. Always Sync Before Reviewing

```bash
# Quick check
./scripts/check-sync-status.sh all

# If behind, sync first
esync
```

### 2. Use the Workflow Script

The `review-pr-workflow.sh` script handles everything:
- Checks sync
- Syncs if needed
- Shows PR info
- Offers to checkout
- Provides next steps

```bash
./scripts/review-pr-workflow.sh agent 1223
```

### 3. Refresh IDE After Git Operations

After any git operation (sync, checkout, merge):
- Reload window: `Cmd/Ctrl+Shift+P` → "Developer: Reload Window"
- Or close and reopen the folder

### 4. Use GitLens to See History

In Cursor:
- Hover over code to see commit info
- Use GitLens sidebar to see file history
- Compare branches: Command Palette → "GitLens: Compare References"

### 5. Check Sync Status Regularly

Add to your daily routine:
```bash
# Morning check
eactions                    # See what needs attention
./scripts/check-sync-status.sh all  # Check sync
```

## 📊 Understanding Sync Status

When you run `check-sync-status.sh`, you'll see:

### ✅ In Sync
```
✓ In sync with upstream/main
✓ In sync with origin/main
```
**Action:** None needed, you're good!

### ⚠️ Behind Upstream
```
✗ 5 commits behind upstream/main
```
**Action:** Run `esync guide` or `esync agent`

### ⚠️ Ahead of Upstream
```
⚠️  2 commits ahead of upstream/main
   Your local commits:
      abc123 Your commit message
```
**Action:** Decide if you want to:
- Keep and push: `git push origin main`
- Discard: `git reset --hard upstream/main`

### ⚠️ Diverged
```
✗ 5 commits behind upstream/main
⚠️  2 commits ahead of upstream/main
```
**Action:** You have local changes AND upstream changes. You need to:
1. Sync with upstream (may have conflicts)
2. Resolve conflicts if any
3. Push your changes

## 🎯 Quick Reference

| Task | Command |
|------|---------|
| Check sync | `./scripts/check-sync-status.sh all` |
| Sync repos | `esync` or `esync guide` |
| Review PR | `./scripts/review-pr-workflow.sh agent 123` |
| Checkout PR | `gh pr checkout 123 --repo embabel/embabel-agent` |
| Refresh IDE | `Cmd/Ctrl+Shift+P` → "Developer: Reload Window" |
| See action items | `eactions` |

## 📚 Related Documentation

- `README.md` - Project overview
- `docs/EMBABEL-WORKFLOW.md` - Complete workflow guide
- `docs/QUICKSTART.md` - Quick start guide

---

**Remember:** Always check sync status before reviewing PRs, and refresh your IDE after git operations!

