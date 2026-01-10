# ⚙️ Configuration Guide

This workspace is now **generic** and can work with any GitHub organization! This guide explains how to configure it for your use.

## Configuration Methods

The scripts support two configuration methods (in order of precedence):

1. **`.env` file** (recommended) - Environment variable style configuration
2. **`config.sh` file** - Bash script style configuration (backward compatibility)

Both methods are supported, but `.env` is recommended for consistency with modern practices and Spring Boot applications.

## Quick Start

### Option 1: Using .env File (Recommended)

1. **Copy the template:**
   ```bash
   cp .env-template .env
   ```

2. **Edit `.env` with your settings:**
   ```bash
   nano .env  # or use your preferred editor
   ```

3. **That's it!** The `.env` file is automatically loaded by all scripts.

**Example `.env` file:**
```bash
# Your personal GitHub username (for your forks)
YOUR_GITHUB_USER=your-username

# The organization you want to monitor (can be different from your username!)
UPSTREAM_ORG=embabel

# Where you clone YOUR forks (under your username)
BASE_DIR=$HOME/github/your-username

# Which repos from UPSTREAM_ORG you want to monitor
MONITOR_REPOS=guide embabel-agent dice

WORKSPACE_NAME=embabel-workspace
MAX_MONITOR_REPOS=10
```

**Real-world example:**
```bash
# Alice wants to monitor Embabel repos
YOUR_GITHUB_USER=alice
UPSTREAM_ORG=embabel  # Monitoring embabel's repos, not alice's org

# Bob wants to monitor Spring Framework
YOUR_GITHUB_USER=bob
UPSTREAM_ORG=spring-projects  # Monitoring spring-projects, not bob's org
```

> **Note:** The `.env` file is git-ignored and should never be committed. It contains user-specific settings.

### Option 2: Using config.sh File (Backward Compatibility)

1. **Copy the example configuration:**
   ```bash
   cp config.sh.example config.sh
   ```

2. **Edit `config.sh` with your settings:**
   ```bash
   # Your GitHub username. Used for forking, cloning, and identifying your contributions.
   YOUR_GITHUB_USER="your-username"

   # The GitHub organization that owns the upstream repositories you're interested in.
   UPSTREAM_ORG="embabel"  # or "spring-projects", "apache", etc.

   # The base directory where your GitHub repositories are cloned.
   # Default: $HOME/github/${YOUR_GITHUB_USER}
   BASE_DIR="$HOME/github/${YOUR_GITHUB_USER}"

   # A space-separated list of repository names to monitor daily.
   # If not set, scripts will auto-detect or query GitHub for all repos.
   # Example: MONITOR_REPOS="guide embabel-agent dice"
   MONITOR_REPOS="guide embabel-agent"
   ```

3. **That's it!** All scripts will now use your configuration.

## Understanding the Two Key Variables

**Important Distinction:**
- **`YOUR_GITHUB_USER`**: Your personal GitHub username (where YOUR forks live)
- **`UPSTREAM_ORG`**: The organization you want to **monitor** (can be completely different!)

**Example Scenario:**
- Your GitHub username: `alice`
- Organization you want to monitor: `embabel`
- Your config:
  ```bash
  YOUR_GITHUB_USER=alice        # Your personal account
  UPSTREAM_ORG=embabel          # Organization to monitor (different!)
  ```
- Result: Scripts will monitor `embabel/*` repos, fork them to `alice/*`, and you'll contribute back to `embabel`

## Configuration Variables

### `YOUR_GITHUB_USER` (Required)

