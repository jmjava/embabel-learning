# Test Suite for embabel-learning Scripts

This directory contains unit and integration tests for the shell scripts in the `embabel-learning` workspace.

## Structure

```
test/
├── README.md                    # This file
├── run-tests.sh                 # Main test runner
├── helpers/
│   └── test-framework.sh       # Simple test framework (self-contained)
├── unit/
│   ├── test-config-loader.sh   # Tests for config-loader.sh
│   └── test-safety-checks.sh   # Tests for safety-checks.sh
└── integration/
    └── (future integration tests)
```

## Test Framework

We use a **self-contained, lightweight test framework** inspired by shunit2. No external dependencies required!

### Assertion Functions

- `assertTrue "message" command` - Asserts command succeeds
- `assertFalse "message" command` - Asserts command fails
- `assertEquals expected actual "message"` - Asserts equality
- `assertNotEquals expected actual "message"` - Asserts inequality
- `assertContains haystack needle "message"` - Asserts substring exists
- `assertNotContains haystack needle "message"` - Asserts substring doesn't exist
- `assertFileExists file "message"` - Asserts file exists
- `assertFileNotExists file "message"` - Asserts file doesn't exist
- `assertDirectoryExists dir "message"` - Asserts directory exists

## Running Tests

### Run All Tests

```bash
cd test
./run-tests.sh
```

### Run Individual Test File

```bash
cd test/unit
bash test-config-loader.sh
```

### Run with Verbose Output

The test framework shows detailed output by default. To see more details, check the test file directly.

## Writing New Tests

### Example Test File

```bash
#!/bin/bash
# Unit tests for my-script.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_FRAMEWORK="$SCRIPT_DIR/../helpers/test-framework.sh"
source "$TEST_FRAMEWORK"

# Setup function (runs before each test)
setUp() {
    # Create test environment
    TEST_DIR="/tmp/test-$$"
    mkdir -p "$TEST_DIR"
}

# Teardown function (runs after each test)
tearDown() {
    # Cleanup
    rm -rf "$TEST_DIR"
}

# Test functions (must start with "test")
testMyFunctionWorks() {
    # Your test code here
    assertTrue "Function should work" my_function
}

testMyFunctionFails() {
    assertFalse "Function should fail with bad input" my_function "bad_input"
}

# Run tests if executed directly
if [ "${0##*/}" = "test-my-script.sh" ]; then
    resetCounters
    runTests "$0"
fi
```

### Test File Structure

1. **Load test framework** - Source `test-framework.sh`
2. **Set up test environment** - Use `setUp()` function
3. **Write test functions** - Functions starting with `test`
4. **Clean up** - Use `tearDown()` function
5. **Run tests** - Call `runTests` if executed directly

## Test Coverage

### Current Tests

- ✅ **config-loader.sh** - Configuration loading, defaults, warnings
- ✅ **safety-checks.sh** - Commit/push blocking, repo detection

### Planned Tests

- [ ] `monitor-embabel.sh` - Monitoring functionality
- [ ] `sync-upstream.sh` - Sync operations
- [ ] `view-pr.sh` - PR viewing
- [ ] `list-embabel-repos.sh` - Repository listing
- [ ] Integration tests for common workflows

## Test Environment

Tests use temporary directories (`/tmp/embabel-learning-test-*`) to avoid polluting the actual workspace. All test directories are cleaned up automatically.

### Isolation

- Each test file runs in its own subshell
- Test directories are created with unique IDs (`$$`)
- Cleanup happens automatically in `tearDown()`

## Continuous Integration

To run tests in CI/CD:

```bash
# Install dependencies (none required!)
# Run tests
cd test && ./run-tests.sh
```

The test framework is self-contained and doesn't require any external tools.

## Contributing

When adding new scripts:

1. **Write tests first** (TDD approach) or
2. **Add tests alongside** the script
3. **Update this README** with test coverage
4. **Ensure all tests pass** before committing

## Troubleshooting

### Issue: Tests fail with "Permission denied"

**Solution:** Make test files executable:
```bash
chmod +x test/**/*.sh
```

### Issue: Tests use wrong paths

**Solution:** Make sure you're running from the test directory:
```bash
cd test
./run-tests.sh
```

### Issue: Test framework not found

**Solution:** Ensure test-framework.sh is executable and in helpers/:
```bash
ls -l test/helpers/test-framework.sh
chmod +x test/helpers/test-framework.sh
```

## Test Framework Details

The test framework (`test-framework.sh`) provides:

- **Assertion functions** - Various assert functions for testing
- **Test statistics** - Automatic counting of passed/failed tests
- **Color output** - Green for pass, red for fail
- **Summary reporting** - Automatic summary at end
- **Error handling** - Proper exit codes for CI/CD

No external dependencies - just pure bash!
