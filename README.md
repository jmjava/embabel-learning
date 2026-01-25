# 🎓 Organization Learning Workspace

### note this is brand new -- unit tests are in place but this is alpha status

Your central hub for learning, monitoring, and contributing to any GitHub organization's repositories.

> **📖 Need detailed information?** See [docs/EMBABEL-WORKFLOW.md](docs/EMBABEL-WORKFLOW.md) for comprehensive guides on PR reviews, contribution tracking, session notes, and more.

## ⚙️ Configuration

**First-time setup:** This workspace is now generic and works with any GitHub organization!

### Option 1: Using .env File (Recommended)

1. **Copy and configure:**
   ```bash
   cp .env-template .env
   # Edit .env with your settings:
   # - YOUR_GITHUB_USER: Your GitHub username
   # - UPSTREAM_ORG: The organization you want to monitor
   # - BASE_DIR: Where you clone repositories (default: $HOME/github/YOUR_GITHUB_USER)
   # - MONITOR_REPOS: Optional - specific repos to monitor (space-separated)
   ```

### Option 2: Using config.sh File (Backward Compatibility)

1. **Copy and configure:**

   ```bash
   cp config.sh.example config.sh
   # Edit config.sh with your settings (same variables as .env)
   ```

2. **The workspace will use these defaults if neither `.env` nor `config.sh` is found:**

   - `UPSTREAM_ORG=embabel`
   - `YOUR_GITHUB_USER=jmjava`
   - `BASE_DIR=~/github/jmjava`

   > **Note:** A warning will be shown when using defaults. Create `.env` or `config.sh` to customize.

> **Important:** The `.env` file is git-ignored and should never be committed. It contains user-specific settings.

See [CONFIGURATION.md](CONFIGURATION.md) for detailed configuration options.

## 🎯 Common Tasks (Quick Reference)

| What You Want to Do            | Command                       |
| ------------------------------ | ----------------------------- |
| **Check what needs attention** | `eactions`                    |
| **Check if repos are in sync** | `esyncstatus all`             |
| **Sync repositories**          | `esync`                       |
| **Reset fork to upstream**     | `ereset <repo-name>`          |
| **Safe push (with checks)**    | `epush`                       |
| **Review a PR**                | `epr <repo-name> <pr-number>` |
| **Daily monitoring**           | `em`                          |
| **List all repos**             | `elist`                       |
| **Your contributions**         | `emy`                         |
| **Generate weekly notes**      | `eweek`                       |
| **Generate daily checklist**   | `echecklist`                  |
| **Catch up after break**       | `ecatchup`                    |
| **Embabel repo summaries**     | `esummary`                    |
| **Sync Discord messages**      | `./discord-sync/sync-discord.sh --channel ID --after DATE` |

## 🚀 Quick Start (5 minutes)

```bash
# 1. Configure for your organization (REQUIRED for first-time setup)
cd /path/to/organization-learning  # or clone this repo
cp .env-template .env  # Recommended: use .env file
# Or: cp config.sh.example config.sh  # Alternative: use config.sh
# Edit .env (or config.sh) with YOUR_GITHUB_USER and UPSTREAM_ORG

# 2. Set up convenient aliases
source scripts/setup-aliases.sh
source ~/.bash_aliases

# 3. List all organization repos and their status
elist

# 4. Fork all organization repositories
efork

# 5. Clone the repos you want to work with
eclone

# 6. Set up upstream tracking
scripts/setup-upstreams.sh

# 7. Set up pre-commit hooks and GitGuardian (recommended)
./scripts/setup-pre-commit.sh

# 8. Start monitoring daily
em
```

