# Generalization Plan: Making embabel-learning Generic

This document outlines all changes needed to make the `embabel-learning` repository generic enough for others to use with any GitHub organization.

## Overview

The repository currently has many hardcoded values specific to:
- **Username**: `jmjava`
- **Organization**: `embabel`
- **Base directory**: `~/github/jmjava`
- **Workspace name**: `embabel-learning`
- **Specific repos**: `guide`, `embabel-agent`, `dice`

## 1. Configuration Variables (Primary Changes)

### 1.1 Create a Central Configuration File

**New File**: `config.sh` or `.env` or `config/config.ini`

```bash
# User Configuration
YOUR_GITHUB_USER="jmjava"           # Your GitHub username
UPSTREAM_ORG="embabel"               # Organization to monitor
BASE_DIR="$HOME/github/${YOUR_GITHUB_USER}"  # Base directory for repos
LEARNING_DIR="${BASE_DIR}/embabel-learning"  # This workspace directory

# Optional: Specific repos to monitor (space-separated)
MONITOR_REPOS="guide embabel-agent dice"

# Optional: Workspace name (for Cursor workspace file)
WORKSPACE_NAME="embabel-workspace"
```

**Usage**: All scripts should source this file at the top:
```bash
# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEARNING_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ -f "$LEARNING_DIR/config.sh" ]; then
    source "$LEARNING_DIR/config.sh"
else
    echo "Error: config.sh not found. Please copy config.sh.example and configure it."
    exit 1
fi
```

### 1.2 Files Requiring Configuration Variables

All scripts that currently have hardcoded values should be updated to use variables:

#### Critical Scripts (Must Change):
- `scripts/list-embabel-repos.sh` - Lines 14-16
- `scripts/fork-all-embabel.sh` - Lines 13-15
- `scripts/clone-embabel-repos.sh` - Lines 13-15
- `scripts/setup-upstreams.sh` - Lines 13-15
- `scripts/my-contributions.sh` - Lines 15-17
- `scripts/monitor-embabel.sh` - Lines 7-9, 77, 83, 91
- `scripts/safety-checks.sh` - Lines 18, 23, 32, 52, 69, 79, 84, 107

#### Secondary Scripts (Should Change):
- `scripts/setup-aliases.sh` - Line 6, 56-58
- `scripts/check-sync-status.sh` - Lines 7-8, 23
- `scripts/sync-upstream.sh` - Lines 12-13, 44, 50, 85
- `scripts/reset-to-upstream.sh` - Lines 10-11, 118
- `scripts/compare-branches.sh` - Lines 7-8
- `scripts/view-pr.sh` - Lines 16-17
- `scripts/review-pr-workflow.sh` - Lines 16-17
- `scripts/list-action-items.sh` - Lines 35-36
- `scripts/generate-weekly-notes.sh` - Lines 72-73
- `scripts/generate-catch-up.sh` - Lines 64, 73, 89-90, 116-117
- `scripts/analyze-pr-impact.sh` - Lines 17-19, 32, 36
- `scripts/explain-commit.sh` - Lines 19-20, 33, 37
- `scripts/prepare-commit-summaries.sh` - Lines 20-22, 35, 39
- `scripts/prep-for-discussion.sh` - Line 23, 173
- `scripts/open-workspace.sh` - Line 5
- `scripts/get-embabel-summary.sh` - Line 8
- `scripts/review-my-pr.sh` - Line 24
- `scripts/list-fork-urls.sh` - Line 7, 37
- `scripts/setup-git-remote.sh` - Line 66

## 2. Script-Specific Changes

### 2.1 `monitor-embabel.sh`

**Current**: Hardcodes specific repos (`guide`, `embabel-agent`, `dice`)

**Change to**: Use configurable list or auto-detect monitored repos

```bash
# Option 1: From config
MONITOR_REPOS="${MONITOR_REPOS:-guide embabel-agent}"

# Option 2: Auto-detect from cloned repos
MONITOR_REPOS=$(find "$BASE_DIR" -maxdepth 1 -type d -name "*" | \
    xargs -I {} basename {} | grep -v "^\." | head -10)
```

### 2.2 `safety-checks.sh`

**Current**: Hardcoded `jmjava` username check

**Change to**: Use `$YOUR_GITHUB_USER` variable

```bash
# Old:
if [[ "$origin_url" == *"embabel/"* ]] && [[ "$origin_url" != *"jmjava"* ]]; then

# New:
if [[ "$origin_url" == *"${UPSTREAM_ORG}/"* ]] && [[ "$origin_url" != *"${YOUR_GITHUB_USER}"* ]]; then
```

### 2.3 `setup-aliases.sh`

