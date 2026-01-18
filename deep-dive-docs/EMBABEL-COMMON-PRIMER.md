# Embabel Common - Architecture Primer

## Overview

**Embabel Common** is a foundational library providing core components, utilities, and shared dependencies used across all Embabel projects. It establishes common patterns, interfaces, and utilities that enable consistent development across the Embabel ecosystem.

## Key Purposes

1. **Dependency Management**: BOM for consistent library versions
2. **Core Abstractions**: Common interfaces like `Identified`, `Versioned`
3. **AI Utilities**: Model abstraction, LLM options, prompt templates
4. **Text Processing**: Jinja template rendering
5. **Test Support**: Testing utilities for AI and Neo4j

---

## Module Structure

```
embabel-common/
├── embabel-common-dependencies/    # BOM (Bill of Materials)
├── embabel-common-core/            # Core interfaces & types
├── embabel-common-util/            # Utility classes
├── embabel-common-ai/              # AI/LLM abstractions
├── embabel-common-textio/          # Template rendering
└── embabel-common-test/            # Test utilities
    ├── embabel-common-test-ai/     # AI testing support
    ├── embabel-common-test-neo/    # Neo4j testing support
    └── embabel-common-test-dependencies/
```

---

## Module Details

### embabel-common-dependencies

**Purpose**: Maven BOM for consistent dependency versions across all Embabel projects.

**Usage**:

```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>com.embabel.common</groupId>
            <artifactId>embabel-common-dependencies</artifactId>
            <version>1.0.0-SNAPSHOT</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

---

### embabel-common-core

**Purpose**: Core interfaces and types used throughout the Embabel ecosystem.

#### Package: `com.embabel.common.core`

| File | Description |
|------|-------------|
| `Identified.kt` | Interface for objects with optional persistent IDs |
| `StableIdentified.kt` | Identified with stable (immutable) ID |
| `Sourced.kt` | Interface for objects with source tracking |
| `Versioned.kt` | Interface for versioned objects |
| `VersionSelection.kt` | Version selection strategies |
| `NameGenerator.kt` | Name generation utilities |

#### Key Interfaces

**Identified** - Objects with optional persistent IDs:

```kotlin
interface Identified {
    val id: String?
        get() = null
    fun persistent(): Boolean
}

interface Persistent : Identified {
    override fun persistent(): Boolean = true
}

interface Ephemeral : Identified {
    override fun persistent(): Boolean = false
}
```

**NameGenerator** - Functional interface for name generation:

```kotlin
fun interface NameGenerator {
    fun generateName(): String
}

val MobyNameGenerator = NameGenerator {
    MobyNamesGenerator.getRandomName()  // Docker-style names
}

