# Test Architecture Documentation

This document explains how the test suite is structured and how to write tests that properly integrate with the configuration system.

## Overview

The test suite uses a self-contained test framework (`helpers/test-framework.sh`) that provides assertion functions and test running infrastructure. All tests should use the configuration system (`config-loader.sh`) rather than hardcoding values.

## Key Principles

### 1. **Never Hardcode Configuration Values**

❌ **BAD:**
```bash
export UPSTREAM_ORG="testorg"
export YOUR_GITHUB_USER="testuser"
```

✅ **GOOD:**
```bash
# Load config via config-loader
export LEARNING_DIR="$TEST_ROOT"
source "$SCRIPTS_DIR/config-loader.sh"
# Now use ${UPSTREAM_ORG} and ${YOUR_GITHUB_USER} from config
```

### 2. **Use Configuration System**

All tests should load configuration through `config-loader.sh`, which:
- Loads from `.env` file (if present)
- Falls back to `config.sh` (if present)
- Uses defaults if neither exists
- Respects `TEST_UPSTREAM_ORG` when `TEST_MODE=true`

### 3. **Respect TEST_UPSTREAM_ORG**

The configuration system has special handling for tests:

```bash
# In config-loader.sh
if [ -n "${TEST_UPSTREAM_ORG:-}" ] && [ "${TEST_MODE:-false}" = "true" ]; then
    UPSTREAM_ORG="$TEST_UPSTREAM_ORG"
fi
```

- `TEST_MODE=true` is set by `run-tests.sh`
- If `TEST_UPSTREAM_ORG` is set in `.env`, it will be used (safer for testing)
- If not set, tests use `UPSTREAM_ORG` from config file
- **Don't unset `TEST_UPSTREAM_ORG` unless testing config file loading specifically**

## Test Framework Structure

```
test/
├── helpers/
│   └── test-framework.sh    # Test framework (assertions, runner)
├── unit/
│   ├── test-config-loader.sh
│   ├── test-safety-checks.sh
│   └── test-sync-discord.sh
├── run-tests.sh             # Main test runner
└── ARCHITECTURE.md          # This file
```

## Writing New Tests

### Basic Test File Structure

```bash
#!/bin/bash
# Unit tests for your-script.sh

# Load test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_FRAMEWORK="$SCRIPT_DIR/../helpers/test-framework.sh"
source "$TEST_FRAMEWORK"

# Test directory setup
TEST_ROOT="/tmp/embabel-learning-test-$$"
LEARNING_DIR="$TEST_ROOT"
SCRIPTS_DIR="$LEARNING_DIR/scripts"

setUp() {
    # Create test directory structure
    mkdir -p "$SCRIPTS_DIR"

    # Copy actual scripts to test location
    local actual_scripts_dir="$(cd "$SCRIPT_DIR/../../scripts" && pwd)"
    cp "$actual_scripts_dir/your-script.sh" "$SCRIPTS_DIR/"
    cp "$actual_scripts_dir/config-loader.sh" "$SCRIPTS_DIR/"

    # Create test config file
    mkdir -p "$LEARNING_DIR"
    cat > "$LEARNING_DIR/config.sh" << 'EOF'
YOUR_GITHUB_USER="testuser"
UPSTREAM_ORG="testorg"
BASE_DIR="/tmp/test-repos"
EOF

    # Unset variables to ensure clean state
    unset YOUR_GITHUB_USER
    unset UPSTREAM_ORG
    unset BASE_DIR
    export LEARNING_DIR="$TEST_ROOT"
}

tearDown() {
    # Cleanup
    rm -rf "$TEST_ROOT"
    unset YOUR_GITHUB_USER
    unset UPSTREAM_ORG
    unset BASE_DIR
    unset LEARNING_DIR
}

testYourFunction() {
    # Load config properly
    export LEARNING_DIR="$TEST_ROOT"
    source "$SCRIPTS_DIR/config-loader.sh" 2>/dev/null

    # Use variables from config (not hardcoded!)
    assertContains "${UPSTREAM_ORG}" "testorg" "Should use UPSTREAM_ORG from config"
    assertContains "${YOUR_GITHUB_USER}" "testuser" "Should use YOUR_GITHUB_USER from config"
}

# Run tests if executed directly
if [ "${0##*/}" = "test-your-script.sh" ] && [ "${RUNNING_TESTS:-false}" != "true" ]; then
    resetCounters
    runTests "$0"
fi
```

## Configuration Loading in Tests

### Standard Pattern

```bash
# 1. Set LEARNING_DIR to test directory
export LEARNING_DIR="$TEST_ROOT"

# 2. Source config-loader (it will find config.sh in LEARNING_DIR)
source "$SCRIPTS_DIR/config-loader.sh" 2>/dev/null

# 3. Use variables from config
echo "Testing with UPSTREAM_ORG=${UPSTREAM_ORG}"
echo "Testing with YOUR_GITHUB_USER=${YOUR_GITHUB_USER}"
```

### When Testing Config File Loading

If you need to test that config files are loaded correctly (without TEST_UPSTREAM_ORG override):

```bash
# Only for tests that specifically test config file loading
unset TEST_UPSTREAM_ORG
export TEST_MODE=false
source "$SCRIPTS_DIR/config-loader.sh"
```

**Note:** This should only be done in tests that specifically validate config file loading behavior.

## Test Organization Parameters

### TEST_UPSTREAM_ORG

