#!/bin/bash
# Start embabel-hub container
# Requires: OPENAI_API_KEY environment variable

if [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: OPENAI_API_KEY environment variable is not set"
    echo "Usage: OPENAI_API_KEY=your-key-here ./starthub.sh"
    exit 1
fi

# Check if container exists (running or stopped)
if docker ps -a --format '{{.Names}}' | grep -q "^embabel-hub$"; then
    echo "Found existing embabel-hub container, stopping and removing..."
    docker stop embabel-hub 2>/dev/null || true
    docker rm embabel-hub 2>/dev/null || true
    echo "Existing container removed"
fi

echo "Starting new embabel-hub container..."
docker run -d \
  --platform linux/amd64 \
  --name embabel-hub \
  -p 1337:1337 \
  -p 27474:7474 \
  -p 27687:7687 \
  -p 8042:8042 \
  -v embabel-neo4j-data:/data \
  -v embabel-neo4j-logs:/logs \
  -e OPENAI_API_KEY=$OPENAI_API_KEY \
  embabel/hub:latest

if [ $? -eq 0 ]; then
    echo "✓ embabel-hub container started successfully"
    echo ""
    echo "Hub: http://localhost:1337"
    echo "Neo4j Browser: http://localhost:27474"
    echo "Neo4j Bolt: bolt://localhost:27687"
    echo "Additional service: http://localhost:8042"
else
    echo "✗ Failed to start embabel-hub container"
    exit 1
fi

