# Embabel Agent Patterns Quick Reference

## 📦 Module Map

| Module | Purpose | Key Types |
|--------|---------|-----------|
| `embabel-agent-api` | Core framework | `Agent`, `Action`, `Goal`, `Ai`, `PromptRunner` |
| `embabel-agent-common` | Shared utilities | `LlmOptions`, `PromptContributor`, `EmbeddingService` |
| `embabel-agent-shell` | Spring Shell CLI | `ShellCommands`, `TerminalServices` |
| `embabel-agent-mcpserver` | MCP protocol | `McpToolExport`, `ToolRegistry` |
| `embabel-agent-rag-core` | RAG abstractions | `ToolishRag`, `ContentElement`, `SearchOperations` |
| `embabel-agent-discord` | Discord bot | `ChatbotSessionEventListener` |
| `embabel-agent-test-support` | Testing | `FakeOperationContext`, `FakePromptRunner` |

---

## 🎯 Agent Definition Patterns

### Annotation-Based Agent (Java)

```java
@Agent(description = "Find news based on star sign")
public class StarNewsFinder {

    @Action
    public StarPerson extractPerson(UserInput input, Ai ai) {
        return ai.withDefaultLlm()
            .createObject("Create a person from: " + input, StarPerson.class);
    }

    @Action(toolGroups = {CoreToolGroups.WEB})
    public News findNews(StarPerson person, Ai ai) {
        return ai.withDefaultLlm()
            .createObject("Find news for " + person.name(), News.class);
    }

    @AchievesGoal(description = "Write amusing writeup")
    @Action
    public Writeup writeup(StarPerson person, News news, Ai ai) {
        return ai.withLlm(LlmOptions.withModel("gpt-4").withTemperature(0.9))
            .createObject("Write up for " + person.name(), Writeup.class);
    }
}
```

### Annotation-Based Agent (Kotlin)

```kotlin
@Agent(description = "Find news based on star sign")
class StarNewsFinder {

    @Action
    fun extractPerson(input: UserInput, ai: Ai): StarPerson =
        ai.withDefaultLlm().createObject("Create a person from: $input")

    @Action(toolGroups = [CoreToolGroups.WEB])
    fun findNews(person: StarPerson, ai: Ai): News =
        ai.withDefaultLlm().createObject("Find news for ${person.name}")

    @AchievesGoal(description = "Write amusing writeup")
    @Action
    fun writeup(person: StarPerson, news: News, ai: Ai): Writeup =
        ai.withLlm(LlmOptions.withModel("gpt-4").withTemperature(0.9))
            .createObject("Write up for ${person.name}")
}
```

### DSL-Based Agent (Kotlin)

```kotlin
val myAgent = agent(
    name = "StarNewsFinder",
    description = "Find news based on star sign"
) {
    action<UserInput, StarPerson>("extractPerson") { input, ai ->
        ai.withDefaultLlm().createObject("Create a person from: $input")
    }

    action<StarPerson, News>("findNews") { person, ai ->
        ai.withToolGroup("web").createObject("Find news for ${person.name}")
    }

    goal("writeup", "Write amusing writeup") {
        action<Pair<StarPerson, News>, Writeup> { (person, news), ai ->
            ai.createObject("Write up for ${person.name}")
        }
    }
}
```

---

## 🔧 Action Patterns

### Basic Action

```kotlin
@Action
fun myAction(input: Input, ai: Ai): Output =
    ai.withDefaultLlm().createObject("Process $input", Output::class.java)
```

### Action with Tools

```kotlin
@Action(toolGroups = [CoreToolGroups.WEB, "custom-tools"])
fun searchAction(query: Query, ai: Ai): Results =
    ai.withDefaultLlm().createObject("Search for ${query.text}")
```

### Action with Custom Tool Objects

```kotlin
@Action
fun actionWithTools(input: Input, ai: Ai, myTools: MyToolProvider): Output =
    ai.withDefaultLlm()
        .withToolObject(myTools)
        .createObject("Process $input")
```

### Action with Trigger (Chatbot Pattern)

```kotlin
@Action(trigger = UserMessage::class)
fun respond(conversation: Conversation, context: ActionContext) {
    val response = context.ai()
        .withDefaultLlm()
        .respondWithSystemPrompt(conversation, templateModel)
    conversation.addMessage(response)
    context.sendMessage(response)
}
```

