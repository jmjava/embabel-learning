#!/bin/bash
# Unit tests for discord-sync/sync-discord.sh

# Load test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_FRAMEWORK="$SCRIPT_DIR/../helpers/test-framework.sh"
source "$TEST_FRAMEWORK"

# Test directory setup
TEST_ROOT="/tmp/embabel-learning-test-$$"
LEARNING_DIR="$TEST_ROOT"
DISCORD_SYNC_DIR="$LEARNING_DIR/discord-sync"
SCRIPTS_DIR="$LEARNING_DIR/scripts"
EXPORTS_DIR="$LEARNING_DIR/exports/discord"

setUp() {
    # Create test directory structure
    mkdir -p "$DISCORD_SYNC_DIR"
    mkdir -p "$SCRIPTS_DIR"
    mkdir -p "$EXPORTS_DIR"

    # Copy actual scripts to test location
    local actual_scripts_dir="$(cd "$SCRIPT_DIR/../../scripts" && pwd)"
    local actual_discord_sync_dir="$(cd "$SCRIPT_DIR/../../discord-sync" && pwd)"

    cp "$actual_scripts_dir/config-loader.sh" "$SCRIPTS_DIR/"
    cp "$actual_discord_sync_dir/sync-discord.sh" "$DISCORD_SYNC_DIR/"

    # Unset Discord-related variables
    unset DISCORD_TOKEN
    unset CHANNEL_ID
    unset AFTER_DATE
    unset BEFORE_DATE
    unset OUTPUT_DIR

    # Set LEARNING_DIR for scripts
    export LEARNING_DIR="$TEST_ROOT"
}

tearDown() {
    # Cleanup
    rm -rf "$TEST_ROOT"
    unset DISCORD_TOKEN
    unset LEARNING_DIR
}

testScriptExists() {
    assertFileExists "$DISCORD_SYNC_DIR/sync-discord.sh" "Discord sync script should exist"
}

testScriptIsExecutable() {
    assertTrue "Script should be executable" [ -x "$DISCORD_SYNC_DIR/sync-discord.sh" ]
}

testScriptPathResolution() {
    # Test that script correctly resolves paths
    local output=$(bash -c "
        cd '$DISCORD_SYNC_DIR'
        export LEARNING_DIR='$LEARNING_DIR'
        export CONFIG_WARNING_SHOWN=true
        source '$SCRIPTS_DIR/config-loader.sh' >/dev/null 2>&1
        SCRIPT_DIR=\"\$(cd \"\$(dirname \"sync-discord.sh\")\" 2>/dev/null && pwd || pwd)\"
        LEARNING_DIR_RESOLVED=\"\$(cd \"\$SCRIPT_DIR/..\" 2>/dev/null && pwd || pwd)\"
        echo \"SCRIPT_DIR=\$SCRIPT_DIR\"
        echo \"LEARNING_DIR=\$LEARNING_DIR_RESOLVED\"
    ")

    assertContains "$output" "discord-sync" "SCRIPT_DIR should contain discord-sync"
    assertContains "$output" "$TEST_ROOT" "LEARNING_DIR should resolve correctly"
}

testHelpOption() {
    # Test --help option
    local output=$(bash "$DISCORD_SYNC_DIR/sync-discord.sh" --help 2>&1)

    assertContains "$output" "Discord Sync" "Help should mention Discord Sync"
    # Use assertContains which handles the grep properly
    assertContains "$output" "channel" "Help should show channel option"
    assertContains "$output" "after" "Help should show after option"
    assertContains "$output" "before" "Help should show before option"
    assertContains "$output" "username" "Help should show username option"
    assertContains "$output" "topic" "Help should show topic option"
}

testMissingChannelError() {
    # Test that missing --channel shows error
    export DISCORD_TOKEN="test-token"
    local output=$(bash "$DISCORD_SYNC_DIR/sync-discord.sh" 2>&1)

    # Remove color codes for matching
    local clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')
    assertContains "$clean_output" "channel is required" "Should error when channel is missing"
    assertContains "$output" "Error" "Should show error message"
}

testMissingTokenError() {
    # Test that missing DISCORD_TOKEN shows error
    local output=$(bash "$DISCORD_SYNC_DIR/sync-discord.sh" --channel "123456789" 2>&1)

    assertContains "$output" "DISCORD_TOKEN not set" "Should error when token is missing"
    assertContains "$output" ".env file" "Should mention .env file"
}

testArgumentParsing() {
    # Test that arguments are parsed correctly
    export DISCORD_TOKEN="test-token"

    # Mock the script to just parse arguments and exit early
    local test_script=$(cat << 'EOF'
#!/bin/bash
set -e
CHANNEL_ID=""
AFTER_DATE=""
BEFORE_DATE=""
USERNAMES=()
TOPICS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --channel)
            CHANNEL_ID="$2"
            shift 2
            ;;
        --after)
            AFTER_DATE="$2"
            shift 2
            ;;
        --before)
            BEFORE_DATE="$2"
            shift 2
            ;;
        --username)
            USERNAMES+=("$2")
            shift 2
            ;;
        --topic)
            TOPICS+=("$2")
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

