# Embabel Agent Framework - Deep Dive Primer

## Overview

**Embabel Agent** is a framework for building intelligent agent applications on the JVM. It models agentic flows using **Actions**, **Goals**, **Conditions**, and a **Domain Model**, with AI-powered planning to achieve goals dynamically.

### Key Differentiators

1. **Sophisticated Planning** - Uses GOAP (Goal Oriented Action Planning) or Utility AI, not just FSMs
2. **Superior Extensibility** - Adding actions/goals extends capabilities without editing existing code
3. **Strong Typing** - Full Java/Kotlin type safety with Jackson integration for LLM schema generation
4. **Platform Abstraction** - Clean separation between programming model and runtime
5. **LLM Mixing** - Easy to use different models for different tasks

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        EMBABEL AGENT FRAMEWORK                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                         USER APPLICATION                                │ │
│  │                                                                         │ │
│  │   ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────────┐  │ │
│  │   │ @Agent classes  │   │ Domain Objects  │   │ Kotlin DSL agents  │  │ │
│  │   │ @Action methods │   │ (records/data)  │   │ agent { ... }      │  │ │
│  │   └────────┬────────┘   └────────┬────────┘   └──────────┬──────────┘  │ │
│  └────────────┼─────────────────────┼───────────────────────┼─────────────┘ │
│               │                     │                       │               │
│  ┌────────────┴─────────────────────┴───────────────────────┴─────────────┐ │
│  │                         AGENT PLATFORM                                  │ │
│  │                                                                         │ │
│  │   ┌─────────────┐   ┌─────────────┐   ┌─────────────────────────────┐  │ │
│  │   │   Agents    │   │   Goals     │   │        Conditions           │  │ │
│  │   │   Actions   │   │   Planning  │   │        Blackboard           │  │ │
│  │   └─────────────┘   └─────────────┘   └─────────────────────────────┘  │ │
│  │                           │                                             │ │
│  │   ┌───────────────────────┴─────────────────────────────────────────┐  │ │
│  │   │                      PLANNER                                     │  │ │
│  │   │                                                                  │  │ │
│  │   │     ┌─────────────┐              ┌─────────────────────┐        │  │ │
│  │   │     │    GOAP     │      OR      │     Utility AI      │        │  │ │
│  │   │     │  Planning   │              │      Planning       │        │  │ │
│  │   │     └─────────────┘              └─────────────────────┘        │  │ │
│  │   └─────────────────────────────────────────────────────────────────┘  │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                  │                                           │
│  ┌───────────────────────────────┴───────────────────────────────────────┐  │
│  │                         SPI LAYER                                      │  │
│  │                                                                        │  │
│  │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │  │
│  │   │LlmOperations│  │ToolResolver │  │  Rankers    │  │  Logging    │  │  │
│  │   └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                                  │                                           │
│  ┌───────────────────────────────┴───────────────────────────────────────┐  │
│  │                      MODEL PROVIDERS                                   │  │
│  │                                                                        │  │
│  │   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  │  │
│  │   │  OpenAI  │  │Anthropic │  │  Gemini  │  │  Ollama  │  │ Others │  │  │
│  │   └──────────┘  └──────────┘  └──────────┘  └──────────┘  └────────┘  │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Module Structure

```
embabel-agent/
├── embabel-agent-api/          # Core framework (Actions, Goals, Agents, Planning)
├── embabel-agent-common/       # Shared utilities (LlmOptions, Prompts, Models)
├── embabel-agent-autoconfigure/ # Spring Boot auto-configuration
│   ├── embabel-agent-platform-autoconfigure/
│   ├── embabel-agent-shell-autoconfigure/
│   └── models/                 # Per-provider model configuration
├── embabel-agent-starters/     # Spring Boot starters
│   ├── embabel-agent-starter/
│   ├── embabel-agent-starter-openai/
│   ├── embabel-agent-starter-anthropic/
│   ├── embabel-agent-starter-ollama/
│   └── ...
├── embabel-agent-shell/        # Spring Shell CLI
├── embabel-agent-mcpserver/    # MCP protocol server
├── embabel-agent-rag/          # RAG (Retrieval Augmented Generation)
│   ├── embabel-agent-rag-core/
│   ├── embabel-agent-rag-neo/
│   ├── embabel-agent-rag-lucene/
│   └── embabel-agent-rag-tika/
├── embabel-agent-discord/      # Discord bot integration
├── embabel-agent-a2a/          # Agent-to-Agent protocol
├── embabel-agent-code/         # Code generation utilities
├── embabel-agent-eval/         # Evaluation framework
├── embabel-agent-test-support/ # Testing utilities
└── embabel-agent-docs/         # AsciiDoc documentation
```

