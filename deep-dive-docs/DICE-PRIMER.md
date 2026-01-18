# DICE - Architecture Primer

## Overview

**DICE (Domain-Integrated Context Engineering)** is a knowledge graph construction and reasoning library built on a proposition-based architecture. It extracts structured knowledge from text, stores it as confidence-weighted propositions, and projects it to multiple representations (Neo4j graphs, Prolog facts, agent memory).

## Key Purposes

1. **Knowledge Extraction**: LLM-based proposition extraction from text
2. **Evidence Accumulation**: Confidence-weighted propositions with decay
3. **Multi-Backend Projection**: Neo4j, Prolog, Memory views
4. **Agent Memory**: Semantic/episodic/procedural memory for agents

---

## Core Concepts

### Proposition-Based Architecture

Inspired by [GUM (General User Models)](https://arxiv.org/abs/2505.10831) research:

```
┌─────────────┐      ┌─────────────────┐      ┌──────────────────────┐
│   Text      │ ───► │ LLM Extraction  │ ───► │    Propositions      │
│   Chunks    │      │                 │      │ (System of Record)   │
└─────────────┘      └─────────────────┘      └──────────┬───────────┘
                                                         │
                     ┌───────────────────────────────────┼───────────┐
                     │                                   │           │
                     ▼                                   ▼           ▼
              ┌─────────────┐                    ┌─────────────┐ ┌──────────┐
              │   Neo4j     │                    │   Prolog    │ │ Memory   │
              │   Graph     │                    │   Facts     │ │ Context  │
              └─────────────┘                    └─────────────┘ └──────────┘
```

### Key Principles

| Principle | Description |
|-----------|-------------|
| **Propositions as System of Record** | Natural language statements are the source of truth |
| **Confidence-Weighted** | Each proposition has confidence (0-1) and decay rate |
| **Evidence Accumulation** | Multiple observations reinforce or contradict |
| **Typed Projections** | Project to graphs, Prolog, or memory on demand |
| **Domain Integration** | Schema-driven extraction using domain models |

---

## Package Structure

```
com.embabel.dice/
├── common/                   # Shared types
│   ├── SourceAnalysisContext # Context for all DICE operations
│   ├── EntityResolver        # Entity disambiguation interface
│   ├── KnownEntity           # Pre-defined entity hints
│   ├── Relation              # Predicate with KnowledgeType
│   ├── Relations             # Builder for relation collections
│   └── KnowledgeType         # SEMANTIC, EPISODIC, PROCEDURAL, WORKING
│
├── proposition/              # Core types (source of truth)
│   ├── Proposition           # Natural language fact
│   ├── EntityMention         # Entity reference within proposition
│   ├── PropositionQuery      # Composable query specification
│   ├── PropositionRepository # Storage interface
│   ├── content/              # Content ingestion
│   ├── revision/             # Proposition revision
│   └── extraction/           # LLM extraction
│
├── projection/               # Materialized views
│   ├── graph/                # Knowledge graph projection
│   ├── prolog/               # Prolog inference
│   └── memory/               # Agent memory
│
├── operations/               # Proposition transformations
│   ├── abstraction/          # Higher-level synthesis
│   └── contrast/             # Difference identification
│
├── query/oracle/             # Natural language Q&A
├── pipeline/                 # Pipeline orchestration
└── text2graph/               # Knowledge graph building
```

---

## Core Types

### Proposition

The fundamental unit of knowledge:

```kotlin
data class Proposition(
    val id: String = UUID.randomUUID().toString(),
    val contextId: ContextId,           // Scoping context
    val text: String,                   // "Alice works at Acme Corp"
    val mentions: List<EntityMention>,  // Entity references
    val confidence: ZeroToOne,          // 0.0-1.0 certainty
    val decay: ZeroToOne = 0.0,         // Staleness rate
    val reasoning: String? = null,      // LLM explanation
    val grounding: List<String> = emptyList(),  // Source chunk IDs
    val created: Instant = Instant.now(),
    val revised: Instant = Instant.now(),
    val status: PropositionStatus = PropositionStatus.ACTIVE,
    val level: Int = 0,                 // 0 = raw, 1+ = derived
    val sourceIds: List<String> = emptyList(),  // For derived props
)
```

**Design**: One Proposition = One Relationship. Complex sentences should be extracted as multiple propositions.

### ContextId

Primary scoping mechanism for all queries:

```kotlin
@JvmInline
value class ContextId(val value: String)
```

| Scoping Pattern | Example |
|-----------------|---------|
| User-specific | `ContextId("user-alice-123")` |
| Shared context | `ContextId("team-engineering")` |
| Session context | `ContextId("session-abc")` |
| Batch context | `ContextId("batch-2025-01-09")` |

### SourceAnalysisContext

Configuration for all DICE operations:

```kotlin
data class SourceAnalysisContext(
    val schema: DataDictionary,           // Valid entity/relationship types
    val entityResolver: EntityResolver,   // Disambiguation strategy
    val contextId: ContextId,             // Analysis context
    val knownEntities: List<KnownEntity> = emptyList(),
    val relations: Relations = Relations.empty(),
    val promptVariables: Map<String, Any> = emptyMap(),
)
```

**Java Builder**:

```java
SourceAnalysisContext context = SourceAnalysisContext
    .withContextId("my-context")
    .withEntityResolver(AlwaysCreateEntityResolver.INSTANCE)
    .withSchema(DataDictionary.fromClasses(Person.class))
    .withKnownEntities(knownEntities)
    .withTemplateModel(templateModel);
```

### KnowledgeType

Memory classification:

```kotlin
enum class KnowledgeType {
    SEMANTIC,    // Facts: "Paris is in France"
    EPISODIC,    // Events: "Met Alice yesterday"
    PROCEDURAL,  // Preferences: "Likes jazz"
    WORKING      // Session context
}
```

---

## Proposition Pipeline

### Extraction → Resolution → Revision → Persistence

```
┌──────────────────┐     ┌────────────────────┐     ┌─────────────────┐
│   1. Extraction  │ ──► │  2. Resolution     │ ──► │  3. Revision    │
│   LLM extracts   │     │  Mentions → IDs    │     │  Merge/Reinforce│
│   propositions   │     │                    │     │  /Contradict    │
└──────────────────┘     └────────────────────┘     └────────┬────────┘
                                                              │
                                                              ▼
                                                    ┌─────────────────┐
                                                    │  4. Persistence │
                                                    │  Store in repo  │
                                                    └─────────────────┘
```

### Revision Classifications

| Classification | Action |
|----------------|--------|
| **IDENTICAL** | Merge, boost confidence |
| **SIMILAR** | Reinforce existing |
| **CONTRADICTORY** | Reduce old confidence |
| **GENERALIZES** | Create abstraction |
| **UNRELATED** | Add as new |

### ContentIngestionPipeline

```kotlin
// Create content with context
val content = SimpleContent(
    contextId = ContextId("batch-2025-01-05"),
    sourceId = "doc-123",
    context = "Alice works at Acme Corp as a senior engineer."
)

// Create pipeline
val pipeline = ContentIngestionPipeline.create(ai, repository, "gum_propose")

// Process content
val result = pipeline.process(content)

// Persist entities and propositions
result.persist(propositionRepository, entityRepository)
```

---

## Projections

### Graph Projection (Neo4j)

```kotlin
val projector = RelationBasedGraphProjector.from(relations)
val results = projector.projectAll(propositions, schema)

// Persist to graph database
val persister = NamedEntityDataRepositoryGraphRelationshipPersister(repository)
persister.persist(results)
```

**Predicate Matching Priority**:
1. Schema `@Semantics(predicate="...")` → uses property name
2. `Relations` predicates → derives via UPPER_SNAKE_CASE

### Prolog Projection

```kotlin
val prologProjector = PrologProjector(prologEngine)
val facts = prologProjector.project(propositions)
```

Generated facts:

```prolog
expert_in(Person, Technology).
works_at(Person, Company).
reports_to(Person, Manager).
```

Custom rules in `prolog/dice-rules.pl`:

```prolog
% Transitive reporting chain
reports_to_chain(X, Y) :- reports_to(X, Y).
reports_to_chain(X, Y) :- reports_to(X, Z), reports_to_chain(Z, Y).

% Derived relationships
coworker(X, Y) :- works_at(X, Company), works_at(Y, Company), X \= Y.
```

### Memory Projection

```kotlin
// Query propositions
val props = repository.query(
    (PropositionQuery forContextId sessionContext)
        .withEntityId("alice-123")
        .withMinEffectiveConfidence(0.5)
        .orderedByEffectiveConfidence()
        .withLimit(50)
)

// Project into memory types
val projector = DefaultMemoryProjector.DEFAULT
val memory = projector.project(props)

// Use classified propositions
memory.semantic   // factual knowledge
memory.episodic   // event-based memories
memory.procedural // preferences and rules
memory.working    // session context
```

**MemoryProjection** implements `PromptContributor`:

```kotlin
data class MemoryProjection(
    val semantic: List<Proposition> = emptyList(),
    val episodic: List<Proposition> = emptyList(),
    val procedural: List<Proposition> = emptyList(),
    val working: List<Proposition> = emptyList(),
) : PromptContributor {

    override fun contribution(): String = buildString {
        if (semantic.isNotEmpty()) {
            appendLine("## Known Facts")
            semantic.forEach { appendLine("- ${it.text}") }
        }
        // ... other sections
    }
}
```

---

## PropositionQuery

Composable, Java-friendly query builder:

### Kotlin (Infix Notation)

```kotlin
val contextProps = repository.query(
    PropositionQuery forContextId sessionContext
)

val query = PropositionQuery(
    contextId = sessionContext,
    entityId = "alice-123",
    minEffectiveConfidence = 0.5,
    orderBy = PropositionQuery.OrderBy.EFFECTIVE_CONFIDENCE_DESC,
    limit = 20,
)
```

### Java (Builder Pattern)

```java
PropositionQuery query = PropositionQuery.againstContext("session-123")
    .withEntityId("alice-123")
    .withMinEffectiveConfidence(0.5)
    .orderedByEffectiveConfidence()
    .withLimit(20);

List<Proposition> results = repository.query(query);
```

---

## Proposition Operations

### Abstraction

Generate higher-level insights:

```kotlin
val abstractor = LlmPropositionAbstractor.withLlm(llm).withAi(ai)
val bobGroup = PropositionGroup("Bob", repository.findByEntity("bob-123"))

val abstractions = abstractor.abstract(bobGroup, targetCount = 2)
// "Bob values thoroughness and clarity in work processes"
```

### Contrast

Identify differences between groups:

```kotlin
val contraster = LlmPropositionContraster.withLlm(llm).withAi(ai)

val differences = contraster.contrast(aliceGroup, bobGroup, targetCount = 3)
// "Alice prefers morning meetings while Bob prefers afternoons"
```

---

## Relations Builder

Define relationship predicates with knowledge types:

```kotlin
val relations = Relations.empty()
    .withProcedural("likes", "expresses preference for")
    .withProcedural("prefers", "indicates preference")
    .withSemantic("works at", "is employed by")
    .withSemantic("is located in", "geographical location")
    .withEpisodic("met", "encountered")
    .withEpisodic("visited", "went to")
```

Use `@Semantics` annotations on schema properties:

```kotlin
data class Person(
    val id: String,
    val name: String,
    @field:Semantics([With(key = Proposition.PREDICATE, value = "works at")])
    val employer: Company? = null,
) : NamedEntity
```

---

## Effective Confidence (Time Decay)

Propositions decay over time using exponential decay:

```kotlin
// Effective confidence = confidence * exp(-decay * k * age_days)
val effectiveConf = proposition.effectiveConfidence(k = 2.0)

// Query with minimum effective confidence
val query = PropositionQuery.forContextId(context)
    .withMinEffectiveConfidence(0.5)  // Filters by decayed confidence
    .orderedByEffectiveConfidence()
```

---

## Oracle (Q&A)

Natural language question answering with Prolog:

| Tool | Description |
|------|-------------|
| `show_facts` | Display sample facts with readable names |
| `query_prolog` | Execute Prolog queries |
| `check_fact` | Verify if a fact is true |
| `list_entities` | Browse known entities |
| `list_predicates` | Show available relationship types |

---

## Installation

```xml
<dependency>
    <groupId>com.embabel</groupId>
    <artifactId>dice</artifactId>
    <version>0.1.0-SNAPSHOT</version>
</dependency>
```

---

## Technology Stack

- **tuProlog (2p-kt)**: Pure Kotlin Prolog engine
- **Spring Boot**: Application framework
- **Spring Shell**: Interactive CLI (optional)
- **OpenAI/Anthropic**: LLM providers
- **Kotlin**: Primary language

---

## GUM Pipeline Mapping

```
  GUM Pipeline                    DICE
  ────────────                    ────
  Propose     ─────────────────►  PropositionExtractor
  Retrieve    ─────────────────►  PropositionRepository.findSimilar()
  Revise      ─────────────────►  PropositionReviser
  Audit       ─────────────────►  ProjectionPolicy
```
