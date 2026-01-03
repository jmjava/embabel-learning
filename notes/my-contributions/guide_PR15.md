# PR #15: feat: Enable MCP server integration with Cursor IDE

**Repository:** embabel/guide
**Status:** MERGED
**Created:** 2025-12-19T03:24:53Z
**URL:** https://github.com/embabel/guide/pull/15

## Description
Files changed:
- .dockerignore: Include source files for multi-stage Docker build
- .gitignore: Ignore *.pid files
- CURSOR-PR.md: Detailed PR documentation (see this file for full change descriptions)
- Dockerfile: Multi-stage build to compile from source
- README.md: Cursor integration docs, Docker startup improvements, testing prerequisites
- compose.yaml: Parameterized port, optional services via profiles
- images/cursor-mcp-installed-servers.svg: Documentation screenshot
- src/main/kotlin/.../SecurityConfig.kt: Bypass Spring Security for /sse and /mcp endpoints
- src/test/kotlin/.../Neo4jTestContainer.kt: Use local Neo4j for tests
- src/test/kotlin/.../McpSecurityTest.kt: Regression tests for MCP endpoint accessibility

See CURSOR-PR.md for detailed file-by-file analysis and rationale.

## Files Changed
- `.dockerignore` (+8/-8)
- `.gitignore` (+3/-0)
- `CURSOR-PR.md` (+563/-0)
- `Dockerfile` (+14/-9)
- `README.md` (+172/-6)
- `compose.yaml` (+5/-1)
- `images/cursor-mcp-installed-servers.svg` (+41/-0)
- `src/main/kotlin/com/embabel/guide/chat/security/SecurityConfig.kt` (+41/-0)
- `src/test/kotlin/com/embabel/guide/Neo4jTestContainer.kt` (+6/-3)
- `src/test/kotlin/com/embabel/guide/TestApplicationContext.kt` (+3/-3)
- `src/test/kotlin/com/embabel/guide/chat/security/McpSecurityTest.kt` (+69/-0)
- `src/test/resources/application-test.yml` (+2/-2)