---

## Core Concepts

### 1. Agent

An **Agent** is a container for Actions, Goals, and Conditions that work together:

```kotlin
@Agent(description = "Find news based on a person's star sign")
class StarNewsFinder {

    @Action
    fun extractPerson(userInput: UserInput, ai: Ai): StarPerson =
        ai.withDefaultLlm().createObject("Create a person from: $userInput")

    @Action(toolGroups = [CoreToolGroups.WEB])
    fun findNews(person: StarPerson, ai: Ai): RelevantNews = ...

    @AchievesGoal(description = "Write up for the person")
    @Action
    fun writeup(person: StarPerson, news: RelevantNews, ai: Ai): Writeup = ...
}
```

### 2. Action

An **Action** is a single step in an agent flow:

- Takes inputs from the **Blackboard** (parameters)
- Returns outputs that are added to the Blackboard
- May use LLMs, tools, or regular code
- Has preconditions (what must be true before running)
- Has effects/postconditions (what becomes true after running)

```kotlin
@Action(
    description = "Extract person details from user input",
    toolGroups = [CoreToolGroups.WEB],  // Tools needed
    canRerun = false,                    // Can this run again?
    trigger = UserMessage::class         // Only trigger on this type
)
fun myAction(input: Input, ai: Ai): Output = ...
```

### 3. Goal

A **Goal** is what an agent tries to achieve:

```kotlin
@AchievesGoal(
    description = "Write an amusing writeup for the target person",
    export = @Export(
        remote = true,                  // Export via MCP
        name = "starNewsWriteup",
        startingInputTypes = [UserInput::class]
    )
)
@Action
fun writeup(...): Writeup = ...
```

Goals have:
- **Preconditions** - What must be true to achieve the goal
- **Value** - How valuable achieving this goal is
- **Tags** - Categories for classification
- **Examples** - Sample scenarios

### 4. Blackboard

The **Blackboard** is a shared memory space during agent execution:

```kotlin
interface Blackboard {
    val objects: Map<String, Any>
    fun <T> get(clazz: Class<T>, binding: String): T?
    fun <T> last(clazz: Class<T>): T?
    fun <T> all(clazz: Class<T>): List<T>
    fun addObject(value: Any, binding: String? = null)
}
```

- Actions read inputs from the blackboard
- Action outputs are added to the blackboard
- The planner uses blackboard state to determine available actions

### 5. Condition

A **Condition** is an evaluable predicate:

```kotlin
@Condition(name = "userIsAuthenticated", cost = 0.1)
fun checkAuth(user: User): Boolean = user.isAuthenticated
```

Used for:
- Action preconditions
- Goal preconditions
- Dynamic planning decisions

---

## Planning Systems

### GOAP (Goal Oriented Action Planning)

The default planner. Works by:

1. Examining the current world state (blackboard)
2. Identifying available actions (preconditions met)
3. Planning a sequence to achieve the goal
4. Re-planning after each action (OODA loop)

```kotlin
@Agent(
    description = "My agent",
    planner = PlannerType.GOAP  // Default
)
class MyAgent { ... }
```

### Utility AI

Alternative planner that chooses actions by utility score:

```kotlin
@Agent(
    description = "Chatbot",
    planner = PlannerType.UTILITY
)
class MyChatbot { ... }
```

- Better for open-ended tasks
- Actions have cost/value scores
- Highest utility action is chosen
- Good for chatbots and exploration

---

## The Ai Interface

The primary gateway to LLM functionality:

```kotlin
interface Ai {
    fun withLlm(llm: LlmOptions): PromptRunner
    fun withDefaultLlm(): PromptRunner
    fun withAutoLlm(): PromptRunner
    fun withLlmByRole(role: String): PromptRunner
    fun withEmbeddingService(criteria: ModelSelectionCriteria): EmbeddingService
}
```

Usage in actions:

```kotlin
@Action
fun myAction(input: Input, ai: Ai): Output {
    return ai
        .withLlm(LlmOptions.withModel("gpt-4"))
        .withToolGroup("web")
        .createObject("Generate output from $input", Output::class.java)
}
```

---

## PromptRunner

Fluent API for LLM interactions:

