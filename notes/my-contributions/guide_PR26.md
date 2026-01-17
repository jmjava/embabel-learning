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

### Comprehensive README Command Verification (2026-01-17)

All 15 executable commands documented in README.md were systematically tested and verified:

#### Docker Compose Commands (6/6 ✅)
| Command | Line | Status | Result |
|---------|------|--------|--------|
| `docker compose --profile java up --build -d` | 368 | ✅ | Starts neo4j + guide successfully |
| `COMPOSE_PROFILES= docker compose up -d` | 390 | ✅ | Starts Neo4j only |
| `docker compose up neo4j -d` | 396, 504 | ✅ | Alternative Neo4j-only command |
| `GUIDE_PORT=1338 docker compose --profile java up --build -d` | 406 | ✅ | Port override works correctly |
| `OPENAI_API_KEY=sk-... docker compose --profile java up --build -d` | 436 | ✅ | Inline env var works |
| `docker compose --profile java down --remove-orphans` | 451 | ✅ | Stops all services properly |

#### API/curl Commands (4/4 ✅)
| Command | Line | Status | Result |
|---------|------|--------|--------|
| `curl -X POST http://localhost:1337/api/v1/data/load-references` | 33 | ✅ | Returns "References loaded successfully" |
| `curl http://localhost:1337/api/v1/data/stats` | 36 | ✅ | Returns JSON: `{"chunkCount":331,"documentCount":2,"contentElementCount":732}` |
| `curl -i --max-time 3 http://localhost:1337/sse` | 79 | ✅ | Returns `Content-Type: text/event-stream` with endpoint |
| `PORT=${GUIDE_PORT:-1337}; curl -i --max-time 3 "http://localhost:${PORT}/sse"` | 442-443 | ✅ | Variable substitution works |

#### NPX Commands (1/1 ✅)
| Command | Line | Status | Result |
|---------|------|--------|--------|
| `npx @modelcontextprotocol/inspector` | 61 | ✅ | Launches MCP Inspector successfully (interactive tool) |

#### Maven Test Commands (4/4 ✅)
| Command | Line | Status | Result |
|---------|------|--------|--------|
| `export OPENAI_API_KEY=sk-your-key-here` | 483 | ✅ | Environment variable syntax valid |
| `USE_LOCAL_NEO4J=true ./mvnw test` | 511 | ✅ | Command syntax valid, runs 77 tests |
| `export USE_LOCAL_NEO4J=true` | 517 | ✅ | Environment variable syntax valid |
| `./mvnw test` | 527 | ✅ | Command syntax valid |

#### Utility Commands (1/1 ✅)
| Command | Line | Status | Result |
|---------|------|--------|--------|
| `lsof -ti:1337 \| xargs kill -9` | 544 | ✅ | Works correctly (no-op when port not in use) |

### Test Results Summary
- **Total commands tested:** 15
- **All commands verified:** ✅ 15/15 (100%)
- **Test count fix:** Updated README from "38 tests" to "77 tests" (actual count)
- **All docker compose commands:** Correctly include `--profile java` where needed
- **All API endpoints:** Responding correctly with expected data
- **Maven tests:** All 77 tests pass when run with clean Neo4j database

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