> **Configuration required:** Make sure to create `.env` from `.env-template` (or `config.sh` from `config.sh.example`) before running the scripts. See [CONFIGURATION.md](CONFIGURATION.md) for details.

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
├── discord-sync/              # Discord message export and summarization
│   ├── sync-discord.sh        # Export and summarize Discord messages
│   └── README.md              # Discord sync documentation
├── embabel-hub/               # Embabel Hub Docker container management
│   ├── starthub.sh            # Start embabel-hub container
│   ├── stophub.sh             # Stop embabel-hub container
│   └── STARTUP.md             # Hub startup guide
├── docs/                       # Documentation
│   └── EMBABEL-WORKFLOW.md    # Complete detailed workflow guide
├── notes/                      # Your personal learning notes
│   ├── session-notes/          # Weekly notes and catch-up summaries
│   ├── my-contributions/       # Your PR and contribution tracking
│   └── discussions/            # PR discussion briefs
├── test/                       # Test suite
│   ├── ARCHITECTURE.md         # Test architecture documentation
│   ├── unit/                   # Unit tests
│   └── run-tests.sh           # Test runner
├── .pre-commit-config.yaml    # Pre-commit hooks configuration
├── .yamllint.yml              # YAML linting rules
├── .secrets.baseline          # Secrets detection baseline
└── .gitignore                 # Git ignore rules
```

## 🛠️ Available Scripts

### Repository Management

| Script                   | Alias    | Description                                        |
| ------------------------ | -------- | -------------------------------------------------- |
| `list-embabel-repos.sh`  | `elist`  | Show all organization repos with fork/clone status |
| `fork-all-embabel.sh`    | `efork`  | Fork all organization repos you haven't forked yet |
| `clone-embabel-repos.sh` | `eclone` | Clone your forked repositories                     |
| `setup-upstreams.sh`     | -        | Configure upstream remotes for tracking            |

### Daily Monitoring & Sync

| Script                | Alias      | Description                                                                    |
| --------------------- | ---------- | ------------------------------------------------------------------------------ |
| `monitor-embabel.sh`  | `em`       | Check PRs, releases, commits across configured repos                           |
| `sync-upstream.sh`    | `esync`    | Sync your fork with upstream changes (use `esync <repo-name>` or `esync all`)  |
| `compare-branches.sh` | `ecompare` | Compare your fork with upstream (use `ecompare <repo-name>` or `ecompare all`) |
| `view-pr.sh`          | `epr`      | Deep dive into a specific PR (use `epr <repo-name> <pr-number>`)               |

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

### Discord Integration

| Script/Tool                    | Description                                                          |
| ------------------------------ | -------------------------------------------------------------------- |
| `discord-sync/sync-discord.sh` | Export and summarize Discord messages with filtering options          |
|                                | See [discord-sync/README.md](discord-sync/README.md) for full docs   |

**Features:**
- Date range filtering (`--after`, `--before`)
- Username filtering (`--username`, supports multiple)
- Topic/keyword filtering (`--topic`, supports multiple)
- Multiple output formats (JSON, TXT, HTML)
- Automatic summary generation with statistics

**Quick Example:**
```bash
# Export today's messages
./discord-sync/sync-discord.sh \
  --channel YOUR_CHANNEL_ID \
  --after "2026-01-25"
```

### Navigation & Workspace

| Script              | Alias        | Description                         |
| ------------------- | ------------ | ----------------------------------- |
| `open-workspace.sh` | `eworkspace` | Open multi-repo workspace in Cursor |

| Alias        | Goes To                               |
| ------------ | ------------------------------------- |
| `elearn`     | learning workspace directory          |
| `eworkspace` | Open workspace (all configured repos) |

**Repo-specific aliases** (dynamically generated from `MONITOR_REPOS`):

- `e<repo-name>` - Navigate to a specific repo (e.g., `eguide`, `eagent`)
- These are automatically created based on your `MONITOR_REPOS` configuration

## 🎯 Getting Started with Your Organization

Once configured, you can:

1. **View organization statistics:**

   ```bash
   elist  # Shows all repos in your configured UPSTREAM_ORG
   ```

2. **Check current status:**

   ```bash
   em        # Monitor daily changes
   esummary  # Get comprehensive summary
   ```

3. **Explore repositories:**
   - Use `elist` to see all repositories
   - Fork interesting ones with `efork`
   - Clone what you want to work with using `eclone`
   - Set up upstream tracking with `setup-upstreams.sh`

### Example: Working with Any Organization

This workspace is generic! You can use it with:

- **Embabel** (default): `UPSTREAM_ORG=embabel`
- **Spring Framework**: `UPSTREAM_ORG=spring-projects`
- **Apache Projects**: `UPSTREAM_ORG=apache`
- **Any GitHub organization**: Just set `UPSTREAM_ORG` in `config.sh`

> **Note:** The examples in this README use "embabel" as a default, but all scripts work with any organization once configured.

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

# 4. Start exploring (use your configured BASE_DIR)
cd $BASE_DIR/<repo-name>  # or use dynamically generated alias: e<repo-name>
glog  # view recent commits
```

### Analyzing a PR

```bash
# View PR in any repository
epr <repo-name> <pr-number>

# Example: View PR #1204 in a repo called "agent"
epr agent 1204

# Or checkout locally to test
cd $BASE_DIR/<repo-name>
gh pr checkout <pr-number> --repo ${UPSTREAM_ORG}/<repo-name>

# Test it...
mvn clean install  # or appropriate build command

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

### 4. Discord Sync

For exporting and summarizing Discord messages:

```bash
# Export messages from a channel
./discord-sync/sync-discord.sh \
  --channel YOUR_CHANNEL_ID \
  --after "2026-01-25" \
  --before "2026-01-26"

# Filter by username
./discord-sync/sync-discord.sh \
  --channel YOUR_CHANNEL_ID \
  --after "2026-01-25" \
  --username "alice" \
  --username "bob"