```kotlin
ai.withDefaultLlm()
    .withToolGroup("web")                     // Add tools
    .withToolObject(myToolProvider)           // Add @Tool annotated object
    .withReference(ragReference)              // Add RAG context
    .withSystemPrompt("You are a helper")     // System prompt
    .withTemplate("my_template")              // Jinja template
    .withImage(AgentImage.fromUrl("..."))     // Vision input
    .createObject(prompt, OutputClass::class.java)
```

Key operations:

| Method | Description |
|--------|-------------|
| `createObject<T>(prompt)` | Generate typed object |
| `createObjectIfPossible<T>(prompt)` | Return null if LLM can't |
| `generateText(prompt)` | Generate raw text |
| `respond(messages)` | Chat response |
| `stream()` | Streaming responses |
| `withThinking()` | Extract thinking blocks |

---

## ActionContext

Context passed to action methods:

```kotlin
interface ActionContext : ExecutingOperationContext {
    val processContext: ProcessContext
    val action: Action?

    fun sendMessage(message: Message)
    fun updateProgress(message: String)
    fun <O> asSubProcess(outputClass: Class<O>, agent: Agent): O
}
```

Usage:

```kotlin
@Action
fun myAction(context: ActionContext): Output {
    context.updateProgress("Starting...")
    val result = context.ai()
        .withDefaultLlm()
        .createObject("...", Output::class.java)
    context.sendMessage(AssistantMessage(result.text))
    return result
}
```

---

## Execution Modes

### Focused Mode

User code calls a specific agent:

```kotlin
val result = autonomy.runAgent<Output>(
    agentClass = MyAgent::class.java,
    input = UserInput("...")
)
```

### Closed Mode

Platform chooses agent from available agents:

```kotlin
val result = autonomy.chooseAndRunAgent(
    intent = "Find news for Lynda who is a Scorpio",
    processOptions = ProcessOptions()
)
```

### Open Mode

Platform uses ALL available actions across agents:

```kotlin
val result = autonomy.chooseAndAccomplishGoal(
    processOptions = processOptions,
    goalChoiceApprover = GoalChoiceApprover.APPROVE_ALL,
    agentScope = agentPlatform,
    bindings = mapOf("userInput" to UserInput(intent))
)
```

---

## Chatbot Integration

For conversational AI, use the `Chatbot` interface:

```kotlin
interface Chatbot {
    fun createSession(
        user: User?,
        outputChannel: OutputChannel,
        systemMessage: String?
    ): ChatSession

    fun findSession(conversationId: String): ChatSession?
}
```

Chatbot-backed agents:
- Use **Utility AI** planner
- Respond to `UserMessage` triggers
- Maintain conversation in `Conversation` object
- Long-lived `AgentProcess` that pauses between messages

```kotlin
@EmbabelComponent
class ChatActions {

    @Action(trigger = UserMessage::class)
    fun respond(
        conversation: Conversation,
        context: ActionContext
    ) {
        val response = context.ai()
            .withReferences(ragReferences)
            .withTemplate("chat_system")
            .respondWithSystemPrompt(conversation, model)
        conversation.addMessage(response)
        context.sendMessage(response)
    }
}
```

---

## Tools System

### Tool Groups

Named collections of tools:

```kotlin
object CoreToolGroups {
    const val WEB = "web"           // Web search, fetch
    const val FILE = "file"         // File operations
    const val MATH = "math"         // Calculator
}

@Action(toolGroups = [CoreToolGroups.WEB])
fun searchWeb(ai: Ai): Results = ...
```

### Tool Objects

Objects with `@Tool` annotated methods:

```kotlin
class MyTools {
    @Tool("Search the database")
    fun searchDb(query: String): List<Result> = ...
}

// In action:
ai.withToolObject(myTools).createObject(...)
```

### MCP Tools

Consumed from Docker Desktop or other MCP servers:

```yaml
spring:
  ai:
    mcp:
      client:
        stdio:
          connections:
            docker-mcp:
              command: docker
              args: [run, -i, --rm, alpine/socat, STDIO, TCP:host.docker.internal:8811]
```

---

## MCP Server Export

Export Embabel goals as MCP tools:

```kotlin
@Bean
fun mcpExport(store: DrivineStore): McpToolExport {
    val rag = ToolishRag("docs", "Documentation", store)
    return McpToolExport.fromLlmReference(rag, namingStrategy)
}
```

Goals with `export = @Export(remote = true)` are automatically exposed via `/sse`.

---

## RAG Integration

### ToolishRag

Exposes RAG as LLM tools:

```kotlin
val rag = ToolishRag("docs", "Embabel documentation", drivineStore)

ai.withReference(rag)
    .withHint(TryHyDE.usingConversationContext())  // Hypothetical Document Embeddings
    .createObject(prompt, Output::class.java)
```

### Content Ingestion

```kotlin
val reader = TikaHierarchicalContentReader()
val chunks = reader.parseFromUri(url)
store.writeAndChunkDocument(chunks)
```

### Search Operations

```kotlin
val results = store.search(
    query = "How do actions work?",
    limit = 10
)
```

---

## Testing

### Unit Testing with FakeOperationContext

```java
public class MyAgentTest {

    @Test
    void actionPassesCorrectPrompt() {
        var context = new FakeOperationContext();
        context.expectResponse(new Output("result"));

        var agent = new MyAgent();
        agent.myAction(input, context);

        var prompt = context.getLlmInvocations().getFirst().getPrompt();
        assertTrue(prompt.contains("expected text"));
    }
}
```

### Integration Testing

```kotlin
@SpringBootTest
class MyAgentIntegrationTest {

    @Autowired
    lateinit var agentPlatform: AgentPlatform

    @Test
    fun `agent achieves goal`() {
        val process = agentPlatform.runAgentFrom(
            agent = myAgent,
            bindings = mapOf("input" to input)
        )
        assertEquals(OperationStatus.SUCCEEDED, process.status)
    }
}
```

---

## Configuration

### Platform Properties

Internal framework behavior (`embabel.agent.platform.*`):

```properties
embabel.agent.platform.scanning.annotation=true
embabel.agent.platform.llm-operations.data-binding.max-attempts=10
embabel.agent.platform.ranking.max-attempts=5
embabel.agent.platform.autonomy.agent-confidence-cut-off=0.6
```

### Application Properties

Developer-controlled settings (`embabel.agent.*`):

```yaml
embabel:
  agent:
    logging:
      personality: starwars  # Fun logging themes!
    models:
      default-llm: gpt-4.1-mini
      default-embedding-model: text-embedding-3-small
```

### Model Configuration

Per-provider in starters:

```yaml
# OpenAI
OPENAI_API_KEY=sk-...

# Anthropic  
ANTHROPIC_API_KEY=sk-ant-...

# Ollama (auto-detected)
# Just run Ollama locally
```

---

## Spring Shell Commands

Interactive CLI for development:

| Command | Description |
|---------|-------------|
| `agents` | List all agents |
| `actions` | List all actions |
| `goals` | List all goals |
| `tools` | List tool groups |
| `execute "intent"` | Run in closed mode |
| `execute "intent" -o` | Run in open mode |
| `chat` | Interactive chat |
| `blackboard` | Show current state |
| `models` | List available LLMs |

---

## Key Interfaces Summary

| Interface | Purpose |
|-----------|---------|
| `AgentPlatform` | Runtime for agents |
| `Agent` | Container for actions/goals |
| `Action` | Single step in flow |
| `Goal` | What to achieve |
| `Condition` | Evaluable predicate |
| `Blackboard` | Shared memory |
| `Ai` | Gateway to LLMs |
| `PromptRunner` | Fluent LLM operations |
| `ActionContext` | Context for actions |
| `Chatbot` | Multi-session chat |
| `ChatSession` | Single conversation |
| `LlmReference` | RAG/tool provider |

---

## Best Practices

1. **Type Everything** - Use data classes for LLM inputs/outputs
2. **Test Prompts** - Unit test that prompts contain expected content
3. **Mix LLMs** - Use cheaper models for simple tasks
4. **Use Tools Wisely** - Only enable tools that are needed
5. **Leverage Planning** - Let the planner find novel paths
6. **Add Descriptions** - Good descriptions help agent/goal selection
7. **Consider Utility AI** - For open-ended/chat scenarios

---

## Summary

Embabel Agent provides:

1. **Declarative Agent Definition** - `@Agent`, `@Action`, `@Goal`, `@Condition`
2. **AI-Powered Planning** - GOAP or Utility AI
3. **Type-Safe LLM Interactions** - Full Java/Kotlin types
4. **Extensible Tool System** - MCP, tool groups, @Tool annotations
5. **RAG Integration** - Built-in retrieval augmented generation
6. **Multi-Model Support** - OpenAI, Anthropic, Ollama, etc.
7. **Easy Testing** - `FakeOperationContext` for unit tests
8. **Spring Integration** - Auto-configuration, DI, profiles