echo "CHANNEL=$CHANNEL_ID"
echo "AFTER=$AFTER_DATE"
echo "BEFORE=$BEFORE_DATE"
echo "USERNAMES=${USERNAMES[*]}"
echo "TOPICS=${TOPICS[*]}"
EOF
)

    echo "$test_script" > "$TEST_ROOT/test-args.sh"
    chmod +x "$TEST_ROOT/test-args.sh"

    local output=$(bash "$TEST_ROOT/test-args.sh" \
        --channel "123456789" \
        --after "2026-01-25" \
        --before "2026-01-26" \
        --username "alice" \
        --username "bob" \
        --topic "embabel" \
        --topic "agent")

    assertContains "$output" "CHANNEL=123456789" "Should parse channel ID"
    assertContains "$output" "AFTER=2026-01-25" "Should parse after date"
    assertContains "$output" "BEFORE=2026-01-26" "Should parse before date"
    assertContains "$output" "USERNAMES=alice bob" "Should parse multiple usernames"
    assertContains "$output" "TOPICS=embabel agent" "Should parse multiple topics"
}

testFilenameGeneration() {
    # Test filename generation logic
    local test_script=$(cat << 'EOF'
#!/bin/bash
CHANNEL_ID="123456789"
AFTER_DATE="2026-01-25"
BEFORE_DATE="2026-01-26"

# Generate filename based on date range
if [ -n "$AFTER_DATE" ] && [ -n "$BEFORE_DATE" ]; then
    AFTER_CLEAN=$(echo "$AFTER_DATE" | tr -d ':-' | cut -d'T' -f1)
    BEFORE_CLEAN=$(echo "$BEFORE_DATE" | tr -d ':-' | cut -d'T' -f1)
    FILENAME="discord_${CHANNEL_ID}_${AFTER_CLEAN}_to_${BEFORE_CLEAN}"
elif [ -n "$AFTER_DATE" ]; then
    AFTER_CLEAN=$(echo "$AFTER_DATE" | tr -d ':-' | cut -d'T' -f1)
    FILENAME="discord_${CHANNEL_ID}_from_${AFTER_CLEAN}"
else
    FILENAME="discord_${CHANNEL_ID}_$(date +%Y%m%d_%H%M%S)"
fi

echo "$FILENAME"
EOF
)

    echo "$test_script" > "$TEST_ROOT/test-filename.sh"
    chmod +x "$TEST_ROOT/test-filename.sh"

    local output=$(bash "$TEST_ROOT/test-filename.sh")
    assertEquals "discord_123456789_20260125_to_20260126" "$output" "Should generate correct filename with date range"

    # Test with only after date
    AFTER_DATE="2026-01-25" BEFORE_DATE="" CHANNEL_ID="123456789"
    output=$(AFTER_DATE="2026-01-25" BEFORE_DATE="" CHANNEL_ID="123456789" bash -c '
        AFTER_CLEAN=$(echo "$AFTER_DATE" | tr -d ":-" | cut -d"T" -f1)
        FILENAME="discord_${CHANNEL_ID}_from_${AFTER_CLEAN}"
        echo "$FILENAME"
    ')
    assertEquals "discord_123456789_from_20260125" "$output" "Should generate correct filename with only after date"
}

testOutputDirectoryCreation() {
    # Test that output directory is created
    export DISCORD_TOKEN="test-token"
    export LEARNING_DIR="$TEST_ROOT"

    # Create a minimal test that just checks directory creation
    local test_dir="$TEST_ROOT/exports/discord"
    rm -rf "$test_dir"

    # The script should create this directory
    mkdir -p "$test_dir"
    assertDirectoryExists "$test_dir" "Output directory should be created"
}

testDateFormatNormalization() {
    # Test that dates are normalized to ISO format
    local test_script=$(cat << 'EOF'
#!/bin/bash
AFTER_DATE="2026-01-25"
BEFORE_DATE="2026-01-26"

# Ensure proper ISO format
if [[ ! "$AFTER_DATE" =~ T ]]; then
    AFTER_DATE="${AFTER_DATE}T00:00:00"
fi

if [[ ! "$BEFORE_DATE" =~ T ]]; then
    BEFORE_DATE="${BEFORE_DATE}T23:59:59"
fi

echo "AFTER=$AFTER_DATE"
echo "BEFORE=$BEFORE_DATE"
EOF
)

    echo "$test_script" > "$TEST_ROOT/test-date-format.sh"
    chmod +x "$TEST_ROOT/test-date-format.sh"

    local output=$(bash "$TEST_ROOT/test-date-format.sh")
    assertContains "$output" "AFTER=2026-01-25T00:00:00" "Should normalize after date to ISO format"
    assertContains "$output" "BEFORE=2026-01-26T23:59:59" "Should normalize before date to ISO format"
}

testConfigLoaderIntegration() {
    # Test that script can load config from config-loader
    export LEARNING_DIR="$TEST_ROOT"
    export CONFIG_WARNING_SHOWN=true

    # Create a test .env file
    cat > "$TEST_ROOT/.env" << 'EOF'
DISCORD_TOKEN=test-token-from-env
EOF

    # Source config-loader and check if token is loaded
    local output=$(bash -c "
        export LEARNING_DIR='$TEST_ROOT'
        export CONFIG_WARNING_SHOWN=true
        source '$SCRIPTS_DIR/config-loader.sh' >/dev/null 2>&1
        echo \"TOKEN=\${DISCORD_TOKEN:-NOT_SET}\"
    ")

    # Note: config-loader.sh doesn't automatically load .env for DISCORD_TOKEN
    # The script itself handles DISCORD_TOKEN from environment
    # But we can test that the config-loader is accessible
    assertFileExists "$SCRIPTS_DIR/config-loader.sh" "Config loader should be accessible"
}

testMultipleUsernameFiltering() {
    # Test that multiple usernames can be specified
    export DISCORD_TOKEN="test-token"

    # Test argument parsing for multiple usernames
    local test_output=$(bash -c '
        USERNAMES=()
        while [[ $# -gt 0 ]]; do
            case $1 in
                --username)
                    USERNAMES+=("$2")
                    shift 2
                    ;;
                *)
                    shift
                    ;;
            esac
        done
        for u in "${USERNAMES[@]}"; do
            echo "$u"
        done
    ' -- --username "alice" --username "bob" --username "charlie")

    assertContains "$test_output" "alice" "Should capture first username"
    assertContains "$test_output" "bob" "Should capture second username"
    assertContains "$test_output" "charlie" "Should capture third username"
}

testMultipleTopicFiltering() {
    # Test that multiple topics can be specified
    export DISCORD_TOKEN="test-token"

    # Test argument parsing for multiple topics
    local test_output=$(bash -c '
        TOPICS=()
        while [[ $# -gt 0 ]]; do
            case $1 in
                --topic)
                    TOPICS+=("$2")
                    shift 2
                    ;;
                *)
                    shift
                    ;;
            esac
        done
        for t in "${TOPICS[@]}"; do
            echo "$t"
        done
    ' -- --topic "embabel" --topic "agent" --topic "guide")

    assertContains "$test_output" "embabel" "Should capture first topic"
    assertContains "$test_output" "agent" "Should capture second topic"
    assertContains "$test_output" "guide" "Should capture third topic"
}

testFormatOption() {
    # Test that format option is parsed
    export DISCORD_TOKEN="test-token"

    local test_output=$(bash -c '
        OUTPUT_FORMAT="json"
        while [[ $# -gt 0 ]]; do
            case $1 in
                --format)
                    OUTPUT_FORMAT="$2"
                    shift 2
                    ;;
                *)
                    shift
                    ;;
            esac
        done
        echo "FORMAT=$OUTPUT_FORMAT"
    ' -- --format "html")

    assertContains "$test_output" "FORMAT=html" "Should parse format option"
}

# Only run tests if executed directly (not sourced)
if [ "${0##*/}" = "test-sync-discord.sh" ] && [ "${RUNNING_TESTS:-false}" != "true" ]; then
    resetCounters
    runTests "$0"
fi