Your personal GitHub username. Used for:
- Forking repositories from `UPSTREAM_ORG` to your account (`gh repo fork`)
- Cloning YOUR forks (not the upstream org's repos directly)
- Identifying your contributions in PRs
- Setting up git remotes (origin = your fork, upstream = org's repo)

**Example:**
```bash
YOUR_GITHUB_USER="alice"
```

**Important Notes:**
- This is your **personal username**, NOT your organization name
- If you have a personal organization (e.g., `menkelabs`), that's separate from `YOUR_GITHUB_USER`
- Example: Username `jmjava` with personal org `menkelabs` → `YOUR_GITHUB_USER="jmjava"` (not "menkelabs")
- This can be different from the organization you monitor. You might be `alice` but want to monitor `embabel` repos.

### `UPSTREAM_ORG` (Required)

The GitHub organization whose repositories you want to **monitor and learn from**. This can be:
- **Different from your personal organization/user** (most common use case)
- `embabel` (default)
- `spring-projects`
- `apache`
- `kubernetes`
- Any GitHub organization name

**Important:** This is the organization you want to monitor, NOT your personal GitHub organization. For example:
- If you want to monitor Embabel's repos: `UPSTREAM_ORG="embabel"` (even if your username is different)
- If you want to monitor Spring Framework: `UPSTREAM_ORG="spring-projects"` (even if your username is different)

**Example:**
```bash
# Your personal GitHub username
YOUR_GITHUB_USER="jmjava"

# Organization to monitor (production)
UPSTREAM_ORG="embabel"
```

> **Note:** For testing with your personal organization, use `TEST_UPSTREAM_ORG` (see below). This keeps production and test configs separate.

### `BASE_DIR` (Optional)

The base directory where you clone repositories. Defaults to:
```bash
BASE_DIR="$HOME/github/${YOUR_GITHUB_USER}"
```

**Example:**
```bash
BASE_DIR="$HOME/code/my-org-repos"
```

### `TEST_UPSTREAM_ORG` (Optional)

The GitHub organization to use for **testing only**. If set, test scripts will automatically use this instead of `UPSTREAM_ORG`.

**Use Cases:**
- Use your personal organization for testing (safer, since it's your own org)
- Keep production scripts using `UPSTREAM_ORG` (e.g., `embabel`)
- Tests automatically switch to `TEST_UPSTREAM_ORG` without manual changes

**Example:**
```bash
# Production org
UPSTREAM_ORG=embabel

# Test org (your personal org)
TEST_UPSTREAM_ORG=menkelabs
```

**How it works:**
- Production scripts: Always use `UPSTREAM_ORG` (e.g., `embabel`)
- Test scripts: Automatically use `TEST_UPSTREAM_ORG` if set (e.g., `menkelabs`)
- If `TEST_UPSTREAM_ORG` is not set, tests also use `UPSTREAM_ORG`

**Benefits:**
- No need to manually switch `UPSTREAM_ORG` between testing and production
- Clear separation between test and production configurations
- Tests use safer test org automatically
- Production scripts remain unchanged

### `MONITOR_REPOS` (Optional)

A space-separated list of repository names to monitor daily. If not set:
- Scripts will auto-detect from cloned repos in `BASE_DIR`
- Or query GitHub API for all repos in the organization

**Example:**
```bash
MONITOR_REPOS="spring-boot spring-framework spring-data"
```

**Note:** If you set `MONITOR_REPOS`, only these repos will be monitored. If you want all repos, leave this unset or empty.

## Default Values

If `config.sh` is **not** present, scripts will use these defaults:

```bash
YOUR_GITHUB_USER="jmjava"
UPSTREAM_ORG="embabel"
BASE_DIR="$HOME/github/jmjava"
MONITOR_REPOS="guide embabel-agent"
```

> **Warning:** A message will be shown when using defaults. Create `config.sh` to customize.

## Examples

### Example 1: Monitoring Embabel (Default)

**Scenario:** Your username is `jmjava`, but you want to monitor `embabel` repos.

```bash
# .env or config.sh
YOUR_GITHUB_USER="jmjava"          # YOUR personal GitHub username
UPSTREAM_ORG="embabel"              # Organization to MONITOR (different!)
BASE_DIR="$HOME/github/jmjava"
MONITOR_REPOS="guide embabel-agent dice"
```

**How it works:**
- Scripts monitor: `github.com/embabel/*` repos
- Your forks: `github.com/jmjava/*` repos
- Safety checks block pushing to `embabel/*` repos
- You contribute by forking to `jmjava/*` and creating PRs back to `embabel`

### Example 2: Monitoring Spring Framework

**Scenario:** Your username is `alice`, but you want to monitor `spring-projects` repos.

```bash
# .env or config.sh
YOUR_GITHUB_USER="alice"            # YOUR personal GitHub username
UPSTREAM_ORG="spring-projects"      # Organization to MONITOR (different!)
BASE_DIR="$HOME/github/alice"
MONITOR_REPOS="spring-boot spring-framework spring-data"
```

### Example 3: Personal Organization vs Monitoring Organization

**Scenario:** Your username is `jmjava`, you have a personal org `menkelabs`, and you want to monitor `embabel`.

**For Testing (using your personal org - safer):**
```bash
# .env or config.sh
YOUR_GITHUB_USER="jmjava"           # YOUR personal GitHub username
UPSTREAM_ORG="menkelabs"           # Your personal org (safer for testing)
BASE_DIR="$HOME/github/jmjava"
MONITOR_REPOS="repo1 repo2"        # Repos from menkelabs to test with
```

**For Production (monitoring embabel):**
```bash
# .env or config.sh
YOUR_GITHUB_USER="jmjava"           # YOUR personal GitHub username
UPSTREAM_ORG="embabel"             # Organization to MONITOR (not menkelabs!)
BASE_DIR="$HOME/github/jmjava"
MONITOR_REPOS="guide embabel-agent dice"  # Repos from embabel to monitor

# Note: menkelabs is your personal org (good for testing),
# but UPSTREAM_ORG is what you want to monitor (embabel for production)
```

### Example 4: Apache Projects

```bash
# .env or config.sh
YOUR_GITHUB_USER="bob"              # YOUR personal GitHub username
UPSTREAM_ORG="apache"               # Organization to MONITOR (different!)
BASE_DIR="$HOME/code/apache-repos"
MONITOR_REPOS="kafka hadoop spark"  # Or leave empty to monitor all
```

## How Configuration is Loaded

1. Scripts source `config-loader.sh`
2. `config-loader.sh` sets default values
3. If `config.sh` exists, it sources it to override defaults
4. Variables are exported so they're available in subshells

**Path to config.sh:**
```bash
CONFIG_FILE="$(dirname "$(dirname "$SCRIPT_DIR")")/config.sh"
# i.e., ${LEARNING_DIR}/config.sh
```

## Verification

After setting up `config.sh`, verify it's working:

```bash
# Check if configuration is loaded
source scripts/config-loader.sh
echo "GitHub User: $YOUR_GITHUB_USER"
echo "Upstream Org: $UPSTREAM_ORG"
echo "Base Dir: $BASE_DIR"
echo "Monitor Repos: $MONITOR_REPOS"
```

Or test with a script:
```bash
./scripts/list-embabel-repos.sh
# Should show repos from your configured UPSTREAM_ORG
```

## Troubleshooting

### Issue: "No custom config.sh found. Using default configuration."

**Solution:** Create `config.sh` from `config.sh.example`:
```bash
cp config.sh.example config.sh
# Edit config.sh with your settings
```

### Issue: Scripts still use old organization name

**Solution:** Make sure `config.sh` is in the workspace root:
```bash
# Should be at:
# ${LEARNING_DIR}/config.sh
```

### Issue: `MONITOR_REPOS` not working

**Solution:** Ensure it's a space-separated list, no commas:
```bash
# ✅ Correct
MONITOR_REPOS="repo1 repo2 repo3"

# ❌ Wrong
MONITOR_REPOS="repo1,repo2,repo3"
```

### Issue: Script can't find repositories

**Solution:** Check that `BASE_DIR` exists and contains the repos:
```bash
ls $BASE_DIR
# Should show your cloned repositories
```

## Advanced Configuration

### Custom Script Behavior

Some scripts allow runtime overrides:
- `monitor-embabel.sh` accepts repo names as arguments
- `sync-upstream.sh` accepts `all` or specific repo names
- `compare-branches.sh` accepts `all` or specific repo names

**Example:**
```bash
# Monitor specific repo even if not in MONITOR_REPOS
./scripts/monitor-embabel.sh guide

# Sync all repos regardless of MONITOR_REPOS
./scripts/sync-upstream.sh all
```

### Environment Variables

You can also set configuration via environment variables (though `config.sh` is preferred):

```bash
export YOUR_GITHUB_USER="alice"
export UPSTREAM_ORG="spring-projects"
export BASE_DIR="$HOME/github/alice"
export MONITOR_REPOS="spring-boot spring-framework"
```

## Security Notes

- **Never commit `config.sh`** - It contains your GitHub username (though this is usually public info)
- Add to `.gitignore` if you want extra safety:
  ```bash
  echo "config.sh" >> .gitignore
  ```
- The workspace is already configured to prevent commits/pushes to upstream organization

## Need Help?

- Check [README.md](README.md) for usage examples
- See [docs/EMBABEL-WORKFLOW.md](docs/EMBABEL-WORKFLOW.md) for detailed workflows
- Review script source code - they all load `config-loader.sh` at the top