**Current**: Hardcoded paths and repo-specific aliases (`eguide`, `eagent`)

**Change to**: Generate aliases dynamically or make them configurable

```bash
# Generate repo aliases dynamically
for repo in $MONITOR_REPOS; do
    alias "e${repo//-/_}"="cd $BASE_DIR/$repo"
done
```

### 2.4 All Scripts with `gh repo list "$EMBABEL_ORG"`

**Current**: Hardcoded `"embabel"`

**Change to**: Use `"$UPSTREAM_ORG"`

**Affected Files**:
- `list-embabel-repos.sh` - Line 24
- `fork-all-embabel.sh` - Line 23
- `get-embabel-summary.sh` - Multiple lines

## 3. Documentation Updates

### 3.1 `README.md`

**Changes needed**:
- Replace "embabel" with "upstream organization" or use variable references
- Replace "jmjava" with "your-username" or `$YOUR_GITHUB_USER`
- Replace `~/github/jmjava` with `$BASE_DIR`
- Update all example commands to use configuration
- Add setup section for configuration

**Sections to update**:
- Quick Start (lines 28-30)
- Usage Examples (lines 195-249)
- Learning Resources (lines 268-269)
- Troubleshooting (lines 712)
- All path references

### 3.2 `SETUP-ALIASES-NOW.sh`

**Current**: Hardcoded paths

**Change to**: Source config.sh first

### 3.3 `docs/EMBABEL-WORKFLOW.md`

**Changes needed**:
- Replace all `~/github/jmjava` references
- Replace "embabel" with generic organization references
- Update all path examples

### 3.4 Archive Files

The following files in `archive/` contain personal references but are less critical:
- `QUICKSTART.md`
- `PR-REVIEW-GUIDE.md`
- `CONTRIBUTION-TOOLS-ADDED.md`
- `CATCH-UP-SUMMARY.md`

**Action**: Consider making these templates with placeholders, or mark as "examples for jmjava"

### 3.5 `notes/` Directory

**Current**: Contains personal notes and contributions

**Action**:
- Keep as-is (these are personal)
- Consider adding to `.gitignore` or moving to a separate repo
- Or create template structure: `notes/templates/` vs `notes/personal/`

## 4. Directory Structure Changes

### 4.1 Workspace Name

**Current**: `embabel-learning`, `embabel-workspace.code-workspace`

**Option 1**: Make it configurable via `WORKSPACE_NAME` variable
**Option 2**: Rename to generic `organization-learning` template
**Option 3**: Keep as `embabel-learning` but make all references configurable

**Recommendation**: Option 1 - keep name, make references configurable

### 4.2 Base Directory

**Current**: Hardcoded `~/github/jmjava`

**Change to**: Use `$BASE_DIR` from config, default to `~/github/${YOUR_GITHUB_USER}`

## 5. Naming Conventions

### 5.1 Script Names

**Current**: Many scripts have "embabel" in name:
- `monitor-embabel.sh`
- `fork-all-embabel.sh`
- `clone-embabel-repos.sh`
- `list-embabel-repos.sh`
- `get-embabel-summary.sh`

**Options**:
1. **Keep names, make internals generic** (recommended - easier migration)
2. Rename all scripts (breaking change, harder)
3. Create generic versions with different names

**Recommendation**: Option 1 - keep script names for backward compatibility, make internals generic

### 5.2 Variable Names in Scripts

**Current**: Variables like `EMBABEL_ORG`, `ALL_EMBABEL_REPOS`

**Change to**: Generic names:
- `UPSTREAM_ORG` instead of `EMBABEL_ORG`
- `ALL_REPOS` instead of `ALL_EMBABEL_REPOS`
- `YOUR_USER` instead of hardcoded `jmjava`

## 6. Implementation Strategy

### Phase 1: Create Configuration System

1. Create `config.sh.example` template
2. Create `config.sh` loader in all scripts
3. Add validation/error handling for missing config

### Phase 2: Update Core Scripts

Priority order:
1. `safety-checks.sh` (used by many scripts)
2. `list-embabel-repos.sh` (foundation script)
3. `fork-all-embabel.sh`, `clone-embabel-repos.sh` (setup scripts)
4. `monitor-embabel.sh` (daily use)
5. `sync-upstream.sh`, `reset-to-upstream.sh` (sync scripts)

### Phase 3: Update Secondary Scripts

Update all other scripts to use configuration variables

### Phase 4: Update Documentation

1. Update `README.md` with configuration instructions
2. Create `CONFIGURATION.md` guide
3. Update all path references in docs
4. Add examples for different organizations

### Phase 5: Testing & Validation

