# 🎓 Embabel Learning Workspace

Your central hub for learning, monitoring, and contributing to the [Embabel ecosystem](https://github.com/orgs/embabel/repositories).

> **📖 Need detailed information?** See [docs/EMBABEL-WORKFLOW.md](docs/EMBABEL-WORKFLOW.md) for comprehensive guides on PR reviews, contribution tracking, session notes, and more.

## 🎯 Common Tasks (Quick Reference)

| What You Want to Do            | Command             |
| ------------------------------ | ------------------- |
| **Check what needs attention** | `eactions`          |
| **Check if repos are in sync** | `esyncstatus all`   |
| **Sync repositories**          | `esync`             |
| **Reset fork to upstream**     | `ereset agent`      |
| **Safe push (with checks)**    | `epush`             |
| **Review a PR**                | `ereview agent 123` |
| **Daily monitoring**           | `em`                |
| **List all repos**             | `elist`             |
| **Your contributions**         | `emy`               |
| **Generate weekly notes**      | `eweek`             |
| **Generate daily checklist**   | `echecklist`        |
| **Catch up after break**       | `ecatchup`          |
| **Embabel repo summaries**     | `esummary`          |

## 🚀 Quick Start (5 minutes)

```bash
# 1. Set up convenient aliases
cd ~/github/jmjava/embabel-learning
source scripts/setup-aliases.sh
source ~/.bash_aliases

# 2. List all embabel repos and their status
elist

# 3. Fork all embabel repositories (23 repos to fork)
efork

# 4. Clone the repos you want to work with
eclone

# 5. Set up upstream tracking
scripts/setup-upstreams.sh

# 6. Set up pre-commit hooks and GitGuardian (recommended)
./scripts/setup-pre-commit.sh

# 7. Start monitoring daily
em
```

## 📁 Project Structure

```
embabel-learning/
├── scripts/                    # All automation scripts
│   ├── list-embabel-repos.sh  # List all repos with fork/clone status
│   ├── fork-all-embabel.sh    # Fork all embabel repositories
│   ├── clone-embabel-repos.sh # Clone your forked repos
│   ├── setup-upstreams.sh     # Configure upstream remotes
│   ├── monitor-embabel.sh     # Daily monitoring (PRs, releases, commits)
│   ├── sync-upstream.sh       # Sync your fork with upstream
│   ├── compare-branches.sh    # Compare your changes with upstream
│   ├── view-pr.sh            # Analyze specific PRs
│   ├── setup-aliases.sh       # Install convenient shell aliases
│   └── setup-pre-commit.sh   # Setup pre-commit & GitGuardian
├── docs/                       # Documentation
│   └── EMBABEL-WORKFLOW.md    # Complete detailed workflow guide
├── notes/                      # Your personal learning notes
│   ├── session-notes/          # Weekly notes and catch-up summaries
│   ├── my-contributions/       # Your PR and contribution tracking
│   └── discussions/            # PR discussion briefs
├── .pre-commit-config.yaml    # Pre-commit hooks configuration
├── .yamllint.yml              # YAML linting rules
├── .secrets.baseline          # Secrets detection baseline
└── .gitignore                 # Git ignore rules
```

## 🛠️ Available Scripts

### Repository Management

| Script                   | Alias    | Description                                      |
| ------------------------ | -------- | ------------------------------------------------ |
| `list-embabel-repos.sh`  | `elist`  | Show all 25 embabel repos with fork/clone status |
| `fork-all-embabel.sh`    | `efork`  | Fork all embabel repos you haven't forked yet    |
| `clone-embabel-repos.sh` | `eclone` | Clone your forked repositories                   |
| `setup-upstreams.sh`     | -        | Configure upstream remotes for tracking          |

### Daily Monitoring & Sync

| Script                | Alias      | Description                                   |
| --------------------- | ---------- | --------------------------------------------- |
| `monitor-embabel.sh`  | `em`       | Check PRs, releases, commits across all repos |
| `sync-upstream.sh`    | `esync`    | Sync your fork with upstream changes          |
| `compare-branches.sh` | `ecompare` | Compare your fork with upstream               |
| `view-pr.sh`          | `epr`      | Deep dive into a specific PR                  |

### Your Contribution Tracking

| Script                   | Alias     | Description                                |
| ------------------------ | --------- | ------------------------------------------ |
| `my-contributions.sh`    | `emy`     | Find ALL your PRs and commits across repos |
| `review-my-pr.sh`        | `ereview` | Quick review of your specific PR           |
| `prep-for-discussion.sh` | `eprep`   | Create discussion brief for a PR           |

### Session Notes & Action Items

| Script                        | Alias        | Description                                            |
| ----------------------------- | ------------ | ------------------------------------------------------ |
| `list-action-items.sh`        | `eactions`   | List all actionable items (PRs, syncs, releases, etc.) |
| `generate-weekly-notes.sh`    | `eweek`      | Auto-generate weekly session notes with action items   |
| `generate-catch-up.sh`        | `ecatchup`   | Auto-generate catch-up summary with current status     |
| `generate-daily-checklist.sh` | `echecklist` | Generate daily learning checklist from workflow guide  |

### PR Review & Sync

| Script                  | Alias         | Description                                           |
| ----------------------- | ------------- | ----------------------------------------------------- |
| `check-sync-status.sh`  | `esyncstatus` | Check repository sync status with clear fixes         |
| `review-pr-workflow.sh` | `ereview`     | Step-by-step PR review workflow (keeps IDE in sync)   |
| `reset-to-upstream.sh`  | `ereset`      | Reset fork to match upstream (discards local changes) |
| `safe-push.sh`          | `epush`       | Push with GitGuardian & pre-commit checks             |

### Security & Quality

| Script                | Alias | Description                            |
| --------------------- | ----- | -------------------------------------- |
| `setup-pre-commit.sh` | -     | Setup pre-commit hooks and GitGuardian |

### Navigation & Workspace

| Script              | Alias        | Description                         |
| ------------------- | ------------ | ----------------------------------- |
| `open-workspace.sh` | `eworkspace` | Open multi-repo workspace in Cursor |

| Alias        | Goes To                    |
| ------------ | -------------------------- |
| `elearn`     | embabel-learning directory |
| `eguide`     | guide repository           |
| `eagent`     | embabel-agent repository   |
| `eworkspace` | Open workspace (all repos) |

## 🎯 Current Status (as of Dec 23, 2025)

### Embabel Organization Stats

- **Total Repositories:** 25 (all active, non-archived)
- **Most Starred:** embabel-agent (⭐ 2,958)
- **Your Forks:** 2 (guide, embabel-agent)
- **To Fork:** 23 repositories

### Top Repositories to Explore

Based on [https://github.com/orgs/embabel/repositories](https://github.com/orgs/embabel/repositories):

1. **[embabel-agent](https://github.com/embabel/embabel-agent)** ⭐ 2,958

   - Main agent framework for the JVM
   - Latest: v0.3.1 (released Dec 23, 2025)
   - Active development with 2 open PRs

2. **[embabel-agent-examples](https://github.com/embabel/embabel-agent-examples)** ⭐ 135

   - Examples for Java & Kotlin developers
   - Great learning resource

3. **[tripper](https://github.com/embabel/tripper)** ⭐ 112

   - Travel planner agent
   - Real-world agent example

4. **[java-agent-template](https://github.com/embabel/java-agent-template)** ⭐ 109

   - Template for creating Java agents
   - Good starting point for new projects

5. **[coding-agent](https://github.com/embabel/coding-agent)** ⭐ 51
   - Agentic flow for software engineers
   - Meta project!

### Other Interesting Projects

- **[guide](https://github.com/embabel/guide)** - Talk to the docs (you have this!)
- **[ragbot](https://github.com/embabel/ragbot)** - RAG demo
- **[flicker](https://github.com/embabel/flicker)** - Movie finder agent
- **[decker](https://github.com/embabel/decker)** - Slide deck creation agent
- **[shepherd](https://github.com/embabel/shepherd)** - Community manager
- **[awesome-embabel](https://github.com/embabel/awesome-embabel)** - Curated resources

## 📖 Usage Examples

### Daily Workflow

```bash
# Morning check (2 minutes)
em

# If there are interesting PRs
epr agent 1204

# Weekly sync (every Friday)
esync
```

### Starting with a New Repo

```bash
# 1. Fork it (or fork all at once)
efork

# 2. Clone it
eclone

# 3. Set up tracking
scripts/setup-upstreams.sh

# 4. Start exploring
cd ~/github/jmjava/tripper
glog  # view recent commits
```

### Analyzing a PR

```bash
# View PR in embabel-agent
epr agent 1204

# Or checkout locally to test
cd ~/github/jmjava/embabel-agent
gh pr checkout 1204 --repo embabel/embabel-agent

# Test it...
mvn clean install

# Return to your branch
git checkout main
```

### Comparing Your Changes

```bash
# See how your fork differs from upstream
ecompare

# Detailed diff for guide repo
cd ~/github/jmjava/guide
git diff upstream/main
```

## 🎓 Learning Resources

### Documentation

- **[EMBABEL-WORKFLOW.md](docs/EMBABEL-WORKFLOW.md)** - Complete detailed guide (read when you need deep dive)

### External Resources

- **Embabel Agent Docs:** Check the [embabel-agent README](https://github.com/embabel/embabel-agent)
- **Examples:** Explore [embabel-agent-examples](https://github.com/embabel/embabel-agent-examples)
- **Community:** Check [awesome-embabel](https://github.com/embabel/awesome-embabel) for curated resources

### Your Learning Notes

Create notes in the `notes/` directory:

```bash
cd ~/github/jmjava/embabel-learning/notes
echo "# My Learning Journey" > learning-log.md
```

## 🔧 Tools You'll Use

### 1. GitHub CLI (`gh`)

For PR monitoring, forking, cloning:

```bash
gh pr list --repo embabel/embabel-agent
gh release list --repo embabel/embabel-agent
```

### 2. GitLens (in Cursor/VS Code)

For understanding code history:

- File blame annotations
- Commit history
- Branch comparison
- See who's working on what

### 3. Git with Upstreams

For keeping your fork in sync:

```bash
git fetch upstream
git merge upstream/main
```

### 4. These Scripts

For automation and monitoring!

## 🚀 Next Steps

### Week 1: Setup & Exploration

- [x] Set up embabel-learning workspace
- [ ] Run `efork` to fork all repositories
- [ ] Run `eclone` to clone interesting repos
- [ ] Set up aliases with `setup-aliases.sh`
- [ ] Read through `QUICKSTART.md`
- [ ] Explore top 5 repos

### Week 2: Deep Dive

- [ ] Pick 2-3 repos to focus on
- [ ] Analyze recent PRs in those repos
- [ ] Run and test example projects
- [ ] Start taking notes in `notes/`
- [ ] Use GitLens to understand code history

### Week 3: Contribute

- [ ] Find a "good first issue"
- [ ] Make a small contribution
- [ ] Learn from code review feedback
- [ ] Help review others' PRs

## 📊 Monitoring Dashboard

Run `elist` to see a live dashboard:

```
Repository                     Forked   Cloned   Upstream   Stars
────────────────────────────────────────────────────────────────────
embabel-agent                  ✓        ✓        ✓          ⭐ 2958
guide                          ✓        ✓        ✓          ⭐ 3
embabel-agent-examples         ○        ○        ○          ⭐ 135
...
```

Legend:

- ✓ = Done
- ○ = Not done

## 🤝 Contributing to Embabel

### Before You Start

1. Fork the repo (done via `efork`)
2. Clone it locally (done via `eclone`)
3. Set up upstream tracking (done via `setup-upstreams.sh`)

### Making Changes

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Make your changes
3. Test thoroughly
4. Commit with clear messages
5. Push to your fork: `git push origin feature/my-feature`
6. Create a PR on GitHub

### Staying in Sync

```bash
# Before starting new work
esync

# Or manually
git fetch upstream
git merge upstream/main
```

## 📝 Tips & Best Practices

### 1. Daily Monitoring

```bash
# Add to your daily routine
em
```

### 2. Selective Cloning

You don't need to clone all 25 repos. Start with:

- `embabel-agent` (the core)
- `embabel-agent-examples` (learning)
- `guide` (documentation)
- One or two example projects that interest you

### 3. Use GitLens

Open any file in Cursor and see:

- Who wrote each line
- When it was changed
- Why (commit message)

### 4. Learn from PRs

PRs are the best learning resource:

```bash
gh pr list --repo embabel/embabel-agent --state all --limit 20
epr agent <number>
```

### 5. Take Notes

Document your learning in `notes/`:

```bash
cd ~/github/jmjava/embabel-learning/notes
echo "# Understanding embabel-agent architecture" > architecture.md
```

## 🛡️ Safety: No Commits to Embabel Organization

**CRITICAL SAFETY FEATURE:** This workspace is configured to **PREVENT** any commits or pushes to embabel organization repositories.

### What's Protected

✅ **Automatic blocking** of:

- Commits when `origin` points to embabel
- Pushes to embabel organization
- Accidental modifications to embabel repos

✅ **Allowed operations:**

- Reading embabel repos
- Syncing FROM embabel (pull/merge)
- Committing to YOUR forks (jmjava/...)
- Pushing to YOUR forks

### How It Works

1. **Git Hooks** - Installed automatically to block commits/pushes
2. **Script Safety Checks** - All scripts check before operations
3. **Remote Validation** - Verifies `origin` points to your fork

### Contributing to Embabel

To contribute to embabel projects:

1. **Work on your fork:**

   ```bash
   # Make sure origin points to YOUR fork
   git remote set-url origin git@github.com:jmjava/REPO_NAME.git
   ```

2. **Make changes and commit:**

   ```bash
   git add .
   git commit -m "Your changes"
   epush  # Safe push with checks
   ```

3. **Create PR from your fork:**
   ```bash
   gh pr create --repo embabel/REPO_NAME
   ```

**Never commit directly to embabel repos - always work through your fork!**

---

## 🔒 Security & Pre-commit Hooks

This repository includes **GitGuardian** secret scanning and **pre-commit** hooks to ensure code quality and security.

### Setup

Run the setup script:

```bash
cd ~/github/jmjava/embabel-learning
./scripts/setup-pre-commit.sh
```

This will:

- Install `pre-commit` (if not already installed)
- Install GitGuardian CLI (`ggshield`)
- Install pre-commit hooks
- Run initial checks on all files

### What's Included

**Security Checks:**

- ✅ **GitGuardian** - Scans for secrets, API keys, credentials
- ✅ **detect-secrets** - Additional secret detection
- ✅ **Private key detection** - Detects SSH keys, certificates
- ✅ **AWS credentials detection** - Scans for AWS keys

**Code Quality Checks:**

- ✅ **Shell script linting** (shellcheck)
- ✅ **YAML linting** (yamllint)
- ✅ **JSON validation**
- ✅ **Markdown linting**
- ✅ **Trailing whitespace removal**
- ✅ **End of file fixes**
- ✅ **Large file detection**

### GitGuardian Configuration

#### Option 1: API Key (Recommended for Teams)

Get your API key from [GitGuardian Dashboard](https://dashboard.gitguardian.com/):

```bash
# Authenticate with GitGuardian
ggshield auth login

# Or set environment variable
export GITGUARDIAN_API_KEY=your-api-key-here
```

#### Option 2: Local Scanning (No API Key Required)

GitGuardian will work locally without an API key, but with limited features:

- ✅ Secret detection still works
- ❌ No cloud sync
- ❌ No team policies

### Usage

**Safe Push (Recommended):**

Always use `epush` to push with security checks:

```bash
# From any git repo directory
epush

# Or specify branch/remote
epush main origin
```

This automatically:

- ✅ Runs pre-commit hooks on all files
- ✅ Runs GitGuardian scan
- ✅ Shows what will be pushed
- ✅ Confirms before pushing

**Automatic (on commit):**

```bash
git commit -m "Your message"
# Pre-commit hooks run automatically
```

**Manual:**

```bash
# Run on staged files
pre-commit run

# Run on all files
pre-commit run --all-files

# Run specific hook
pre-commit run ggshield
pre-commit run shellcheck
```

**GitGuardian Manual Scan:**

```bash
# Scan entire repository
ggshield scan

# Scan specific file
ggshield scan path/to/file.sh

# Scan commit
ggshield scan commit HEAD
```

### Updating Hooks

Update hook versions to latest:

```bash
pre-commit autoupdate
```

### Bypassing Hooks (Not Recommended)

If you need to bypass hooks (emergency only):

```bash
git commit --no-verify -m "Emergency commit"
```

⚠️ **Warning:** Only use `--no-verify` when absolutely necessary. It bypasses all security checks.

### Configuration Files

- `.pre-commit-config.yaml` - Pre-commit hooks configuration
- `.yamllint.yml` - YAML linting rules
- `.secrets.baseline` - Baseline for detect-secrets (auto-updated)
- `.gitignore` - Ignored files (includes pre-commit cache)

### Troubleshooting

**Hooks not running?**

```bash
# Reinstall hooks
pre-commit uninstall
pre-commit install
```

**GitGuardian auth issues?**

```bash
# Check auth status
ggshield auth status

# Re-authenticate
ggshield auth login
```

**Hook failures?**

```bash
# See detailed output
pre-commit run --verbose

# Update hooks
pre-commit autoupdate
```

**Python/pip not found?**

```bash
# Ubuntu/Debian
sudo apt-get install python3-pip

# macOS
brew install python3

# Then re-run setup
./scripts/setup-pre-commit.sh
```

### What Gets Checked

| Check               | What It Does                        | When It Runs             |
| ------------------- | ----------------------------------- | ------------------------ |
| GitGuardian         | Scans for secrets, API keys, tokens | Every commit             |
| detect-secrets      | Additional secret patterns          | Every commit             |
| shellcheck          | Shell script linting                | On `.sh` files           |
| yamllint            | YAML validation                     | On `.yaml`, `.yml` files |
| markdownlint        | Markdown formatting                 | On `.md` files           |
| trailing-whitespace | Removes trailing spaces             | Every commit             |
| end-of-file-fixer   | Ensures newline at EOF              | Every commit             |
| check-json          | Validates JSON syntax               | On `.json` files         |
| detect-private-key  | Finds private keys                  | Every commit             |

### Best Practices

1. **Always use safe push:**

   ```bash
   epush  # Runs all checks before pushing
   ```

   This ensures GitGuardian and pre-commit checks run before your code reaches GitHub.

2. **Run before pushing (alternative):**

   ```bash
   pre-commit run --all-files
   ggshield scan
   git push
   ```

3. **Keep hooks updated:**

   ```bash
   pre-commit autoupdate
   ```

4. **Review secrets baseline:**

   - `.secrets.baseline` is auto-generated
   - Review if new secrets are detected
   - Commit the baseline if secrets are false positives

5. **Use GitGuardian dashboard:**
   - Monitor secret detection across all repos
   - Set up team policies
   - Get alerts for new secrets

## 🆘 Troubleshooting

### Scripts not working?

```bash
chmod +x ~/github/jmjava/embabel-learning/scripts/*.sh
```

### Aliases not working?

```bash
source ~/.bash_aliases
```

### Can't fork/clone?

Check GitHub authentication:

```bash
gh auth status
```

### Merge conflicts when syncing?

```bash
# The sync script will guide you, or:
git status
# Fix conflicts in editor
git add .
git merge --continue
```

## 📋 Reviewing PRs & Keeping IDE in Sync

**Problem:** IDE shows wrong files or outdated information when reviewing PRs

**Solution:** Always check sync status first, then review

### Quick Workflow

```bash
# 1. Check sync status (30 seconds)
esyncstatus all

# 2. If behind, sync
esync

# 3. Review PR (handles sync automatically)
ereview agent 1223
```

### What `ereview` Does

The `ereview` command automatically:

- ✅ Checks if repo is in sync
- ✅ Syncs if needed
- ✅ Shows PR information
- ✅ Lists files changed
- ✅ Offers to checkout locally
- ✅ Shows diff
- ✅ Provides next steps

### After Git Operations: Refresh IDE

After syncing, checking out PRs, or any git operation:

1. **Reload window:** `Cmd/Ctrl+Shift+P` → "Developer: Reload Window"
2. **Or close and reopen** the repo folder in Cursor

### Common Issues

**IDE shows wrong branch:**

```bash
git branch                    # Check current branch
git checkout main            # Switch to correct branch
# Then reload IDE window
```

**IDE shows outdated files:**

```bash
esyncstatus all              # Check sync status
esync                        # Sync if needed
# Then reload IDE window
```

**Can't see PR changes:**

```bash
ereview agent 123            # Use the workflow script
# Or manually:
gh pr checkout 123 --repo embabel/embabel-agent
# Then reload IDE window
```

## 📚 Further Reading

- **[PR Review Guide](docs/PR-REVIEW-GUIDE.md)** - Complete guide to reviewing PRs and keeping IDE in sync
- [GitHub Fork Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/forking-workflow)
- [GitHub CLI Manual](https://cli.github.com/manual/)
- [GitLens Documentation](https://gitlens.amod.io/)

## 📜 License

This learning workspace is for personal use. The embabel repositories each have their own licenses (typically Apache 2.0).

---

**Ready to start?** Run `elist` to see what's available, then `efork` to get all the repos! 🚀
