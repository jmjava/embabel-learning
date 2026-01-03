# PR #1193: Add Cursor support for Agent Skills front matter formatting

**Repository:** embabel/embabel-agent
**Status:** MERGED
**Created:** 2025-12-21T14:24:57Z
**URL:** https://github.com/embabel/embabel-agent/pull/1193

## Description
## Summary

Adds `CursorFrontMatterFormatter` to format Agent Skills metadata using Cursor-friendly markdown, complementing the existing `ClaudeFrontMatterFormatter` which uses XML tags.

## Changes

- `CursorFrontMatterFormatter` - Formats skills as markdown with headers and bullet points
- `CursorFrontMatterFormatterTest` - Comprehensive test coverage

## Output Format

**Claude (XML):**
```xml
<available_skills>
  <skill>
    <name>my-skill</name>
    <description>A helpful skill</description>
  </skill>
</available_skills>
```

**Cursor (Markdown):**
```markdown
## Available Skills

- **my-skill**: A helpful skill
- **another-skill**: Description of this skill
```

## Usage

```kotlin
val skills = Skills(name = "my-skills", description = "...")
    .withFrontMatterFormatter(CursorFrontMatterFormatter)
    .withLocalSkills("/path/to/skills")
```

## Files Changed
- `embabel-agent-skills/src/main/kotlin/com/embabel/agent/skills/support/CursorFrontMatterFormatter.kt` (+65/-0)
- `embabel-agent-skills/src/test/kotlin/com/embabel/agent/skills/CursorFrontMatterFormatterTest.kt` (+172/-0)

