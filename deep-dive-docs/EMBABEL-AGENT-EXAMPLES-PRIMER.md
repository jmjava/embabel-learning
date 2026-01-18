# Embabel Agent Examples - Architecture Primer

## Overview

The `embabel-agent-examples` repository is a **learning-oriented project** that demonstrates best practices for building AI agents with the Embabel Agent Framework. It provides both Java and Kotlin implementations of the same examples, making it an excellent resource for understanding how to structure agent projects.

## Key Purposes

1. **Educational Resource**: Side-by-side Java and Kotlin examples
2. **Best Practices**: Demonstrates current recommended patterns
3. **Multiple Modes**: Shows shell, MCP client, and MCP server configurations
4. **Template Reference**: Serves as extended documentation for the template repositories

## Module Structure

```
embabel-agent-examples/
├── examples-java/           # ☕ Java implementations
├── examples-kotlin/         # 🏆 Kotlin implementations
├── examples-common/         # 🔧 Shared services & utilities
└── scripts/                 # 🚀 Quick-start scripts
    ├── java/
    │   ├── shell.sh         # Launch shell mode
    │   └── mcp_server.sh    # Launch MCP server
    └── kotlin/
        ├── shell.sh
        └── mcp_server.sh
```

---

## Package Organization

### examples-java/src/main/java/com/embabel/example/

| Package | Description | Key Files |
|---------|-------------|-----------|
| `horoscope/` | Beginner: Star news finder agent | `StarNewsFinder.java`, `Horoscope.java` |
| `injection/` | Simplest AI usage with Spring DI | `InjectedComponent.java` |
| `injection/travel/` | Travel planning example | Multiple agents |
| `factchecker/` | Fact verification agent | `FactChecker.java` |
| `handoff/` | Agent handoff patterns | `Handoff.java`, `Subagents.java` |
| `crew/bookwriter/` | Multi-agent book writing | README, implementation |
| `pydantic/banksupport/` | Bank support example | Multiple files |
| `repeatuntil/` | Iterative improvement pattern | `ReviseStoryUntilSatisfied.java` |
| `supervisor/` | Supervisor pattern | `Stages.java`, `SupervisorShell.java` |
| `wikipedia/` | Research agent | `WikiAgent.java` |

### examples-kotlin/src/main/kotlin/com/embabel/example/

| Package | Description | Key Files |
|---------|-------------|-----------|
| `horoscope/` | Kotlin star news agent | `StarNewsFinder.kt` |
| `factchecker/` | DSL-based fact checker | `factChecker.kt` |
| `researcher/` | Multi-LLM research agent | `researcher.kt` |

### examples-common/

Shared components used by both Java and Kotlin examples:

| Package | Description |
|---------|-------------|
| `common/` | `InMemoryCrudRepository` for testing |
| `common/prompt/` | Shared prompt utilities |
| `common/support/` | Support utilities |
| `horoscope/` | `HoroscopeService` - shared service |

---

## Application Modes

The examples demonstrate three distinct application modes:

### 1. Shell Mode (Interactive CLI)

```java
@SpringBootApplication
@EnableAgents(loggingTheme = LoggingThemes.STAR_WARS)
public class JavaAgentShellApplication { }
```

**Starter dependency**: `embabel-agent-starter-shell`

### 2. Shell + MCP Client Mode

```java
@SpringBootApplication
@EnableAgents(
    loggingTheme = LoggingThemes.SEVERANCE,
    mcpServers = {McpServers.DOCKER_DESKTOP}
)
public class JavaAgentShellMcpClientApplication { }
```

Enables access to external MCP tools like Docker Desktop.

### 3. MCP Server Mode

```java
@SpringBootApplication
@EnableAgents(mcpServers = {McpServers.DOCKER_DESKTOP})
public class JavaMcpServerApplication { }
```

**Starter dependency**: `embabel-agent-starter-mcpserver`

Exposes agents as MCP tools callable from Claude Desktop or other MCP clients.

---

## Key Patterns Demonstrated

### Pattern 1: Annotation-Based Agent (Java)

The `StarNewsFinder` demonstrates the standard annotation approach:

```java
@Agent(
    name = "JavaStarNewsFinder",
    description = "Find news based on a person's star sign",
    beanName = "javaStarNewsFinder"
)
public class StarNewsFinder {

    @Action
    public Person extractPerson(UserInput userInput, Ai ai) {
        return ai.withLlm(OpenAiModels.GPT_41)
            .createObjectIfPossible("...", PersonImpl.class);
    }

    @Action(cost = 100.0)  // High cost = last resort
    public Starry makeStarry(Person person) {
        return WaitFor.formSubmission("...", Starry.class);
    }

    @Action(toolGroups = {CoreToolGroups.WEB})
    public RelevantNewsStories findNewsStories(...) { ... }

    @AchievesGoal(
        description = "Write an amusing writeup...",
        export = @Export(remote = true, name = "starNewsWriteupJava")
    )
    @Action
    public Writeup writeup(...) { ... }
}
```

