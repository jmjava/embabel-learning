# Discussion Brief

## PR Information

**Repository:** embabel/guide
**PR Number:** #15
**Title:** feat: Enable MCP server integration with Cursor IDE
**Status:** MERGED
**Author:** jmjava
**Created:** 2025-12-19T03:24:53Z
**PR URL:** https://github.com/embabel/guide/pull/15
**CURSOR-PR.md:** https://github.com/embabel/guide/blob/main/CURSOR-PR.md

## Changes Summary

- **Lines Added:** 927
- **Lines Removed:** 32
- **Files Changed:** 12

## Description

Files changed:

- .dockerignore: Include source files for multi-stage Docker build
- .gitignore: Ignore \*.pid files
- CURSOR-PR.md: Detailed PR documentation ([view on GitHub](https://github.com/embabel/guide/blob/main/CURSOR-PR.md))
- Dockerfile: Multi-stage build to compile from source
- README.md: Cursor integration docs, Docker startup improvements, testing prerequisites
- compose.yaml: Parameterized port, optional services via profiles
- images/cursor-mcp-installed-servers.svg: Documentation screenshot
- src/main/kotlin/.../SecurityConfig.kt: Bypass Spring Security for /sse and /mcp endpoints
- src/test/kotlin/.../Neo4jTestContainer.kt: Use local Neo4j for tests
- src/test/kotlin/.../McpSecurityTest.kt: Regression tests for MCP endpoint accessibility

See CURSOR-PR.md for detailed file-by-file analysis and rationale.

## Files Modified

### `.dockerignore`

- **Additions:** +8
- **Deletions:** -8

### `.gitignore`

- **Additions:** +3
- **Deletions:** -0

### `CURSOR-PR.md`

- **Additions:** +563
- **Deletions:** -0

### `Dockerfile`

- **Additions:** +14
- **Deletions:** -9

### `README.md`

- **Additions:** +172
- **Deletions:** -6

### `compose.yaml`

- **Additions:** +5
- **Deletions:** -1

### `images/cursor-mcp-installed-servers.svg`

- **Additions:** +41
- **Deletions:** -0

### `src/main/kotlin/com/embabel/guide/chat/security/SecurityConfig.kt`

- **Additions:** +41
- **Deletions:** -0

### `src/test/kotlin/com/embabel/guide/Neo4jTestContainer.kt`

- **Additions:** +6
- **Deletions:** -3

### `src/test/kotlin/com/embabel/guide/TestApplicationContext.kt`

- **Additions:** +3
- **Deletions:** -3

### `src/test/kotlin/com/embabel/guide/chat/security/McpSecurityTest.kt`

- **Additions:** +69
- **Deletions:** -0

### `src/test/resources/application-test.yml`

- **Additions:** +2
- **Deletions:** -2

## Key Technical Changes

### Summary

This PR enables **Cursor IDE** to connect to the Embabel MCP server by fixing Spring Security configuration issues that were blocking MCP endpoints. It also improves the Docker workflow so `docker compose up --build` works from a fresh clone without requiring a pre-built JAR.

### Main Changes

1. **Fixed HTTP 403 errors blocking Cursor from connecting to `/sse` and `/mcp` endpoints**

   - Added three-layer security defense (WebSecurityCustomizer, dedicated filter chain, explicit matchers)
   - Used `AntPathRequestMatcher` to match servlet-registered endpoints
   - Ensures MCP endpoints are never blocked by Spring Security

2. **Multi-stage Docker build enabling builds from source**

   - Stage 1: Maven build inside Docker container
   - Stage 2: Runtime JRE image with compiled JAR
   - Now works from fresh clone with only Docker installed (no local Java/Maven needed)

3. **Flexible Docker Compose configuration**

   - Parameterized port via `GUIDE_PORT` environment variable
   - Profile-gated optional services (`neo4j-init`, `frontend`)
   - Prevents failures from missing dependencies

4. **Comprehensive documentation**

   - Step-by-step Cursor MCP setup instructions
   - Visual confirmation screenshot (SVG)
   - Testing prerequisites and local vs CI testing guide

5. **Regression tests for MCP security**
   - 3 new tests in `McpSecurityTest.kt`
   - Prevents future security config breaks
   - Validates `/sse`, `/mcp`, and `/mcp/tools/list` are accessible

## Rationale / Why These Changes?

### Problem 1: Cursor Couldn't Connect (HTTP 403)

**Root Cause:** Spring Boot auto-configuration was adding additional `SecurityFilterChain` beans that took precedence over custom configurations. When multiple filter chains exist, the first matching chain handles the request—and if it doesn't explicitly permit the path, it defaults to denying access.

**Why the fix works:**

- **WebSecurityCustomizer** completely bypasses the security filter chain for MCP paths
- **@Order(0) filter chain** catches MCP requests before any other chain if web.ignoring() is removed
- **Explicit matchers** in main filter chain as belt-and-suspenders
- **AntPathRequestMatcher** needed because `/sse` is registered by MCP library directly with servlet container, not Spring MVC

### Problem 2: Docker Build Required Pre-built JAR

**Pain Point:** Developers needed to install Java 21 + Maven locally and run `mvn package` before `docker compose up`. Fresh clones would fail.

**Why multi-stage build:**

- Eliminates local Java/Maven requirement
- Makes onboarding easier for new contributors
- Works in any environment with just Docker
- Trade-off: Longer build time (~2-3 min vs ~5 sec) but better DX

### Problem 3: Port Conflicts and Missing Dependencies

**Issues:**

- Port 1337 might be in use by another service
- `neo4j-init` requires files that might not exist
- **`frontend` requires `../embabel-hub` repo checkout** (critical issue)

**The embabel-hub Problem:**

The `compose.yaml` originally had a `frontend` service that referenced:

```yaml
frontend:
  build:
    context: ../embabel-hub # Assumes embabel-hub repo exists next to guide
```

**Why this was problematic:**

1. **embabel-hub is a separate repository** (and may be private)
2. **Not everyone has access** - public contributors can't clone private repos
3. **Fresh clone scenario fails:**
   ```bash
   git clone git@github.com:embabel/guide.git
   cd guide
   docker compose up  # ❌ FAILS - can't find ../embabel-hub
   ```
4. **Confusing error messages** for new contributors who don't have access
5. **Couples guide repo to embabel-hub** - breaks isolation

**Why profiles and parameterization:**

- **`GUIDE_PORT`** allows developers to override port without editing files
- **Profiles make optional services opt-in**, preventing startup failures
- **Decouples guide from embabel-hub** - guide repo is now self-contained
- **Default config works from fresh clone** with zero external dependencies
- **Developers with access** can still use frontend: `COMPOSE_PROFILES=frontend docker compose up`

**The bigger win:** This made the guide repo **public-friendly** and accessible to external contributors who don't have access to private repos.

### Problem 4: Testing Friction

**Issue:** `USE_LOCAL_NEO4J` was a compile-time constant requiring code edits.

**Why environment variable:**

- No code changes needed to switch between local Neo4j and Testcontainers
- No risk of accidentally committing `true`
- Faster local development (reuse running Neo4j vs spin up Testcontainers)

## Testing Done

- [x] **All 38 tests pass** (18 HubApiController + 6 HubService + 8 DrivineGuideUser + 3 GuideUserService + 3 McpSecurity)
- [x] **Cursor MCP connection verified** - Connected Cursor IDE to `/sse`, saw "38 tools enabled"
- [x] **Docker fresh-clone test** - `rm -rf target/ && docker compose up --build -d` succeeded
- [x] **MCP endpoint accessibility** - Verified `/sse`, `/mcp`, `/mcp/tools/list` return 200, not 401/403
- [x] **Port override** - Tested `GUIDE_PORT=1338 docker compose up --build -d`
- [x] **Profile-gated services** - Verified default compose up skips `neo4j-init` and `frontend`
- [x] **Local Neo4j testing** - `USE_LOCAL_NEO4J=true ./mvnw test` succeeded
- [x] **CI testing** - GitHub Actions pipeline passed with Testcontainers

## Key Discussion Points

### Potential Questions:

**Q: Why three layers of security configuration? Isn't that overkill?**
A: Spring Security's behavior with multiple filter chains can be unpredictable, especially as dependencies and auto-configuration evolve. The three-layer approach ensures:

- Layer 1 (WebSecurityCustomizer) is the strongest - completely bypasses filters
- Layer 2 (@Order(0) chain) is backup if Layer 1 is ever removed
- Layer 3 (explicit matchers) is defense-in-depth

This "belt and suspenders" approach prevents the exact issue that caused the original 403 errors.

**Q: Why AntPathRequestMatcher instead of the recommended MvcRequestMatcher?**
A: The `/sse` endpoint is registered by the MCP library directly with the servlet container, not through Spring MVC. `MvcRequestMatcher` only matches paths registered with Spring MVC, so it doesn't see `/sse`. `AntPathRequestMatcher` matches any request path regardless of how it's registered.

Yes, there are deprecation warnings - Spring recommends `AntPathRequestMatcher.antMatcher("/path")` instead of the constructor. This is cosmetic and can be addressed in a follow-up if needed.

**Q: The Docker build is now much slower (2-3 minutes vs 5 seconds). Is this acceptable?**
A: Yes, because:

1.  **Better DX**: Fresh clones work with only Docker (no Java/Maven install needed)
2.  **Better for new contributors**: Lower barrier to entry
3.  **Cached in practice**: Layers are cached, rebuilds only take ~30 seconds
4.  **CI unchanged**: CI can still use pre-built JARs if preferred

The trade-off favors onboarding and ease of use over build speed.

**Q: Why use profiles for neo4j-init and frontend instead of just removing them?**
A: Profiles preserve existing functionality for developers who use these services while making them opt-in. Developers with the full setup can run:

```bash
COMPOSE_PROFILES=init,frontend docker compose up --build -d
```

This is better than forcing everyone to comment/uncomment service definitions.

**Q: How does this relate to embabel-hub being private?**
A: The `frontend` service required `../embabel-hub` to exist, which created several problems:

**The Problem:**

- embabel-hub is a separate repository (potentially private)
- Public contributors can't access private repos
- Fresh clones fail: `docker compose up` → Error: "context path ../embabel-hub does not exist"
- Tightly couples guide repo to embabel-hub availability

**The Solution (Profiles):**

- Made `frontend` opt-in via profile: only runs if `COMPOSE_PROFILES=frontend` is set
- Default `docker compose up` now works without embabel-hub
- Guide repo is now **self-contained and public-friendly**
- External contributors can use guide without access to private repos

**Impact:**

| Scenario                          | Before                    | After                                       |
| --------------------------------- | ------------------------- | ------------------------------------------- |
| Public contributor clones guide   | ❌ Fails (no embabel-hub) | ✅ Works (frontend optional)                |
| Developer with embabel-hub access | ✅ Works                  | ✅ Works (with `COMPOSE_PROFILES=frontend`) |
| CI/CD pipelines                   | ❌ May fail               | ✅ Works (no frontend by default)           |
| Fresh clone experience            | ❌ Confusing errors       | ✅ Clean start                              |

This is a **key design decision** that makes the guide repo accessible to the broader community while preserving functionality for internal developers with full access.

**Q: How does this impact existing developers?**
A: Minimal impact:

- Docker builds are slower (but cached)
- Need to add `--build -d` to docker compose command
- Tests require `OPENAI_API_KEY` exported (was already needed, now documented)
- Everything else works as before

**Q: Did you consider alternative approaches to the security fix?**
A: Yes, considered:

1.  **Disabling Spring Security entirely** - Too risky, needed for other endpoints
2.  **Custom filter** - More complex, harder to maintain
3.  **Moving MCP to separate port** - Would require client config changes

The WebSecurityCustomizer approach is Spring's recommended way to completely bypass security for specific paths.

**Q: Why add regression tests if the fix works?**
A: Because this exact issue (security blocking MCP endpoints) could easily be re-introduced:

- Someone adds a new security config
- Spring Boot version upgrade changes auto-configuration
- Dependency update changes filter chain ordering

The tests fail fast if any of these break MCP access.

**Q: Why make USE_LOCAL_NEO4J an environment variable instead of a constant?**
A: Prevents the common mistake of:

1.  Developer changes constant to `true` for local testing
2.  Forgets to change it back
3.  Commits `true` to repo
4.  CI fails because it expects Testcontainers

Environment variable approach is "pit of success" - impossible to accidentally commit the wrong value.

## Review Comments & Responses

_No review comments - PR was merged directly._

---

## Detailed Technical Reference

_For deeper dives during discussion, see sections below:_

### Security Configuration Deep Dive

**Three-Layer Defense:**

1. **WebSecurityCustomizer (Layer 1 - Strongest)**

   ```kotlin
   @Bean
   fun webSecurityCustomizer(): WebSecurityCustomizer = WebSecurityCustomizer { web ->
       web.ignoring().requestMatchers(*mcpMatchers)
   }
   ```

   - Completely bypasses Spring Security filter chain
   - Requests to `/sse/**` and `/mcp/**` never touch security filters

2. **Dedicated Filter Chain (Layer 2 - Backup)**

   ```kotlin
   @Bean
   @Order(0)
   fun mcpFilterChain(http: HttpSecurity): SecurityFilterChain {
       http.securityMatcher(mcpMatcher)
           .csrf { it.disable() }
           .cors { }
           .authorizeHttpRequests { it.anyRequest().permitAll() }
       return http.build()
   }
   ```

   - @Order(0) ensures it's checked first
   - Catches MCP requests before any other filter chain

3. **Explicit Matchers (Layer 3 - Belt and Suspenders)**
   ```kotlin
   it.requestMatchers(*mcpMatchers).permitAll()
   ```
   - Added to existing filterChain
   - Defense-in-depth

### Docker Multi-Stage Build

#### The Problem Before

The original Dockerfile expected a pre-built JAR:

```dockerfile
COPY target/*.jar app.jar
```

This created pain points:

1. 🚫 Developers had to **install Java 21 + Maven locally**
2. 🚫 Had to run `mvn clean package -DskipTests` **before** `docker compose up`
3. 🚫 **Fresh clones would fail** if Java wasn't installed
4. 🚫 Higher barrier to entry for new contributors
5. 🚫 Two-step process instead of one command

#### The Solution: Multi-Stage Build

**Stage 1: Build** (Lines 108-112)

```dockerfile
FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /workspace
COPY pom.xml ./
COPY src ./src
RUN mvn -q -DskipTests package
```

- Uses a Maven image to compile the code **inside Docker**
- No local Java/Maven installation needed
- Source files are copied into the build container
- Maven runs in the container to produce the JAR

**Stage 2: Runtime** (Lines 115-119)

```dockerfile
FROM eclipse-temurin:21-jre-jammy AS runtime
WORKDIR /app
COPY --from=build /workspace/target/*.jar /app/app.jar
EXPOSE 1337
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

- Takes the JAR from Stage 1 using `COPY --from=build`
- Uses a lightweight JRE image (not the full Maven image)
- Final image is smaller and cleaner (~400MB vs ~800MB with Maven)
- Only runtime dependencies included

#### Why This Matters

✅ **Fresh clones now work** - Just `docker compose up --build` with only Docker installed
✅ **Better onboarding** - New contributors don't need to install Java toolchain
✅ **Simpler workflow** - One command instead of two-step process
✅ **Works anywhere** - Same behavior on Mac, Windows, Linux
✅ **"Pit of success"** - Easiest path is also the correct path
✅ **Docker layer caching** - Rebuilds are fast (~30 seconds) since `pom.xml` is copied separately

#### Trade-offs

| Aspect        | Before                | After                      |
| ------------- | --------------------- | -------------------------- |
| Build time    | ~5 seconds (copy JAR) | ~2-3 minutes (Maven build) |
| Prerequisites | Java 21 + Maven       | **Docker only**            |
| Fresh clone   | ❌ Fails              | ✅ **Works**               |
| CI/CD         | May need adjustment   | Works as-is                |
| Image size    | ~200MB (JRE only)     | ~400MB (multi-stage)       |
| Rebuild time  | N/A                   | ~30 seconds (cached)       |

**Conclusion:** Slower initial build time is worth it for better developer experience and lower barrier to entry. The trade-off heavily favors onboarding and ease of use.

### Docker Compose Improvements

#### Parameterized Port

**Problem:** Port 1337 might be in use by another service.

**Solution:**

```yaml
ports:
  - '${GUIDE_PORT:-1337}:1337'
```

Usage: `GUIDE_PORT=1338 docker compose up --build -d`

#### Profile-Gated Services (Critical for Public Access)

**Problem:** Services had hard dependencies on external repos and files:

- `frontend` → requires `../embabel-hub` (potentially private repo)
- `neo4j-init` → requires `neo4j-init/init.sh` (may not exist)

**Solution:** Made them opt-in via Docker Compose profiles:

```yaml
neo4j-init:
  profiles:
    - init
  # Only runs if COMPOSE_PROFILES includes "init"

frontend:
  profiles:
    - frontend
  build:
    context: ../embabel-hub # Only accessed if profile is active
```

**Usage Examples:**

```bash
# Default: Works from fresh clone, no external dependencies
docker compose up --build -d
# Starts: neo4j + guide only

# With frontend (requires embabel-hub repo)
COMPOSE_PROFILES=frontend docker compose up --build -d
# Starts: neo4j + guide + frontend

# With neo4j-init (requires init script)
COMPOSE_PROFILES=init docker compose up --build -d
# Starts: neo4j + neo4j-init + guide

# With multiple profiles
COMPOSE_PROFILES=init,frontend docker compose up --build -d
# Starts: neo4j + neo4j-init + guide + frontend
```

**Why This Matters:**

This change **decoupled the guide repo from embabel-hub**, making it:

- ✅ **Self-contained** - works without external repos
- ✅ **Public-friendly** - external contributors don't need access to private repos
- ✅ **Easier onboarding** - fresh clones just work
- ✅ **Flexible** - internal devs can still use full stack with one env var

**Key Design Principle:** Default behavior should work for the most people (public contributors), with opt-in for advanced scenarios (internal devs with full access).

### Test Strategy

**Local Development (Fast):**

```bash
docker compose up neo4j -d
USE_LOCAL_NEO4J=true ./mvnw test
```

**CI (Isolated):**

```bash
# Testcontainers spins up Neo4j automatically
./mvnw test
```

### Files Changed Summary

| File                               | Change         | Impact                                       |
| ---------------------------------- | -------------- | -------------------------------------------- |
| `SecurityConfig.kt`                | +37 lines      | Fixes Cursor 403 errors                      |
| `Dockerfile`                       | Rewrite        | Enables fresh-clone Docker builds            |
| `.dockerignore`                    | Rewrite        | Supports multi-stage build                   |
| `compose.yaml`                     | +6 lines       | Adds port flexibility, optional services     |
| `README.md`                        | +170 lines     | Documents Cursor setup, Local vs CI testing  |
| `McpSecurityTest.kt`               | New (69 lines) | Prevents security regressions                |
| `cursor-mcp-installed-servers.svg` | New (41 lines) | Visual documentation                         |
| `Neo4jTestContainer.kt`            | +5 / -2 lines  | `USE_LOCAL_NEO4J` now env var (not constant) |
| `TestApplicationContext.kt`        | +2 / -2 lines  | Uses `useLocalNeo4j()` function              |
| `application-test.yml`             | +2 / -2 lines  | Updated comment for env var approach         |
| `.gitignore`                       | +3 lines       | Ignores `*.pid` files                        |
