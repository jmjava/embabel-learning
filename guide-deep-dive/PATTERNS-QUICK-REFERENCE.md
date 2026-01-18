# Guide Patterns Quick Reference

## 📦 Package Map

| Package | Purpose | Key Classes |
|---------|---------|-------------|
| `guide.chat.controller` | WebSocket/REST endpoints | `ChatController`, `ChatApiController` |
| `guide.chat.service` | Business logic | `JesseService`, `ThreadService`, `ChatService` |
| `guide.chat.model` | Data transfer objects | `ThreadTimeline`, `MessageWithVersion` |
| `guide.chat.repository` | Persistence | `ThreadRepositoryImpl` |
| `guide.domain` | User domain | `GuideUser`, `GuideUserService` |
| `guide.chat.security` | Auth/security | `SecurityConfig` |
| `hub` | Auth endpoints | `HubService`, `HubApiController` |
| `guide.rag` | RAG/AI | `DataManager`, `RagConfiguration` |

---

## 🔧 Drivine Patterns

### Define a Node (Single Entity)

```kotlin
@NodeFragment(labels = ["MyNode"])
data class MyNodeData(
    @NodeId
    var id: String,
    var name: String
)
```

### Define a GraphView (Composite Entity)

```kotlin
@GraphView
data class MyComposite(
    @Root
    val core: MyNodeData,

    @GraphRelationship(type = "HAS_CHILD", direction = Direction.OUTGOING)
    val children: List<ChildData> = emptyList()
)
```

### Raw Cypher Query

```kotlin
@Transactional(readOnly = true)
fun findByName(name: String): Optional<MyComposite> {
    val cypher = """
        MATCH (n:MyNode {name: ${'$'}name})
        RETURN { core: properties(n) }
    """
    return manager.optionalGetOne(
        QuerySpecification
            .withStatement(cypher)
            .bind(mapOf("name" to name))
            .transform(MyComposite::class.java)
    )
}
```

### DSL Query (Generated)

```kotlin
@Transactional(readOnly = true)
fun findByName(name: String): List<MyComposite> {
    return graphObjectManager.loadAll<MyComposite> {
        where {
            core.name eq name
        }
        orderBy {
            core.id.desc()
        }
    }
}
```

### Save Entity

```kotlin
@Transactional
fun save(entity: MyComposite): MyComposite {
    return graphObjectManager.save(entity)
}
```

---

## 🌐 WebSocket Patterns

### STOMP Controller

```kotlin
@Controller
class MyController(private val service: MyService) {

    @MessageMapping("my.endpoint")
    fun handleMessage(principal: Principal, payload: MyPayload) {
        service.process(principal.name, payload)
    }
}
```

### Send to User

```kotlin
@Service
class MyService(private val messaging: SimpMessagingTemplate) {

    fun sendToUser(userId: String, message: Any) {
        messaging.convertAndSendToUser(userId, "/queue/messages", message)
    }
}
```

### WebSocket Config

```kotlin
@Configuration
@EnableWebSocketMessageBroker
class WebSocketConfig : WebSocketMessageBrokerConfigurer {

    override fun registerStompEndpoints(registry: StompEndpointRegistry) {
        registry.addEndpoint("/ws")
            .setAllowedOriginPatterns("*")
            .withSockJS()
    }

    override fun configureMessageBroker(registry: MessageBrokerRegistry) {
        registry.enableSimpleBroker("/topic", "/queue")
        registry.setApplicationDestinationPrefixes("/app")
        registry.setUserDestinationPrefix("/user")
    }
}
```

---

## 🔐 Security Patterns

### JWT Service

```kotlin
@Service
class JwtTokenService(
    @Value("\${jwt.secret}") private val jwtSecret: String
) {
    private val key: SecretKey by lazy {
        Keys.hmacShaKeyFor(jwtSecret.toByteArray())
    }

    fun generateToken(userId: String): String {
        return Jwts.builder()
            .subject(userId)
            .issuedAt(Date())
            .expiration(Date(System.currentTimeMillis() + 86400000))
            .signWith(key)
            .compact()
    }

    fun validateToken(token: String): String {
        return Jwts.parser()
            .verifyWith(key)
            .build()
            .parseSignedClaims(token)
            .payload.subject
    }
}
```

### Security Filter Chain

```kotlin
@Bean
fun filterChain(http: HttpSecurity): SecurityFilterChain {
    http.csrf { it.disable() }
        .cors { }
        .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter::class.java)
        .authorizeHttpRequests {
            it.requestMatchers("/public/**").permitAll()
            it.anyRequest().authenticated()
        }
    return http.build()
}
```

---

## 🤖 Embabel Action Pattern

### Basic Action

```java
@EmbabelComponent
public class MyActions {

    @Action(canRerun = true, trigger = UserMessage.class)
    void respond(Conversation conversation, ActionContext context) {
        var response = context.ai()
            .withLlm(llmOptions)
            .withTemplate("my_template")
            .respondWithSystemPrompt(conversation, templateModel);

        conversation.addMessage(response);
        context.sendMessage(response);
    }
}
```