## Code Changes
```diff
diff --git a/embabel-agent-skills/src/main/kotlin/com/embabel/agent/skills/support/CursorFrontMatterFormatter.kt b/embabel-agent-skills/src/main/kotlin/com/embabel/agent/skills/support/CursorFrontMatterFormatter.kt
new file mode 100644
index 000000000..6fe8a913e
--- /dev/null
+++ b/embabel-agent-skills/src/main/kotlin/com/embabel/agent/skills/support/CursorFrontMatterFormatter.kt
@@ -0,0 +1,65 @@
+/*
+ * Copyright 2024-2025 Embabel Software, Inc.
+ *
+ * Licensed under the Apache License, Version 2.0 (the "License");
+ * you may not use this file except in compliance with the License.
+ * You may obtain a copy of the License at
+ *
+ * http://www.apache.org/licenses/LICENSE-2.0
+ *
+ * Unless required by applicable law or agreed to in writing, software
+ * distributed under the License is distributed on an "AS IS" BASIS,
+ * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
+ * See the License for the specific language governing permissions and
+ * limitations under the License.
+ */
+package com.embabel.agent.skills.support
+
+import com.embabel.agent.skills.SkillFrontMatterFormatter
+import com.embabel.agent.skills.spec.SkillMetadata
+
+/**
+ * Formats skill metadata in Cursor's preferred markdown format.
+ *
+ * Output format:
+ * ```markdown
+ * ## Available Skills
+ *
+ * - **skill-name**: What it does
+ * - **another-skill**: Description of this skill
+ * ```
+ *
+ * @see <a href="https://agentskills.io/integrate-skills">Agent Skills Integration</a>
+ */
+object CursorFrontMatterFormatter : SkillFrontMatterFormatter {
+
+    override fun format(skills: List<SkillMetadata>): String {
+        if (skills.isEmpty()) {
+            return "## Available Skills\n\nNo skills available."
+        }
+
+        val skillsList = skills.joinToString("\n") { skill ->
+            formatSkill(skill)
+        }
+
+        return """
+            |## Available Skills
+            |
+            |$skillsList
+        """.trimMargin()
+    }
+
+    override fun formatSkill(skill: SkillMetadata): String {
+        return "- **${escapeMarkdown(skill.name)}**: ${escapeMarkdown(skill.description)}"
+    }
+
+    private fun escapeMarkdown(text: String): String {
+        return text
+            .replace("\\", "\\\\")
+            .replace("*", "\\*")
+            .replace("_", "\\_")
+            .replace("`", "\\`")
+            .replace("[", "\\[")
+            .replace("]", "\\]")
+    }
+}
diff --git a/embabel-agent-skills/src/test/kotlin/com/embabel/agent/skills/CursorFrontMatterFormatterTest.kt b/embabel-agent-skills/src/test/kotlin/com/embabel/agent/skills/CursorFrontMatterFormatterTest.kt
new file mode 100644
index 000000000..98465372d
--- /dev/null
+++ b/embabel-agent-skills/src/test/kotlin/com/embabel/agent/skills/CursorFrontMatterFormatterTest.kt
@@ -0,0 +1,172 @@
+/*
+ * Copyright 2024-2025 Embabel Software, Inc.
+ *
+ * Licensed under the Apache License, Version 2.0 (the "License");
+ * you may not use this file except in compliance with the License.
+ * You may obtain a copy of the License at
+ *
+ * http://www.apache.org/licenses/LICENSE-2.0
+ *
+ * Unless required by applicable law or agreed to in writing, software
+ * distributed under the License is distributed on an "AS IS" BASIS,
+ * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
+ * See the License for the specific language governing permissions and
+ * limitations under the License.
+ */
+package com.embabel.agent.skills
+
+import com.embabel.agent.skills.spec.SkillDefinition
+import com.embabel.agent.skills.support.CursorFrontMatterFormatter
+import org.junit.jupiter.api.Assertions.*
+import org.junit.jupiter.api.Test
+
+class CursorFrontMatterFormatterTest {
+
+    private val formatter = CursorFrontMatterFormatter
+
+    @Test
+    fun `format empty list returns no skills available message`() {
+        val result = formatter.format(emptyList())
+
+        assertEquals("## Available Skills\n\nNo skills available.", result)
+    }
+
+    @Test
+    fun `format single skill returns correct markdown structure`() {
+        val skill = SkillDefinition(
+            name = "my-skill",
+            description = "A helpful skill for testing",
+        )
+
+        val result = formatter.format(listOf(skill))
+
+        val expected = """
+            |## Available Skills
+            |
+            |- **my-skill**: A helpful skill for testing
+        """.trimMargin()
+
+        assertEquals(expected, result)
+    }
+
+    @Test
+    fun `format multiple skills returns all skills in markdown`() {
+        val skills = listOf(
+            SkillDefinition(name = "skill-one", description = "First skill"),
+            SkillDefinition(name = "skill-two", description = "Second skill"),
+            SkillDefinition(name = "skill-three", description = "Third skill"),
+        )
+
+        val result = formatter.format(skills)
+
+        assertTrue(result.startsWith("## Available Skills"))
+        assertTrue(result.contains("- **skill-one**: First skill"))
+        assertTrue(result.contains("- **skill-two**: Second skill"))
+        assertTrue(result.contains("- **skill-three**: Third skill"))
+    }
+
+    @Test
+    fun `formatSkill returns correct markdown for single skill`() {
+        val skill = SkillDefinition(
+            name = "test-skill",
+            description = "Test description",
+        )
+
+        val result = formatter.formatSkill(skill)
+
+        assertEquals("- **test-skill**: Test description", result)
+    }
+
+    @Test
+    fun `format escapes markdown special characters in name`() {
+        val skill = SkillDefinition(
+            name = "skill*with_special`chars",
+            description = "Normal description",
+        )
+
+        val result = formatter.formatSkill(skill)
+
+        assertTrue(result.contains("skill\\*with\\_special\\`chars"))
+        assertFalse(result.contains("skill*with"))
+    }
+
+    @Test
+    fun `format escapes markdown special characters in description`() {
+        val skill = SkillDefinition(
+            name = "my-skill",
+            description = "Use **bold** and _italic_ with `code` and [links]",
+        )
+
+        val result = formatter.formatSkill(skill)
+
+        assertTrue(result.contains("\\*\\*bold\\*\\*"))
+        assertTrue(result.contains("\\_italic\\_"))
+        assertTrue(result.contains("\\`code\\`"))
+        assertTrue(result.contains("\\[links\\]"))
+        assertFalse(result.contains("**bold**"))
+    }
+
+    @Test
+    fun `format escapes backslashes`() {
+        val skill = SkillDefinition(
+            name = "my-skill",
+            description = "Path like C:\\Users\\name",
+        )
+
+        val result = formatter.formatSkill(skill)
+
+        assertTrue(result.contains("C:\\\\Users\\\\name"))
+    }
+
+    @Test
+    fun `format does not include optional fields`() {
+        val skill = SkillDefinition(
+            name = "full-skill",
+            description = "Has all optional fields",
+            license = "Apache-2.0",
+            compatibility = "Requires Python 3.9+",
+            metadata = mapOf("author" to "test"),
+            allowedTools = "Bash(git:*) Read",
+            instructions = "# Full Instructions\n\nLots of detail here...",
+        )
+
+        val result = formatter.formatSkill(skill)
+
+        // Should only contain name and description, not other fields
+        assertTrue(result.contains("**full-skill**"))
+        assertTrue(result.contains("Has all optional fields"))
+        assertFalse(result.contains("license"))
+        assertFalse(result.contains("compatibility"))
+        assertFalse(result.contains("metadata"))
+        assertFalse(result.contains("allowed"))
+        assertFalse(result.contains("instructions"))
+        assertFalse(result.contains("Apache"))
+        assertFalse(result.contains("Python"))
+    }
+
+    @Test
+    fun `format produces valid markdown structure`() {
+        val skills = listOf(
+            SkillDefinition(name = "skill-a", description = "Description A"),
+            SkillDefinition(name = "skill-b", description = "Description B"),
+        )
+
+        val result = formatter.format(skills)
+
+        // Should have header and two bullet points
+        assertTrue(result.startsWith("## Available Skills"))
+        assertEquals(2, result.split("\n- **").size - 1)
+    }
+
+    @Test
+    fun `format handles multiline description`() {
+        val skill = SkillDefinition(
+            name = "multiline-skill",
+            description = "First line\nSecond line\nThird line",
+        )
+
+        val result = formatter.formatSkill(skill)
+
+        assertTrue(result.contains("First line\nSecond line\nThird line"))
+    }
+}
```

## Reviews & Comments