### Pattern 2: DSL-Based Agent (Kotlin)

The `factChecker.kt` shows the functional DSL approach:

```kotlin
fun factCheckerAgent(llms: List<LlmOptions>, properties: FactCheckerProperties) =
    agent(name = "FactChecker", description = "Check content for factual accuracy") {

        flow {
            aggregate<UserInput, FactualAssertions, RationalizedFactualAssertions>(
                transforms = llms.map { llm ->
                    { context -> context.ai().withLlm(llm).createObject("...") }
                },
                merge = { list, context -> context.ai().withDefaultLlm().createObject("...") }
            )
        }

        transformation<RationalizedFactualAssertions, FactCheck> { operationContext ->
            // Parallel fact checking
            val checks = operationContext.input.factualAssertions.parallelMap(operationContext) {
                // Check each assertion
            }
            FactCheck(checks)
        }

        goal(
            name = "factCheckingDone",
            satisfiedBy = FactCheck::class
        )
    }
```

### Pattern 3: Simple AI Injection

The simplest use of Embabel - inject `Ai` into any Spring component:

```java
@Component
public record InjectedComponent(Ai ai) {

    public String tellJokeAbout(String topic) {
        return ai.withDefaultLlm()
            .generateText("Tell me a joke about " + topic);
    }

    public Joke createJokeObjectAbout(String topic1, String topic2, String voice) {
        return ai.withLlm(LlmOptions.withDefaultLlm().withTemperature(.8))
            .createObject("...", Joke.class);
    }
}
```

### Pattern 4: Configuration Properties

Externalized configuration with Spring Boot:

```kotlin
@ConfigurationProperties("embabel.fact-checker")
data class FactCheckerProperties(
    val reasoningWordCount: Int = 30,
    val trustedSources: List<String> = listOf("Wikipedia", "BBC", ...),
    val untrustedSources: List<String> = listOf("Reddit", "Twitter", ...)
)
```

---

## Running the Examples

### Via Scripts (Recommended)

```bash
# Kotlin shell mode
cd scripts/kotlin && ./shell.sh

# Java shell mode
cd scripts/java && ./shell.sh

# With MCP tools (Docker Desktop)
./shell.sh --docker-tools

# MCP server mode
./mcp_server.sh
```

### Via Maven Profiles

```bash
# Shell mode
cd examples-kotlin && mvn -P enable-shell spring-boot:run

# Shell + MCP client
cd examples-kotlin && mvn -P enable-shell-mcp-client spring-boot:run

# MCP server
cd examples-kotlin && mvn -P enable-agent-mcp-server spring-boot:run
```

---

## Learning Progression

| Level | Example | Concepts |
|-------|---------|----------|
| **Beginner** | `InjectedComponent` | Simple AI injection |
| **Beginner** | `StarNewsFinder` | Actions, goals, tool groups |
| **Intermediate** | `handoff/` | Agent handoff patterns |
| **Advanced** | `researcher/` | Multi-LLM, self-improvement |
| **Expert** | `factChecker` | DSL, parallel processing, aggregation |

---

## MCP Integration

### As MCP Server

When running in MCP server mode, each agent's goals become MCP tools:

```json
{
  "mcpServers": {
    "embabel-examples": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "http://localhost:8080/sse"]
    }
  }
}
```

### As MCP Client

Using `mcpServers = {McpServers.DOCKER_DESKTOP}` enables agents to use:
- Docker container execution
- Containerized services
- Other MCP-compatible tools

---

## Key Annotations Reference

| Annotation | Purpose |
|------------|---------|
| `@Agent` | Marks a class as an agent |
| `@EmbabelComponent` | Marks a class with actions but no goal |
| `@Action` | Marks a method as an action |
| `@AchievesGoal` | Marks an action that achieves a goal |
| `@Condition` | Marks a boolean method for flow control |
| `@Cost` | Sets the cost of an action for planning |
| `@Export` | Exposes a goal as MCP tool |

---

## Related Resources

- **Java Template**: [github.com/embabel/java-agent-template](https://github.com/embabel/java-agent-template)
- **Kotlin Template**: [github.com/embabel/kotlin-agent-template](https://github.com/embabel/kotlin-agent-template)
- **Project Creator**: `uvx --from git+https://github.com/embabel/project-creator.git project-creator`
