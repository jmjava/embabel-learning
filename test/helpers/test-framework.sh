#!/bin/bash
# Simple test framework for shell scripts
# Inspired by shunit2 but self-contained

# Test statistics
TEST_COUNT=0
PASSED_COUNT=0
FAILED_COUNT=0
FAILED_TESTS=()

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test setup/teardown functions (override in test files)
setUp() { true; }
tearDown() { true; }

# Assert functions
assertTrue() {
    local message="$1"
    shift
    TEST_COUNT=$((TEST_COUNT + 1))

    if "$@" >/dev/null 2>&1; then
        PASSED_COUNT=$((PASSED_COUNT + 1))
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_TESTS+=("FAIL: $message")
        echo -e "${RED}✗${NC} $message"
        return 1
    fi
}

assertFalse() {
    local message="$1"
    shift
    TEST_COUNT=$((TEST_COUNT + 1))

    if ! "$@" >/dev/null 2>&1; then
        PASSED_COUNT=$((PASSED_COUNT + 1))
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_TESTS+=("FAIL: $message")
        echo -e "${RED}✗${NC} $message"
        return 1
    fi
}

assertEquals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"
    TEST_COUNT=$((TEST_COUNT + 1))

    if [ "$expected" = "$actual" ]; then
        PASSED_COUNT=$((PASSED_COUNT + 1))
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_TESTS+=("FAIL: $message (expected: '$expected', got: '$actual')")
        echo -e "${RED}✗${NC} $message"
        echo -e "  ${YELLOW}Expected:${NC} '$expected'"
        echo -e "  ${YELLOW}Got:${NC}      '$actual'"
        return 1
    fi
}

assertNotEquals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should not be equal}"
    TEST_COUNT=$((TEST_COUNT + 1))

    if [ "$expected" != "$actual" ]; then
        PASSED_COUNT=$((PASSED_COUNT + 1))
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_TESTS+=("FAIL: $message (both values: '$expected')")
        echo -e "${RED}✗${NC} $message"
        return 1
    fi
}

assertContains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain substring}"
    TEST_COUNT=$((TEST_COUNT + 1))

    if echo "$haystack" | grep -q "$needle"; then
        PASSED_COUNT=$((PASSED_COUNT + 1))
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_TESTS+=("FAIL: $message ('$haystack' should contain '$needle')")
        echo -e "${RED}✗${NC} $message"
        return 1
    fi
}

assertNotContains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should not contain substring}"
    TEST_COUNT=$((TEST_COUNT + 1))

    if ! echo "$haystack" | grep -q "$needle"; then
        PASSED_COUNT=$((PASSED_COUNT + 1))
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_TESTS+=("FAIL: $message ('$haystack' should not contain '$needle')")
        echo -e "${RED}✗${NC} $message"
        return 1
    fi
}

assertFileExists() {
    local file="$1"
    local message="${2:-File should exist}"
    TEST_COUNT=$((TEST_COUNT + 1))

    if [ -f "$file" ]; then
        PASSED_COUNT=$((PASSED_COUNT + 1))
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_TESTS+=("FAIL: $message (file: '$file')")
        echo -e "${RED}✗${NC} $message"
        return 1
    fi
}

assertFileNotExists() {
    local file="$1"
    local message="${2:-File should not exist}"
    TEST_COUNT=$((TEST_COUNT + 1))

    if [ ! -f "$file" ]; then
        PASSED_COUNT=$((PASSED_COUNT + 1))
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_TESTS+=("FAIL: $message (file: '$file')")
        echo -e "${RED}✗${NC} $message"
        return 1
    fi
}

assertDirectoryExists() {
    local dir="$1"
    local message="${2:-Directory should exist}"
    TEST_COUNT=$((TEST_COUNT + 1))

    if [ -d "$dir" ]; then
        PASSED_COUNT=$((PASSED_COUNT + 1))
        echo -e "${GREEN}✓${NC} $message"
        return 0
    else
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_TESTS+=("FAIL: $message (directory: '$dir')")
        echo -e "${RED}✗${NC} $message"
        return 1
    fi
}

# Test runner
runTests() {
    local test_file="$1"

    if [ ! -f "$test_file" ]; then
        echo -e "${RED}Error: Test file not found: $test_file${NC}" >&2
        return 1
    fi

    echo -e "${BLUE}Running tests from: $(basename "$test_file")${NC}"
    echo ""

    # Prevent infinite recursion by checking if we're already running tests
    if [ "${RUNNING_TESTS:-false}" = "true" ]; then
        return 0
    fi

    export RUNNING_TESTS=true

    # Extract test functions before sourcing (to avoid recursion)
    local test_functions=$(grep -E '^test[A-Za-z_][A-Za-z0-9_]*\(' "$test_file" | sed 's/(.*$//' | sort)

    # Reset counters for this test file
    local file_test_count=0
    local file_passed=0
    local file_failed=0

    # Source the test file in a subshell to avoid variable pollution
    (
        # Source test framework again to get fresh counters in subshell
        source "$TEST_FRAMEWORK" 2>/dev/null || true

        # Source the actual test file
        source "$test_file"

        # Run all test functions
        for test_func in $test_functions; do
            # Check if function exists
            if ! type "$test_func" >/dev/null 2>&1; then
                continue
            fi

            echo -e "${YELLOW}Running: $test_func${NC}"
            setUp
            "$test_func" || true  # Continue even if test fails
            tearDown
            echo ""
        done
    )

    unset RUNNING_TESTS

    # Note: The counters are updated by assertion functions which run in the subshell
    # The parent shell still has the original counters, which is what we want
}

# Print summary
printSummary() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Total tests:  $TEST_COUNT"
    echo -e "${GREEN}Passed:      $PASSED_COUNT${NC}"

    if [ $FAILED_COUNT -gt 0 ]; then
        echo -e "${RED}Failed:      $FAILED_COUNT${NC}"
        echo ""
        echo -e "${RED}Failed tests:${NC}"
        for failed in "${FAILED_TESTS[@]}"; do
            echo -e "  ${RED}✗${NC} $failed"
        done
        return 1
    else
        echo -e "${GREEN}Failed:      0${NC}"
        return 0
    fi
}

# Reset counters (useful when running multiple test files)
resetCounters() {
    TEST_COUNT=0
    PASSED_COUNT=0
    FAILED_COUNT=0
    FAILED_TESTS=()
}

# Cleanup function
cleanup() {
    printSummary
    exit $?
}

# Trap to run cleanup on exit
trap cleanup EXIT
