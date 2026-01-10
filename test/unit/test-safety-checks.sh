#!/bin/bash
# Unit tests for safety-checks.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_FRAMEWORK="$SCRIPT_DIR/../helpers/test-framework.sh"
source "$TEST_FRAMEWORK"

TEST_ROOT="/tmp/embabel-learning-test-$$"
SCRIPTS_DIR="$TEST_ROOT/scripts"
SAFETY_CHECKS="$SCRIPTS_DIR/safety-checks.sh"

setUp() {
    mkdir -p "$SCRIPTS_DIR"

    # Get absolute path to actual scripts directory
    local actual_scripts_dir="$(cd "$SCRIPT_DIR/../../scripts" 2>/dev/null && pwd || echo "")"

    if [ -z "$actual_scripts_dir" ] || [ ! -d "$actual_scripts_dir" ]; then
        # Fallback: try relative path
        actual_scripts_dir="$(dirname "$SCRIPT_DIR")/../scripts"
        actual_scripts_dir="$(cd "$actual_scripts_dir" 2>/dev/null && pwd || echo "")"
    fi

    # Store actual scripts dir for use in tests
    export ACTUAL_SCRIPTS_DIR="$actual_scripts_dir"

    # Copy scripts to test location (they need to be together for safety-checks.sh to find config-loader.sh)
    if [ -n "$actual_scripts_dir" ] && [ -d "$actual_scripts_dir" ]; then
        cp "$actual_scripts_dir/config-loader.sh" "$SCRIPTS_DIR/" 2>/dev/null || true
        cp "$actual_scripts_dir/safety-checks.sh" "$SCRIPTS_DIR/" 2>/dev/null || true
    fi

    # Create a minimal config for testing
    mkdir -p "$TEST_ROOT"
    cat > "$TEST_ROOT/config.sh" << 'EOF'
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
    rm -rf "$TEST_ROOT"
    unset YOUR_GITHUB_USER
    unset UPSTREAM_ORG
    unset BASE_DIR
    unset LEARNING_DIR
}

# Helper function to load safety-checks functions into current shell
load_safety_checks() {
    # Use actual scripts directory (not copied ones) for more reliable loading
    local scripts_source_dir="${ACTUAL_SCRIPTS_DIR:-$(cd "$SCRIPT_DIR/../../scripts" 2>/dev/null && pwd || echo "")}"

    if [ -z "$scripts_source_dir" ] || [ ! -d "$scripts_source_dir" ]; then
        # Fallback to copied scripts
        scripts_source_dir="$SCRIPTS_DIR"
    fi

    # Set environment for config-loader
    export LEARNING_DIR="$TEST_ROOT"
    export YOUR_GITHUB_USER="${YOUR_GITHUB_USER:-testuser}"
    export UPSTREAM_ORG="${UPSTREAM_ORG:-testorg}"
    export BASE_DIR="${BASE_DIR:-/tmp/test-repos}"

    # Load config-loader first (it needs LEARNING_DIR set)
    if [ -f "$scripts_source_dir/config-loader.sh" ]; then
        # Temporarily set SCRIPT_DIR for config-loader if needed
        local old_script_dir="${SCRIPT_DIR:-}"
        export SCRIPT_DIR="$(dirname "$scripts_source_dir/config-loader.sh")"
        source "$scripts_source_dir/config-loader.sh" 2>/dev/null || {
            # Config-loader might fail, but continue anyway
            true
        }
        [ -n "$old_script_dir" ] && export SCRIPT_DIR="$old_script_dir" || unset SCRIPT_DIR
    fi

    # Ensure variables are set (either from config or defaults)
    export YOUR_GITHUB_USER="${YOUR_GITHUB_USER:-testuser}"
    export UPSTREAM_ORG="${UPSTREAM_ORG:-testorg}"

    # Now load safety-checks.sh - it will use SCRIPT_DIR to find config-loader if needed
    if [ -f "$scripts_source_dir/safety-checks.sh" ]; then
        # Set SCRIPT_DIR so safety-checks.sh can find config-loader.sh in same directory
        export SCRIPT_DIR="$scripts_source_dir"
        # Source directly - functions will be available in current shell
        source "$scripts_source_dir/safety-checks.sh" 2>/dev/null || {
            # If sourcing fails, try with explicit SCRIPT_DIR
            export SCRIPT_DIR="$(cd "$(dirname "$scripts_source_dir/safety-checks.sh")" 2>/dev/null && pwd || echo "$scripts_source_dir")"
            source "$scripts_source_dir/safety-checks.sh" 2>/dev/null || true
        }
    fi
}

testBlockUpstreamCommit() {
    # Test blocking commits when origin points to upstream org
    test_repo="$TEST_ROOT/test-repo-block-$$"
    rm -rf "$test_repo"
    mkdir -p "$test_repo"
    cd "$test_repo" || return 1

    git init --quiet
    git remote add origin "git@github.com:testorg/repo.git" 2>/dev/null || git remote set-url origin "git@github.com:testorg/repo.git"

    # Load safety checks using helper
    load_safety_checks

    # Verify function exists
    if ! type block_upstream_commit >/dev/null 2>&1; then
        assertTrue "block_upstream_commit function should exist after sourcing safety-checks.sh" false
        return
    fi

    # Should block commit (return non-zero)
    block_upstream_commit >/dev/null 2>&1
    result=$?
    assertTrue "Should block commit to upstream org" [ $result -ne 0 ]
}