val RandomNameGenerator = NameGenerator {
    UUID.randomUUID().toString()
}
```

#### Package: `com.embabel.common.core.types`

| Type | Description |
|------|-------------|
| `ZeroToOne` | Type alias for values between 0.0 and 1.0 |
| `Named` | Interface for named objects |
| `HasInfoString` | Objects with debug info strings |
| `Timestamped` | Objects with timestamp |
| `Timed` | Objects with duration |
| `Paginated` | Pagination support |
| `SearchResults` | Search result containers |
| `SimilarityCutoff` | Similarity threshold config |

#### Package: `com.embabel.common.core.config`

Cross-JAR property loading utilities:

| File | Description |
|------|-------------|
| `CrossJarPropertiesUtil.kt` | Load properties from multiple JARs |
| `CommonPlatformPropertiesLoader.kt` | Platform-wide property loading |
| `PropertyCoreModels.kt` | Core property models |
| `PropertyDiscoveryModels.kt` | Property discovery models |

#### Package: `com.embabel.common.core.streaming`

Server-Sent Events (SSE) streaming support:

| File | Description |
|------|-------------|
| `StreamingEvent.kt` | SSE event model |
| `StreamingConfigProperties.kt` | Streaming configuration |

---

### embabel-common-util

**Purpose**: General-purpose utilities used across services.

#### Package: `com.embabel.common.util`

| File | Description |
|------|-------------|
| `AnsiBuilder.kt` | ANSI color/style builder for terminal output |
| `formatUtils.kt` | String formatting utilities |
| `NameUtils.kt` | Name manipulation utilities |
| `NamingUtils.kt` | Naming convention helpers |
| `StringTrimmingUtils.kt` | String trimming/truncation |
| `GetLogger.kt` | Logging helper extension |
| `reflectionUtils.kt` | Reflection utilities |
| `time.kt` | Time/duration utilities |
| `DoubleUtils.kt` | Double precision utilities |
| `Mac.kt` | macOS-specific utilities |
| `WinUtils.kt` | Windows-specific utilities |
| `MessageGenerator.kt` | Message generation interface |
| `RandomFromFileMessageGenerator.kt` | Load random messages from file |
| `DummyInstanceCreator.kt` | Create dummy instances for testing |
| `VisualizableTask.kt` | Task visualization interface |
| `ExcludeFromJacocoGeneratedReport.kt` | JaCoCo exclusion annotation |

---

### embabel-common-ai

**Purpose**: AI/LLM abstractions and utilities.

#### Package: `com.embabel.common.ai.model`

| File | Description |
|------|-------------|
| `Llm.kt` | LLM wrapper around Spring AI ChatModel |
| `LlmOptions.kt` | Configuration options for LLM calls |
| `LlmMetadata.kt` | LLM metadata interface |
| `ModelProvider.kt` | Interface for providing AI models |
| `ConfigurableModelProvider.kt` | Configurable model provider |
| `EmbeddingService.kt` | Embedding service interface |
| `AiModel.kt` | Base AI model interface |
| `OptionsConverter.kt` | Convert LlmOptions to provider-specific options |
| `PricingModel.kt` | Token pricing information |

**Llm** - Wraps Spring AI ChatModel:

```kotlin
data class Llm(
    override val name: String,
    override val provider: String,
    override val model: ChatModel,
    val optionsConverter: OptionsConverter<*> = DefaultOptionsConverter,
    override val knowledgeCutoffDate: LocalDate? = null,
    override val promptContributors: List<PromptContributor> = ...,
    override val pricingModel: PricingModel? = null,
) : AiModel<ChatModel>, LlmMetadata, PromptContributorConsumer
```

**LlmOptions** - Configuration for LLM calls:

```kotlin
data class LlmOptions(
    val model: String? = null,
    val temperature: Double? = null,
    val maxTokens: Int? = null,
    val thinking: Boolean = false,
    // ... other options
)
```

#### Package: `com.embabel.common.ai.prompt`

| File | Description |
|------|-------------|
| `PromptContributor.kt` | Interface for contributing to prompts |
| `PromptContributorConsumer.kt` | Consumes prompt contributors |
| `CurrentDate.kt` | Adds current date to prompts |
| `KnowledgeCutoffDate.kt` | Adds knowledge cutoff to prompts |

**PromptContributor** - Add context to prompts:

```kotlin
interface PromptContributor {
    fun contribution(): String
}
```

#### Package: `com.embabel.common.ai.converters`

| File | Description |
|------|-------------|
| `JacksonOutputConverter.kt` | Convert LLM output using Jackson |
| `FilteringJacksonOutputConverter.kt` | Filtered JSON conversion |
| `streaming/` | Streaming response converters |

#### Package: `com.embabel.common.ai.autoconfig`

| File | Description |
|------|-------------|
| `AbstractModelLoader.kt` | Base class for model loaders |
| `LlmAutoConfigMetadata.kt` | Auto-configuration metadata |
| `ProviderInitialization.kt` | Provider initialization utilities |

---

### embabel-common-textio

**Purpose**: Template rendering using Jinja.

#### Package: `com.embabel.common.textio.template`

| File | Description |
|------|-------------|
| `TemplateRenderer.kt` | Template rendering interface |
| `TemplateProvider.kt` | Template loading interface |
| `JinjavaTemplateRenderer.kt` | Jinja implementation using HubSpot Jinjava |
| `RegistryTemplateProvider.kt` | Registry-based template provider |

**JinjavaTemplateRenderer** - Render Jinja templates:

```kotlin
class JinjavaTemplateRenderer(
    private val jinja: JinjaProperties = JinjaProperties(
        prefix = "classpath:/prompts/",
        suffix = ".jinja",
        failOnUnknownTokens = false
    ),
    private val resourceLoader: ResourceLoader = DefaultResourceLoader()
) : TemplateRenderer {

    override fun renderLoadedTemplate(templateName: String, model: Map<String, Any>): String {
        val template = load(templateName)
        return renderLiteralTemplate(template, model)
    }

    override fun renderLiteralTemplate(template: String, model: Map<String, Any>): String {
        return Jinjava(jcConfig).run {
            registerFilter(EscFilter())
            resourceLocator = SpringResourceLocator()
            render(template, model)
        }
    }
}
```

**JinjaProperties** - Configuration:

```kotlin
data class JinjaProperties(
    val prefix: String,           // Template location prefix
    val suffix: String = ".jinja", // Template file suffix
    val failOnUnknownTokens: Boolean = false
)
```

---

### embabel-common-test

**Purpose**: Testing utilities for AI and database components.

#### embabel-common-test-ai

| File | Description |
|------|-------------|
| Test utilities for mocking AI operations |

#### embabel-common-test-neo

| File | Description |
|------|-------------|
| Neo4j test container utilities |

---

## Usage in Projects

### Adding Dependencies

```xml
<dependencies>
    <dependency>
        <groupId>com.embabel.common</groupId>
        <artifactId>embabel-common-core</artifactId>
    </dependency>
    <dependency>
        <groupId>com.embabel.common</groupId>
        <artifactId>embabel-common-util</artifactId>
    </dependency>
    <dependency>
        <groupId>com.embabel.common</groupId>
        <artifactId>embabel-common-ai</artifactId>
    </dependency>
    <dependency>
        <groupId>com.embabel.common</groupId>
        <artifactId>embabel-common-textio</artifactId>
    </dependency>
