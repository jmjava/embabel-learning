# Key Flows in Guide

This document walks through the major runtime flows to help understand how the pieces fit together.

---

## 1. User Registration Flow

**Entry:** `POST /api/hub/register`

```
HubApiController.registerUser()
       │
       ▼
HubService.registerUser()
       │
       ├── Validate request (passwords match, length, etc.)
       │
       ├── Generate UUIDv7 for userId
       │
       ├── Hash password with BCrypt
       │
       ├── Generate JWT refresh token
       │
       ├── Create WebUserData
       │
       ▼
GuideUserService.saveFromWebUser()
       │
       ▼
GuideUserRepository.createWithWebUser()
       │
       ├── CREATE (u:GuideUser) SET u += props
       ├── CREATE (w:WebUser) SET w += props
       └── CREATE (u)-[:IS_WEB_USER]->(w)
       │
       ▼
WelcomeGreeter.greetNewUser() [async]
       │
       ├── Create welcome thread
       └── Generate AI greeting
```

**Result:** New user with GuideUser + WebUser nodes linked in Neo4j, plus a welcome thread.

---

## 2. User Login Flow

**Entry:** `POST /api/hub/login`

```
HubApiController.loginUser()
       │
       ▼
HubService.loginUser()
       │
       ├── Validate username/password not blank
       │
       ▼
GuideUserService.findByWebUserName()
       │
       ▼
DrivineGuideUserRepository.findByWebUserName()
       │
       ├── MATCH (u:GuideUser)-[:IS_WEB_USER]->(w:WebUser)
       └── WHERE w.userName = $userName
       │
       ▼
BCryptPasswordEncoder.matches(password, hash)
       │
       ▼
Return LoginResponse with JWT token
```

**Result:** JWT token for subsequent authenticated requests.

---

## 3. WebSocket Connection Flow

**Entry:** `ws://localhost:1337/ws?token=<JWT>`

```
Client connects to /ws
       │
       ▼
AnonymousPrincipalHandshakeHandler.determineUser()
       │
       ├── Check for existing Spring Security principal
       │
       ├── Extract token from query parameter
       │
       ├── JwtTokenService.validateRefreshToken(token)
       │   │
       │   └── Return userId from JWT claims
       │
       └── Create Principal with userId
       │
       ▼
WebSocket connection established
       │
       ▼
Client subscribes to:
  - /user/queue/messages
  - /user/queue/status
```

**If no token:** Falls back to anonymous user via `GuideUserService.findOrCreateAnonymousWebUser()`.

---

## 4. Chat Message Flow

**Entry:** STOMP message to `/app/chat.send`

```
ChatController.receive()
       │
       ├── Extract principal.name (webUserId)
       ├── Extract threadId, message body
       │
       ▼
JesseService.receiveMessage() [async via coroutineScope]
       │
       ├── Look up GuideUser by webUserId
       │
       ├── ThreadService.addMessage() [save user message]
       │   │
       │   └── ThreadRepository.addMessage()
       │       │
       │       └── graphObjectManager.save(timeline.withMessage(...))
       │
       ├── Load prior messages for context
       │
       ▼
RagServiceAdapter.sendMessage()
       │
       ├── Get/create ChatSession for thread
       │   │
       │   └── chatbot.createSession(user, outputChannel, null)
       │
       ├── Load prior messages into conversation (if new session)
       │   │
       │   └── session.conversation.addMessage(UserMessage/AssistantMessage)
       │
       ├── session.onUserMessage(UserMessage(message))
       │
       ▼
Embabel Agent Processing
       │
       ├── ChatActions.respond() triggered
       │   │
       │   ├── Build template model (persona, user info)
       │   │
       │   ├── context.ai().withTemplate("guide_system")
       │   │
       │   ├── withReference(ToolishRag) for RAG search
       │   │
       │   └── respondWithSystemPrompt()
       │
       ├── OutputChannel receives events:
       │   ├── ProgressOutputChannelEvent → sendStatusToUser("typing")
       │   └── MessageOutputChannelEvent (AssistantMessage) → capture response
       │
       ▼
JesseService continues...
       │
       ├── ThreadService.addMessage() [save assistant response]
       │
       └── sendMessageToUser() via ChatService
           │
           └── SimpMessagingTemplate.convertAndSendToUser(
                   userId, "/queue/messages", deliveredMessage)
```

