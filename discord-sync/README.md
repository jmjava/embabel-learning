# Discord Sync and Summary Tool

Automate exporting and summarizing Discord messages with flexible filtering options for dates, usernames, and topics.

## Prerequisites

- **Docker** installed and running
- **jq** (optional but recommended for summary generation)
  - Install: `sudo apt-get install jq` (Linux) or `brew install jq` (macOS)
- **Discord Token** - Your personal Discord user token (see [Getting Your Discord Token](#getting-your-discord-token) below)

## Getting Your Discord Token

This tool uses your personal Discord account token to export messages. You don't need any special server permissions - it works with your existing access to servers you're already a member of.

**Steps to get your user token:**

1. **Open Discord in your browser**
   - Go to https://discord.com/app
   - Log in to your Discord account

2. **Open Developer Tools**
   - Press `F12` or `Ctrl+Shift+I` (Windows/Linux) or `Cmd+Option+I` (Mac)
   - Go to the "Network" tab (this is the most reliable method)

3. **Find the Token (Network Tab Method - Recommended)**
   - In the Network tab, make sure it's recording (red circle should be active)
   - Filter by "Fetch/XHR" or search for "api" in the filter box
   - Reload the page or interact with Discord (send a message, switch channels)
   - Look for requests to `discord.com/api` (they'll show up as you use Discord)
   - Click on any request (look for ones like "messages", "channels", "gateway")
   - In the request details, go to the "Headers" tab
   - Scroll down to "Request Headers"
   - Look for "authorization" - the value is your user token
   - It will be a long string that looks like: `MTIzNDU2Nzg5MDEyMzQ1Njc4OQ.abcdef.xyz123...`

   **Alternative: Console Method**
   - Open Developer Tools (F12)
   - Go to the "Console" tab
   - Type: `(webpackChunkdiscord_app.push([[''],{},e=>{m=[];for(let c in e.c)m.push(e.c[c])}]),m).find(m=>m?.exports?.default?.getToken!==void 0).exports.default.getToken()`
   - Press Enter - this will display your token in the console
   - Copy the token (it will be a long string)

   **Note:** If the console method doesn't work, use the Network tab method - it's more reliable.

4. **Use the Token**
   - Copy the token
   - Add it to your `.env` file as `DISCORD_TOKEN=your-user-token-here`

**How it works:**
- Uses your existing Discord account
- Can export from any server you're already a member of
- No server admin permissions needed
- Works immediately - no bot setup required

**Security Note:**
- Keep your token secret - it gives access to your account
- Don't share it or commit it to git
- Discord may revoke tokens if they detect abuse
- For personal use and occasional exports, this is perfectly fine

**Note:** This tool is designed for regular users. No bot setup or server admin permissions needed.

## Configuration

The script automatically sources environment variables from a `.env` file if present.

### Option 1: Using a .env file (Recommended)

Create a `.env` file in either:

- `discord-sync/.env` (preferred, most specific)
- `embabel-learning/.env` (parent directory, fallback)

Add your Discord token:

```bash
DISCORD_TOKEN=your-discord-token-here
```

The script will automatically load this file when run.

### Option 2: Export environment variable

```bash
export DISCORD_TOKEN=your-discord-token-here
```

### Option 3: Pass inline

```bash
DISCORD_TOKEN=your-token-here ./discord-sync/sync-discord.sh --channel 123456789 --after "2026-01-25"
```

## Usage

### Basic Export

Export messages from a specific date range:

```bash
./discord-sync/sync-discord.sh \
  --channel 123456789012345678 \
  --after "2026-01-25T00:00:00" \
  --before "2026-01-26T00:00:00"
```

### Date Formats

Dates can be specified in multiple formats:

- Full ISO: `2026-01-25T00:00:00`
- Date only: `2026-01-25` (automatically expands to `2026-01-25T00:00:00` for `--after` and `2026-01-25T23:59:59` for `--before`)

### Filter by Username

Export messages from specific users:

```bash
./discord-sync/sync-discord.sh \
  --channel 123456789012345678 \
  --after "2026-01-25" \
  --username "alice" \
  --username "bob"
```

You can specify multiple usernames - messages from any of them will be included.

### Filter by Topic/Keyword

Export messages containing specific keywords:

```bash
./discord-sync/sync-discord.sh \
  --channel 123456789012345678 \
  --after "2026-01-25" \
  --topic "embabel" \
  --topic "agent"
```

You can specify multiple topics - messages containing any of them will be included.

### Combined Filters

Combine username and topic filters:

```bash
./discord-sync/sync-discord.sh \
  --channel 123456789012345678 \
  --after "2026-01-25" \
  --before "2026-01-26" \
  --username "alice" \
  --topic "embabel"
```

This will export messages from "alice" that also contain "embabel".

### Output Formats

Export in different formats:

```bash
# JSON (default, enables summary generation)
./discord-sync/sync-discord.sh --channel 123456789 --after "2026-01-25" --format json

# Plain text
./discord-sync/sync-discord.sh --channel 123456789 --after "2026-01-25" --format txt

# HTML
./discord-sync/sync-discord.sh --channel 123456789 --after "2026-01-25" --format html
```

### Summary Only Mode

Generate a summary from an existing export file:

```bash
./discord-sync/sync-discord.sh \
  --channel 123456789012345678 \
  --after "2026-01-25" \
  --summary-only
```

**Note:** This requires an existing export file. The script will look for a file matching the channel ID and date range.

### Custom Output Directory

Specify a custom directory for exports:

```bash
./discord-sync/sync-discord.sh \
  --channel 123456789012345678 \
  --after "2026-01-25" \
  --output-dir /path/to/exports
```

Default location: `$LEARNING_DIR/exports/discord/`

## Output Files

The script generates two types of files:

1. **Export File**: Raw message data in the specified format
   - Location: `$LEARNING_DIR/exports/discord/`
   - Naming: `discord_{CHANNEL_ID}_{DATE_RANGE}.{format}`
   - Example: `discord_123456789_20260125_to_20260126.json`

2. **Summary File**: Markdown summary with statistics and recent messages (JSON format only)
   - Location: Same as export file
   - Naming: `discord_{CHANNEL_ID}_{DATE_RANGE}_summary.md`
   - Example: `discord_123456789_20260125_to_20260126_summary.md`

### Summary Contents

The summary includes:

- **Statistics**: Total messages, unique authors, date range
- **Top Contributors**: Most active users (top 10)
- **Recent Messages**: Last 20 messages with author and timestamp
- **Topic Mentions**: Count of messages containing specified topics
- **Media & Links**: Count of messages with links or attachments

## Getting Channel ID

To find a Discord channel ID:

1. Enable Developer Mode in Discord (User Settings → Advanced → Developer Mode)
2. Right-click on the channel
3. Select "Copy ID"

## Examples

### Export Today's Messages

```bash
TODAY=$(date +%Y-%m-%d)
TOMORROW=$(date -d "tomorrow" +%Y-%m-%d)

./discord-sync/sync-discord.sh \
  --channel 123456789012345678 \
  --after "${TODAY}T00:00:00" \
  --before "${TOMORROW}T00:00:00"
```

### Export Last Week's Messages

```bash
LAST_WEEK=$(date -d "7 days ago" +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)

./discord-sync/sync-discord.sh \
  --channel 123456789012345678 \
  --after "${LAST_WEEK}" \
  --before "${TODAY}"
```

### Export and Filter for Specific Project

```bash
./discord-sync/sync-discord.sh \
  --channel 123456789012345678 \
  --after "2026-01-01" \
  --topic "embabel-agent" \
  --topic "embabel-guide" \
  --format json
```

### Generate Summary from Existing Export

If you already have an export file and want to regenerate the summary with different filters:

```bash
# First export (if not already done)
./discord-sync/sync-discord.sh \
  --channel 123456789012345678 \
  --after "2026-01-25"

# Then generate summary with filters
./discord-sync/sync-discord.sh \
  --channel 123456789012345678 \
  --after "2026-01-25" \
  --username "alice" \
  --summary-only
```

## Troubleshooting

### Error: DISCORD_TOKEN not set

**Solution:** Set the token in your `.env` file or export it:

```bash
export DISCORD_TOKEN=your-token-here
```

Or add to `.env`:
```bash
DISCORD_TOKEN=your-token-here
```

### Error: Docker is not installed

**Solution:** Install Docker:

- Linux: `sudo apt-get install docker.io` or follow [Docker installation guide](https://docs.docker.com/engine/install/)
- macOS: Install [Docker Desktop](https://www.docker.com/products/docker-desktop)

### Warning: jq is not installed

**Solution:** Install jq for summary generation:

```bash
# Linux
sudo apt-get install jq

# macOS
brew install jq
```

**Note:** The script will still work without jq, but summary generation will be disabled.

### Error: Export file was not created

**Possible causes:**

1. **Invalid channel ID** - Verify the channel ID is correct
2. **Invalid token** - Check that your Discord token is valid and has access to the channel
3. **Date range issues** - Ensure dates are in the correct format
4. **Docker volume mount issues** - Check that the output directory is writable

**Solution:** Check Docker logs:

```bash
docker logs $(docker ps -lq)
```

### No messages found in date range

**Solution:**
- Verify the date range contains messages
- Check that your token has access to the channel
- Try a wider date range

### Summary generation fails

**Possible causes:**

1. **jq not installed** - Install jq (see above)
2. **Non-JSON format** - Summary generation only works with JSON format
3. **Export file missing** - Ensure the export completed successfully

**Solution:**
- Use `--format json` for exports
- Install jq if missing
- Verify the export file exists

### Permission denied errors

**Solution:** Make the script executable:

```bash
chmod +x discord-sync/sync-discord.sh
```

## Advanced Usage

### Using with Scripts

You can integrate this into other scripts:

```bash
#!/bin/bash
CHANNEL_ID="123456789012345678"
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)

./discord-sync/sync-discord.sh \
  --channel "$CHANNEL_ID" \
  --after "${YESTERDAY}T00:00:00" \
  --before "${YESTERDAY}T23:59:59" \
  --topic "embabel"

# Process the summary file
SUMMARY_FILE="$LEARNING_DIR/exports/discord/discord_${CHANNEL_ID}_*_summary.md"
if [ -f "$SUMMARY_FILE" ]; then
    # Your processing here
    cat "$SUMMARY_FILE"
fi
```

### Scheduled Exports

Add to crontab for daily exports:

```bash
# Export daily at 2 AM
0 2 * * * /path/to/embabel-learning/discord-sync/sync-discord.sh --channel YOUR_CHANNEL_ID --after "$(date -d 'yesterday' +\%Y-\%m-\%d)" --before "$(date +\%Y-\%m-\%d)"
```

## Security Notes

- **Never commit your Discord token to git** - The `.env` file is in `.gitignore`
- **Keep your token secret** - It gives full access to your Discord account
- **Don't share your token** - Anyone with it can access your account
- **Rotate tokens if compromised** - If you suspect your token is exposed, get a new one

## See Also

- [Discord Chat Exporter Documentation](https://github.com/Tyrrrz/DiscordChatExporter)
