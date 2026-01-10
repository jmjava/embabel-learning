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
    
    # Get absolute path to actual scripts directory (without cd)
    local actual_scripts_dir="$(cd "$SCRIPT_DIR/../../scripts" 2>/dev/null && pwd || echo "$SCRIPT_DIR/../../scripts")"
    
    # If cd failed, try alternative path resolution
    if [ ! -d "$actual_scripts_dir" ] || [ ! -f "$actual_scripts_dir/config-loader.sh" ]; then
        # Try relative to test directory
        actual_scripts_dir="$(dirname "$SCRIPT_DIR")/../scripts"
        actual_scripts_dir="$(cd "$actual_scripts_dir" 2>/dev/null && pwd || echo "$actual_scripts_dir")"
    fi
    
    # Copy scripts to test location
    if [ -f "$actual_scripts_dir/config-loader.sh" ]; then
        cp "$actual_scripts_dir/config-loader.sh" "$SCRIPTS_DIR/" 2>/dev/null || true
    fi
    if [ -f "$actual_scripts_dir/safety-checks.sh" ]; then
        cp "$actual_scripts_dir/safety-checks.sh" "$SCRIPTS_DIR/" 2>/dev/null || true
    fi
    
    # Create a minimal config for testing
    mkdir -p "$TEST_ROOT"
    cat > "$TEST_ROOT/config.sh" << 'EOF'
YOUR_GITHUB_USER="testuser"
UPSTREAM_ORG="testorg"
BASE_DIR="/tmp/test-repos"
EOF
    
    # Unset variables
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

testBlockUpstreamCommit() {
    # Test blocking commits when origin points to upstream org
    test_repo="$TEST_ROOT/test-repo-block"
    rm -rf "$test_repo"
    mkdir -p "$test_repo"
    cd "$test_repo" || return 1
    
    git init --quiet
    git remote add origin "git@github.com:testorg/repo.git" 2>/dev/null || git remote set-url origin "git@github.com:testorg/repo.git"
    
    # Load safety checks
    export LEARNING_DIR="$TEST_ROOT"
    if [ -f "$SCRIPTS_DIR/safety-checks.sh" ]; then
        source "$SCRIPTS_DIR/safety-checks.sh" >/dev/null 2>&1
    else
        # Fallback: source from actual scripts directory
        actual_scripts_dir="$(cd "$SCRIPT_DIR/../../scripts" 2>/dev/null && pwd || echo "")"
        if [ -f "$actual_scripts_dir/safety-checks.sh" ]; then
            export SCRIPT_DIR="$actual_scripts_dir"
            source "$actual_scripts_dir/safety-checks.sh" >/dev/null 2>&1
        fi
    fi
    
    # Should block commit (function should exist and return non-zero)
    if type block_upstream_commit >/dev/null 2>&1; then
        block_upstream_commit 2>/dev/null
        result=$?
        assertTrue "Should block commit to upstream org" [ $result -ne 0 ]
    else
        assertTrue "block_upstream_commit function should exist" false
    fi
}

testAllowForkCommit() {
    # Test allowing commits when origin points to user's fork
    test_repo="$TEST_ROOT/test-repo-allow"
    rm -rf "$test_repo"
    mkdir -p "$test_repo"
    cd "$test_repo" || return 1
    
    git init --quiet
    git remote add origin "git@github.com:testuser/repo.git" 2>/dev/null || git remote set-url origin "git@github.com:testuser/repo.git"
    
    export LEARNING_DIR="$TEST_ROOT"
    if [ -f "$SCRIPTS_DIR/safety-checks.sh" ]; then
        source "$SCRIPTS_DIR/safety-checks.sh" >/dev/null 2>&1
    else
        actual_scripts_dir="$(cd "$SCRIPT_DIR/../../scripts" 2>/dev/null && pwd || echo "")"
        if [ -f "$actual_scripts_dir/safety-checks.sh" ]; then
            export SCRIPT_DIR="$actual_scripts_dir"
            source "$actual_scripts_dir/safety-checks.sh" >/dev/null 2>&1
        fi
    fi
    
    # Should allow commit
    if type block_upstream_commit >/dev/null 2>&1; then
        block_upstream_commit 2>/dev/null
        result=$?
        assertTrue "Should allow commit to user's fork" [ $result -eq 0 ]
    else
        assertTrue "block_upstream_commit function should exist" false
    fi
}

