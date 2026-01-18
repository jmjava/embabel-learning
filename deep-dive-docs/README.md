# Deep Dive Documentation

This folder contains comprehensive documentation for understanding the **Guide** application and the **Embabel Agent** framework.

## Guide Application

| Document | Description | When to Use |
|----------|-------------|-------------|
| [GUIDE-PRIMER.md](./GUIDE-PRIMER.md) | Complete Guide architecture overview | First read when learning Guide |
| [PATTERNS-QUICK-REFERENCE.md](./PATTERNS-QUICK-REFERENCE.md) | Code snippets for Guide | When implementing Guide features |
| [KEY-FLOWS.md](./KEY-FLOWS.md) | Step-by-step runtime flows | When debugging Guide |

## Embabel Agent Framework

| Document | Description | When to Use |
|----------|-------------|-------------|
| [EMBABEL-AGENT-PRIMER.md](./EMBABEL-AGENT-PRIMER.md) | Complete framework architecture | First read when learning Embabel |
| [EMBABEL-AGENT-PATTERNS.md](./EMBABEL-AGENT-PATTERNS.md) | Code patterns and examples | When building agents |

---

## Quick Start Reading Order

### For Guide
1. **GUIDE-PRIMER.md** - Architecture, packages, Drivine patterns
2. **KEY-FLOWS.md** - Request tracing
3. **PATTERNS-QUICK-REFERENCE.md** - Code snippets

### For Embabel Agent
1. **EMBABEL-AGENT-PRIMER.md** - Core concepts (Actions, Goals, Planning)
2. **EMBABEL-AGENT-PATTERNS.md** - Implementation patterns

---

## Key Technologies

### Guide
- **Spring Boot 3.5** - Application framework
- **Kotlin + Java 21** - Languages
- **Neo4j + Drivine** - Graph database with ORM
- **WebSocket/STOMP** - Real-time chat
- **Embabel Agent** - AI agent framework

### Embabel Agent
- **Spring Boot** - Foundation
- **Kotlin + Java** - Languages (both supported)
- **GOAP / Utility AI** - Planning systems
- **Spring AI** - LLM integration foundation
- **MCP Protocol** - Tool server/client

---

## Package Quick Map

### Guide
```
com.embabel.guide.chat.*    → WebSocket chat system
com.embabel.guide.domain.*  → User domain model
com.embabel.hub.*           → REST auth/user management
com.embabel.guide.rag.*     → RAG and AI integration
```

### Embabel Agent
```
com.embabel.agent.core.*    → Agent, Action, Goal, Blackboard
com.embabel.agent.api.*     → Ai, PromptRunner, ActionContext
com.embabel.agent.spi.*     → Extension points (LlmOperations, etc.)
com.embabel.chat.*          → Chatbot, Conversation
com.embabel.agent.rag.*     → RAG integration
```

---

## Running

### Guide
```bash
docker compose up neo4j -d
OPENAI_API_KEY=sk-... ./mvnw spring-boot:run
```

### Embabel Agent Examples
```bash
git clone https://github.com/embabel/embabel-agent-examples
cd embabel-agent-examples/scripts/kotlin
./shell.sh
```

---

*Generated: January 2026*