testAllowForkCommit() {
    # Test allowing commits when origin points to user's fork
    test_repo="$TEST_ROOT/test-repo-allow-$$"
    rm -rf "$test_repo"
    mkdir -p "$test_repo"
    cd "$test_repo" || return 1

    git init --quiet
    git remote add origin "git@github.com:testuser/repo.git" 2>/dev/null || git remote set-url origin "git@github.com:testuser/repo.git"

    # Load safety checks using helper
    load_safety_checks

    # Verify function exists
    if ! type block_upstream_commit >/dev/null 2>&1; then
        assertTrue "block_upstream_commit function should exist" false
        return
    fi

    # Should allow commit (return zero)
    block_upstream_commit >/dev/null 2>&1
    result=$?
    assertTrue "Should allow commit to user's fork" [ $result -eq 0 ]
}

testBlockUpstreamPush() {
    # Test blocking pushes to upstream org
    test_repo="$TEST_ROOT/test-repo-push-block-$$"
    rm -rf "$test_repo"
    mkdir -p "$test_repo"
    cd "$test_repo" || return 1

    git init --quiet
    git remote add origin "git@github.com:testorg/repo.git" 2>/dev/null || git remote set-url origin "git@github.com:testorg/repo.git"

    # Load safety checks using helper
    load_safety_checks

    # Verify function exists
    if ! type block_upstream_push >/dev/null 2>&1; then
        assertTrue "block_upstream_push function should exist" false
        return
    fi

    # Should block push (return non-zero)
    block_upstream_push "origin" >/dev/null 2>&1
    result=$?
    assertTrue "Should block push to upstream org" [ $result -ne 0 ]
}

testAllowForkPush() {
    # Test allowing pushes to user's fork
    test_repo="$TEST_ROOT/test-repo-push-allow-$$"
    rm -rf "$test_repo"
    mkdir -p "$test_repo"
    cd "$test_repo" || return 1

    git init --quiet
    git remote add origin "git@github.com:testuser/repo.git" 2>/dev/null || git remote set-url origin "git@github.com:testuser/repo.git"

    # Load safety checks using helper
    load_safety_checks

    # Verify function exists
    if ! type block_upstream_push >/dev/null 2>&1; then
        assertTrue "block_upstream_push function should exist" false
        return
    fi

    # Should allow push (return zero)
    block_upstream_push "origin" >/dev/null 2>&1
    result=$?
    assertTrue "Should allow push to user's fork" [ $result -eq 0 ]
}

testCheckUpstreamRepo() {
    # Test detecting upstream org repos
    test_repo="$TEST_ROOT/testorg-repo-$$"
    rm -rf "$test_repo"
    mkdir -p "$test_repo"
    cd "$test_repo" || return 1

    git init --quiet
    git remote add origin "git@github.com:testorg/repo.git" 2>/dev/null || git remote set-url origin "git@github.com:testorg/repo.git"

    # Load safety checks using helper
    load_safety_checks

    # Verify function exists
    if ! type check_upstream_repo >/dev/null 2>&1; then
        assertTrue "check_upstream_repo function should exist" false
        return
    fi

    # Should detect upstream org repo (return zero)
    check_upstream_repo >/dev/null 2>&1
    result=$?
    assertTrue "Should detect upstream org repo" [ $result -eq 0 ]
}

testCheckUserRepo() {
    # Test that user's repos are not flagged
    test_repo="$TEST_ROOT/testuser-repo-$$"
    rm -rf "$test_repo"
    mkdir -p "$test_repo"
    cd "$test_repo" || return 1

    git init --quiet
    git remote add origin "git@github.com:testuser/repo.git" 2>/dev/null || git remote set-url origin "git@github.com:testuser/repo.git"

    # Load safety checks using helper
    load_safety_checks

    # Verify function exists
    if ! type check_upstream_repo >/dev/null 2>&1; then
        assertTrue "check_upstream_repo function should exist" false
        return
    fi

    # Should NOT flag user's repo (return non-zero)
    check_upstream_repo >/dev/null 2>&1
    result=$?
    assertTrue "Should not flag user's repo" [ $result -ne 0 ]
}

# Run tests if executed directly (not sourced)
if [ "${0##*/}" = "test-safety-checks.sh" ] || [ "$(basename "$0" 2>/dev/null)" = "test-safety-checks.sh" ]; then
    # Only run if not already running via run-tests.sh
    if [ "${SKIP_AUTO_RUN:-false}" != "true" ]; then
        # Source framework first
        source "$TEST_FRAMEWORK"
        resetCounters

        # Extract and run test functions
        test_functions=$(grep -E '^test[A-Za-z_][A-Za-z0-9_]*\(' "$0" | sed 's/(.*$//' | sort)

        echo -e "${BLUE}Running tests from: $(basename "$0")${NC}"
        echo ""

        for test_func in $test_functions; do
            if ! type "$test_func" >/dev/null 2>&1; then
                continue
            fi
            echo -e "${YELLOW}Running: $test_func${NC}"
            setUp
            "$test_func" || true
            tearDown
            echo ""
        done

        # Print summary
        printSummary
    fi
fi
