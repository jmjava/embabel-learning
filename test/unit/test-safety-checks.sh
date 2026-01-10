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
    
    # Copy scripts using absolute paths
    local actual_scripts_dir="$(cd "$SCRIPT_DIR/../../scripts" && pwd)"
    cp "$actual_scripts_dir/config-loader.sh" "$SCRIPTS_DIR/"
    cp "$actual_scripts_dir/safety-checks.sh" "$SCRIPTS_DIR/"
    
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
    local test_repo="$TEST_ROOT/test-repo"
    mkdir -p "$test_repo/.git"
    cd "$test_repo"
    
    git init --quiet
    git remote add origin "git@github.com:testorg/repo.git"
    
    # Load safety checks
    export LEARNING_DIR="$TEST_ROOT"
    source "$SCRIPTS_DIR/safety-checks.sh" >/dev/null 2>&1
    
    # Should block commit
    block_upstream_commit
    local result=$?
    
    assertTrue "Should block commit to upstream org" [ $result -ne 0 ]
}

testAllowForkCommit() {
    # Test allowing commits when origin points to user's fork
    local test_repo="$TEST_ROOT/test-repo"
    mkdir -p "$test_repo/.git"
    cd "$test_repo"
    
    git init --quiet
    git remote add origin "git@github.com:testuser/repo.git"
    
    export LEARNING_DIR="$TEST_ROOT"
    source "$SCRIPTS_DIR/safety-checks.sh" >/dev/null 2>&1
    
    # Should allow commit
    block_upstream_commit
    local result=$?
    
    assertTrue "Should allow commit to user's fork" [ $result -eq 0 ]
}

testBlockUpstreamPush() {
    # Test blocking pushes to upstream org
    local test_repo="$TEST_ROOT/test-repo"
    mkdir -p "$test_repo/.git"
    cd "$test_repo"
    
    git init --quiet
    git remote add origin "git@github.com:testorg/repo.git"
    
    export LEARNING_DIR="$TEST_ROOT"
    source "$SCRIPTS_DIR/safety-checks.sh" >/dev/null 2>&1
    
    block_upstream_push "origin"
    local result=$?
    
    assertTrue "Should block push to upstream org" [ $result -ne 0 ]
}

testAllowForkPush() {
    # Test allowing pushes to user's fork
    local test_repo="$TEST_ROOT/test-repo"
    mkdir -p "$test_repo/.git"
    cd "$test_repo"
    
    git init --quiet
    git remote add origin "git@github.com:testuser/repo.git"
    
    export LEARNING_DIR="$TEST_ROOT"
    source "$SCRIPTS_DIR/safety-checks.sh" >/dev/null 2>&1
    
    block_upstream_push "origin"
    local result=$?
    
    assertTrue "Should allow push to user's fork" [ $result -eq 0 ]
}

testCheckUpstreamRepo() {
    # Test detecting upstream org repos
    local test_repo="$TEST_ROOT/testorg-repo"
    mkdir -p "$test_repo/.git"
    cd "$test_repo"
    
    git init --quiet
    git remote add origin "git@github.com:testorg/repo.git"
    
    export LEARNING_DIR="$TEST_ROOT"
    source "$SCRIPTS_DIR/safety-checks.sh" >/dev/null 2>&1
    
    check_upstream_repo
    local result=$?
    
    assertTrue "Should detect upstream org repo" [ $result -eq 0 ]
}

testCheckUserRepo() {
    # Test that user's repos are not flagged
    local test_repo="$TEST_ROOT/testuser-repo"
    mkdir -p "$test_repo/.git"
    cd "$test_repo"
    
    git init --quiet
    git remote add origin "git@github.com:testuser/repo.git"
    
    export LEARNING_DIR="$TEST_ROOT"
    source "$SCRIPTS_DIR/safety-checks.sh" >/dev/null 2>&1
    
    check_upstream_repo
    local result=$?
    
    assertTrue "Should not flag user's repo" [ $result -ne 0 ]
}

# Only run tests if executed directly (not sourced)
if [ "${0##*/}" = "test-safety-checks.sh" ] && [ "${RUNNING_TESTS:-false}" != "true" ]; then
    resetCounters
    runTests "$0"
fi