**Key insight:** The message goes through Embabel's agent system where `ChatActions.respond()` is invoked, which uses RAG to ground the response in documentation.

---

## 5. RAG Document Search Flow

**Triggered by:** AI action needing context

```
ToolishRag.search(query)
       │
       ▼
DrivineStore.search(query)
       │
       ├── TryHyDE (optional)
       │   │
       │   └── Generate hypothetical document from query
       │       to improve embedding similarity
       │
       ├── EmbeddingService.embed(query)
       │   │
       │   └── OpenAI text-embedding-3-small
       │
       ▼
DrivineCypherSearch.search(embedding, limit)
       │
       ├── MATCH (c:ContentElement)
       ├── WHERE c.embedding IS NOT NULL
       ├── RETURN c, gds.similarity.cosine(c.embedding, $embedding) AS score
       └── ORDER BY score DESC LIMIT $limit
       │
       ▼
Return ranked ContentElement chunks
```

---

## 6. MCP Tool Call Flow

**Entry:** MCP client (Cursor, Claude) calls tool via `/sse`

```
MCP Client → SSE connection to /sse
       │
       ▼
Spring MCP Server handles SSE
       │
       ├── Tool discovery: lists available tools
       │   │
       │   └── McpToolExport beans expose ToolishRag tools
       │
       ▼
Client calls tool (e.g., "docs_vectorSearch")
       │
       ▼
ToolishRag.vectorSearch(query)
       │
       └── [Same as RAG Document Search Flow above]
       │
       ▼
Return results to MCP client
```

---

## 7. Thread Creation Flow

**Entry:** `POST /api/hub/threads`

```
HubApiController.createThread()
       │
       ├── Get authenticated webUserId
       │
       ├── GuideUserService.findByWebUserId()
       │
       ▼
ThreadService.createThreadFromContent()
       │
       ├── RagServiceAdapter.generateTitle(content)
       │   │
       │   └── One-shot AI call to generate 3-6 word title
       │
       ├── UUIDv7.generateString() for threadId
       │
       ▼
ThreadRepository.createWithMessage()
       │
       ├── graphObjectManager.save(ThreadTimeline)
       │   │
       │   ├── (Thread {threadId, title, createdAt})
       │   ├── (Thread)-[:OWNED_BY]->(GuideUser)
       │   └── (Thread)-[:HAS_MESSAGE]->(Message)-[:CURRENT_VERSION]->(Version)
       │
       ▼
Return threadId and title to client
```

---

## 8. Content Ingestion Flow (Startup)

**Entry:** Application startup if `reload-content-on-startup: true`

```
DataManager constructor
       │
       ├── store.provision() [create indexes]
       │
       └── if (guideProperties.reloadContentOnStartup())
           │
           ▼
         loadReferences()
           │
           ├── for each URL in guideProperties.urls():
           │   │
           │   ▼
           │ ingestPage(url)
           │   │
           │   ├── ContentRefreshPolicy.ingestUriIfNeeded()
           │   │   │
           │   │   └── Check if already ingested (skip if not -SNAPSHOT)
           │   │
           │   ├── TikaHierarchicalContentReader.parseFromUri(url)
           │   │   │
           │   │   └── Extract text hierarchy from HTML/etc.
           │   │
           │   ▼
           │ DrivineStore.writeAndChunkDocument(root)
           │   │
           │   ├── Chunk text into ContentElement nodes
           │   │
           │   ├── EmbeddingService.embed(chunk.text)
           │   │
           │   └── Store chunks with embeddings in Neo4j
           │
           └── Log success/failure counts
```

---

## 9. Security Check Flow

**Entry:** Any HTTP request

