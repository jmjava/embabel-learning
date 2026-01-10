# 📚 How to Investigate Commits from `em` Using GitKraken

**Date:** 2026-01-03  
**Purpose:** Guide for investigating commits listed in daily monitoring output using GitKraken

## 🔍 What `em` Shows

When you run `em` (monitor-embabel.sh), you'll see:

1. **Open PRs** - Pull requests to review
2. **Recent Releases** - New version releases
3. **New commits in upstream** - Commits you don't have locally
4. **Your unpushed commits** - Local commits not on GitHub

This guide focuses on **investigating commits** from the monitoring output **using GitKraken**.

## 📝 Investigating Upstream Commits

### Step 1: Identify the Commit

From `em` output, you'll see something like:

```
📝 New commits in upstream (last 10):
  abc1234 Fix issue with authentication
  def5678 Add new feature for X
  ghi9012 Update documentation
```

### Step 2: View Commit Details

**Option A: Using GitHub CLI**

```bash
# View commit details
gh api repos/embabel/REPO_NAME/commits/abc1234

# View commit diff
gh api repos/embabel/REPO_NAME/commits/abc1234 --jq '.files[] | "\(.filename): +\(.additions)/-\(.deletions)"'
```

**Option B: Using Git (if you have the repo)**

```bash
cd ~/github/jmjava/REPO_NAME
git fetch upstream
git show abc1234              # Full commit details
git show abc1234 --stat        # File changes summary
git show abc1234 --name-only   # Just file names
```

**Option C: View on GitHub**

```bash
# Open commit in browser
gh browse --commit abc1234 --repo embabel/REPO_NAME
```

### Step 7: Understand the Context in GitKraken

**View commit history:**

1. **Graph view** shows commits visually
2. See commits **before and after** the one you're investigating
3. Hover over commits to see messages
4. Click to see details

**See commit relationships:**

1. **Graph lines** show branch relationships
2. **Merge commits** show as junctions
3. **Upstream commits** appear in different color/style

**Check if you have the commit:**

1. Look for the commit hash in your branch
2. If it's on `upstream/main` but not your branch, you're behind
3. GitKraken shows this visually in the graph

### Step 8: Check Related PRs

**In GitKraken:**

1. GitKraken can show PR information if integrated with GitHub
2. Look for PR numbers in commit messages
3. Click commit to see if PR link is available

**Or use command line:**

```bash
# Find PRs with this commit
gh pr list --repo embabel/REPO_NAME --search "abc1234"

# View PR details
ereview REPO_NAME <PR_NUMBER>
```

## 🔍 Investigating Your Unpushed Commits in GitKraken

### Step 1: Identify Your Unpushed Commits

From `em` output:

```
🔧 Your unpushed commits:
  xyz7890 Your local change
  abc1234 Another change
```

### Step 2: View in GitKraken

**Open the repository in GitKraken:**

1. File → Open Repo → `~/github/jmjava/REPO_NAME`

**Find your unpushed commits:**

1. Look at the graph view
2. Your commits appear **ahead** of `origin/BRANCH`
3. They'll be highlighted or shown in a different color
4. GitKraken shows "X commits ahead" indicator

### Step 3: Review Each Commit

**Click on your commit:**

1. **Right panel** shows commit details
2. **Files Changed** list shows what you modified
3. **Click any file** to see the diff
4. **Side-by-side view** shows your changes

**Compare with upstream:**

1. Select your branch (e.g., `main`, `commit`)
2. Right-click on `upstream/main`
3. Choose **"Compare [your-branch] with upstream/main"**
4. See all your commits and differences

**See just your commits:**

1. In graph view, commits between `origin/BRANCH` and `HEAD` are yours
2. Click each to review
3. GitKraken shows them in sequence

### Step 4: Decide What to Do

**Option A: Keep and push**

1. Review commits in GitKraken
2. If good, click **Push** button (or `Cmd/Ctrl+Shift+P`)
3. Or use command line: `epush` (safer, with checks)

**Option B: Discard**

1. Right-click on `upstream/main` (or your target branch)
2. Choose **"Reset [your-branch] to this commit"**
3. Select **Hard reset** (discards changes)
4. Or use command line: `ereset REPO_NAME`

**Option C: Create a branch for it**

1. Right-click on your commit
2. Choose **"Create branch here"**
3. Name it (e.g., `my-feature`)
4. Then reset your main branch to upstream

## 🛠️ GitKraken Features for Investigation

### Visual Commit History

**Graph View:**

- See all commits visually
- Understand branch relationships
- Identify merge points
- See commit flow

**Commit Details Panel:**

- Click any commit to see details
- Files changed with stats
- Full diff view
- Author and date info

### Compare Views

**Compare Branches:**

1. Select your branch
2. Right-click on `upstream/main`
3. Choose **"Compare [your-branch] with upstream/main"**
4. See all differences at once

**Compare Commits:**

1. Select first commit
2. Right-click on second commit
3. Choose **"Compare commits"**
4. See differences between them

**Compare with Working Directory:**

1. See uncommitted changes
2. Compare with any commit
3. Stage/unstage files visually

### Search and Filter

**Search Commits:**

- `Cmd/Ctrl+F` to search
- Search by hash, message, or author
- Filter by date range
- Filter by file

**Filter Graph:**

- Show/hide branches
- Focus on specific branches
- Hide merge commits (optional)

### File History

**View file history:**