testBlockUpstreamPush() {
    # Test blocking pushes to upstream org
    test_repo="$TEST_ROOT/test-repo-push-block"
    rm -rf "$test_repo"
    mkdir -p "$test_repo"
    cd "$test_repo" || return 1
    
    git init --quiet
    git remote add origin "git@github.com:testorg/repo.git" 2>/dev/null || git remote set-url origin "git@github.com:testorg/repo.git"
    
    export LEARNING_DIR="$TEST_ROOT"
    if [ -f "$SCRIPTS_DIR/safety-checks.sh" ]; then
        source "$SCRIPTS_DIR/safety-checks.sh" >/dev/null 2>&1
    else
        actual_scripts_dir="$(cd "$SCRIPT_DIR/../../scripts" 2>/dev/null && pwd || echo "")"
        if [ -f "$actual_scripts_dir/safety-checks.sh" ]; then
            export SCRIPT_DIR="$actual_scripts_dir"
            source "$actual_scripts_dir/safety-checks.sh" >/dev/null 2>&1
        fi
    fi
    
    if type block_upstream_push >/dev/null 2>&1; then
        block_upstream_push "origin" 2>/dev/null
        result=$?
        assertTrue "Should block push to upstream org" [ $result -ne 0 ]
    else
        assertTrue "block_upstream_push function should exist" false
    fi
}

testAllowForkPush() {
    # Test allowing pushes to user's fork
    test_repo="$TEST_ROOT/test-repo-push-allow"
    rm -rf "$test_repo"
    mkdir -p "$test_repo"
    cd "$test_repo" || return 1
    
    git init --quiet
    git remote add origin "git@github.com:testuser/repo.git" 2>/dev/null || git remote set-url origin "git@github.com:testuser/repo.git"
    
    export LEARNING_DIR="$TEST_ROOT"
    if [ -f "$SCRIPTS_DIR/safety-checks.sh" ]; then
        source "$SCRIPTS_DIR/safety-checks.sh" >/dev/null 2>&1
    else
        actual_scripts_dir="$(cd "$SCRIPT_DIR/../../scripts" 2>/dev/null && pwd || echo "")"
        if [ -f "$actual_scripts_dir/safety-checks.sh" ]; then
            export SCRIPT_DIR="$actual_scripts_dir"
            source "$actual_scripts_dir/safety-checks.sh" >/dev/null 2>&1
        fi
    fi
    
    if type block_upstream_push >/dev/null 2>&1; then
        block_upstream_push "origin" 2>/dev/null
        result=$?
        assertTrue "Should allow push to user's fork" [ $result -eq 0 ]
    else
        assertTrue "block_upstream_push function should exist" false
    fi
}

testCheckUpstreamRepo() {
    # Test detecting upstream org repos
    test_repo="$TEST_ROOT/testorg-repo"
    rm -rf "$test_repo"
    mkdir -p "$test_repo"
    cd "$test_repo" || return 1
    
    git init --quiet
    git remote add origin "git@github.com:testorg/repo.git" 2>/dev/null || git remote set-url origin "git@github.com:testorg/repo.git"
    
    export LEARNING_DIR="$TEST_ROOT"
    if [ -f "$SCRIPTS_DIR/safety-checks.sh" ]; then
        source "$SCRIPTS_DIR/safety-checks.sh" >/dev/null 2>&1
    else
        actual_scripts_dir="$(cd "$SCRIPT_DIR/../../scripts" 2>/dev/null && pwd || echo "")"
        if [ -f "$actual_scripts_dir/safety-checks.sh" ]; then
            export SCRIPT_DIR="$actual_scripts_dir"
            source "$actual_scripts_dir/safety-checks.sh" >/dev/null 2>&1
        fi
    fi
    
    if type check_upstream_repo >/dev/null 2>&1; then
        check_upstream_repo 2>/dev/null
        result=$?
        assertTrue "Should detect upstream org repo" [ $result -eq 0 ]
    else
        assertTrue "check_upstream_repo function should exist" false
    fi
}

testCheckUserRepo() {
    # Test that user's repos are not flagged
    test_repo="$TEST_ROOT/testuser-repo"
    rm -rf "$test_repo"
    mkdir -p "$test_repo"
    cd "$test_repo" || return 1
    
    git init --quiet
    git remote add origin "git@github.com:testuser/repo.git" 2>/dev/null || git remote set-url origin "git@github.com:testuser/repo.git"
    
    export LEARNING_DIR="$TEST_ROOT"
    if [ -f "$SCRIPTS_DIR/safety-checks.sh" ]; then
        source "$SCRIPTS_DIR/safety-checks.sh" >/dev/null 2>&1
    else
        actual_scripts_dir="$(cd "$SCRIPT_DIR/../../scripts" 2>/dev/null && pwd || echo "")"
        if [ -f "$actual_scripts_dir/safety-checks.sh" ]; then
            export SCRIPT_DIR="$actual_scripts_dir"
            source "$actual_scripts_dir/safety-checks.sh" >/dev/null 2>&1
        fi
    fi
    
    if type check_upstream_repo >/dev/null 2>&1; then
        check_upstream_repo 2>/dev/null
        result=$?
        assertTrue "Should not flag user's repo" [ $result -ne 0 ]
    else
        assertTrue "check_upstream_repo function should exist" false
    fi
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