```
HTTP Request
       │
       ▼
SecurityFilterChain selection (by @Order)
       │
       ├── Order 0: mcpFilterChain
       │   │
       │   └── Matches /sse, /mcp/** → permitAll (no auth needed)
       │
       └── Order 1: filterChain
           │
           ├── JwtAuthenticationFilter
           │   │
           │   ├── Extract "Authorization: Bearer <token>"
           │   │
           │   ├── JwtTokenService.validateRefreshToken(token)
           │   │
           │   └── Set SecurityContext with userId
           │
           ├── Check authorizeHttpRequests rules:
           │   │
           │   ├── /ws/**, /api/hub/login, /api/hub/register → permitAll
           │   │
           │   └── anyRequest() → authenticated
           │
           └── Proceed to controller or return 401/403
```

---

## 10. Persona Selection Flow

**During:** AI response generation

```
ChatActions.respond()
       │
       ├── Get GuideUser from context
       │
       ├── persona = guideUser.core.persona ?: defaultPersona
       │
       ├── Build templateModel:
       │   │
       │   └── {"persona": "jesse", "user": {"displayName": "John", ...}}
       │
       ▼
context.ai().withTemplate("guide_system")
       │
       ▼
Jinja rendering: guide_system.jinja
       │
       ├── {% include "elements/personalization" %}
       │   │
       │   ├── if user.customPersona:
       │   │   └── {{ user.customPersona }}
       │   │
       │   └── else:
       │       └── {% include "persona/" + persona %}
       │           │
       │           └── Load persona/jesse.jinja (or default)
       │
       └── Final system prompt with persona-specific style
```

---

## Flow Interactions Summary

```
                                    ┌─────────────────┐
                                    │   MCP Clients   │
                                    │ (Cursor/Claude) │
                                    └────────┬────────┘
                                             │
                           ┌─────────────────┼─────────────────┐
                           │                 │                 │
                    ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
                    │  REST API   │   │  WebSocket  │   │ MCP Server  │
                    │  /api/hub/* │   │    /ws      │   │   /sse      │
                    └──────┬──────┘   └──────┬──────┘   └──────┬──────┘
                           │                 │                 │
                           └─────────────────┼─────────────────┘
                                             │
                    ┌────────────────────────┼────────────────────────┐
                    │                        │                        │
             ┌──────▼──────┐         ┌───────▼───────┐       ┌───────▼───────┐
             │  HubService │         │ JesseService  │       │  ToolishRag   │
             │  (Auth)     │         │ (Chat Bot)    │       │  (RAG Tools)  │
             └──────┬──────┘         └───────┬───────┘       └───────┬───────┘
                    │                        │                       │
                    │                 ┌──────▼──────┐                │
                    │                 │ ChatActions │                │
                    │                 │ (Embabel)   │                │
                    │                 └──────┬──────┘                │
                    │                        │                       │
                    └────────────────────────┼───────────────────────┘
                                             │
                    ┌────────────────────────┼────────────────────────┐
                    │                        │                        │
             ┌──────▼──────┐         ┌───────▼───────┐       ┌───────▼───────┐
             │ GuideUser   │         │   Thread      │       │  DrivineStore │
             │ Repository  │         │  Repository   │       │  (RAG Store)  │
             └──────┬──────┘         └───────┬───────┘       └───────┬───────┘
                    │                        │                       │
                    └────────────────────────┼───────────────────────┘
                                             │
                                      ┌──────▼──────┐
                                      │   Neo4j     │
                                      │  Database   │
                                      └─────────────┘
```

---

## Debugging Tips

### WebSocket Issues
1. Check `/ws` endpoint is permitted in `SecurityConfig`
2. Verify JWT token in query parameter
3. Check `AnonymousPrincipalHandshakeHandler` logs

### RAG Not Working
1. Verify content loaded: `GET /api/v1/data/stats`
2. Check embeddings exist in Neo4j: `MATCH (c:ContentElement) WHERE c.embedding IS NOT NULL RETURN count(c)`
3. Check `rag.adapter.type: guide` in config

### Authentication Issues
1. Check JWT secret matches
2. Verify token not expired
3. Check `JwtAuthenticationFilter` logs

### Chat Not Responding
1. Check `JesseService` coroutine not failing silently
2. Verify `ChatActions.respond()` is triggered
3. Check WebSocket subscription to correct queues
