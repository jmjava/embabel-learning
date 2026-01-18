# Ragbot - Architecture Primer

## Overview

**Ragbot** is a RAG (Retrieval-Augmented Generation) chatbot example built with the Embabel Agent Framework. It demonstrates how to build a production-ready chatbot that answers questions using ingested documents, with configurable personas and objectives.

## Key Purposes

1. **RAG Reference Implementation**: Shows proper RAG integration with Embabel
2. **Prompt Engineering Demo**: Jinja-based template system for complex prompts
3. **Persona System**: Separates voice (how) from objective (what)
4. **Lucene Vector Store**: Local vector storage without external dependencies

---

## Package Structure

```
ragbot/
├── src/main/java/com/embabel/examples/ragbot/
│   ├── RagbotApplication.java     # Main application
│   ├── RagbotShell.java           # Spring Shell commands
│   ├── RagConfiguration.java      # Lucene RAG setup
│   ├── ChatConfiguration.java     # Chatbot creation
│   ├── ChatActions.java           # Action handling
│   ├── RagbotProperties.java      # Configuration properties
│   └── javelit/                   # Web UI components
│       ├── JavelitChatUI.java
│       └── JavelitShell.java
├── src/main/resources/
│   ├── application.yml
│   ├── prompts/
│   │   ├── ragbot.jinja           # Main template
│   │   ├── elements/
│   │   │   ├── guardrails.jinja   # Safety rules
│   │   │   └── personalization.jinja
│   │   ├── personas/              # HOW to communicate
│   │   │   ├── clause.jinja
│   │   │   ├── shakespeare.jinja
│   │   │   └── ...
│   │   └── objectives/            # WHAT to accomplish
│   │       ├── legal.jinja
│   │       └── music.jinja
│   └── ui/chat.css                # Web UI styles
└── data/                          # Sample documents
    ├── gov.au/                    # Legal documents
    └── schumann/                  # Music criticism
```

---

## Architecture Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                              Spring Shell                           │
│   > chat                                                            │
│   > What penalties apply to social media platforms?                 │
└─────────────────────────────────┬───────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                             AgentProcess                            │
│   Manages conversation state and action dispatch                    │
└─────────────────────────────────┬───────────────────────────────────┘
                                  │ UserMessage triggers
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     @Action: ChatActions.respond()                  │
│   Uses Ai interface with ToolishRag as LLM tool                     │
└─────────────────────────────────┬───────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                            Ai Interface                             │
│   • Renders system prompt from Jinja template                       │
│   • Packages ToolishRag as tool definition                          │
│   • Sends request to LLM                                            │
└─────────────────────────────────┬───────────────────────────────────┘
                                  │
                                  ▼
                         LLM decides to call tools
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    ToolishRag → LuceneSearchOperations              │
│   • Converts query to embedding                                     │
│   • Searches ./.lucene-index for similar chunks                     │
│   • Returns relevant content to LLM                                 │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Key Components

### 1. RAG Configuration

`RagConfiguration.java` sets up the Lucene vector store:

```java
@Bean
LuceneSearchOperations luceneSearchOperations(
        ModelProvider modelProvider,
        RagbotProperties properties) {
    var embeddingService = modelProvider.getEmbeddingService(
        DefaultModelSelectionCriteria.INSTANCE);
    return LuceneSearchOperations
        .withName("docs")
        .withEmbeddingService(embeddingService)
        .withChunkerConfig(properties.chunkerConfig())
        .withIndexPath(Paths.get("./.lucene-index"))
        .buildAndLoadChunks();
}
```

### 2. Chat Actions

`ChatActions.java` handles user messages:

```java
@EmbabelComponent
public class ChatActions {

    private final ToolishRag toolishRag;
    private final RagbotProperties properties;

    public ChatActions(SearchOperations searchOperations, RagbotProperties properties) {
        this.toolishRag = new ToolishRag(
            "sources",
            "The music criticism written by Robert Schumann",
            searchOperations)
            .withHint(TryHyDE.usingConversationContext());
        this.properties = properties;
    }

    @Action(canRerun = true, trigger = UserMessage.class)
    void respond(Conversation conversation, ActionContext context) {
        var assistantMessage = context.ai()
            .withLlm(properties.chatLlm())
            .withReference(toolishRag)
            .withTemplate("ragbot")
            .respondWithSystemPrompt(conversation, Map.of(
                "properties", properties,
                "voice", properties.voice(),
                "objective", properties.objective()
            ));
        context.sendMessage(conversation.addMessage(assistantMessage));
    }
}
```

### 3. Chatbot Creation

`ChatConfiguration.java` creates the chatbot:

```java
@Bean
Chatbot chatbot(AgentPlatform agentPlatform) {
    return AgentProcessChatbot.utilityFromPlatform(agentPlatform);
}
```

---

## Prompt Template System

### Main Template Structure

```
ragbot.jinja
├── {% include "elements/guardrails.jinja" %}
└── {% include "elements/personalization.jinja" %}
        ├── {% include "personas/{persona}.jinja" %}
        └── {% include "objectives/{objective}.jinja" %}
```

### Separating Voice from Objective

| Concern | Purpose | Example |
|---------|---------|---------|
| **Objective** | WHAT to accomplish | "Answer legal questions" |
| **Voice** | HOW to communicate | "In Shakespearean English" |

### Dynamic Template Loading

```jinja
{% set persona_template = "personas/" ~ properties.voice().persona() ~ ".jinja" %}
{% include persona_template %}

{% set objective_template = "objectives/" ~ properties.objective() ~ ".jinja" %}
{% include objective_template %}
```

---

## Configuration

### application.yml

```yaml
ragbot:
  chunker-config:
    max-chunk-size: 800
    overlap-size: 100

  chat-llm:
    model: gpt-4.1-mini
    temperature: 0.0

  voice:
    persona: clause        # personas/clause.jinja
    max-words: 30

  objective: legal         # objectives/legal.jinja

embabel:
  agent:
    shell:
      redirect-log-to-file: true
```

### RagbotProperties.java

```java
@ConfigurationProperties(prefix = "ragbot")
public record RagbotProperties(
    Voice voice,
    String objective,
    ChunkerConfig chunkerConfig,
    LlmOptions chatLlm
) {
    public record Voice(String persona, int maxWords) {}
}
```

---

## Shell Commands

| Command | Description |
|---------|-------------|
| `ingest [url]` | Ingest URL into RAG store |
| `ingest-directory <path>` | Ingest markdown/text files from directory |
| `zap` | Clear all documents from index |
| `chunks` | Display all stored chunks |
| `chat` | Start interactive chat session |
| `uichat [port]` | Launch web-based chat UI |
| `info` | Show Lucene store statistics |

---

## Key Patterns

### Pattern 1: ToolishRag Integration

RAG is exposed to the LLM as a callable tool:

```java
this.toolishRag = new ToolishRag(
    "sources",                              // Tool name
    "Description of content",               // Description
    searchOperations)                       // Lucene operations
    .withHint(TryHyDE.usingConversationContext());  // HyDE optimization
```

### Pattern 2: Template Bindings

Pass Java objects directly to Jinja templates:

```java
context.ai()
    .withTemplate("ragbot")
    .respondWithSystemPrompt(conversation, Map.of(
        "properties", properties,
        "voice", properties.voice(),
        "objective", properties.objective()
    ));
```

### Pattern 3: Trigger-Based Actions

Actions triggered by message types:

```java
@Action(
    canRerun = true,              // Can run multiple times
    trigger = UserMessage.class   // Triggered by user messages
)
void respond(Conversation conversation, ActionContext context) { ... }
```

---

## Creating Custom Personas

### Step 1: Create Persona Template

`src/main/resources/prompts/personas/film_critic.jinja`:

```jinja
Your name is Cinephile.
You are a passionate film critic with deep knowledge of cinema history.
You speak with enthusiasm about cinematography, direction, and storytelling.
```

### Step 2: Create Objective Template

`src/main/resources/prompts/objectives/discuss_films.jinja`:

```jinja
Answer questions about classic cinema and film history.
Always back up your points with direct quotes from the sources.
DO NOT RELY ON GENERAL KNOWLEDGE unless certain a better answer is not in sources.
```

### Step 3: Update ToolishRag Description

```java
this.toolishRag = new ToolishRag(
    "sources",
    "Film reviews and criticism: Classic cinema analysis",
    searchOperations);
```

### Step 4: Configure application.yml

```yaml
ragbot:
  voice:
    persona: film_critic
  objective: discuss_films
```

---

## Web UI (Javelit)

The `uichat` command launches a browser-based chat interface:

```java
@Bean
JavelitChatUI javelitChatUI(Chatbot chatbot) {
    return new JavelitChatUI(chatbot);
}
```

Access at `http://localhost:8888` by default.

---

## HyDE (Hypothetical Document Embeddings)

Ragbot uses HyDE to improve retrieval quality:

```java
.withHint(TryHyDE.usingConversationContext())
```

This generates a hypothetical answer before searching, improving semantic match quality.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No LLM output in chat | Set `redirect-log-to-file: false` in config |
| Poor RAG results | Run `info`, `chunks` to debug; adjust chunking |
| Complex HTML not parsing | Preprocess with docling before ingestion |