- **Purpose:** Use a different organization for testing (safer than using production org)
- **Location:** Set in `.env` file
- **Usage:** Automatically used when `TEST_MODE=true` (set by `run-tests.sh`)
- **Example:** `TEST_UPSTREAM_ORG=menkelabs` (your test org)

### TEST_MODE

- **Purpose:** Indicates we're in test mode
- **Set by:** `run-tests.sh` automatically sets `TEST_MODE=true`
- **Effect:** Enables `TEST_UPSTREAM_ORG` override if set

## Helper Functions Pattern

When creating helper functions that load scripts:

```bash
load_your_script() {
    local scripts_source_dir="$(cd "$SCRIPT_DIR/../../scripts" && pwd)"

    # Set environment for config-loader
    export LEARNING_DIR="$TEST_ROOT"
    # Don't set defaults - let config-loader load from config file

    # Load config-loader first
    if [ -f "$scripts_source_dir/config-loader.sh" ]; then
        export SCRIPT_DIR="$(dirname "$scripts_source_dir/config-loader.sh")"
        # TEST_MODE is already set to true by run-tests.sh
        # If TEST_UPSTREAM_ORG is set, config-loader will use it
        source "$scripts_source_dir/config-loader.sh" 2>/dev/null || true
    fi

    # Variables are now loaded from config file via config-loader
    # If TEST_UPSTREAM_ORG is set, it will override UPSTREAM_ORG

    # Now load your script
    if [ -f "$scripts_source_dir/your-script.sh" ]; then
        export SCRIPT_DIR="$scripts_source_dir"
        source "$scripts_source_dir/your-script.sh" 2>/dev/null || true
    fi
}
```

## Common Mistakes to Avoid

### ❌ Hardcoding Values

```bash
# DON'T DO THIS
export UPSTREAM_ORG="testorg"
export YOUR_GITHUB_USER="testuser"
```

### ❌ Unsetting TEST_UPSTREAM_ORG Unnecessarily

```bash
# DON'T DO THIS (unless testing config file loading specifically)
unset TEST_UPSTREAM_ORG
export TEST_MODE=false
```

### ❌ Setting Variables Before Loading Config

```bash
# DON'T DO THIS
export UPSTREAM_ORG="testorg"  # This overrides config!
source "$SCRIPTS_DIR/config-loader.sh"
```

### ✅ Correct Pattern

```bash
# DO THIS
export LEARNING_DIR="$TEST_ROOT"
source "$SCRIPTS_DIR/config-loader.sh"
# Now use ${UPSTREAM_ORG} and ${YOUR_GITHUB_USER} from config
```

## Test Framework Functions

### Assertions

- `assertTrue "message" command` - Asserts command succeeds
- `assertFalse "message" command` - Asserts command fails
- `assertEquals expected actual "message"` - Asserts equality
- `assertNotEquals expected actual "message"` - Asserts inequality
- `assertContains haystack needle "message"` - Asserts substring exists
- `assertNotContains haystack needle "message"` - Asserts substring doesn't exist
- `assertFileExists file "message"` - Asserts file exists
- `assertFileNotExists file "message"` - Asserts file doesn't exist
- `assertDirectoryExists dir "message"` - Asserts directory exists

### Test Lifecycle

- `setUp()` - Called before each test function
- `tearDown()` - Called after each test function
- `runTests "$0"` - Runs all test functions in the file

## Running Tests

### Run All Tests

```bash
cd test
./run-tests.sh
```

### Run Individual Test File

```bash
cd test/unit
bash test-your-script.sh
```

### Test Environment

- Tests use temporary directories (`/tmp/embabel-learning-test-*`)
- Each test file runs in its own subshell
- Test directories are cleaned up automatically in `tearDown()`

## Configuration File Priority

When `config-loader.sh` runs, it checks in this order:

1. `.env` file in `LEARNING_DIR` (highest priority)
2. `config.sh` file in `LEARNING_DIR`
3. Defaults (lowest priority)

**In test mode:**
- If `TEST_UPSTREAM_ORG` is set and `TEST_MODE=true`, it overrides `UPSTREAM_ORG` from any source

## Examples

### Example 1: Testing Script That Uses Config

```bash
testScriptUsesConfig() {
    # Set up test environment
    export LEARNING_DIR="$TEST_ROOT"

    # Load config
    source "$SCRIPTS_DIR/config-loader.sh" 2>/dev/null

    # Test that script uses config values
    local output=$(bash "$SCRIPTS_DIR/your-script.sh" 2>&1)
    assertContains "$output" "${UPSTREAM_ORG}" "Script should use UPSTREAM_ORG from config"
}
```

### Example 2: Testing With Git Repos

```bash
testGitOperation() {
    test_repo="$TEST_ROOT/test-repo-$$"
    mkdir -p "$test_repo"
    cd "$test_repo" || return 1

    git init --quiet

    # Load config first to get UPSTREAM_ORG
    load_safety_checks  # Helper that loads config + safety-checks

    # Use config values (not hardcoded!)
    git remote add origin "git@github.com:${UPSTREAM_ORG}/repo.git"

    # Test...
}
```

## Summary

1. **Always use `config-loader.sh`** - Never hardcode configuration values
2. **Respect `TEST_UPSTREAM_ORG`** - It's there for a reason (safer testing)
3. **Load config before using variables** - Set `LEARNING_DIR`, then source config-loader
4. **Use variables from config** - Reference `${UPSTREAM_ORG}`, `${YOUR_GITHUB_USER}`, etc.
5. **Only disable TEST_UPSTREAM_ORG** when specifically testing config file loading

Following these patterns ensures tests are maintainable and properly integrated with the configuration system.
