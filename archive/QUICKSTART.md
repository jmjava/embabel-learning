# 🚀 Quick Start Guide - Monitoring Embabel Projects

## ✅ Setup Complete!

Your environment is now configured to monitor and contribute to the embabel project.

### What's Been Set Up:

1. ✅ **Upstream remotes configured**
   - `guide` → tracks `embabel/guide`
   - `embabel-agent` → tracks `embabel/embabel-agent`

2. ✅ **Monitoring scripts created**
   - `monitor-embabel.sh` - Daily project monitoring
   - `sync-upstream.sh` - Sync your fork with upstream
   - `view-pr.sh` - Analyze specific PRs
   - `compare-branches.sh` - Compare your changes with upstream
   - `setup-aliases.sh` - Install convenient shell aliases

3. ✅ **Comprehensive documentation**
   - `EMBABEL-WORKFLOW.md` - Full workflow guide

## 🎯 Start Here (5 minutes)

### 1. Set up convenient aliases:
```bash
source ~/github/jmjava/embabel-learning/scripts/setup-aliases.sh
source ~/.bash_aliases
```

Now you can use:
- `em` - Monitor projects (instead of full path)
- `esync` - Sync with upstream
- `ecompare` - Compare branches
- `eguide` - Jump to guide directory
- `eagent` - Jump to embabel-agent directory

### 2. Run your first monitoring check:
```bash
em
```

This shows you:
- 📋 Open PRs (currently 2 in embabel-agent!)
- 🏷️ Recent releases (v0.3.1 just released today!)
- 📝 New commits in upstream
- 🔧 Your uncommitted work

### 3. Explore open PRs:
```bash
# List all PRs in embabel-agent
cd ~/github/jmjava/embabel-agent
gh pr list --repo embabel/embabel-agent

# View details of an interesting PR
epr agent 1204
```

## 📚 Key Commands Reference

| What you want to do | Command |
|---------------------|---------|
| Daily check of what's new | `em` |
| Sync your fork with latest changes | `esync` |
| See your differences from upstream | `ecompare` |
| View details of PR #123 in guide | `epr guide 123` |
| List all open PRs | `gh pr list --repo embabel/embabel-agent` |
| Test a PR locally | `gh pr checkout 123 --repo embabel/guide` |
| View latest releases | `gh release list --repo embabel/embabel-agent` |

## 🎓 Learning Path (Your First Week)

### Day 1: Explore (TODAY!)
```bash
# Monitor what's happening
em

# Check out the most recent release notes
cd ~/github/jmjava/embabel-agent
gh release view --repo embabel/embabel-agent

# Look at a few recent PRs
gh pr list --repo embabel/embabel-agent --limit 5
epr agent 1204  # The HTML conversion PR
```

### Day 2: Deep Dive into a PR
```bash
# Pick an interesting open PR and analyze it
epr agent 1204

# Checkout locally to test it
cd ~/github/jmjava/embabel-agent
gh pr checkout 1204 --repo embabel/embabel-agent

# Test it, read the code, understand it
# Then switch back to your branch
git checkout main
```

### Day 3: Compare Your Fork
```bash
# See how your fork differs from upstream
ecompare

# Sync if needed
esync
```

### Days 4-7: Code Exploration with GitLens

Open Cursor and use GitLens features:

1. **File Blame Annotations**
   - Open any `.kt` or `.java` file
   - See who wrote each line and when
   - Click on annotations to see full commit

2. **File History**
   - Right-click any file → "Open File History"
   - See how it evolved over time
   - Great for understanding design decisions

3. **Compare Branches**
   - Command Palette → "GitLens: Compare References"
   - Compare `main` with `upstream/main`
   - See all differences visually

4. **Search Commits**
   - GitLens sidebar → "Search & Compare"
   - Search for keywords in commit messages
   - Find when features were added

## 🔍 Using GitLens Effectively

### Best GitLens Features for Learning:

1. **Hover on any line** → See commit info + author
2. **GitLens sidebar** → File History view
3. **Command Palette** → "GitLens: Show Commit Graph"
4. **Right-click file** → "Open Changes with Previous Revision"

### Pro Tip: Create a Learning Branch
```bash
cd ~/github/jmjava/guide
git checkout -b learning/my-notes

# Now add comments, experiment, break things!
# Commit your learning notes:
git add .
git commit -m "Learning notes: understanding chat service"
```

## 🎯 Current Interesting Things (Dec 23, 2025)

Based on your monitoring check:

### In embabel-agent:
- 🆕 **v0.3.1 released today!** Check release notes
- 📋 **PR #1204**: HTML conversion with Docling (open)
- 📋 **PR #1177**: Environment-based OpenAI compatibility (open)
- 🔥 **Recent work**: State action methods, Gemini 3 Flash support

### In guide:
- 📝 Recent fixes to tests
- 📖 Documentation improvements (Antigravity instructions)
- 🔧 You have 1 unpushed commit

## 💡 Daily Routine (Recommended)

**Morning (2 minutes):**
```bash
em  # Check what's new
```

**Weekly (30 minutes):**
```bash
# Deep dive
esync                    # Sync with upstream
ecompare                 # See what changed
gh pr list --repo embabel/embabel-agent  # Review PRs
epr agent <PR_NUMBER>   # Analyze interesting ones
```

## 📖 Full Documentation

For complete details, see: `~/github/jmjava/embabel-learning/docs/EMBABEL-WORKFLOW.md`

Topics covered:
- Detailed tool explanations
- Advanced GitLens features
- Contributing guidelines
- GitHub notification setup
- Workspace configuration
- Best practices for learning codebases

## 🆘 Quick Troubleshooting

**Problem:** Script doesn't run
```bash
chmod +x ~/github/jmjava/*.sh
```

**Problem:** Aliases don't work
```bash
source ~/.bash_aliases
```

**Problem:** Can't access upstream
```bash
# Check if you have GitHub SSH set up
ssh -T git@github.com
```

**Problem:** Merge conflicts when syncing
```bash
# The sync script will tell you what to do
# Usually: fix conflicts, then
git merge --continue
```

## 🎉 You're Ready!

You now have a professional-grade monitoring setup. Start with:

```bash
em
```

And explore from there!

**Questions?** Check `EMBABEL-WORKFLOW.md` for detailed guidance.

---

**Happy coding!** 🚀
