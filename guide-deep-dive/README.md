# Guide Deep Dive Documentation

This folder contains comprehensive documentation for understanding the **Guide** application codebase.

## Documents

| Document | Description | When to Use |
|----------|-------------|-------------|
| [GUIDE-PRIMER.md](./GUIDE-PRIMER.md) | Complete architecture overview with all patterns explained | First read when learning the codebase |
| [PATTERNS-QUICK-REFERENCE.md](./PATTERNS-QUICK-REFERENCE.md) | Code snippets and patterns for quick lookup | When implementing new features |
| [KEY-FLOWS.md](./KEY-FLOWS.md) | Step-by-step runtime flow diagrams | When debugging or tracing requests |

## Quick Start Reading Order

1. **Start with the Primer** - Understand the overall architecture, packages, and design patterns
2. **Review Key Flows** - Trace how requests flow through the system
3. **Keep Quick Reference handy** - Use as a cheat sheet when coding

## Key Technologies

- **Spring Boot 3.5** - Application framework
- **Kotlin + Java 21** - Languages (Kotlin for most code, Java for some configurations)
- **Neo4j + Drivine** - Graph database with ORM
- **WebSocket/STOMP** - Real-time chat
- **Embabel Agent** - AI agent framework
- **OpenAI** - LLM and embeddings

## Package Quick Map

```
com.embabel.guide.chat.*    → WebSocket chat system
com.embabel.guide.domain.*  → User domain model
com.embabel.hub.*           → REST auth/user management
com.embabel.guide.rag.*     → RAG and AI integration (Java)
```

## Running Guide

```bash
# Start Neo4j
docker compose up neo4j -d

# Run the application
./mvnw spring-boot:run

# Or with specific profile
OPENAI_API_KEY=sk-... USE_LOCAL_NEO4J=true ./mvnw spring-boot:run
```

## Key Endpoints

| Endpoint | Protocol | Purpose |
|----------|----------|---------|
| `/api/hub/register` | REST POST | User registration |
| `/api/hub/login` | REST POST | User login (returns JWT) |
| `/ws` | WebSocket | Real-time chat |
| `/sse` | SSE | MCP tool server |
| `/api/v1/data/stats` | REST GET | RAG stats |

---

*Generated: January 2026*
