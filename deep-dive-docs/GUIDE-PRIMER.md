# Guide Application - Deep Dive Primer

## Overview

**Guide** is a sophisticated chat server and MCP (Model Context Protocol) server that exposes Embabel Agent Framework resources. It's built with Spring Boot 3.5, Kotlin, and Java 21, using Neo4j as its graph database via the Drivine ORM.

### What Guide Does

1. **Chat Server** - Real-time WebSocket/STOMP-based chat with an AI assistant ("Jesse")
2. **MCP Server** - Exposes tools for AI coding assistants (Claude Desktop, Cursor, etc.)
3. **RAG System** - Retrieval-Augmented Generation for grounding AI responses in documentation

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                           GUIDE APPLICATION                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────┐   ┌──────────────────┐   ┌─────────────────┐ │
│  │   REST API       │   │   WebSocket      │   │   MCP Server    │ │
│  │   /api/hub/*     │   │   /ws (STOMP)    │   │   /sse          │ │
│  └────────┬─────────┘   └────────┬─────────┘   └────────┬────────┘ │
│           │                      │                       │          │
│           └──────────────────────┼───────────────────────┘          │
│                                  │                                   │
│  ┌───────────────────────────────┴────────────────────────────────┐ │
│  │                      SERVICE LAYER                              │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │ │
│  │  │ HubService  │  │JesseService │  │  RagServiceAdapter      │ │ │
│  │  │ (Auth)      │  │ (AI Bot)    │  │  (RAG Integration)      │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                  │                                   │
│  ┌───────────────────────────────┴────────────────────────────────┐ │
│  │                      DATA LAYER (Drivine)                       │ │
│  │  ┌──────────────────┐  ┌──────────────────┐                    │ │
│  │  │GuideUserRepository│  │ ThreadRepository │                    │ │
│  │  └──────────────────┘  └──────────────────┘                    │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                  │                                   │
└──────────────────────────────────┼───────────────────────────────────┘
                                   │
                          ┌────────┴────────┐
                          │     Neo4j       │
                          │  (Graph DB)     │
                          └─────────────────┘
```

---

## Package Structure

```
src/main/kotlin/com/embabel/
├── guide/
│   ├── chat/                    # Real-time chat system
│   │   ├── config/              # Async configuration
│   │   ├── controller/          # WebSocket/REST controllers
│   │   ├── listener/            # WebSocket lifecycle listeners
│   │   ├── model/               # Chat data models
│   │   ├── repository/          # Thread persistence (Drivine)
│   │   ├── security/            # WebSocket security
│   │   ├── service/             # Chat business logic
│   │   └── socket/              # WebSocket configuration
│   ├── config/                  # Web configuration (CORS, etc.)
│   ├── domain/                  # User domain model
│   └── util/                    # Utilities (UUIDv7)
└── hub/                         # Authentication & user management

src/main/java/com/embabel/guide/
├── ChatActions.java             # Embabel agent actions
├── ChatConfig.java              # Chatbot bean configuration
├── GuideProperties.java         # Application properties
└── rag/
    ├── DataManager.java         # RAG content management
    ├── DataManagerController.java
    ├── McpToolExportConfiguration.java
    └── RagConfiguration.java    # RAG/DrivineStore setup
```

---

## Key Patterns

### 1. GraphView Pattern (Drivine ORM)

The most important pattern in Guide is the **GraphView** pattern from Drivine. It maps Neo4j graph structures to Kotlin data classes.

**Example: GuideUser**

```kotlin
@GraphView
data class GuideUser(
    @Root
    val core: GuideUserData,

    @GraphRelationship(type = "IS_WEB_USER", direction = Direction.OUTGOING)
    val webUser: WebUserData? = null,

    @GraphRelationship(type = "IS_DISCORD_USER", direction = Direction.OUTGOING)
    val discordUserInfo: DiscordUserInfoData? = null
) : User, HasGuideUserData
```

**Key Concepts:**
- `@GraphView` - Marks a class as a composite graph view
- `@Root` - The primary node in the graph traversal
- `@GraphRelationship` - Defines relationships to other nodes
- `@NodeFragment` - Marks a class as a single node type

**Node Fragments:**

```kotlin
@NodeFragment(labels = ["GuideUser"])
data class GuideUserData(
    @NodeId
    var id: String,
    var persona: String? = null,
    var customPrompt: String? = null
)
```

### 2. Repository Pattern

Guide uses two repository approaches:

#### A. Raw Cypher (DrivineGuideUserRepository)
Manual Cypher queries for complex operations:

```kotlin
@Transactional(readOnly = true)
fun findByWebUserId(webUserId: String): Optional<GuideUserWithWebUser> {
    val cypher = """
        MATCH (u:GuideUser)-[:IS_WEB_USER]->(w:WebUser)
        WHERE w.id = ${'$'}webUserId
        RETURN {
          guideUserData: properties(u),
          webUser: properties(w)
        }
    """
    return manager.optionalGetOne(
        QuerySpecification
            .withStatement(cypher)
            .bind(mapOf("webUserId" to webUserId))
            .transform(GuideUserWithWebUser::class.java)
    )
}
```

#### B. GraphObjectManager DSL (ThreadRepositoryImpl)
Type-safe DSL for CRUD operations:

```kotlin
@Transactional(readOnly = true)
override fun findByThreadId(threadId: String): Optional<ThreadTimeline> {
    val results = graphObjectManager.loadAll<ThreadTimeline> {
        where {
            thread.threadId eq threadId
        }
        orderBy {
            messages.message.messageId.asc()
        }
    }
    return Optional.ofNullable(results.firstOrNull())
}
```

### 3. Service Layer Pattern

Services follow standard Spring patterns with constructor injection:

```kotlin
@Service
class GuideUserService(
    private val guideUserRepository: GuideUserRepository
) {
    fun findById(id: String): Optional<GuideUser> {
        return guideUserRepository.findById(id)
    }
}
```

### 4. Adapter Pattern (RagServiceAdapter)

Interface-based adapters allow swapping implementations:

```kotlin
interface RagServiceAdapter {
    suspend fun sendMessage(
        threadId: String,
        message: String,
        fromUserId: String,
        priorMessages: List<PriorMessage> = emptyList(),
        onEvent: (String) -> Unit = {}
    ): String
}

// Real implementation
@Service
@ConditionalOnProperty(name = ["rag.adapter.type"], havingValue = "guide")
class GuideRagServiceAdapter(
    private val chatbot: Chatbot,
    private val guideUserRepository: GuideUserRepository
) : RagServiceAdapter

// Fake for testing
@Service
@ConditionalOnProperty(name = ["rag.adapter.type"], havingValue = "fake")
class FakeRagServiceAdapter : RagServiceAdapter
```

### 5. Embabel Action Pattern

The `@Action` annotation marks methods that respond to chat messages:

```java
@EmbabelComponent
public class ChatActions {

    @Action(canRerun = true, trigger = UserMessage.class)
    void respond(Conversation conversation, ActionContext context) {
        var assistantMessage = context
            .ai()
            .withLlm(guideProperties.chatLlm())
            .withReferences(dataManager.referencesForUser(context.user()))
            .withTemplate("guide_system")
            .respondWithSystemPrompt(conversation, templateModel);
        conversation.addMessage(assistantMessage);
        context.sendMessage(assistantMessage);
    }
}
```

---

## Data Model

### User Domain (Neo4j Graph)

```
(GuideUser)──[:IS_WEB_USER]──>(WebUser)
     │
     └──[:IS_DISCORD_USER]──>(DiscordUserInfo)
```

**GuideUser** is the central identity that can be linked to:
- `WebUser` - Web application users (username/password)
- `DiscordUserInfo` - Discord bot users

### Thread/Message Domain

```
(Thread)──[:OWNED_BY]──>(GuideUser)
    │
    └──[:HAS_MESSAGE]──>(Message)──[:CURRENT_VERSION]──>(MessageVersion)
                             │
                             └──[:AUTHORED_BY]──>(GuideUser)
```

### UUIDv7 for Ordering

Guide uses UUIDv7 (time-ordered UUIDs) for all IDs:

```kotlin
object UUIDv7 {
    private val generator = Generators.timeBasedEpochGenerator()
    fun generateString(): String = generator.generate().toString()
}
```

Benefits:
- Natural chronological ordering
- Database index efficiency
- No coordination needed

---

## WebSocket Architecture

### STOMP Protocol

Guide uses STOMP over WebSocket with SockJS fallback:

```kotlin
@Configuration
@EnableWebSocketMessageBroker
class WebSocketConfig : WebSocketMessageBrokerConfigurer {

    override fun registerStompEndpoints(registry: StompEndpointRegistry) {
        registry.addEndpoint("/ws")
            .setAllowedOriginPatterns("*")
            .setHandshakeHandler(handshakeHandler)
            .withSockJS()
    }

    override fun configureMessageBroker(registry: MessageBrokerRegistry) {
        registry.enableSimpleBroker("/topic", "/queue")
        registry.setApplicationDestinationPrefixes("/app")
        registry.setUserDestinationPrefix("/user")
    }
}
```

### Message Flow

```
Client                    Server
   │                         │
   │──POST /api/hub/login───>│ (Get JWT token)
   │<──────{token}───────────│
   │                         │
   │──WS /ws?token=xxx──────>│ (WebSocket handshake)
   │                         │
   │──SUBSCRIBE──────────────>│ /user/queue/messages
   │──SUBSCRIBE──────────────>│ /user/queue/status
   │                         │
   │──SEND──────────────────>│ /app/chat.send
   │                         │   │
   │                         │   └──> JesseService.receiveMessage()
   │                         │          │
   │<──MESSAGE───────────────│          └──> RAG processing
   │  /user/queue/status     │                  │
   │  {"status":"typing"}    │                  │
   │                         │                  │
   │<──MESSAGE───────────────│<─────────────────┘
   │  /user/queue/messages   │
   │  {"body":"response"}    │
```

### Controller Pattern

```kotlin
@Controller
class ChatController(private val jesseService: JesseService) {

    @MessageMapping("chat.send")
    fun receive(principal: Principal, payload: ChatMessage) {
        jesseService.receiveMessage(
            threadId = payload.threadId,
            fromWebUserId = principal.name,
            message = payload.body
        )
    }
}
```

---

## Security Model

### Security Filter Chain

Guide has two security filter chains with different priorities:

```kotlin
@Bean
@Order(0)  // Highest priority
fun mcpFilterChain(http: HttpSecurity): SecurityFilterChain {
    // MCP endpoints bypass all security
    http.securityMatcher(mcpMatcher)
        .csrf { it.disable() }
        .authorizeHttpRequests { it.anyRequest().permitAll() }
    return http.build()
}

@Bean
@Order(1)
fun filterChain(http: HttpSecurity): SecurityFilterChain {
    http.csrf { it.disable() }
        .cors { }
        .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter::class.java)
        .authorizeHttpRequests {
            it.requestMatchers("/ws/**", "/api/hub/register", "/api/hub/login").permitAll()
            it.anyRequest().authenticated()
        }
    return http.build()
}
```

### JWT Authentication

```kotlin
@Service
class JwtTokenService(
    @Value("\${jwt.secret}") private val jwtSecret: String,
    @Value("\${jwt.refresh-token-expiry-days:30}") private val refreshTokenExpiryDays: Long
) {
    fun generateRefreshToken(userId: String): String {
        return Jwts.builder()
            .subject(userId)
            .issuedAt(Date.from(Instant.now()))
            .expiration(Date.from(Instant.now().plus(refreshTokenExpiryDays, ChronoUnit.DAYS)))
            .signWith(key)
            .compact()
    }

    fun validateRefreshToken(token: String): String {
        return Jwts.parser()
            .verifyWith(key)
            .build()
            .parseSignedClaims(token)
            .payload.subject
    }
}
```

### WebSocket Authentication

WebSocket connections extract JWT from query parameters:

```kotlin
class AnonymousPrincipalHandshakeHandler : DefaultHandshakeHandler() {

    override fun determineUser(request: ServerHttpRequest, ...): Principal {
        // Try JWT from query parameter
        val token = extractTokenFromRequest(request)
        if (token != null) {
            val userId = jwtTokenService.validateRefreshToken(token)
            return Principal { userId }
        }
        // Fall back to anonymous user
        return Principal { guideUserService.findOrCreateAnonymousWebUser().webUser?.id }
    }
}
```

---

## RAG (Retrieval-Augmented Generation)

### Components

1. **DrivineStore** - Neo4j-based vector store for document chunks
2. **DataManager** - Content ingestion and reference management
3. **ToolishRag** - LLM-callable RAG tools
4. **HyDE** - Hypothetical Document Embeddings for better retrieval

### Configuration

```java
@Bean
DrivineStore drivineStore(
    @Qualifier("neo") PersistenceManager persistenceManager,
    EmbeddingService embeddingService,
    NeoRagServiceProperties neoRagProperties,
    GuideProperties guideProperties
) {
    return new DrivineStore(
        persistenceManager,
        neoRagProperties,
        guideProperties.chunkerConfig(),
        chunkTransformer,
        embeddingService,
        platformTransactionManager,
        new DrivineCypherSearch(persistenceManager)
    );
}
```

### Content Ingestion

```java
@Service
public class DataManager {

    public void ingestPage(String url) {
        var root = contentRefreshPolicy
            .ingestUriIfNeeded(store, hierarchicalContentReader, url);
    }

    public void loadReferences() {
        for (var url : guideProperties.urls()) {
            ingestPage(url);
        }
    }
}
```

### AI Response Generation

```java
@Action(canRerun = true, trigger = UserMessage.class)
void respond(Conversation conversation, ActionContext context) {
    var assistantMessage = context.ai()
        .withLlm(guideProperties.chatLlm())
        .withReferences(dataManager.referencesForUser(context.user()))
        .withReference(new ToolishRag("docs", "Embabel docs", drivineStore)
            .withHint(TryHyDE.usingConversationContext()))
        .withTemplate("guide_system")
        .respondWithSystemPrompt(conversation, templateModel);
}
```

---

## MCP Server

### Tool Export

Guide exports RAG tools via MCP for AI assistants:

```java
@Configuration
class McpToolExportConfiguration {

    @Bean
    McpToolExport documentationRagTools(DrivineStore drivineStore) {
        var toolishRag = new ToolishRag("docs", "Embabel docs", drivineStore);
        return McpToolExport.fromLlmReference(toolishRag, properties.toolNamingStrategy());
    }
}
```

### Endpoints

- **SSE**: `http://localhost:1337/sse` - Server-Sent Events for MCP
- **MCP**: `http://localhost:1337/mcp/**` - MCP protocol endpoints

---

## Prompt System

### Template Structure

```
resources/prompts/
├── guide_system.jinja           # Main system prompt
├── elements/
│   ├── coding_style.jinja       # Code style guidelines
│   ├── guardrails.jinja         # Safety guardrails
│   ├── personalization.jinja    # User customization
│   └── references.jinja         # Reference materials
└── persona/
    ├── adaptive.jinja           # Default persona
    ├── jesse.jinja              # Jesse personality
    ├── shakespeare.jinja        # Literary personas
    └── ...
```

### Template Composition

```jinja
{# guide_system.jinja #}
Your purpose is to help users with Embabel...

{% include "elements/references" %}
{% include "elements/coding_style" %}
{% include "elements/guardrails" %}
{% include "elements/personalization" %}
```

### Personalization

```jinja
{# personalization.jinja #}
{% if user.customPersona is defined and user.customPersona %}
    {{ user.customPersona }}
{% else %}
    {% set persona_template = "persona/" + persona %}
    {% include persona_template %}
{% endif %}

{% if user.displayName is defined and user.displayName %}
    The user's name is {{ user.displayName }}. Address them by name.
{% endif %}
```

---

## Configuration

### Application Properties

```yaml
server:
  port: 1337

guide:
  reload-content-on-startup: false
  projects-path: ./embabel-projects
  default-persona: adaptive
  chat-llm:
    model: gpt-4.1-mini
  content-chunker:
    max-chunk-size: 4000
    overlap-size: 200
  urls:
    - https://docs.embabel.com/embabel-agent/guide/0.3.1-SNAPSHOT/

rag:
  adapter:
    type: guide  # or "fake" for testing

embabel:
  models:
    default-embedding-model: text-embedding-3-small
    default-llm: gpt-4.1-mini
  agent:
    rag:
      neo:
        uri: bolt://localhost:7687
        username: neo4j
        password: brahmsian

database:
  dataSources:
    neo:
      type: NEO4J
      host: localhost
      port: 7687
```

---

## Testing Patterns

### Test Configuration

```kotlin
@SpringBootTest
@ActiveProfiles("test")
@ContextConfiguration(initializers = [Neo4jPropertiesInitializer::class])
@ImportAutoConfiguration(exclude = [McpClientAutoConfiguration::class])
class HubServiceTest {

    @Autowired
    lateinit var service: HubService

    @Test
    fun `registerUser should create a new user successfully`() {
        val request = UserRegistrationRequest(...)
        val result = service.registerUser(request)
        assertNotNull(result.guideUserData())
    }
}
```

### Test Profiles

- `local` - Uses local Neo4j instance
- `test` - Uses TestContainers for ephemeral Neo4j
- `USE_LOCAL_NEO4J=true` - Environment flag for faster local testing

---

## Code Generation (KSP)

Guide uses Kotlin Symbol Processing for Drivine DSL generation:

```
codegen-gradle/
├── build.gradle.kts
└── build/generated/ksp/main/kotlin/
    └── com/embabel/guide/
        ├── chat/model/
        │   ├── MessageWithVersionQueryDsl.kt
        │   └── ThreadTimelineQueryDsl.kt
        └── domain/
            └── GuideUserQueryDsl.kt
```

The generated DSL enables type-safe queries:

```kotlin
graphObjectManager.loadAll<ThreadTimeline> {
    where {
        thread.threadId eq threadId  // Generated property
    }
}
```

---

## Key Dependencies

| Dependency | Purpose |
|------------|---------|
| `embabel-agent-starter` | Core Embabel agent framework |
| `embabel-agent-rag-neo-drivine` | Neo4j RAG integration |
| `embabel-agent-discord` | Discord bot support |
| `embabel-agent-starter-mcpserver` | MCP server support |
| `drivine4j-spring-boot-starter` | Drivine ORM for Neo4j |
| `jjwt` | JWT token generation/validation |
| `java-uuid-generator` | UUIDv7 support |
| `spring-boot-starter-websocket` | WebSocket/STOMP support |

---

## Common Workflows

### 1. Adding a New User Property

1. Add field to `GuideUserData` (or `WebUserData`)
2. Update repository methods if needed
3. Migration: Add Cypher to set default value

### 2. Adding a New Chat Feature

1. Add model class in `chat/model/`
2. Add repository method if persistence needed
3. Add service logic
4. Add controller endpoint

### 3. Adding a New MCP Tool

1. Create `LlmReference` implementation
2. Add `@Bean` in `McpToolExportConfiguration`
3. Tools are automatically exposed via `/sse`

### 4. Adding a New Persona

1. Create file in `resources/prompts/persona/your_persona.jinja`
2. Personas are automatically discovered by `PersonaService`

---

## Summary

Guide follows these core principles:

1. **Separation of Concerns** - Clear layers (controller → service → repository)
2. **Graph-First Data Model** - Leverages Neo4j relationships via Drivine
3. **Interface Adapters** - Swappable implementations (e.g., `RagServiceAdapter`)
4. **Spring Conventions** - Standard DI, transactions, configuration properties
5. **Real-time First** - WebSocket/STOMP for chat with REST for authentication
6. **AI Integration** - Embabel Agent actions with RAG grounding

The codebase is well-structured for extension - most new features can be added by following existing patterns in the appropriate package.