## Code Changes
```diff
diff --git a/.dockerignore b/.dockerignore
index ac2427e..511f00c 100644
--- a/.dockerignore
+++ b/.dockerignore
@@ -1,13 +1,13 @@
-# Don't exclude target/ - we need the pre-built JAR
 .git/
 .gitignore
-*.md
-.mvn/
-mvnw
-mvnw.cmd
 .DS_Store
-*.iml
 .idea/
 .vscode/
-src/
-pom.xml
\ No newline at end of file
+*.iml
+
+# Keep build context lean
+target/
+
+# Docs/images aren't needed to build the backend image
+*.md
+images/
\ No newline at end of file
diff --git a/.gitignore b/.gitignore
index cdd8b38..8762ca3 100644
--- a/.gitignore
+++ b/.gitignore
@@ -35,3 +35,6 @@ embabel-agent-api/src/main/resources/mcp/**
 *.bak
 *.swp
 *~
+
+# Runtime artifacts
+*.pid
diff --git a/CURSOR-PR.md b/CURSOR-PR.md
new file mode 100644
index 0000000..36933b9
--- /dev/null
+++ b/CURSOR-PR.md
@@ -0,0 +1,563 @@
+# PR: Cursor MCP Integration & Docker Improvements
+
+## Summary
+
+This PR enables **Cursor IDE** to connect to the Embabel MCP server by fixing Spring Security configuration issues that were blocking MCP endpoints. It also improves the Docker workflow so `docker compose up --build` works from a fresh clone without requiring a pre-built JAR.
+
+### Key Changes
+
+1. **Fix HTTP 403 errors** blocking Cursor from connecting to `/sse` and `/mcp` endpoints
+2. **Multi-stage Docker build** so the image builds from source
+3. **Flexible Docker Compose** with port override and optional services
+4. **Documentation** for Cursor setup and testing
+5. **Regression tests** to prevent future MCP security issues
+
+---
+
+## File-by-File Changes
+
+### 1. `src/main/kotlin/com/embabel/guide/chat/security/SecurityConfig.kt`
+
+**Type:** Modified  
+**Lines Changed:** +37
+
+#### Problem
+
+Cursor was receiving `HTTP 403 Forbidden` when connecting to `/sse` and `/mcp` endpoints. Despite these paths being listed in `permittedPatterns`, Spring Security was still blocking them.
+
+#### Root Cause
+
+Spring Boot auto-configuration can contribute additional `SecurityFilterChain` beans that take precedence over custom configurations. When multiple filter chains exist, the first one that matches a request handles it—and if that chain doesn't explicitly permit the path, it defaults to denying access.
+
+#### Solution
+
+Three-layer defense to ensure MCP endpoints are never blocked:
+
+**Layer 1: `WebSecurityCustomizer` (strongest)**
+
+```kotlin
+@Bean
+fun webSecurityCustomizer(): WebSecurityCustomizer = WebSecurityCustomizer { web ->
+    web.ignoring().requestMatchers(*mcpMatchers)
+}
+```
+
+This completely bypasses the Spring Security filter chain for MCP paths. Requests to `/sse/**` and `/mcp/**` never touch security filters at all.
+
+**Layer 2: Dedicated high-priority filter chain**
+
+```kotlin
+@Bean
+@Order(0)
+fun mcpFilterChain(http: HttpSecurity): SecurityFilterChain {
+    http.securityMatcher(mcpMatcher)
+        .csrf { it.disable() }
+        .cors { }
+        .authorizeHttpRequests { it.anyRequest().permitAll() }
+    return http.build()
+}
+```
+
+If `web.ignoring()` is ever removed, this `@Order(0)` chain catches MCP requests before any other chain.
+
+**Layer 3: Explicit matchers in main filter chain**
+
+```kotlin
+it.requestMatchers(*mcpMatchers).permitAll()
+```
+
+Belt-and-suspenders addition to the existing `filterChain`.
+
+#### Why `AntPathRequestMatcher`?
+
+Spring's default `MvcRequestMatcher` only matches paths registered with Spring MVC. The `/sse` endpoint is registered by the MCP library directly with the servlet container, so `MvcRequestMatcher` doesn't see it. `AntPathRequestMatcher` matches any request path regardless of how it's registered.
+
+#### Compiler Warnings
+
+There are 4 deprecation warnings about `AntPathRequestMatcher` constructor. Spring recommends using `AntPathRequestMatcher.antMatcher("/path")` instead. The current code works correctly; this is cosmetic.
+
+---
+
+### 2. `Dockerfile`
+
+**Type:** Modified  
+**Lines Changed:** +8 / -7
+
+#### Problem
+
+The original Dockerfile expected a pre-built JAR in `target/`:
+
+```dockerfile
+COPY target/*.jar app.jar
+```
+
+This meant developers had to:
+
+1. Install Java 21 and Maven locally
+2. Run `mvn clean package -DskipTests`
+3. Then run `docker compose up`
+
+For a fresh clone, step 2 would fail if Java wasn't installed.
+
+#### Solution
+
+Convert to a **multi-stage build** that compiles inside Docker:
+
+```dockerfile
+# Stage 1: Build
+FROM maven:3.9.9-eclipse-temurin-21 AS build
+WORKDIR /workspace
+COPY pom.xml ./
+COPY src ./src
+RUN mvn -q -DskipTests package
+
+# Stage 2: Runtime
+FROM eclipse-temurin:21-jre-jammy AS runtime
+WORKDIR /app
+COPY --from=build /workspace/target/*.jar /app/app.jar
+EXPOSE 1337
+ENTRYPOINT ["java", "-jar", "/app/app.jar"]
+```
+
+Now `docker compose up --build` works from a fresh clone with only Docker installed.
+
+#### Trade-offs
+
+| Aspect        | Before                | After                      |
+| ------------- | --------------------- | -------------------------- |
+| Build time    | ~5 seconds (copy JAR) | ~2-3 minutes (Maven build) |
+| Prerequisites | Java 21 + Maven       | Docker only                |
+| Fresh clone   | ❌ Fails              | ✅ Works                   |
+| CI/CD         | May need adjustment   | Works as-is                |
+
+---
+
+### 3. `.dockerignore`
+
+**Type:** Modified  
+**Lines Changed:** +8 / -9
+
+#### Problem
+
+The original `.dockerignore` excluded source files because the old Dockerfile only needed the pre-built JAR:
+
+```
+src/
+pom.xml
+mvnw
+```
+
+With the multi-stage build, we need source files in the Docker context.
+
+#### Solution
+
+Invert the logic—include source files, exclude build artifacts:
+
+```
+# Keep build context lean
+target/
+
+# Docs/images aren't needed to build the backend image
+*.md
+images/
+```
+
+Files now **included** in Docker context:
+
+- `pom.xml` ✅
+- `src/` ✅
+- `mvnw`, `mvnw.cmd` ✅ (not used, but harmless)
+
+Files **excluded**:
+
+- `target/` (local build artifacts)
+- `*.md`, `images/` (documentation)
+- `.git/`, `.idea/`, etc. (IDE/VCS)
+
+---
+
+### 4. `compose.yaml`
+
+**Type:** Modified  
+**Lines Changed:** +6
+
+#### Change 1: Parameterized Port
+
+**Problem:** Port 1337 may already be in use by another service. Running the guide app caused:
+
+```
+Error: bind: address already in use
+```
+
+**Solution:** Use environment variable with default:
+
+```yaml
+ports:
+  - '${GUIDE_PORT:-1337}:1337'
+```
+
+Usage:
+
+```bash
+# Default (port 1337)
+docker compose up --build -d
+
+# Override (port 1338)
+GUIDE_PORT=1338 docker compose up --build -d
+```
+
+#### Change 2: Profile-Gated Services
+
+**Problem:** Two services caused failures on fresh clones:
+
+1. `neo4j-init` — requires `neo4j-init/init.sh` which may not exist
+2. `frontend` — requires `../embabel-hub` repo checkout
+
+**Solution:** Move to Compose profiles (opt-in):
+
+```yaml
+neo4j-init:
+  profiles:
+    - init
+  # ...
+
+frontend:
+  profiles:
+    - frontend
+  # ...
+```
+
+Usage:
+
+```bash
+# Default: only neo4j + guide
+docker compose up --build -d
+
+# With frontend (requires ../embabel-hub)
+COMPOSE_PROFILES=frontend docker compose up --build -d
+
+# With neo4j-init (requires neo4j-init/init.sh)
+COMPOSE_PROFILES=init docker compose up --build -d
+```
+
+---
+
+### 5. `README.md`
+
+**Type:** Modified  
+**Lines Changed:** +131
+
+#### New Section: "Consuming MCP Tools With Cursor"
+
+Step-by-step instructions for connecting Cursor to the MCP server:
+
+1. **Verify server is running** — `curl` command to check `/sse`
+2. **Configure `~/.cursor/mcp.json`** — Example using `mcp-remote` stdio bridge
+3. **Reload Cursor** — Note about "Developer: Reload Window" command
+4. **Visual confirmation** — Embedded SVG screenshot
+
+#### Expanded Section: "Docker"
+
+- Changed `docker compose up` → `docker compose up --build -d`
+- Added port conflict handling (`GUIDE_PORT`)
+- Added Compose override variables documentation
+- Added `COMPOSE_PROFILES=frontend` example
+- Added MCP verification command
+
+#### New Section: "Testing"
+
+- Prerequisites: `OPENAI_API_KEY`, Neo4j
+- Expected test count (38 tests)
+- MCP Security regression test mention
+
+#### New Section: "Local vs CI Testing"
+
+Documents how to run tests locally vs in CI:
+
+| Mode                  | `USE_LOCAL_NEO4J` | How Neo4j is provided |
+| --------------------- | ----------------- | --------------------- |
+| **CI (default)**      | unset/`false`     | Testcontainers        |
+| **Local development** | `true`            | Docker Compose        |
+
+Local developers can run:
+
+```bash
+docker compose up neo4j -d
+USE_LOCAL_NEO4J=true ./mvnw test
+```
+
+#### Minor Formatting
+
+- Added blank lines between code blocks (markdown best practice)
+- Aligned table columns
+- Fixed trailing commas in JavaScript example
+
+---
+
+### 6. `src/test/kotlin/com/embabel/guide/chat/security/McpSecurityTest.kt`
+
+**Type:** New File  
+**Lines:** 69
+
+#### Purpose
+
+Regression test to ensure MCP endpoints are never blocked by Spring Security. If someone accidentally breaks the security configuration, these tests will fail.
+
+#### Tests
+
+```kotlin
+@Test
+fun `MCP SSE endpoint should be accessible without authentication`() {
+    mockMvc.perform(get("/sse"))
+        .andExpect(status().isOk)
+}
+
+@Test
+fun `MCP endpoint should be accessible without authentication`() {
+    val result = mockMvc.perform(get("/mcp")).andReturn()
+    val httpStatus = result.response.status
+    assert(httpStatus != 401 && httpStatus != 403)
+}
+
+@Test
+fun `MCP tools list endpoint should be accessible without authentication`() {
+    val result = mockMvc.perform(get("/mcp/tools/list")).andReturn()
+    val httpStatus = result.response.status
+    assert(httpStatus != 401 && httpStatus != 403)
+}
+```
+
+#### Design Decisions
+
+1. **Uses `@SpringBootTest`** — Full application context, tests real security config
+2. **Checks for NOT 401/403** — The endpoint might return 404 if not registered, which is fine; we only care that Security isn't blocking it
+3. **Includes license header** — Matches project convention
+
+---
+
+### 7. `images/cursor-mcp-installed-servers.svg`
+
+**Type:** New File  
+**Lines:** 41
+
+#### Purpose
+
+Visual documentation showing what a successful Cursor MCP connection looks like.
+
+#### Why SVG?
+
+- **Text-based** — Git can diff it, no binary blobs
+- **Small** — 41 lines, ~2KB
+- **Matches Cursor theme** — Dark background (#0f1115), proper typography
+- **Self-contained** — No external dependencies
+
+#### Content
+
+Shows the "Installed MCP Servers" panel with:
+
+- Server name: `embabel-dev`
+- Status: `38 tools enabled`
+- Toggle: On (green)
+
+---
+
+### 8. `src/test/kotlin/com/embabel/guide/Neo4jTestContainer.kt`
+
+**Type:** Modified  
+**Lines Changed:** +5 / -2
+
+#### Problem
+
+The `USE_LOCAL_NEO4J` flag was a compile-time constant, requiring developers to edit source code to switch between local Neo4j and Testcontainers.
+
+#### Solution
+
+Changed from `const val` to environment variable:
+
+```kotlin
+// Before (required code edit)
+const val USE_LOCAL_NEO4J = false
+
+// After (environment-driven)
+private val USE_LOCAL_NEO4J: Boolean = System.getenv("USE_LOCAL_NEO4J")?.toBoolean() ?: false
+```
+
+Now developers just run:
+
+```bash
+USE_LOCAL_NEO4J=true ./mvnw test
+```
+
+No code changes needed, no risk of accidentally committing `true`.
+
+---
+
+### 9. `src/test/kotlin/com/embabel/guide/TestApplicationContext.kt`
+
+**Type:** Modified  
+**Lines Changed:** +2 / -2
+
+#### Change
+
+Updated to use the `useLocalNeo4j()` function instead of directly accessing the now-private constant:
+
+```kotlin
+// Before
+val useLocalNeo4j = Neo4jTestContainer.USE_LOCAL_NEO4J
+
+// After
+val useLocalNeo4j = Neo4jTestContainer.useLocalNeo4j()
+```
+
+---
+
+### 10. `src/test/resources/application-test.yml`
+
+**Type:** Modified  
+**Lines Changed:** +2 / -2
+
+#### Change
+
+Updated comment to reflect the new environment variable approach:
+
+```yaml
+# Before
+# Edit Neo4jTestContainer.USE_LOCAL_NEO4J constant in Neo4jTestContainer.kt
+
+# After
+# Set environment variable USE_LOCAL_NEO4J=true before running tests
+```
+
+---
+
+### 11. `.gitignore`
+
+**Type:** Modified  
+**Lines Changed:** +3
+
+#### Addition
+
+```gitignore
+# Runtime artifacts
+*.pid
+```
+
+#### Reason
+
+Running the Spring Boot app locally creates `guide-local.pid`. This file should not be committed.
+
+---
+
+## Testing
+
+All 38 tests pass:
+
+```
+[INFO] Tests run: 38, Failures: 0, Errors: 0, Skipped: 0
+[INFO] BUILD SUCCESS
+```
+
+Breakdown:
+
+- 18 HubApiControllerTest
+- 6 HubServiceTest
+- 8 DrivineGuideUserRepositoryTest
+- 3 GuideUserServiceTest
+- **3 McpSecurityTest** (new)
+
+### Test Prerequisites
+
+#### For CI (GitHub Actions)
+
+Tests use Testcontainers to automatically spin up Neo4j. Just needs `OPENAI_API_KEY` secret configured.
+
+#### For Local Development
+
+For faster test runs during development, use a local Neo4j instance:
+
+```bash
+# 1. Start Neo4j
+docker compose up neo4j -d
+
+# 2. Set OpenAI API key
+export OPENAI_API_KEY=sk-your-key-here
+
+# 3. Run tests with local Neo4j
+USE_LOCAL_NEO4J=true ./mvnw test
+```
+
+---
+
+## Verification Steps
+
+### Cursor MCP Connection
+
+1. Start the server:
+
+   ```bash
+   ./mvnw spring-boot:run
+   ```
+
+2. Configure `~/.cursor/mcp.json`:
+
+   ```json
+   {
+     "mcpServers": {
+       "embabel-dev": {
+         "command": "npx",
+         "args": ["-y", "mcp-remote", "http://localhost:1337/sse", "--transport", "sse-only"]
+       }
+     }
+   }
+   ```
+
+3. In Cursor: **Command Palette** → **Developer: Reload Window**
+
+4. Check MCP panel shows "embabel-dev" with "38 tools enabled"
+
+### Docker Build
+
+```bash
+# Fresh clone simulation
+rm -rf target/
+
+# Should succeed without local Maven/Java
+docker compose up --build -d
+
+# Verify
+curl -i --max-time 3 http://localhost:1337/sse
+# Expected: HTTP 200, Content-Type: text/event-stream
+```
+
+---
+
+## Breaking Changes
+
+### For Existing Developers
+
+1. **Docker build is slower** — First build takes ~2-3 minutes (Maven inside Docker)
+
+### Migration
+
+No code changes required. Just be aware:
+
+- `docker compose up` → `docker compose up --build -d` (add `--build`)
+- Tests need `OPENAI_API_KEY` exported
+
+---
+
+## Files Changed Summary
+
+| File                               | Change         | Impact                                       |
+| ---------------------------------- | -------------- | -------------------------------------------- |
+| `SecurityConfig.kt`                | +37 lines      | Fixes Cursor 403 errors                      |
+| `Dockerfile`                       | Rewrite        | Enables fresh-clone Docker builds            |
+| `.dockerignore`                    | Rewrite        | Supports multi-stage build                   |
+| `compose.yaml`                     | +6 lines       | Adds port flexibility, optional services     |
+| `README.md`                        | +170 lines     | Documents Cursor setup, Local vs CI testing  |
+| `McpSecurityTest.kt`               | New (69 lines) | Prevents security regressions                |
+| `cursor-mcp-installed-servers.svg` | New (41 lines) | Visual documentation                         |
+| `Neo4jTestContainer.kt`            | +5 / -2 lines  | `USE_LOCAL_NEO4J` now env var (not constant) |
+| `TestApplicationContext.kt`        | +2 / -2 lines  | Uses `useLocalNeo4j()` function              |
+| `application-test.yml`             | +2 / -2 lines  | Updated comment for env var approach         |
+| `.gitignore`                       | +3 lines       | Ignores `*.pid` files                        |
diff --git a/Dockerfile b/Dockerfile
index beaaed2..ac02b08 100644
--- a/Dockerfile
+++ b/Dockerfile
@@ -1,14 +1,19 @@
-# Use JRE for runtime
-FROM eclipse-temurin:21-jre-jammy
+#
+# Multi-stage build so `docker compose up --build` works from a fresh clone.
+#

+FROM maven:3.9.9-eclipse-temurin-21 AS build
+WORKDIR /workspace
+
+COPY pom.xml ./
+COPY src ./src
+
+RUN mvn -q -DskipTests package
+
+FROM eclipse-temurin:21-jre-jammy AS runtime
 WORKDIR /app

-# Copy the pre-built jar from local target directory
-# Build the JAR locally first with: mvn clean package -DskipTests
-COPY target/*.jar app.jar
+COPY --from=build /workspace/target/*.jar /app/app.jar

-# Expose the application port
 EXPOSE 1337
-
-# Run the application
-ENTRYPOINT ["java", "-jar", "app.jar"]
+ENTRYPOINT ["java", "-jar", "/app/app.jar"]
diff --git a/README.md b/README.md
index ad2c932..dc898c7 100644
--- a/README.md
+++ b/README.md
@@ -103,6 +103,48 @@ Start via `claude --debug` to see more logging.

 See [Claude Code MCP documentation](https://code.claude.com/docs/en/mcp) for further information.

+### Consuming MCP Tools With Cursor
+
+#### 1) Ensure the MCP server is running
+
+Before troubleshooting Cursor, confirm the server is up and returning SSE headers:
+
+```bash
+curl -i --max-time 3 http://localhost:1337/sse
+```
+
+If you're running the server on a different port (for example `1338`), update the URL accordingly.
+
+#### 2) Configure Cursor MCP
+
+Cursor MCP config (Linux):
+
+- `~/.cursor/mcp.json`
+
+Example (recommended: use `mcp-remote` as a stdio bridge for SSE):
+
+```json
+{
+  "mcpServers": {
+    "embabel-dev": {
+      "command": "npx",
+      "args": ["-y", "mcp-remote", "http://localhost:1337/sse", "--transport", "sse-only"]
+    }
+  }
+}
+```
+
+#### 3) Reload Cursor to reconnect
+
+If you start the server after Cursor is already running, or if the server was temporarily down, Cursor may not
+automatically respawn the MCP process. In Cursor:
+
+- **Command Palette** → **Developer: Reload Window**
+
+You should then see the MCP server listed with tools enabled:
+
+![Cursor Installed MCP Servers](images/cursor-mcp-installed-servers.svg)
+
 #### Auto-Approving Embabel MCP Tools

 By default, Claude Code asks for confirmation before running MCP tools. When you accept a tool with "Yes, don't ask
@@ -249,16 +291,79 @@ client.activate();

 ## Docker

-Run with Docker Compose:
+### Start (Docker Compose)
+
+This will start `neo4j` + `guide`.
+
+```bash
+docker compose up --build -d
+```
+
+#### Port conflicts
+
+If port `1337` is already in use (for example, the `chatbot` app is running), override the exposed port:
+
+```bash
+GUIDE_PORT=1338 docker compose up --build -d
+```
+
+This maps container port `1337` → host port `1338`, so MCP SSE becomes:
+
+- `http://localhost:1338/sse`
+
+#### Compose config overrides
+
+Docker Compose supports environment variable overrides. You can set them inline (shown below) or put them in a local
+`.env` file next to `compose.yaml` (Docker Compose auto-loads it).
+
+- **`GUIDE_PORT`**: override host port mapping (default `1337`)
+- **`OPENAI_API_KEY`**: required for LLM calls
+- **`NEO4J_VERSION` / `NEO4J_USERNAME` / `NEO4J_PASSWORD`**: Neo4j settings (optional)
+- **`DISCORD_TOKEN`**: optional, to enable the Discord bot
+
+#### OpenAI API key
+
+The `guide` container needs `OPENAI_API_KEY`. You can:
+
+1. **Create a `.env` file** next to `compose.yaml`:
+
+```bash
+OPENAI_API_KEY=sk-your-key-here
+```
+
+2. **Or pass it inline**:
+
+```bash
+OPENAI_API_KEY=sk-... docker compose up --build -d
+```
+
+#### Verify MCP
+
+```bash
+PORT=${GUIDE_PORT:-1337}
+curl -i --max-time 3 "http://localhost:${PORT}/sse"
+```
+
+You should see `Content-Type: text/event-stream` and an `event:endpoint` line.
+
+#### Optional: run the frontend
+
+The `frontend` service is behind a Compose profile (it requires the `../embabel-hub` repo checkout):
+
+```bash
+COMPOSE_PROFILES=frontend docker compose up --build -d
+```
+
+#### Stop

 ```bash
-docker compose up
+docker compose down --remove-orphans
 ```

 ### Environment Variables

 | Variable         | Default                        | Description            |
-|------------------|--------------------------------|------------------------|
+| ---------------- | ------------------------------ | ---------------------- |
 | `NEO4J_VERSION`  | `2025.10.1-community-bullseye` | Neo4j Docker image tag |
 | `NEO4J_USERNAME` | `neo4j`                        | Neo4j username         |
 | `NEO4J_PASSWORD` | `brahmsian`                    | Neo4j password         |
@@ -268,9 +373,72 @@ docker compose up
 Example:

 ```bash
-NEO4J_PASSWORD=mysecretpassword OPENAI_API_KEY=sk-... docker compose up
+NEO4J_PASSWORD=mysecretpassword OPENAI_API_KEY=sk-... GUIDE_PORT=1338 docker compose up --build -d
+```
+
+## Testing
+
+### Prerequisites
+
+Tests require the following:
+
+1. **OpenAI API Key**: Set `OPENAI_API_KEY` in your environment before running tests:
+
+```bash
+export OPENAI_API_KEY=sk-your-key-here
+```
+
+2. **Neo4j**: See the [Local vs CI Testing](#local-vs-ci-testing) section below.
+
+### Local vs CI Testing
+
+The test suite uses Neo4j, which can be provided in two ways:
+
+| Mode                  | `USE_LOCAL_NEO4J` | How Neo4j is provided                       | Best for                           |
+| --------------------- | ----------------- | ------------------------------------------- | ---------------------------------- |
+| **CI (default)**      | unset/`false`     | Testcontainers spins up Neo4j automatically | GitHub Actions, fresh environments |
+| **Local development** | `true`            | You run Neo4j via Docker Compose            | Faster iteration                   |
+
+#### For Local Development
+
+For faster test runs during development, use a local Neo4j instance:
+
+1. **Start Neo4j**:
+
+```bash
+docker compose up neo4j -d
+```
+
+2. **Run tests with `USE_LOCAL_NEO4J=true`**:
+
+```bash
+export OPENAI_API_KEY=sk-your-key-here
+USE_LOCAL_NEO4J=true ./mvnw test
+```
+
+Or add to your shell profile for persistence:
+
+```bash
+export USE_LOCAL_NEO4J=true
+```
+
+#### For CI
+
+Leave `USE_LOCAL_NEO4J` unset (the default). GitHub Actions uses Testcontainers to automatically spin up Neo4j.
+
+### Running Tests
+
+```bash
+./mvnw test
 ```

+All 38 tests should pass, including:
+
+- Hub API controller tests
+- User service tests
+- Neo4j repository tests
+- **MCP Security regression tests** (verifies `/sse` and `/mcp` endpoints are not blocked by Spring Security)
+
 ## Miscellaneous

 Sometimes (for example if your IDE crashes) you will be left with an orphaned server process and won't be able to
@@ -280,5 +448,3 @@ To kill the server:
 ```aiignore
 lsof -ti:1337 | xargs kill -9
 ```
-
-
diff --git a/compose.yaml b/compose.yaml
index be26232..8cc722e 100644
--- a/compose.yaml
+++ b/compose.yaml
@@ -26,6 +26,8 @@ services:
       - embabel-network

   neo4j-init:
+    profiles:
+      - init
     image: neo4j:${NEO4J_VERSION:-2025.10.1-community-bullseye}
     container_name: embabel-neo4j-init
     depends_on:
@@ -44,7 +46,7 @@ services:
       dockerfile: Dockerfile
     container_name: embabel-guide
     ports:
-      - "1337:1337"
+      - "${GUIDE_PORT:-1337}:1337"
     environment:
       - NEO4J_URI=bolt://neo4j:7687
       - NEO4J_HOST=neo4j
@@ -62,6 +64,8 @@ services:
     restart: unless-stopped

   frontend:
+    profiles:
+      - frontend
     build:
       context: ../embabel-hub
       dockerfile: Dockerfile
diff --git a/images/cursor-mcp-installed-servers.svg b/images/cursor-mcp-installed-servers.svg
new file mode 100644
index 0000000..9dcaec4
--- /dev/null
+++ b/images/cursor-mcp-installed-servers.svg
@@ -0,0 +1,41 @@
+<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="260" viewBox="0 0 1100 260">
+  <defs>
+    <style>
+      .bg { fill: #0f1115; }
+      .panel { fill: #141823; stroke: #2a2f3a; stroke-width: 1; }
+      .text { fill: #e6e6e6; font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, Noto Sans, Helvetica, Arial; }
+      .muted { fill: #a8b0bf; }
+      .title { font-size: 22px; font-weight: 650; }
+      .label { font-size: 18px; font-weight: 600; }
+      .small { font-size: 16px; }
+      .pill { fill: #1b2230; stroke: #2a2f3a; stroke-width: 1; }
+      .toggleTrack { fill: #1d6f42; }
+      .toggleKnob { fill: #e6fff2; }
+    </style>
+  </defs>
+
+  <!-- background -->
+  <rect class="bg" x="0" y="0" width="1100" height="260" rx="16" />
+
+  <!-- panel -->
+  <rect class="panel" x="40" y="40" width="1020" height="180" rx="14" />
+
+  <!-- title -->
+  <text class="text title" x="70" y="82">Installed MCP Servers</text>
+
+  <!-- server row -->
+  <rect class="pill" x="70" y="105" width="960" height="78" rx="12" />
+
+  <!-- icon -->
+  <circle cx="108" cy="144" r="18" fill="#22283a" stroke="#2a2f3a" stroke-width="1"/>
+  <text class="text label" x="102" y="150">E</text>
+
+  <!-- server name -->
+  <text class="text label" x="155" y="140">embabel-dev</text>
+  <text class="text muted small" x="155" y="165">38 tools enabled</text>
+
+  <!-- toggle -->
+  <rect class="toggleTrack" x="950" y="126" width="64" height="30" rx="15" />
+  <circle class="toggleKnob" cx="1000" cy="141" r="12" />
+</svg>
+
diff --git a/src/main/kotlin/com/embabel/guide/chat/security/SecurityConfig.kt b/src/main/kotlin/com/embabel/guide/chat/security/SecurityConfig.kt
index cb816fe..2494f56 100644
--- a/src/main/kotlin/com/embabel/guide/chat/security/SecurityConfig.kt
+++ b/src/main/kotlin/com/embabel/guide/chat/security/SecurityConfig.kt
@@ -4,10 +4,14 @@ import com.embabel.hub.JwtAuthenticationFilter
 import org.springframework.context.annotation.Bean
 import org.springframework.context.annotation.Configuration
 import org.springframework.http.HttpMethod
+import org.springframework.core.annotation.Order
 import org.springframework.security.config.annotation.web.builders.HttpSecurity
 import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
+import org.springframework.security.config.annotation.web.configuration.WebSecurityCustomizer
 import org.springframework.security.web.SecurityFilterChain
 import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter
+import org.springframework.security.web.util.matcher.AntPathRequestMatcher
+import org.springframework.security.web.util.matcher.OrRequestMatcher

 @Configuration
 @EnableWebSecurity
@@ -22,6 +26,27 @@ class SecurityConfig(
         "/mcp/**",
     )

+    private val mcpMatchers = arrayOf(
+        AntPathRequestMatcher("/sse"),
+        AntPathRequestMatcher("/sse/**"),
+        AntPathRequestMatcher("/mcp"),
+        AntPathRequestMatcher("/mcp/**"),
+    )
+
+    private val mcpMatcher = OrRequestMatcher(*mcpMatchers)
+
+    /**
+     * Hard bypass for MCP endpoints.
+     *
+     * Some auto-configurations can contribute additional SecurityFilterChains that take precedence,
+     * which can cause `/mcp` to return 403 even if we try to permit it. Ignoring bypasses the entire
+     * Spring Security filter chain for these endpoints, which is what Cursor/Claude/etc. want.
+     */
+    @Bean
+    fun webSecurityCustomizer(): WebSecurityCustomizer = WebSecurityCustomizer { web ->
+        web.ignoring().requestMatchers(*mcpMatchers)
+    }
+
     val permittedPatterns = arrayOf(
         "/ws/**",
         "/app/**",
@@ -33,12 +58,28 @@ class SecurityConfig(
     ) + mcpPatterns

     @Bean
+    @Order(0)
+    fun mcpFilterChain(http: HttpSecurity): SecurityFilterChain {
+        // Some Cursor builds try streamable HTTP first (POST /mcp...), then fall back to SSE (/sse).
+        // If any other auto-configured security chain matches /mcp first, it can result in 403s and flakey MCP.
+        // This chain is scoped to MCP endpoints only and is highest precedence.
+        // Use AntPathRequestMatcher so this applies even if /mcp is registered outside Spring MVC handler mappings.
+        http.securityMatcher(mcpMatcher)
+            .csrf { it.disable() }
+            .cors { }
+            .authorizeHttpRequests { it.anyRequest().permitAll() }
+        return http.build()
+    }
+
+    @Bean
+    @Order(1)
     fun filterChain(http: HttpSecurity): SecurityFilterChain {
         http.csrf { it.disable() }
             .cors { }  // Enable CORS with default configuration from WebConfig
             .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter::class.java)
             .authorizeHttpRequests {
                 it.requestMatchers(*permittedPatterns).permitAll()
+                it.requestMatchers(*mcpMatchers).permitAll()
                 it.requestMatchers(
                     HttpMethod.POST,
                     "/api/messages/user",
diff --git a/src/test/kotlin/com/embabel/guide/Neo4jTestContainer.kt b/src/test/kotlin/com/embabel/guide/Neo4jTestContainer.kt
index d01ba4d..3c02581 100644
--- a/src/test/kotlin/com/embabel/guide/Neo4jTestContainer.kt
+++ b/src/test/kotlin/com/embabel/guide/Neo4jTestContainer.kt
@@ -24,10 +24,13 @@ class Neo4jTestContainer : Neo4jContainer<Neo4jTestContainer> {
     companion object {
         /**
          * Toggle between local Neo4j and TestContainers.
-         * Set to true to use local Neo4j (requires Neo4j running on localhost:7687).
-         * Set to false to use TestContainers (slower startup, but fully isolated).
+         *
+         * Set environment variable USE_LOCAL_NEO4J=true to use local Neo4j
+         * (requires Neo4j running on localhost:7687).
+         *
+         * Default (unset or false): Uses TestContainers (slower startup, but fully isolated).
          */
-        const val USE_LOCAL_NEO4J = false
+        private val USE_LOCAL_NEO4J: Boolean = System.getenv("USE_LOCAL_NEO4J")?.toBoolean() ?: false

         private const val LOCAL_NEO4J_URL = "bolt://localhost:7687"
         private const val LOCAL_NEO4J_USERNAME = "neo4j"
diff --git a/src/test/kotlin/com/embabel/guide/TestApplicationContext.kt b/src/test/kotlin/com/embabel/guide/TestApplicationContext.kt
index d9bab8b..cce775b 100644
--- a/src/test/kotlin/com/embabel/guide/TestApplicationContext.kt
+++ b/src/test/kotlin/com/embabel/guide/TestApplicationContext.kt
@@ -46,12 +46,12 @@ class Neo4jPropertiesInitializer : ApplicationContextInitializer<ConfigurableApp
     }

     override fun initialize(applicationContext: ConfigurableApplicationContext) {
-        // Check Neo4jTestContainer.USE_LOCAL_NEO4J constant to determine whether to use local Neo4j
-        val useLocalNeo4j = Neo4jTestContainer.USE_LOCAL_NEO4J
+        // Check USE_LOCAL_NEO4J environment variable to determine whether to use local Neo4j
+        val useLocalNeo4j = Neo4jTestContainer.useLocalNeo4j()

         val activeProfiles = applicationContext.environment.activeProfiles

-        println("@@@ Neo4jPropertiesInitializer.initialize() CALLED! useLocalNeo4j=$useLocalNeo4j (from Neo4jTestContainer.USE_LOCAL_NEO4J), activeProfiles=${activeProfiles.joinToString(",")} @@@")
+        println("@@@ Neo4jPropertiesInitializer.initialize() CALLED! useLocalNeo4j=$useLocalNeo4j (from USE_LOCAL_NEO4J env var), activeProfiles=${activeProfiles.joinToString(",")} @@@")

         val properties = if (useLocalNeo4j) {
             println("@@@ Using local Neo4j at $LOCAL_NEO4J_URI @@@")
diff --git a/src/test/kotlin/com/embabel/guide/chat/security/McpSecurityTest.kt b/src/test/kotlin/com/embabel/guide/chat/security/McpSecurityTest.kt
new file mode 100644
index 0000000..aaa4248
--- /dev/null
+++ b/src/test/kotlin/com/embabel/guide/chat/security/McpSecurityTest.kt
@@ -0,0 +1,69 @@
+/*
+ * Copyright 2024-2025 Embabel Software, Inc.
+ *
+ * Licensed under the Apache License, Version 2.0 (the "License");
+ * you may not use this file except in compliance with the License.
+ * You may obtain a copy of the License at
+ *
+ * http://www.apache.org/licenses/LICENSE-2.0
+ *
+ * Unless required by applicable law or agreed to in writing, software
+ * distributed under the License is distributed on an "AS IS" BASIS,
+ * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
+ * See the License for the specific language governing permissions and
+ * limitations under the License.
+ */
+package com.embabel.guide.chat.security
+
+import org.junit.jupiter.api.Test
+import org.springframework.beans.factory.annotation.Autowired
+import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
+import org.springframework.boot.test.context.SpringBootTest
+import org.springframework.test.web.servlet.MockMvc
+import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
+import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status
+
+/**
+ * Regression test for MCP endpoint security configuration.
+ *
+ * Ensures that MCP endpoints are NOT blocked by Spring Security.
+ * These endpoints must be publicly accessible for MCP clients like Cursor to connect.
+ *
+ * Context: We use WebSecurityCustomizer to bypass Spring Security for MCP paths.
+ * If this test fails with 401 or 403, check SecurityConfig mcpSecurityCustomizer bean.
+ */
+@SpringBootTest
+@AutoConfigureMockMvc
+class McpSecurityTest {
+
+    @Autowired
+    private lateinit var mockMvc: MockMvc
+
+    @Test
+    fun `MCP SSE endpoint should be accessible without authentication`() {
+        mockMvc.perform(get("/sse"))
+            .andExpect(status().isOk)
+    }
+
+    @Test
+    fun `MCP endpoint should be accessible without authentication`() {
+        val result = mockMvc.perform(get("/mcp"))
+            .andReturn()
+
+        val httpStatus = result.response.status
+        assert(httpStatus != 401 && httpStatus != 403) {
+            "MCP endpoint returned $httpStatus but expected not 401 or 403"
+        }
+    }
+
+    @Test
+    fun `MCP tools list endpoint should be accessible without authentication`() {
+        val result = mockMvc.perform(get("/mcp/tools/list"))
+            .andReturn()
+
+        val httpStatus = result.response.status
+        assert(httpStatus != 401 && httpStatus != 403) {
+            "MCP tools endpoint returned $httpStatus but expected not 401 or 403"
+        }
+    }
+}
diff --git a/src/test/resources/application-test.yml b/src/test/resources/application-test.yml
index 1845f4e..48237f7 100644
--- a/src/test/resources/application-test.yml
+++ b/src/test/resources/application-test.yml
@@ -1,9 +1,9 @@
 # Test configuration
 #
 # To toggle between local Neo4j and TestContainers:
-# Edit Neo4jTestContainer.USE_LOCAL_NEO4J constant in Neo4jTestContainer.kt
+# Set environment variable USE_LOCAL_NEO4J=true before running tests
 # - true: Use local Neo4j (faster, requires Neo4j running on localhost:7687)
-# - false: Use TestContainers (slower startup, but fully isolated)
+# - false (default): Use TestContainers (slower startup, but fully isolated)

 # Logging configuration for tests
 logging:
```

## Reviews & Comments
