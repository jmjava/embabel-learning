#!/bin/bash
# Test runner for all unit and integration tests

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_FRAMEWORK="$SCRIPT_DIR/helpers/test-framework.sh"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Running Test Suite${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Track overall results
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0
FAILED_FILES=()

# Find and run all test files
TEST_FILES=(
    "$SCRIPT_DIR/unit/test-config-loader.sh"
    "$SCRIPT_DIR/unit/test-safety-checks.sh"
)

for test_file in "${TEST_FILES[@]}"; do
    if [ ! -f "$test_file" ]; then
        echo -e "${YELLOW}⚠️  Test file not found: $test_file${NC}"
        continue
    fi
    
    # Make executable
    chmod +x "$test_file"
    
    # Source test framework for each test file
    source "$TEST_FRAMEWORK"
    
    # Reset counters before running this test file
    resetCounters
    
    # Extract test functions and run them
    # Use a subshell to avoid variable pollution
    (
        source "$TEST_FRAMEWORK"
        source "$test_file"
        
        # Get test functions from the file
        test_functions=$(grep -E '^test[A-Za-z_][A-Za-z0-9_]*\(' "$test_file" | sed 's/(.*$//' | sort)
        
        echo -e "${BLUE}Running tests from: $(basename "$test_file")${NC}"
        echo ""
        
        # Run each test function
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
        
        # Print summary for this file
        printSummary >&1
    )
    
    # Aggregate results (these are in the parent shell's scope)
    TOTAL_TESTS=$((TOTAL_TESTS + TEST_COUNT))
    TOTAL_PASSED=$((TOTAL_PASSED + PASSED_COUNT))
    TOTAL_FAILED=$((TOTAL_FAILED + FAILED_COUNT))
    
    # Check if any tests failed
    if [ $FAILED_COUNT -gt 0 ]; then
        FAILED_FILES+=("$test_file")
    fi
    
    echo ""
done

# Print final summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Overall Test Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Total tests:  $TOTAL_TESTS"
echo -e "${GREEN}Passed:      $TOTAL_PASSED${NC}"

if [ $TOTAL_FAILED -gt 0 ]; then
    echo -e "${RED}Failed:      $TOTAL_FAILED${NC}"
    echo ""
    if [ ${#FAILED_FILES[@]} -gt 0 ]; then
        echo -e "${RED}Failed test files:${NC}"
        for failed_file in "${FAILED_FILES[@]}"; do
            echo -e "  ${RED}✗${NC} $(basename "$failed_file")"
        done
    fi
    exit 1
else
    echo -e "${GREEN}Failed:      0${NC}"
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
