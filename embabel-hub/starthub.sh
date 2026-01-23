#!/bin/bash
# Start embabel-hub container
# Requires: OPENAI_API_KEY environment variable (can be set in .env file or environment)

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Source .env file if it exists (prefer local .env, then parent directory .env)
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo "Loading environment from $SCRIPT_DIR/.env"
    set -a  # automatically export all variables
    source "$SCRIPT_DIR/.env"
    set +a  # disable automatic export
elif [ -f "$PARENT_DIR/.env" ]; then
    echo "Loading environment from $PARENT_DIR/.env"
    set -a  # automatically export all variables
    source "$PARENT_DIR/.env"
    set +a  # disable automatic export
fi

# Check if OPENAI_API_KEY is set
if [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: OPENAI_API_KEY environment variable is not set"
    echo ""
    echo "You can set it in one of these ways:"
    echo "  1. Create a .env file in embabel-hub/ or parent directory with: OPENAI_API_KEY=your-key-here"
    echo "  2. Export it: export OPENAI_API_KEY=your-key-here"
    echo "  3. Pass it inline: OPENAI_API_KEY=your-key-here ./starthub.sh"
    exit 1
fi

# Check if container exists (running or stopped)
if docker ps -a --format '{{.Names}}' | grep -q "^embabel-hub$"; then
    echo "Found existing embabel-hub container, stopping and removing..."
    docker stop embabel-hub 2>/dev/null || true
    docker rm embabel-hub 2>/dev/null || true
    echo "Existing container removed"
fi

# Remove old embabel/hub images to ensure fresh pull
echo "Removing old embabel/hub images..."
OLD_IMAGES=$(docker images "embabel/hub" -q)
if [ -n "$OLD_IMAGES" ]; then
    echo "$OLD_IMAGES" | xargs docker rmi -f 2>/dev/null || true
fi
echo "Old images removed"

# Pull the latest image
echo "Pulling latest embabel/hub image..."
docker pull embabel/hub:latest
if [ $? -ne 0 ]; then
    echo "✗ Failed to pull embabel/hub:latest"
    exit 1
fi
echo "✓ Latest image pulled successfully"

echo "Starting new embabel-hub container..."
# Note: Removed --platform linux/amd64 to allow Docker to use available image with emulation if needed
# Port mappings:
#   - 21337:1337 - Guide API (Tomcat runs on 1337 inside container)
#   - 27474:7474 - Neo4j Browser (HTTP)
#   - 27687:7687 - Neo4j Bolt (Bolt protocol)
#   - 8042:8042  - Frontend
# pragma: allowlist secret
docker run -d \
  --name embabel-hub \
  -p 21337:1337 \
  -p 27474:7474 \
  -p 27687:7687 \
  -p 8042:8042 \
  -v embabel-neo4j-data:/data \
  -v embabel-neo4j-logs:/logs \
  -e "OPENAI_API_KEY=$OPENAI_API_KEY" \
  embabel/hub:latest

if [ $? -eq 0 ]; then
    echo "✓ embabel-hub container started successfully"
    echo ""
    echo "Waiting for application to start (this may take 30-60 seconds)..."

    # Wait up to 60 seconds for the web server to respond
    max_wait=60
    elapsed=0
    while [ $elapsed -lt $max_wait ]; do
        if curl -s -f http://localhost:21337 > /dev/null 2>&1; then
            echo "✓ Web server is responding!"
            break
        fi
        sleep 2
        elapsed=$((elapsed + 2))
        echo "  Waiting... (${elapsed}s/${max_wait}s)"
    done

    # Check if server is responding
    if curl -s -f http://localhost:21337 > /dev/null 2>&1; then
        echo ""
        echo "✓ Embabel Hub is running!"
        echo ""
        echo "Available services:"
        echo "  - Guide API:    http://localhost:21337"
        echo "  - Neo4j Browser: http://localhost:27474"
        echo "  - Neo4j Bolt:   bolt://localhost:27687"
        echo "  - Frontend:     http://localhost:8042"
    else
        echo ""
        echo "⚠ Warning: Container started but web server is not responding"
        echo ""
        echo "Checking container logs for errors..."
        echo "Recent errors:"
        docker logs embabel-hub 2>&1 | grep -i "error\|exception\|401\|unauthorized" | tail -5 || echo "No obvious errors found"
        echo ""
        echo "To view full logs: docker logs embabel-hub"
        echo "To check container status: docker ps -a | grep embabel-hub"
        echo ""
        echo "Common issues:"
        echo "  - Invalid or expired OPENAI_API_KEY (check for 401 errors in logs)"
        echo "  - Application startup timeout (check logs for startup errors)"
        exit 1
    fi
else
    echo "✗ Failed to start embabel-hub container"
    exit 1
fi