</dependencies>
```

### Repository

```xml
<repository>
    <id>embabel-snapshots</id>
    <url>https://repo.embabel.com/artifactory/libs-snapshot</url>
    <snapshots>
        <enabled>true</enabled>
    </snapshots>
</repository>
```

---

## Key Patterns

### Pattern 1: Identity Abstraction

```kotlin
// Transient object (not yet persisted)
class TransientUser : Identified {
    override val id: String? = null
    override fun persistent() = false
}

// Persistent object
class PersistedUser(override val id: String) : Persistent
```

### Pattern 2: Template Rendering

```kotlin
val renderer = JinjavaTemplateRenderer()

// Load and render template
val output = renderer.renderLoadedTemplate("my-template", mapOf(
    "user" to user,
    "context" to context
))

// Render inline template
val inline = renderer.renderLiteralTemplate(
    "Hello {{ name }}!",
    mapOf("name" to "World")
)
```

### Pattern 3: LLM Configuration

```kotlin
// Basic options
val options = LlmOptions(
    model = "gpt-4",
    temperature = 0.7
)

// With default LLM
val defaultOptions = LlmOptions.withDefaultLlm()
    .withTemperature(0.8)

// First available from list
val fallback = LlmOptions.withFirstAvailableLlmOf(
    AnthropicModels.CLAUDE_37_SONNET,
    OpenAiModels.GPT_41_MINI
)
```

### Pattern 4: Prompt Contributors

```kotlin
// LLM with knowledge cutoff contributor
val llm = Llm(
    name = "gpt-4",
    provider = "openai",
    model = chatModel,
    knowledgeCutoffDate = LocalDate.of(2024, 4, 1)
)
// Automatically adds "Knowledge cutoff: April 2024" to prompts
```

---

## Cross-JAR Property Loading

Load properties from multiple JARs:

```kotlin
// embabel-application.properties and embabel-platform.properties
// are loaded from all JARs on classpath

val properties = CrossJarPropertiesUtil.loadAllProperties(
    "embabel-application.properties"
)
```

This enables modular configuration where each module contributes its own default properties.