1. Right-click any file in commit
2. Choose **"View file history"**
3. See all commits that touched that file
4. Click any commit to see what changed

**Blame view:**

1. Open file in GitKraken
2. See who changed each line
3. Click line to see commit details
4. Understand code evolution

## 📋 GitKraken Investigation Workflow

### For Upstream Commits

1. **Run `em`** to see new commits
2. **Open repo in GitKraken**: File → Open Repo
3. **Fetch upstream**: Pull button → Select upstream → Pull
4. **Find commit**: Search (`Cmd/Ctrl+F`) by hash or message
5. **Click commit** to see details in right panel
6. **Review files changed**: Click each file to see diff
7. **Compare with your branch**: Right-click → Compare
8. **Check context**: Look at commits before/after in graph
9. **Check if in PR**: Look for PR number in commit message
10. **Decide**: Sync to get it? Review PR? Learn from it?

### For Your Unpushed Commits

1. **Run `em`** to see unpushed commits
2. **Open repo in GitKraken**
3. **Look at graph**: Your commits appear ahead of `origin/BRANCH`
4. **Click each commit** to review changes
5. **Compare with upstream**: Right-click `upstream/main` → Compare
6. **Review file diffs**: Click files to see what changed
7. **Decide**: Push? Discard? Branch?
8. **Take action**:
   - **Push**: Click Push button (or use `epush` for safety)
   - **Discard**: Right-click `upstream/main` → Reset → Hard
   - **Branch**: Right-click commit → Create branch

## 🎯 Common Scenarios in GitKraken

### Scenario 1: Interesting Feature Commit

**In GitKraken:**

1. **Open repo** in GitKraken
2. **Fetch upstream** (Pull → upstream)
3. **Search for commit** (`Cmd/Ctrl+F` → type hash `abc1234`)
4. **Click commit** to see details
5. **Review files changed**: Click each file to see diff
6. **Check commit message** for PR number
7. **If PR mentioned**: Use `ereview REPO_NAME <PR_NUMBER>`
8. **Understand context**: Look at commits before/after in graph

### Scenario 2: Bug Fix Commit

**In GitKraken:**

1. **Find commit** in graph (search by hash or message)
2. **Click commit** to see what was fixed
3. **Review diff** to understand the fix
4. **Check related commits**: Look at nearby commits in graph
5. **View file history**: Right-click file → View file history
6. **See when bug was introduced**: Look at earlier commits

### Scenario 3: Your Local Commit

**In GitKraken:**

1. **Open repo** in GitKraken
2. **See your commits** ahead of `origin/BRANCH` in graph
3. **Click each commit** to review
4. **Compare with upstream**: Right-click `upstream/main` → Compare
5. **Review changes**: See what's different
6. **Decide**:
   - **Keep**: Click Push button (or use `epush`)
   - **Discard**: Right-click `upstream/main` → Reset → Hard (or use `ereset`)
   - **Branch**: Right-click commit → Create branch

## 💡 GitKraken Pro Tips

1. **Use Graph View** - Visual representation makes it easy to understand relationships
2. **Search is powerful** - `Cmd/Ctrl+F` to quickly find commits by hash, message, or author
3. **Compare feature** - Right-click to compare branches/commits easily
4. **File history** - Right-click file → View file history to see evolution
5. **Blame view** - See who changed each line and when
6. **Filter graph** - Hide/show branches to focus on what matters
7. **Check PRs first** - Commits are usually part of PRs with more context (use `ereview`)
8. **Read commit messages** - They often explain the "why" (visible in commit panel)
9. **Side-by-side diffs** - Easy to see what changed in each file
10. **Visual indicators** - GitKraken shows ahead/behind status clearly

## 🔗 Related Commands

- `em` - Daily monitoring (shows commits)
- `esyncstatus` - Check sync status (shows commits ahead/behind)
- `ecompare` - Compare with upstream (shows commit differences)
- `ereview` - Review PRs (commits are in PRs)
- `emy` - Your contributions (your commits)

## 📖 Example Investigation in GitKraken

### Step-by-Step Workflow

**1. Run monitoring:**

```bash
em
```

**Output shows:**

```
📝 New commits in upstream (last 10):
  abc1234 Fix authentication bug
```

**2. Open in GitKraken:**

- File → Open Repo
- Navigate to `~/github/jmjava/embabel-agent`
- Click Open

**3. Fetch latest:**

- Click **Pull** button
- Select **upstream** remote
- Click **Pull** (or `Cmd/Ctrl+Shift+P`)

**4. Find the commit:**

- Press `Cmd/Ctrl+F` (search)
- Type: `abc1234`
- GitKraken highlights the commit

**5. Review the commit:**

- Click the commit node in graph
- Right panel shows:
  - Commit message
  - Files changed (with +/- stats)
  - Author and date
- Click any file to see diff

**6. Compare with your branch:**

- Select your branch (e.g., `main`, `commit`)
- Right-click on the commit
- Choose "Compare with [your-branch]"
- See all differences

**7. Check if in PR:**

- Look for PR number in commit message
- Or use: `gh pr list --repo embabel/embabel-agent --search "abc1234"`
- Review PR: `ereview agent <PR_NUMBER>`

**8. Sync to get it:**

- Use `esync agent` (command line)
- Or in GitKraken: Right-click `upstream/main` → Merge into [your-branch]

---

**Happy investigating!** 🔍

Remember: Commits tell you WHAT changed, PRs tell you WHY it changed.