### With RAG

```java
@Action(trigger = UserMessage.class)
void respondWithRag(Conversation conversation, ActionContext context) {
    context.ai()
        .withReferences(references)
        .withReference(new ToolishRag("docs", "Description", drivineStore)
            .withHint(TryHyDE.usingConversationContext()))
        .withTemplate("template")
        .respondWithSystemPrompt(conversation, model);
}
```

---

## ⚙️ Configuration Patterns

### Properties Record

```java
@Validated
@ConfigurationProperties(prefix = "myapp")
public record MyProperties(
    @NotBlank String requiredField,
    @DefaultValue("default") String optionalField,
    List<String> listField
) {}
```

### Enable Properties

```java
@Configuration
@EnableConfigurationProperties(MyProperties.class)
class MyConfiguration {

    @Bean
    MyService myService(MyProperties props) {
        return new MyService(props);
    }
}
```

### Conditional Bean

```kotlin
@Service
@ConditionalOnProperty(name = ["feature.enabled"], havingValue = "true")
class FeatureService { ... }
```

---

## 🧪 Testing Patterns

### Integration Test

```kotlin
@SpringBootTest
@ActiveProfiles("test")
@ContextConfiguration(initializers = [Neo4jPropertiesInitializer::class])
class MyServiceTest {

    @Autowired
    lateinit var service: MyService

    @Test
    fun `should do something`() {
        val result = service.doSomething()
        assertNotNull(result)
    }
}
```

### Test with Cleanup

```kotlin
@BeforeEach
fun setup() {
    repository.deleteAll()
}

@AfterEach
fun cleanup() {
    repository.deleteByUsernameStartingWith("test_")
}
```

---

## 📝 Jinja Template Patterns

### Main Template

```jinja
{# my_template.jinja #}
You are a helpful assistant.

{% include "elements/common" %}

{% if user.name is defined %}
Hello {{ user.name }}!
{% endif %}
```

### Element Include

```jinja
{# elements/common.jinja #}
Follow these guidelines:
- Be helpful
- Be concise
```

### Conditional Persona

```jinja
{% if custom_prompt %}
    {{ custom_prompt }}
{% else %}
    {% include "persona/" + persona %}
{% endif %}
```

---

## 📊 ID Generation

### UUIDv7 (Time-Ordered)

```kotlin
object UUIDv7 {
    private val generator = Generators.timeBasedEpochGenerator()

    fun generate(): UUID = generator.generate()
    fun generateString(): String = generate().toString()
}
```

Usage:
```kotlin
val id = UUIDv7.generateString()  // "01925d4c-8e7a-7..."
```

---

## 🚀 MCP Tool Export

### Export LLM Reference as MCP Tool

```java
@Bean
McpToolExport myTool(MyRag myRag) {
    return McpToolExport.fromLlmReference(
        myRag,
        name -> "prefix_" + name  // naming strategy
    );
}
```

### Export Multiple Tools

```java
@Bean
McpToolExport myTools(DataManager dm) {
    return McpToolExport.fromLlmReferences(
        dm.getAllReferences(),
        properties.toolNamingStrategy()
    );
}
```

---

## 🔄 Async/Coroutine Patterns

### Suspend Function in Service

```kotlin
suspend fun processAsync(id: String): Result = withContext(Dispatchers.IO) {
    // blocking operation
    repository.findById(id)
}
```

### Fire-and-Forget

```kotlin
private val coroutineScope = CoroutineScope(Dispatchers.IO)

fun fireAndForget(work: () -> Unit) {
    coroutineScope.launch {
        try {
            work()
        } catch (e: Exception) {
            logger.error("Background task failed", e)
        }
    }
}
```

---

## 📁 File Organization

```
src/main/
├── kotlin/com/embabel/
│   ├── guide/
│   │   ├── chat/
│   │   │   ├── controller/   # @Controller, @RestController
│   │   │   ├── service/      # @Service
│   │   │   ├── model/        # Data classes
│   │   │   ├── repository/   # @Repository
│   │   │   └── security/     # @Configuration
│   │   └── domain/           # Core domain model
│   └── hub/                  # Auth module
├── java/com/embabel/guide/
│   ├── *Actions.java         # @EmbabelComponent
│   ├── *Config.java          # @Configuration
│   └── *Properties.java      # @ConfigurationProperties
└── resources/
    ├── application.yml
    └── prompts/
        ├── *.jinja
        ├── elements/
        └── persona/
```

---

## 🎯 Common Operations Cheat Sheet

| Task | Pattern |
|------|---------|
| New endpoint | Add `@RestController` or `@MessageMapping` |
| New service | Add `@Service` with constructor injection |
| New graph entity | Create `@NodeFragment` + `@GraphView` |
| New query | Raw Cypher or DSL in repository |
| New config | Add to `application.yml` + `@ConfigurationProperties` |
| New AI action | `@EmbabelComponent` + `@Action` |
| New prompt | Add `.jinja` file, use `{% include %}` |
| New MCP tool | Add `McpToolExport` bean |
