#!/bin/bash
# Sync and summarize Discord messages
# Usage: ./sync-discord.sh [options]
#
# Options:
#   --channel CHANNEL_ID     Discord channel ID (required)
#   --after DATE            Start date (ISO format: 2026-01-25 or 2026-01-25T00:00:00)
#   --before DATE           End date (ISO format: 2026-01-26 or 2026-01-26T00:00:00)
#   --username USERNAME      Filter by username (can be used multiple times)
#   --topic KEYWORD         Filter by topic/keyword in message content (can be used multiple times)
#   --format FORMAT         Output format: json, txt, html (default: json)
#   --summary-only          Only generate summary, don't export raw data
#   --output-dir DIR        Directory for exports (default: $LEARNING_DIR/exports/discord)
#   --help                  Show this help message

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
LEARNING_DIR="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd || pwd)"
source "$LEARNING_DIR/scripts/config-loader.sh"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# Default values
CHANNEL_ID=""
AFTER_DATE=""
BEFORE_DATE=""
USERNAMES=()
TOPICS=()
OUTPUT_FORMAT="json"
SUMMARY_ONLY=false
OUTPUT_DIR="$LEARNING_DIR/exports/discord"
DISCORD_TOKEN="${DISCORD_TOKEN:-}"

# Parse arguments
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
        --format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        --summary-only)
            SUMMARY_ONLY=true
            shift
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --help)
            cat << EOF
Discord Sync and Summary Tool

Usage: $0 [options]

Required:
  --channel CHANNEL_ID     Discord channel ID to export

Date Filters:
  --after DATE            Start date (ISO format: 2026-01-25 or 2026-01-25T00:00:00)
  --before DATE           End date (ISO format: 2026-01-26 or 2026-01-26T00:00:00)

Content Filters:
  --username USERNAME      Filter by username (can be used multiple times)
  --topic KEYWORD         Filter by topic/keyword in message content (can be used multiple times)

Output Options:
  --format FORMAT         Output format: json, txt, html (default: json)
  --summary-only          Only generate summary, don't export raw data
  --output-dir DIR        Directory for exports (default: \$LEARNING_DIR/exports/discord)

Configuration:
  Set DISCORD_TOKEN in your .env file or export it as an environment variable

Examples:
  # Export today's messages
  $0 --channel 123456789 --after "2026-01-25T00:00:00" --before "2026-01-26T00:00:00"

  # Export and filter by username
  $0 --channel 123456789 --after "2026-01-25" --username "alice" --username "bob"

  # Export and filter by topic
  $0 --channel 123456789 --after "2026-01-25" --topic "embabel" --topic "agent"

  # Generate summary only
  $0 --channel 123456789 --after "2026-01-25" --summary-only

EOF
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [ -z "$CHANNEL_ID" ]; then
    echo -e "${RED}Error: --channel is required${NC}"
    echo "Use --help for usage information"
    exit 1
fi

# Check for Discord token
if [ -z "$DISCORD_TOKEN" ]; then
    echo -e "${RED}Error: DISCORD_TOKEN not set${NC}"
    echo "Set it in your .env file or export it:"
    echo "  export DISCORD_TOKEN='your-token-here'"
    echo "Or add to .env: DISCORD_TOKEN=your-token-here"
    exit 1
fi

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
    exit 1
fi

# Check if jq is available (for JSON processing)
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Warning: jq is not installed. Summary generation will be limited.${NC}"
    echo "Install with: sudo apt-get install jq (or brew install jq on macOS)"
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

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

EXPORT_FILE="$OUTPUT_DIR/${FILENAME}.${OUTPUT_FORMAT}"
SUMMARY_FILE="$OUTPUT_DIR/${FILENAME}_summary.md"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📱 Discord Sync & Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${CYAN}Channel ID:${NC} $CHANNEL_ID"
if [ -n "$AFTER_DATE" ]; then
    echo -e "${CYAN}After:${NC} $AFTER_DATE"
fi
if [ -n "$BEFORE_DATE" ]; then
    echo -e "${CYAN}Before:${NC} $BEFORE_DATE"
