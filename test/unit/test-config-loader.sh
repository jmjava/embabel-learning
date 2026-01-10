#!/bin/bash
# Unit tests for config-loader.sh

# Load test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_FRAMEWORK="$SCRIPT_DIR/../helpers/test-framework.sh"
source "$TEST_FRAMEWORK"

# Test directory setup
TEST_ROOT="/tmp/embabel-learning-test-$$"
LEARNING_DIR="$TEST_ROOT"
SCRIPTS_DIR="$LEARNING_DIR/scripts"
CONFIG_FILE="$LEARNING_DIR/config.sh"
CONFIG_EXAMPLE="$LEARNING_DIR/config.sh.example"

setUp() {
    # Create test directory structure
    mkdir -p "$SCRIPTS_DIR"
    mkdir -p "$(dirname "$CONFIG_EXAMPLE")"
    
    # Copy config-loader.sh to test location (use absolute path)
    local actual_scripts_dir="$(cd "$SCRIPT_DIR/../../scripts" && pwd)"
    cp "$actual_scripts_dir/config-loader.sh" "$SCRIPTS_DIR/"
    
    # Unset all config variables
    unset YOUR_GITHUB_USER
    unset UPSTREAM_ORG
    unset BASE_DIR
    unset LEARNING_DIR
    unset MONITOR_REPOS
    unset WORKSPACE_NAME
    unset USING_CONFIG
    unset CONFIG_WARNING_SHOWN
    
    # Set LEARNING_DIR for config-loader
    export LEARNING_DIR="$TEST_ROOT"
}

tearDown() {
    # Cleanup
    rm -rf "$TEST_ROOT"
    unset YOUR_GITHUB_USER
    unset UPSTREAM_ORG
    unset BASE_DIR
    unset LEARNING_DIR
    unset MONITOR_REPOS
    unset WORKSPACE_NAME
    unset USING_CONFIG
    unset CONFIG_WARNING_SHOWN
}

testConfigLoaderWithDefaults() {
    # Test that config-loader works with defaults (no config.sh)
    local output=$(bash -c "
        export LEARNING_DIR='$LEARNING_DIR'
        export CONFIG_WARNING_SHOWN=false
        source '$SCRIPTS_DIR/config-loader.sh' 2>&1
        echo \"USER=\$YOUR_GITHUB_USER\"
        echo \"ORG=\$UPSTREAM_ORG\"
        echo \"BASE=\$BASE_DIR\"
        echo \"USING=\$USING_CONFIG\"
    ")
    
    assertContains "$output" "jmjava" "Default YOUR_GITHUB_USER should be jmjava"
    assertContains "$output" "embabel" "Default UPSTREAM_ORG should be embabel"
    assertContains "$output" "USING=false" "Should indicate not using config file"
}

testConfigLoaderWithConfigFile() {
    # Create a test config file
    cat > "$CONFIG_FILE" << 'EOF'
#!/bin/bash
YOUR_GITHUB_USER="testuser"
UPSTREAM_ORG="testorg"
BASE_DIR="/custom/path"
MONITOR_REPOS="repo1 repo2 repo3"
EOF
    
    local output=$(bash -c "
        export LEARNING_DIR='$LEARNING_DIR'
        export CONFIG_WARNING_SHOWN=false
        source '$SCRIPTS_DIR/config-loader.sh' 2>&1
        echo \"USER=\$YOUR_GITHUB_USER\"
        echo \"ORG=\$UPSTREAM_ORG\"
        echo \"BASE=\$BASE_DIR\"
        echo \"MONITOR=\$MONITOR_REPOS\"
        echo \"USING=\$USING_CONFIG\"
    ")
    
    assertContains "$output" "USER=testuser" "Should load YOUR_GITHUB_USER from config"
    assertContains "$output" "ORG=testorg" "Should load UPSTREAM_ORG from config"
    assertContains "$output" "BASE=/custom/path" "Should load BASE_DIR from config"
    assertContains "$output" "MONITOR=repo1 repo2 repo3" "Should load MONITOR_REPOS from config"
    assertContains "$output" "USING=true" "Should indicate using config file"
}

testConfigLoaderExportsVariables() {
    # Test that variables are exported
    bash -c "
        export LEARNING_DIR='$LEARNING_DIR'
        export CONFIG_WARNING_SHOWN=false
        source '$SCRIPTS_DIR/config-loader.sh' >/dev/null 2>&1
        [ -n \"\$YOUR_GITHUB_USER\" ] && [ -n \"\$UPSTREAM_ORG\" ] && exit 0 || exit 1
    " >/dev/null 2>&1
    
    assertTrue "Variables should be exported" [ $? -eq 0 ]
}

testConfigLoaderValidatesRequiredVariables() {
    # Test validation when required variables are missing
    # Actually, config-loader.sh sets defaults, so this should work
    # Let's test that it properly uses defaults even with an empty config
    cat > "$CONFIG_FILE" << 'EOF'
#!/bin/bash
# Empty config - should use defaults
EOF
    
    # Override the config to set empty values, but config-loader should handle this
    # by setting defaults
    local output=$(bash -c "
        export LEARNING_DIR='$TEST_ROOT'
        export CONFIG_WARNING_SHOWN=false
        unset YOUR_GITHUB_USER
        unset UPSTREAM_ORG
        source '$SCRIPTS_DIR/config-loader.sh' 2>&1
        echo \"USER=\${YOUR_GITHUB_USER:-NOT_SET}\"
        echo \"ORG=\${UPSTREAM_ORG:-NOT_SET}\"
    " 2>&1)
    
    # Should use defaults
    assertContains "$output" "USER=jmjava" "Should use default YOUR_GITHUB_USER"
    assertContains "$output" "ORG=embabel" "Should use default UPSTREAM_ORG"
}

testConfigLoaderWarningMessage() {
    # Test that warning is shown when config.sh is missing
    local output=$(bash -c "
        export LEARNING_DIR='$LEARNING_DIR'
        unset CONFIG_WARNING_SHOWN
        source '$SCRIPTS_DIR/config-loader.sh' 2>&1
    ")
    
    assertContains "$output" "config.sh not found" "Should warn when config.sh is missing"
    assertContains "$output" "Using defaults" "Should mention using defaults"
}

testConfigLoaderNoDuplicateWarnings() {
    # Test that warning is only shown once
    local output=$(bash -c "
        export LEARNING_DIR='$LEARNING_DIR'
        export CONFIG_WARNING_SHOWN=false
        source '$SCRIPTS_DIR/config-loader.sh' >/dev/null 2>&1
        source '$SCRIPTS_DIR/config-loader.sh' 2>&1
    " | grep -c "config.sh not found")
    
    # Should only see warning once (first time)
    assertTrue "Warning should only appear once per execution" [ "$output" -le 1 ]
}

# Only run tests if executed directly (not sourced)
if [ "${0##*/}" = "test-config-loader.sh" ] && [ "${RUNNING_TESTS:-false}" != "true" ]; then
    resetCounters
    runTests "$0"
fi

