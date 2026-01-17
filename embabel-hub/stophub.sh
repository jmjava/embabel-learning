#!/bin/bash
# Stop and remove embabel-hub container

# Check if container exists
if docker ps -a --format '{{.Names}}' | grep -q "^embabel-hub$"; then
    echo "Stopping embabel-hub container..."
    docker stop embabel-hub 2>/dev/null

    echo "Removing embabel-hub container..."
    docker rm embabel-hub 2>/dev/null

    echo "✓ embabel-hub container stopped and removed"
else
    echo "embabel-hub container is not running"
fi
