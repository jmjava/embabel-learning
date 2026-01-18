# Deep Dive Documentation

This folder contains comprehensive documentation for understanding the Embabel ecosystem, including the **Guide** application, **Embabel Agent** framework, and supporting libraries.

---

## Guide Application

| Document | Description | When to Use |
|----------|-------------|-------------|
| [GUIDE-PRIMER.md](./GUIDE-PRIMER.md) | Complete Guide architecture overview | First read when learning Guide |
| [PATTERNS-QUICK-REFERENCE.md](./PATTERNS-QUICK-REFERENCE.md) | Code snippets for Guide | When implementing Guide features |
| [KEY-FLOWS.md](./KEY-FLOWS.md) | Step-by-step runtime flows | When debugging Guide |

---

## Embabel Agent Framework

| Document | Description | When to Use |
|----------|-------------|-------------|
| [EMBABEL-AGENT-PRIMER.md](./EMBABEL-AGENT-PRIMER.md) | Complete framework architecture | First read when learning Embabel |
| [EMBABEL-AGENT-PATTERNS.md](./EMBABEL-AGENT-PATTERNS.md) | Code patterns and examples | When building agents |

---

## Embabel Agent Examples

| Document | Description | When to Use |
|----------|-------------|-------------|
| [EMBABEL-AGENT-EXAMPLES-PRIMER.md](./EMBABEL-AGENT-EXAMPLES-PRIMER.md) | Learning examples in Java & Kotlin | When exploring example implementations |

---

## Ragbot (RAG Chatbot)

| Document | Description | When to Use |
|----------|-------------|-------------|
| [RAGBOT-PRIMER.md](./RAGBOT-PRIMER.md) | RAG chatbot architecture | When building RAG-powered chatbots |

---

## Embabel Common

| Document | Description | When to Use |
|----------|-------------|-------------|
| [EMBABEL-COMMON-PRIMER.md](./EMBABEL-COMMON-PRIMER.md) | Foundational libraries & utilities | Understanding shared components |

---

## DICE (Domain-Integrated Context Engineering)

| Document | Description | When to Use |
|----------|-------------|-------------|
| [DICE-PRIMER.md](./DICE-PRIMER.md) | Knowledge graph & proposition architecture | Building knowledge systems |

---

## Quick Start Reading Order

### For Guide
1. **GUIDE-PRIMER.md** - Architecture, packages, Drivine patterns
2. **KEY-FLOWS.md** - Request tracing
3. **PATTERNS-QUICK-REFERENCE.md** - Code snippets

### For Embabel Agent
1. **EMBABEL-AGENT-PRIMER.md** - Core concepts (Actions, Goals, Planning)
2. **EMBABEL-AGENT-PATTERNS.md** - Implementation patterns
3. **EMBABEL-AGENT-EXAMPLES-PRIMER.md** - See it in action

### For RAG Applications
1. **RAGBOT-PRIMER.md** - Chatbot with RAG integration
2. **EMBABEL-COMMON-PRIMER.md** - Shared utilities

### For Knowledge Systems
1. **DICE-PRIMER.md** - Proposition-based knowledge graphs

---

## Repository Overview

| Repository | Purpose | Key Technologies |
|------------|---------|------------------|
| **guide** | AI-powered chat application | Neo4j, Drivine, WebSocket |
| **embabel-agent** | AI agent framework | GOAP, Utility AI, MCP |
| **embabel-agent-examples** | Learning examples | Java/Kotlin, Shell modes |
| **ragbot** | RAG chatbot reference | Lucene, Jinja templates |
| **embabel-common** | Shared libraries | Core interfaces, utilities |
| **dice** | Knowledge engineering | Prolog, propositions |

---

## Key Technologies

| Technology | Used In | Purpose |
|------------|---------|---------|
| **Spring Boot 3.5** | All | Application framework |
| **Kotlin + Java 21** | All | Primary languages |
| **Neo4j + Drivine** | Guide, DICE | Graph database |
| **WebSocket/STOMP** | Guide | Real-time chat |
| **Lucene** | Ragbot | Vector storage |
| **Jinja (Jinjava)** | All | Prompt templates |
| **GOAP / Utility AI** | embabel-agent | Planning systems |
| **Spring AI** | embabel-agent | LLM integration |
| **MCP Protocol** | embabel-agent | Tool server/client |
| **tuProlog** | DICE | Logical inference |

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
com.embabel.agent.spi.*     → Extension points
com.embabel.chat.*          → Chatbot, Conversation
com.embabel.agent.rag.*     → RAG integration
```

### Embabel Common
```
com.embabel.common.core.*   → Identified, Versioned, types
com.embabel.common.ai.*     → Llm, LlmOptions, ModelProvider
com.embabel.common.textio.* → Template rendering
com.embabel.common.util.*   → General utilities
```

### DICE
```
com.embabel.dice.common.*      → SourceAnalysisContext, Relations
com.embabel.dice.proposition.* → Proposition, EntityMention
com.embabel.dice.projection.*  → Graph, Prolog, Memory projectors
com.embabel.dice.operations.*  → Abstraction, Contrast
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
cd embabel-agent-examples/scripts/kotlin
OPENAI_API_KEY=sk-... ./shell.sh
```

### Ragbot
```bash
cd ragbot
OPENAI_API_KEY=sk-... ./scripts/shell.sh
# Then: ingest, chat
```

---

*Generated: January 2026*
