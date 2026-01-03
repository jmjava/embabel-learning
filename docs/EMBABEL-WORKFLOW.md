# 🚀 Embabel Project Monitoring & Development Workflow

This guide helps you track changes, analyze PRs, and contribute to the embabel project.

## 📁 Your Fork Structure

```
~/github/jmjava/
├── embabel-learning/         # Your embabel learning workspace
│   ├── scripts/             # All monitoring and management scripts
│   ├── docs/                # Documentation and guides
│   └── notes/               # Your personal learning notes
├── guide/                    # Your fork of embabel/guide
├── embabel-agent/            # Your fork of embabel/embabel-agent
└── [other embabel repos]     # Other forked repositories
```

## 🛠️ Tools You Should Use

### 1. **GitLens (Cursor/VS Code Extension)** ✅ Already in Cursor

**Best for:**

- 📜 Viewing file history and blame annotations
- 🔍 Comparing branches visually
- 👀 Seeing who changed what and when
- 🎯 Understanding code evolution

**How to use:**

- Hover over any line to see commit info
- Click "Open Changes" in GitLens sidebar
- Use Command Palette: "GitLens: Compare References" to compare branches
- Click on file annotations to see detailed commit history

### 2. **GitHub CLI (`gh`)** ✅ Already installed

**Best for:**

- 📋 Listing and reviewing PRs
- 💬 Reading PR comments and reviews
- 🧪 Checking out PRs locally for testing
- 🏷️ Tracking releases

**Key commands:**

```bash
# List open PRs
gh pr list --repo embabel/guide

# View specific PR
gh pr view 123 --repo embabel/guide

# Checkout PR locally to test
gh pr checkout 123 --repo embabel/guide

# View PR diff
gh pr diff 123 --repo embabel/guide

# List releases
gh release list --repo embabel/guide
```

### 3. **Git with Upstream Remote** ✅ Now configured

**Best for:**

- 🔄 Syncing your fork with upstream
- 🆚 Comparing your changes with upstream
- 🔀 Merging upstream changes

### 4. **GitHub Web Interface**

**Best for:**

- 👁️ Watching repositories (click Watch → Custom → select events)
- 🔔 Getting notifications for new PRs/issues
- 💭 Participating in discussions
- 📊 Viewing insights and contributor graphs

## 📅 Recommended Daily/Weekly Workflow

### **Daily Quick Check (2-5 minutes)**

```bash
# Run the monitoring script
~/github/jmjava/embabel-learning/scripts/monitor-embabel.sh
# Or if you've set up aliases: em
```

This shows you:

- New PRs opened
- Recent commits in upstream
- New releases
- Your unpushed changes

### **Weekly Deep Dive (15-30 minutes)**

1. **Review all open PRs:**

   ```bash
   cd ~/github/jmjava/guide
   gh pr list --repo embabel/guide

   cd ~/github/jmjava/embabel-agent
   gh pr list --repo embabel/embabel-agent
   ```

2. **Analyze interesting PRs:**

   ```bash
   ~/github/jmjava/embabel-learning/scripts/view-pr.sh guide 123
   ```

3. **Compare your fork with upstream:**

   ```bash
   ~/github/jmjava/embabel-learning/scripts/compare-branches.sh all
   ```

4. **Sync your fork with upstream:**
   ```bash
   ~/github/jmjava/embabel-learning/scripts/sync-upstream.sh all
   ```

### **When You Want to Test a PR Locally**

```bash
cd ~/github/jmjava/guide
gh pr checkout 123 --repo embabel/guide

# Test it...
mvn clean install
# or whatever tests you need

# Go back to your branch
git checkout main  # or your working branch
```

## 🎯 Learning the Codebase - Best Practices

### 1. **Start with Documentation**

```bash
# Read the main READMEs
cat ~/github/jmjava/guide/README.md
cat ~/github/jmjava/embabel-agent/README.md

# Look for contributing guides
find ~/github/jmjava/guide -name "CONTRIBUTING.md"
find ~/github/jmjava/embabel-agent -name "CONTRIBUTING.md"
```

### 2. **Use GitLens to Understand Hot Spots**

- Open GitLens "File Heatmap" to see which files change most
- These are usually the core files you should understand first
- Right-click any file → "Open File History" to see its evolution

### 3. **Track Specific Files You Care About**

```bash
# Watch how a specific file evolves
cd ~/github/jmjava/guide
git log --follow -p -- src/main/kotlin/com/embabel/guide/chat/ChatService.kt

# See who's the expert on a file
git log --format='%an' -- <file> | sort | uniq -c | sort -rn
```

### 4. **Set Up GitHub Notifications**

1. Go to https://github.com/embabel/guide
2. Click "Watch" → "Custom"
3. Select:
   - ✅ Releases
   - ✅ Pull requests
   - ✅ Issues (if you want)
4. Repeat for embabel-agent

### 5. **Create a Learning Branch**

```bash
cd ~/github/jmjava/guide
git checkout -b learning/experiments

# Now you can:
# - Add comments to understand code
# - Try modifications
# - Break things safely
# - Commit your learning notes
```

## 🔧 Helper Scripts Usage

### `monitor-embabel.sh`

Shows comprehensive status of both repos.

```bash
~/github/jmjava/monitor-embabel.sh
```

### `sync-upstream.sh`

Merges upstream changes into your fork.

```bash
# Sync both repos
~/github/jmjava/sync-upstream.sh all

# Sync only guide
~/github/jmjava/sync-upstream.sh guide

# Sync only embabel-agent
~/github/jmjava/sync-upstream.sh agent
```

### `view-pr.sh`

Detailed analysis of a specific PR.

```bash
# View PR #123 in guide repo
~/github/jmjava/view-pr.sh guide 123

# View PR #456 in embabel-agent repo
~/github/jmjava/view-pr.sh agent 456
```