# Filter by topic
./discord-sync/sync-discord.sh \
  --channel YOUR_CHANNEL_ID \
  --after "2026-01-25" \
  --topic "embabel" \
  --topic "agent"
```

See [discord-sync/README.md](discord-sync/README.md) for complete documentation.

### 5. These Scripts

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

You don't need to clone all repos. Start with a few key repositories:

- Use `elist` to see all available repositories
- Fork and clone 2-3 repos that interest you most
- Expand later as you learn more

### 3. Use GitLens

Open any file in Cursor and see:

- Who wrote each line
- When it was changed
- Why (commit message)

### 4. Learn from PRs

PRs are the best learning resource:

```bash
gh pr list --repo ${UPSTREAM_ORG}/<repo-name> --state all --limit 20
epr <repo-name> <number>
```

### 5. Take Notes

Document your learning in `notes/`:

```bash
cd $LEARNING_DIR/notes
echo "# Understanding project architecture" > architecture.md
```

## 🛡️ Safety: No Commits to Upstream Organization

**CRITICAL SAFETY FEATURE:** This workspace is configured to **PREVENT** any commits or pushes to upstream organization repositories.

### What's Protected

✅ **Automatic blocking** of:

- Commits when `origin` points to upstream organization
- Pushes to upstream organization
- Accidental modifications to upstream org repos

✅ **Allowed operations:**

- Reading upstream organization repos
- Syncing FROM upstream (pull/merge)
- Committing to YOUR forks (${YOUR_GITHUB_USER}/...)
- Pushing to YOUR forks

### How It Works

1. **Pre-commit Hooks** - Integrated into pre-commit framework, runs automatically on every commit
   - Uses `UPSTREAM_ORG` from your `.env` file
   - Blocks commits if repository origin points to upstream org
   - Allows commits only to your forks (`YOUR_GITHUB_USER`)
   - See [Security & Pre-commit Hooks](#-security--pre-commit-hooks) section for details
2. **Git Push Hooks** - Installed via `install-git-safety-hooks.sh` to block pushes
3. **Script Safety Checks** - All scripts check before operations
3. **Remote Validation** - Verifies `origin` points to your fork

### Contributing to Upstream Organization

To contribute to upstream organization projects:

1. **Work on your fork:**

   ```bash
   # Make sure origin points to YOUR fork
   git remote set-url origin git@github.com:${YOUR_GITHUB_USER}/REPO_NAME.git
   ```

2. **Make changes and commit:**

   ```bash
   git add .
   git commit -m "Your changes"
   epush  # Safe push with checks
   ```

3. **Create PR from your fork:**
   ```bash
   gh pr create --repo ${UPSTREAM_ORG}/REPO_NAME
   ```

**Never commit directly to upstream organization repos - always work through your fork!**

---

## 🔒 Security & Pre-commit Hooks

This repository includes **GitGuardian** secret scanning and **pre-commit** hooks to ensure code quality and security.

### Setup

Run the setup script:

```bash
cd $LEARNING_DIR  # or your learning workspace directory
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

**Safety Checks:**

- ✅ **Block upstream commits** - Prevents accidental commits to upstream organization repos
  - Uses `UPSTREAM_ORG` from your `.env` file
  - Automatically blocks commits to upstream org repos
  - Allows commits only to your forks (`YOUR_GITHUB_USER`)
  - Integrated into pre-commit framework - runs on every commit

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

**Automatic (on commit and push):**

```bash
# On commit:
git commit -m "Your message"
# Pre-commit hooks run automatically:
# 1. GitGuardian secret scanning (ggshield)
# 2. Safety checks (block-upstream-commit)
# 3. All other hooks (linting, formatting, etc.)

# On push:
git push
# Pre-push hooks run automatically:
# 1. GitGuardian secret scanning (ggshield) - Extra security check
# 2. Safety checks (block-upstream-push) - Prevents pushes to upstream org
# 3. All other pre-push hooks
```

**Important:** All commits AND pushes automatically run:
- ✅ **GitGuardian secret scanning** - Scans for secrets before commit AND push
- ✅ **Safety checks** - Prevents commits/pushes to upstream org repos (uses `UPSTREAM_ORG` from `.env`)
- ✅ **All other hooks** - Linting, formatting, file checks

If any hook fails, the commit/push is blocked. This ensures:
- No secrets are committed or pushed
- No accidental commits/pushes to upstream org repos
- Code quality standards are maintained
- Double protection: secrets checked on both commit and push

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
| GitGuardian         | Scans for secrets, API keys, tokens | Every commit AND push    |
| Safety Checks       | Prevents commits to upstream org    | Every commit             |
| Safety Checks (Push)| Prevents pushes to upstream org     | Every push               |
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
