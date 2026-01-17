# Guide PR #26: Startup Tweaks

**PR:** https://github.com/embabel/guide/pull/26  
**Branch:** `issue-24`  
**Date:** 2026-01-17  
**Status:** Open  

## Summary

This PR consolidates startup improvements, fixes the Docker build, and removes obsolete documentation. It also incorporates changes from PR #25.

## Changes

### Dockerfile
- Added `COPY codegen-gradle ./codegen-gradle` to include the codegen-gradle directory in the build context
- Added `RUN chmod +x /workspace/codegen-gradle/gradlew` to make gradlew executable
- These fixes enable the multi-stage Docker build to work from a fresh clone

### compose.yaml
- Made Neo4j ports configurable via environment variables:
  - `NEO4J_HTTP_PORT` (default: 7474)
  - `NEO4J_BOLT_PORT` (default: 7687)
  - `NEO4J_HTTPS_PORT` (default: 7473)

### README.md
- Added "Docker Build Details" section explaining the multi-stage build process
- Added Neo4j port environment variables to the Environment Variables table
- Fixed all `docker compose` commands to include `--profile java` where needed
- Updated `docker compose down` to use `--profile java` to properly stop the guide service

### Deleted Files
- `CURSOR-PR.md` - Content was previously migrated to README.md, file is now obsolete

## Testing Performed

All documented commands were verified working:

| Command | Result |
|---------|--------|
| `docker compose --profile java up --build -d` | ✅ Starts neo4j + guide |
| `docker compose up neo4j -d` | ✅ Starts Neo4j only |
| `COMPOSE_PROFILES= docker compose up -d` | ✅ Starts Neo4j only (alt) |
| `GUIDE_PORT=1338 docker compose --profile java up --build -d` | ✅ Port override works |
| `curl http://localhost:1337/sse` | ✅ Returns `text/event-stream` |
| `docker compose --profile java down --remove-orphans` | ✅ Stops all services |

## Related Issues

- Closes #24
- Incorporates changes from PR #25

## Key Learnings

1. **Docker Compose Profiles**: When using profiles, the `down` command also needs the profile flag to stop profiled services
2. **Multi-stage Docker builds**: Need to ensure all required directories are copied into the build context
3. **Environment variable precedence**: Shell environment variables override `.env` file values in Docker Compose

## Files Changed

| File | Changes |
|------|---------|
| `CURSOR-PR.md` | Deleted (563 lines) |
| `Dockerfile` | +2 lines |
| `README.md` | +28/-3 lines |
| `compose.yaml` | +6/-6 lines |