### `compare-branches.sh`

See differences between your fork and upstream.

```bash
# Compare both repos
~/github/jmjava/compare-branches.sh all

# Compare only guide
~/github/jmjava/compare-branches.sh guide
```

## 🎨 GitLens Features You Should Use

### **In Cursor/VS Code:**

1. **File Annotations** (always visible)

   - See commit info next to each line
   - Toggle with: Command Palette → "GitLens: Toggle File Blame"

2. **Compare with Branch**

   - Command Palette → "GitLens: Compare References"
   - Compare: `HEAD` with `upstream/main`
   - See all differences visually

3. **File History**

   - GitLens sidebar → "File History" view
   - Click any commit to see changes
   - Use timeline slider to travel through time

4. **Search Commits**

   - GitLens sidebar → "Search & Compare"
   - Search by: message, author, file, change

5. **Contributors View**
   - See who's working on what
   - Identify domain experts

## 📊 Advanced: Set Up Workspace

### Create Multi-Repo Workspace

A workspace lets you open multiple repos in one Cursor window, making it easier to navigate between them.

**The workspace file has been created for you at:**

```
~/github/jmjava/embabel-workspace.code-workspace
```

**To use it:**

```bash
# Easy way (from embabel-learning):
eworkspace

# Or manually:
cursor ~/github/jmjava/embabel-workspace.code-workspace

# Or from anywhere:
cd ~/github/jmjava
cursor embabel-workspace.code-workspace
```

**What's included:**

- 📘 **guide** - Your fork of embabel/guide
- 🤖 **embabel-agent** - Your fork of embabel/embabel-agent
- 🎓 **embabel-learning** - This learning workspace

**Workspace features:**

- ✅ GitLens configured for all repos
- ✅ Optimized file exclusions (target/, .git/, etc.)
- ✅ Recommended extensions (GitLens, GitHub PR, Copilot, Java, Kotlin)
- ✅ Easy navigation between repos in sidebar

### Alternative: Open Individual Repos

If you prefer to work on one repo at a time:

```bash
# Open just guide
cd ~/github/jmjava/guide
cursor .

# Open just embabel-agent
cd ~/github/jmjava/embabel-agent
cursor .

# Open embabel-learning
cd ~/github/jmjava/embabel-learning
cursor .
```

### Workspace Benefits

**With workspace:**

- ✅ See all repos in one window
- ✅ Search across all repos
- ✅ Compare code between repos
- ✅ Unified GitLens view

**Without workspace:**

- ✅ Simpler, one repo at a time
- ✅ Less resource usage
- ✅ Faster for focused work

## 🎓 Learning Path Recommendations

### Week 1: Get Familiar

- ✅ Set up monitoring (Done!)
- ⬜ Run both projects locally
- ⬜ Read all README files
- ⬜ Look at recent PRs to understand common changes
- ⬜ Find the main entry points (Application.kt files)

### Week 2: Understand Structure

- ⬜ Use GitLens to identify "hot" files
- ⬜ Read those files thoroughly
- ⬜ Create a diagram of how components connect
- ⬜ Run tests locally
- ⬜ Make a tiny change and see what breaks

### Week 3: Start Contributing

- ⬜ Find "good first issue" labels
- ⬜ Analyze how similar issues were fixed
- ⬜ Make your first PR
- ⬜ Learn from code review feedback

### Week 4+: Deep Dive

- ⬜ Pick a component to become expert in
- ⬜ Read all related PRs for that component
- ⬜ Review PRs that touch your component
- ⬜ Help others with questions about it

## 🚨 Pro Tips

1. **Set up aliases** using the provided script:

   ```bash
   source ~/github/jmjava/embabel-learning/scripts/setup-aliases.sh
   source ~/.bash_aliases
   ```

   This adds: `em`, `esync`, `ecompare`, `elist`, `efork`, `eclone`, and more

2. **Set up git commit template** for embabel conventions:

   ```bash
   cd ~/github/jmjava/guide
   # Look at recent commits to learn the style
   git log --oneline -20
   ```

3. **Watch the contributors** you find in GitLens:

   - Go to their GitHub profiles
   - Click "Follow"
   - See what they work on

4. **Use GitHub CLI for notifications:**

   ```bash
   # See your notification
   gh notify

   # List issues assigned to you
   gh issue list --assignee @me
   ```

5. **Create a learning journal:**
   ```bash
   # In each repo
   cd ~/github/jmjava/guide
   touch LEARNING.md
   # Document your discoveries, questions, insights
   ```

## 📚 Additional Resources

- **GitHub CLI Manual**: `gh help` or https://cli.github.com/manual/
- **GitLens Documentation**: https://gitlens.amod.io/
- **Git Fork Workflow**: https://www.atlassian.com/git/tutorials/comparing-workflows/forking-workflow

## ❓ Quick Reference

| Task               | Command                                   |
| ------------------ | ----------------------------------------- |
| Daily check        | `~/github/jmjava/monitor-embabel.sh`      |
| Sync with upstream | `~/github/jmjava/sync-upstream.sh all`    |
| View PR            | `~/github/jmjava/view-pr.sh guide 123`    |
| Compare branches   | `~/github/jmjava/compare-branches.sh all` |
| List PRs           | `gh pr list --repo embabel/guide`         |
| Checkout PR        | `gh pr checkout 123 --repo embabel/guide` |
| View releases      | `gh release list --repo embabel/guide`    |
| Your notifications | `gh notify`                               |

---

**Happy Learning! 🎉**

Remember: The best way to learn a codebase is to:

1. 📖 Read it
2. 🔧 Break it
3. 🐛 Fix it
4. 🚀 Improve it