1. Test with different GitHub usernames
2. Test with different organizations
3. Validate all scripts work correctly
4. Update `.gitignore` if needed

## 7. Configuration File Template

Create `config.sh.example`:

```bash
#!/bin/bash
# Configuration for organization-learning workspace
# Copy this file to config.sh and customize for your setup

# Your GitHub username
export YOUR_GITHUB_USER="your-username"

# The organization you want to monitor/contribute to
export UPSTREAM_ORG="organization-name"

# Base directory where you clone repositories
# Default: ~/github/${YOUR_GITHUB_USER}
export BASE_DIR="${HOME}/github/${YOUR_GITHUB_USER}"

# This workspace directory (embabel-learning or your custom name)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LEARNING_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Optional: Specific repositories to monitor in monitor script
# Space-separated list, or leave empty to auto-detect from cloned repos
export MONITOR_REPOS="repo1 repo2 repo3"

# Optional: Workspace name for Cursor/VS Code workspace file
export WORKSPACE_NAME="${UPSTREAM_ORG}-workspace"
```

## 8. Migration Guide for New Users

Create `MIGRATION-GUIDE.md`:

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/organization-learning.git
   cd organization-learning
   ```

2. **Configure for your setup**
   ```bash
   cp config.sh.example config.sh
   # Edit config.sh with your values
   nano config.sh  # or use your preferred editor
   ```

3. **Source the configuration**
   ```bash
   source config.sh
   ```

4. **Set up aliases**
   ```bash
   ./scripts/setup-aliases.sh
   source ~/.bash_aliases
   ```

5. **Start using the tools**
   ```bash
   elist  # List repos in your organization
   efork  # Fork all repos
   ```

## 9. Backward Compatibility

To maintain backward compatibility for existing users:

1. **Default values**: Scripts should work without `config.sh` using sensible defaults
2. **Fallback logic**: If config not found, use hardcoded "embabel" and "jmjava" as defaults
3. **Warning message**: Print warning if using defaults, suggest creating config.sh

Example:
```bash
if [ ! -f "$LEARNING_DIR/config.sh" ]; then
    echo "Warning: config.sh not found. Using defaults (embabel/jmjava)"
    echo "Create config.sh from config.sh.example to customize"
    YOUR_GITHUB_USER="${YOUR_GITHUB_USER:-jmjava}"
    UPSTREAM_ORG="${UPSTREAM_ORG:-embabel}"
    BASE_DIR="${BASE_DIR:-$HOME/github/jmjava}"
fi
```

## 10. Files That Can Stay As-Is

These are personal/example files that don't need generalization:
- `notes/my-contributions/` - Personal contribution tracking
- `notes/session-notes/2026-01-03/` - Personal session notes
- `archive/` - Historical/example files
- `scratch/` - Temporary files
- `.gitignore` - Already generic

**Recommendation**: Keep personal notes but add to `.gitignore` or separate them into `personal/` directory

## 11. Checklist for Making It Generic

- [ ] Create `config.sh.example` template
- [ ] Create config loader utility function
- [ ] Update all scripts to source config
- [ ] Replace all hardcoded `jmjava` with `$YOUR_GITHUB_USER`
- [ ] Replace all hardcoded `embabel` with `$UPSTREAM_ORG`
- [ ] Replace all hardcoded paths with `$BASE_DIR` or `$LEARNING_DIR`
- [ ] Update `monitor-embabel.sh` to use configurable repo list
- [ ] Update `safety-checks.sh` to use variables
- [ ] Update `setup-aliases.sh` to generate aliases dynamically
- [ ] Update `README.md` with configuration instructions
- [ ] Create `CONFIGURATION.md` guide
- [ ] Update all documentation files
- [ ] Add backward compatibility fallbacks
- [ ] Test with different usernames/organizations
- [ ] Create `MIGRATION-GUIDE.md` for new users
- [ ] Update `.gitignore` if needed for personal files

## 12. Estimated Effort

- **Configuration system**: 2-4 hours
- **Core scripts update**: 4-6 hours  
- **Secondary scripts update**: 3-4 hours
- **Documentation updates**: 2-3 hours
- **Testing & validation**: 2-3 hours

**Total**: ~15-20 hours of focused work

## 13. Quick Start for New Users (After Generalization)

```bash
# 1. Clone
git clone https://github.com/your-username/org-learning.git
cd org-learning

# 2. Configure
cp config.sh.example config.sh
# Edit config.sh with YOUR_GITHUB_USER and UPSTREAM_ORG

# 3. Setup
source config.sh
./scripts/setup-aliases.sh
source ~/.bash_aliases

# 4. Use
elist    # See all repos
efork    # Fork them
eclone   # Clone your forks
em       # Monitor daily
```
