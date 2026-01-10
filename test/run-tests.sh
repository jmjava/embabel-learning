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
    chmod +x "$test_file" 2>/dev/null
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Running: $(basename "$test_file")${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Run tests in a subshell and capture output with test counts
    # Use grep to extract actual test results from output
    test_output=$(bash "$test_file" 2>&1)
    test_exit_code=$?
    
    # Display the test output
    echo "$test_output"
    
    # Extract counts from the test output
    # Strip ANSI color codes, then find the FIRST summary (before any duplicates)
    clean_output=$(echo "$test_output" | sed 's/\x1b\[[0-9;]*m//g')
    
    # Find the summary section (between "Test Summary" headers)
    summary_section=$(echo "$clean_output" | sed -n '/Test Summary/,/Test Summary/p' | head -10)
    
    # Extract numbers from summary section
    file_tests=$(echo "$summary_section" | grep "Total tests:" | head -1 | grep -oE '[0-9]+' | head -1 || echo "0")
    file_passed=$(echo "$summary_section" | grep "^Passed:" | head -1 | grep -oE '[0-9]+' | head -1 || echo "0")
    file_failed=$(echo "$summary_section" | grep "^Failed:" | head -1 | grep -oE '[0-9]+' | head -1 || echo "0")
    
    # Fallback: if no summary found, count test results directly from output
    if [ "$file_tests" = "0" ] && [ -n "$test_output" ]; then
        # Count actual test runs (lines with "Running: test")
        file_tests=$(echo "$test_output" | grep -c "Running: test" || echo "0")
        # Count passed (green checkmarks)
        file_passed=$(echo "$test_output" | grep -c "✓" || echo "0")
        # Count failed (red X marks)
        file_failed=$(echo "$test_output" | grep -c "✗" || echo "0")
    fi
    
    # Final safety check - ensure we have valid numbers
    file_tests=${file_tests:-0}
    file_passed=${file_passed:-0}
    file_failed=${file_failed:-0}
    
    # Convert to base 10 explicitly
    file_tests=$((10#$file_tests))
    file_passed=$((10#$file_passed))
    file_failed=$((10#$file_failed))
    
    # Aggregate results
    TOTAL_TESTS=$((TOTAL_TESTS + file_tests))
    TOTAL_PASSED=$((TOTAL_PASSED + file_passed))
    TOTAL_FAILED=$((TOTAL_FAILED + file_failed))
    
    # Check if any tests failed for this file
    if [ "$file_failed" -gt 0 ]; then
        FAILED_FILES+=("$test_file")
    fi
    
    # Print file summary
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}File Summary: $(basename "$test_file")${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Tests:  $file_tests | ${GREEN}Passed: $file_passed${NC} | ${RED}Failed: $file_failed${NC}"
    echo ""
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
    if [ $TOTAL_TESTS -gt 0 ]; then
        echo -e "${GREEN}All tests passed! ✓${NC}"
        exit 0
    else
        echo -e "${RED}⚠️  ERROR: No tests were executed!${NC}"
        exit 1
    fi
fi