### Action with Preconditions

```kotlin
@Action(
    pre = ["userAuthenticated", "hasPermission"],
    post = ["dataProcessed"]
)
fun protectedAction(input: Input, ai: Ai): Output = ...
```

### Action with Custom Cost/Value

```kotlin
@Cost(name = "complexityCost")
fun computeCost(data: LargeData?): Double =
    if (data != null && data.size > 1000) 0.9 else 0.1

@Action(costMethod = "complexityCost")
fun processData(data: LargeData, ai: Ai): Result = ...
```

### Rerunnable Action (for loops)

```kotlin
@Action(canRerun = true)
fun iterativeAction(state: State, ai: Ai): State =
    ai.createObject("Improve state: $state")
```

---

## 🎯 Goal Patterns

### Basic Goal

```kotlin
@AchievesGoal(description = "Complete the task")
@Action
fun finalAction(input: Input, ai: Ai): FinalOutput = ...
```

### Exported Goal (MCP)

```kotlin
@AchievesGoal(
    description = "Write amusing writeup for the target person",
    export = @Export(
        remote = true,
        name = "starNewsWriteup",
        startingInputTypes = [UserInput::class, StarPerson::class]
    )
)
@Action
fun writeup(...): Writeup = ...
```

### Programmatic Goal

```kotlin
val goal = Goal.createInstance(
    description = "Create a writeup",
    type = Writeup::class.java,
    name = "CreateWriteup",
    tags = setOf("content", "news"),
    examples = setOf("Write a news summary for John")
)
```

---

## 🤖 Ai / PromptRunner Patterns

### Basic Object Creation

```kotlin
val result = ai.withDefaultLlm()
    .createObject("Generate a person", Person::class.java)
```

### With Specific Model

```kotlin
val result = ai.withLlm(LlmOptions.withModel("gpt-4").withTemperature(0.7))
    .createObject(prompt, Output::class.java)
```

### With Tools

```kotlin
val result = ai.withDefaultLlm()
    .withToolGroup("web")
    .withToolObject(myCustomTools)
    .createObject(prompt, Output::class.java)
```

### With RAG Reference

```kotlin
val result = ai.withDefaultLlm()
    .withReference(ToolishRag("docs", "Documentation", store)
        .withHint(TryHyDE.usingConversationContext()))
    .createObject(prompt, Output::class.java)
```

### With Template

```kotlin
val result = ai.withDefaultLlm()
    .withTemplate("my_template")
    .createObject(
        outputClass = Output::class.java,
        model = mapOf("name" to "John", "context" to context)
    )
```

### With Images (Vision)

```kotlin
val result = ai.withLlm(LlmOptions.withModel("gpt-4-vision"))
    .withImage(AgentImage.fromUrl("https://example.com/image.jpg"))
    .createObject("Describe this image", Description::class.java)
```

### With System Prompt

```kotlin
val result = ai.withDefaultLlm()
    .withSystemPrompt("You are a helpful assistant")
    .createObject(prompt, Output::class.java)
```

### Streaming Response

```kotlin
if (ai.withDefaultLlm().supportsStreaming()) {
    ai.withDefaultLlm()
        .stream()
        .generateText(prompt) { chunk ->
            print(chunk)
        }
}
```

### Thinking Extraction

```kotlin
val thinkingResult = ai.withLlm(LlmOptions.withThinking(Thinking.withExtraction()))
    .withThinking()
    .createObject(prompt, Output::class.java)

println("Thinking: ${thinkingResult.thinking}")
println("Result: ${thinkingResult.result}")
```

### Optional Object Creation

```kotlin
val maybeResult: Person? = ai.withDefaultLlm()
    .createObjectIfPossible("Create a person if possible", Person::class.java)
```

---

## 📝 Domain Object Patterns

### Basic Data Class

```kotlin
data class StarPerson(
    val name: String,
    val sign: String
)
```

### With JSON Annotations

```kotlin
@JsonClassDescription("Person with astrology details")
data class StarPerson(
    val name: String,
    @get:JsonPropertyDescription("Zodiac star sign")
    val sign: String
)
```

### Java Record

```java
@JsonClassDescription("Person with astrology details")
public record StarPerson(
    String name,
    @JsonPropertyDescription("Star sign") String sign
) {}
```

### With Tool Methods