fi
if [ ${#USERNAMES[@]} -gt 0 ]; then
    echo -e "${CYAN}Usernames:${NC} ${USERNAMES[*]}"
fi
if [ ${#TOPICS[@]} -gt 0 ]; then
    echo -e "${CYAN}Topics:${NC} ${TOPICS[*]}"
fi
echo -e "${CYAN}Format:${NC} $OUTPUT_FORMAT"
echo ""

# Build Docker command
DOCKER_CMD="docker run --rm"
DOCKER_CMD="$DOCKER_CMD -v \"$OUTPUT_DIR:/out\""
DOCKER_CMD="$DOCKER_CMD tyrrrz/discordchatexporter"
DOCKER_CMD="$DOCKER_CMD export"
DOCKER_CMD="$DOCKER_CMD --token \"$DISCORD_TOKEN\""
DOCKER_CMD="$DOCKER_CMD --channel \"$CHANNEL_ID\""
DOCKER_CMD="$DOCKER_CMD --format \"$OUTPUT_FORMAT\""
DOCKER_CMD="$DOCKER_CMD --output \"/out/${FILENAME}.${OUTPUT_FORMAT}\""

if [ -n "$AFTER_DATE" ]; then
    # Ensure proper ISO format
    if [[ ! "$AFTER_DATE" =~ T ]]; then
        AFTER_DATE="${AFTER_DATE}T00:00:00"
    fi
    DOCKER_CMD="$DOCKER_CMD --after \"$AFTER_DATE\""
fi

if [ -n "$BEFORE_DATE" ]; then
    # Ensure proper ISO format
    if [[ ! "$BEFORE_DATE" =~ T ]]; then
        BEFORE_DATE="${BEFORE_DATE}T23:59:59"
    fi
    DOCKER_CMD="$DOCKER_CMD --before \"$BEFORE_DATE\""
fi

# Export messages
if [ "$SUMMARY_ONLY" = false ]; then
    echo -e "${YELLOW}Exporting Discord messages...${NC}"
    eval "$DOCKER_CMD"

    if [ ! -f "$EXPORT_FILE" ]; then
        echo -e "${RED}Error: Export file was not created${NC}"
        exit 1
    fi

    FILE_SIZE=$(du -h "$EXPORT_FILE" | cut -f1)
    echo -e "${GREEN}✓ Exported to: $EXPORT_FILE (${FILE_SIZE})${NC}\n"
else
    echo -e "${YELLOW}Summary-only mode: Skipping export${NC}"
    echo -e "${GRAY}Note: You need an existing export file to generate a summary${NC}\n"
fi

# Generate summary if we have JSON export and jq
if [ "$OUTPUT_FORMAT" = "json" ] && command -v jq &> /dev/null; then
    if [ -f "$EXPORT_FILE" ]; then
        echo -e "${YELLOW}Generating summary...${NC}"

        # Filter messages based on usernames and topics
        FILTERED_JSON="$OUTPUT_DIR/${FILENAME}_filtered.json"
        cp "$EXPORT_FILE" "$FILTERED_JSON"

        # Apply username filters
        if [ ${#USERNAMES[@]} -gt 0 ]; then
            USERNAME_FILTER=""
            for username in "${USERNAMES[@]}"; do
                if [ -z "$USERNAME_FILTER" ]; then
                    USERNAME_FILTER="(.author.name | ascii_downcase | contains(\"${username,,}\"))"
                else
                    USERNAME_FILTER="$USERNAME_FILTER or (.author.name | ascii_downcase | contains(\"${username,,}\"))"
                fi
            done
            jq "[.messages[] | select($USERNAME_FILTER)]" "$FILTERED_JSON" > "${FILTERED_JSON}.tmp" && mv "${FILTERED_JSON}.tmp" "$FILTERED_JSON"
        fi

        # Apply topic filters
        if [ ${#TOPICS[@]} -gt 0 ]; then
            for topic in "${TOPICS[@]}"; do
                jq "[.messages[] | select(.content | ascii_downcase | contains(\"${topic,,}\"))]" "$FILTERED_JSON" > "${FILTERED_JSON}.tmp" && mv "${FILTERED_JSON}.tmp" "$FILTERED_JSON"
            done
        fi

        # Generate summary markdown
        {
            echo "# Discord Messages Summary"
            echo ""
            echo "**Channel ID:** $CHANNEL_ID"
            if [ -n "$AFTER_DATE" ]; then
                echo "**After:** $AFTER_DATE"
            fi
            if [ -n "$BEFORE_DATE" ]; then
                echo "**Before:** $BEFORE_DATE"
            fi
            if [ ${#USERNAMES[@]} -gt 0 ]; then
                echo "**Filtered by usernames:** ${USERNAMES[*]}"
            fi
            if [ ${#TOPICS[@]} -gt 0 ]; then
                echo "**Filtered by topics:** ${TOPICS[*]}"
            fi
            echo "**Generated:** $(date -Iseconds)"
            echo ""

            # Get message count
            MSG_COUNT=$(jq '.messages | length' "$FILTERED_JSON")
            echo "## Statistics"
            echo ""
            echo "- **Total Messages:** $MSG_COUNT"

            # Get unique authors
            UNIQUE_AUTHORS=$(jq -r '.messages[].author.name' "$FILTERED_JSON" | sort -u | wc -l)
            echo "- **Unique Authors:** $UNIQUE_AUTHORS"

            # Get date range of messages
            if [ "$MSG_COUNT" -gt 0 ]; then
                FIRST_MSG_DATE=$(jq -r '.messages[0].timestamp' "$FILTERED_JSON" | cut -d'T' -f1)
                LAST_MSG_DATE=$(jq -r '.messages[-1].timestamp' "$FILTERED_JSON" | cut -d'T' -f1)
                echo "- **Date Range:** $FIRST_MSG_DATE to $LAST_MSG_DATE"
            fi
            echo ""

            # Top contributors
            echo "## Top Contributors"
            echo ""
            jq -r '.messages[].author.name' "$FILTERED_JSON" | sort | uniq -c | sort -rn | head -10 | while read -r count name; do
                echo "- **$name:** $count message(s)"
            done
            echo ""

            # Recent messages summary
            echo "## Recent Messages"
            echo ""
            jq -r '.messages[-20:] | reverse | .[] | "### \(.author.name) - \(.timestamp | split("T")[0]) \(.timestamp | split("T")[1] | split(".")[0])\n\n\(.content)\n"' "$FILTERED_JSON" | head -100
            echo ""

            # Topic analysis (if topics were specified)
            if [ ${#TOPICS[@]} -gt 0 ]; then
                echo "## Topic Mentions"
                echo ""
                for topic in "${TOPICS[@]}"; do
                    TOPIC_COUNT=$(jq -r ".messages[] | select(.content | ascii_downcase | contains(\"${topic,,}\")) | .content" "$FILTERED_JSON" | wc -l)
                    echo "- **$topic:** mentioned in $TOPIC_COUNT message(s)"
                done
                echo ""
            fi

            # Links and attachments
            LINK_COUNT=$(jq '[.messages[] | select(.content | test("https?://"))] | length' "$FILTERED_JSON")
            ATTACHMENT_COUNT=$(jq '[.messages[] | select(.attachments != null and (.attachments | length) > 0)] | length' "$FILTERED_JSON")
            echo "## Media & Links"
            echo ""
            echo "- **Messages with links:** $LINK_COUNT"
            echo "- **Messages with attachments:** $ATTACHMENT_COUNT"
            echo ""

        } > "$SUMMARY_FILE"

        echo -e "${GREEN}✓ Summary generated: $SUMMARY_FILE${NC}\n"

        # Clean up filtered JSON if it's different from original
        if [ "$FILTERED_JSON" != "$EXPORT_FILE" ]; then
            rm -f "$FILTERED_JSON"
        fi
    else
        echo -e "${YELLOW}⚠️  No export file found. Cannot generate summary.${NC}"
    fi
elif [ "$OUTPUT_FORMAT" != "json" ]; then
    echo -e "${GRAY}Note: Summary generation only available for JSON format${NC}"
elif [ ! -f "$EXPORT_FILE" ]; then
    echo -e "${YELLOW}⚠️  No export file found. Cannot generate summary.${NC}"
fi

echo -e "${GREEN}✓ Discord sync complete!${NC}"
echo ""
echo -e "${CYAN}Files:${NC}"
if [ -f "$EXPORT_FILE" ]; then
    echo -e "  ${GREEN}•${NC} Export: $EXPORT_FILE"
fi
if [ -f "$SUMMARY_FILE" ]; then
    echo -e "  ${GREEN}•${NC} Summary: $SUMMARY_FILE"
fi