```kotlin
data class SearchContext(
    val query: String,
    val filters: List<String>
) {
    @Tool("Search the database with current context")
    fun search(): List<Result> = ...
}
```

---

## 🧪 Testing Patterns

### Unit Test with FakeOperationContext (Java)

```java
@Test
void actionPassesCorrectPrompt() {
    var context = new FakeOperationContext();
    context.expectResponse(new Output("test result"));

    var agent = new MyAgent();
    var result = agent.myAction(new Input("test"), context);

    var invocation = context.getLlmInvocations().getFirst();
    assertTrue(invocation.getPrompt().contains("test"));
    assertEquals("test result", result.getText());
}
```

### Unit Test with FakeOperationContext (Kotlin)

```kotlin
@Test
fun `action passes correct prompt`() {
    val context = FakeOperationContext()
    context.expectResponse(Output("test result"))

    val agent = MyAgent()
    val result = agent.myAction(Input("test"), context)

    val prompt = context.llmInvocations.first().prompt
    assertTrue(prompt.contains("test"))
    assertEquals("test result", result.text)
}
```

### Integration Test

```kotlin
@SpringBootTest
class MyAgentIntegrationTest {

    @Autowired
    lateinit var autonomy: Autonomy

    @Test
    fun `agent achieves goal`() {
        val result = autonomy.runAgent<Writeup>(
            agentClass = StarNewsFinder::class.java,
            input = UserInput("Lynda is a Scorpio")
        )
        assertNotNull(result)
    }
}
```

### Testing Prompt Content

```java
@Test
void promptContainsRequiredData() {
    var context = new FakeOperationContext();
    context.expectResponse(new Writeup("result"));

    var person = new StarPerson("John", "Aries");
    var news = new News(List.of("headline1", "headline2"));

    agent.writeup(person, news, context);

    var prompt = context.getLlmInvocations().getFirst().getPrompt();
    assertTrue(prompt.contains(person.name()));
    assertTrue(prompt.contains(person.sign()));
    assertTrue(prompt.contains("headline1"));
}
```

### Testing Tool Groups

```java
@Test
void actionRequestsCorrectTools() {
    var context = new FakeOperationContext();
    context.expectResponse(new Results());

    agent.searchAction(new Query("test"), context);

    var toolGroups = context.getLlmInvocations().getFirst()
        .getInteraction().getToolGroups();
    assertTrue(toolGroups.contains("web"));
}
```

---

## ⚙️ Configuration Patterns

### LlmOptions

```kotlin
// By model name
LlmOptions.withModel("gpt-4")

// With temperature
LlmOptions.withModel("gpt-4").withTemperature(0.9)

// With max tokens
LlmOptions.withModel("gpt-4").withMaxTokens(4000)

// Auto selection
LlmOptions.withAutoLlm()

// Default selection
LlmOptions(criteria = DefaultModelSelectionCriteria)

// By role
LlmOptions(criteria = ModelSelectionCriteria.byRole("summarizer"))

// Fallback chain
LlmOptions(criteria = FallbackByNameModelSelectionCriteria(
    listOf("gpt-4", "gpt-3.5-turbo", "claude-3-opus")
))
```

### Application Configuration

```yaml
embabel:
  agent:
    logging:
      personality: starwars    # severance, colossus, montypython, hh

    models:
      default-llm: gpt-4.1-mini
      default-embedding-model: text-embedding-3-small

      llms:
        summarizer: gpt-4.1-nano

    rag:
      neo:
        uri: bolt://localhost:7687
        username: neo4j
        password: password
```

### Process Options

```kotlin
val options = ProcessOptions(
    verbosity = Verbosity(
        debug = true,
        showPrompts = true,
        showLlmResponses = true,
        showPlanning = true
    ),
    processControl = ProcessControl(
        earlyTerminationPolicy = EarlyTerminationPolicy.maxActions(40),
        toolDelay = Delay.LONG,
        operationDelay = Delay.MEDIUM
    )
)
```

---

## 🔌 MCP Export Patterns

### Export RAG as MCP Tool

```kotlin
@Bean
fun ragTools(store: DrivineStore): McpToolExport {
    val rag = ToolishRag("docs", "Documentation", store)
    return McpToolExport.fromLlmReference(rag) { name -> "prefix_$name" }
}
```

### Export Multiple References

```kotlin
@Bean
fun allTools(dataManager: DataManager): McpToolExport {
    return McpToolExport.fromLlmReferences(
        dataManager.referencesForAllUsers(),
        properties.toolNamingStrategy()
    )
}
```

---

## 💬 Chatbot Patterns

### Basic Chatbot Setup

```kotlin
val chatbot = AgentProcessChatbot(
    agentPlatform = platform,
    agentSource = { myChatAgent },
    plannerType = PlannerType.UTILITY
)

val session = chatbot.createSession(
    user = user,
    outputChannel = myOutputChannel,
    systemMessage = "You are a helpful assistant"
)

session.onUserMessage(UserMessage("Hello!"))
```

### Chat Action with Conversation

```kotlin
@EmbabelComponent
class ChatActions(private val ragAdapter: RagServiceAdapter) {

    @Action(trigger = UserMessage::class)
    fun respond(conversation: Conversation, context: ActionContext) {
        val response = context.ai()
            .withDefaultLlm()
            .withReferences(references)
            .withTemplate("chat_system")
            .respondWithSystemPrompt(conversation, templateModel)

        conversation.addMessage(response)
        context.sendMessage(response)
    }
}
```

### OutputChannel for Chat

```kotlin
val outputChannel = object : OutputChannel {
    override fun send(event: OutputChannelEvent) {
        when (event) {
            is MessageOutputChannelEvent -> println("Message: ${event.message}")
            is ProgressOutputChannelEvent -> println("Progress: ${event.message}")
        }
    }
}
```

---

## 📚 RAG Patterns

### ToolishRag with HyDE

```kotlin
val rag = ToolishRag("docs", "Documentation", drivineStore)
    .withHint(TryHyDE.usingConversationContext())

ai.withReference(rag).createObject(prompt, Output::class.java)
```

### Content Ingestion

```kotlin
val reader = TikaHierarchicalContentReader()
val content = reader.parseFromUri("https://docs.example.com/")

for (root in content.contentRoots) {
    store.writeAndChunkDocument(root)
}
```

### Custom Search

```kotlin
val results = store.search(
    query = "How do actions work?",
    limit = 10,
    filter = EntityFilter.byType("documentation")
)
```

---

## 🔄 Autonomy Patterns

### Run Specific Agent

```kotlin
val result = autonomy.runAgent<Output>(
    agentClass = MyAgent::class.java,
    input = myInput
)
```

### Choose and Run Agent

```kotlin
val execution = autonomy.chooseAndRunAgent(
    intent = "Find news for Lynda who is a Scorpio",
    processOptions = ProcessOptions()
)
```

### Choose and Accomplish Goal (Open Mode)

```kotlin
val execution = autonomy.chooseAndAccomplishGoal(
    processOptions = processOptions,
    goalChoiceApprover = GoalChoiceApprover approveWithScoreOver 0.8,
    agentScope = agentPlatform,
    bindings = mapOf("userInput" to UserInput(intent))
)
```

---

## 📁 File Organization

```
src/main/
├── kotlin/com/myapp/
│   ├── agents/
│   │   └── MyAgent.kt           # @Agent classes
│   ├── actions/
│   │   └── ChatActions.kt       # @EmbabelComponent
│   ├── domain/
│   │   └── Models.kt            # Data classes
│   └── config/
│       └── AppConfig.kt         # @Configuration
├── java/com/myapp/
│   └── agents/
│       └── JavaAgent.java       # Java @Agent
└── resources/
    ├── application.yml
    └── prompts/
        └── *.jinja
```

---

## 🎯 Quick Operation Cheat Sheet

| Task | Pattern |
|------|---------|
| Create typed object | `ai.withDefaultLlm().createObject(prompt, Type.class)` |
| Add tools | `.withToolGroup("web")` or `.withToolObject(obj)` |
| Add RAG | `.withReference(ToolishRag(...))` |
| Use template | `.withTemplate("name").createObject(Type.class, model)` |
| Stream text | `.stream().generateText(prompt) { chunk -> }` |
| Chat response | `.respondWithSystemPrompt(conversation, model)` |
| Test action | `FakeOperationContext().expectResponse(...)` |
| Run agent | `autonomy.runAgent<Output>(AgentClass::class.java, input)` |
| Export to MCP | `McpToolExport.fromLlmReference(...)` |
