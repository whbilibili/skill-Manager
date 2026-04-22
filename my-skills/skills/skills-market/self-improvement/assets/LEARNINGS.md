# Learnings

Corrections, insights, and knowledge gaps captured during development.

**Categories**: correction | insight | knowledge_gap | best_practice
**Areas**: frontend | backend | infra | tests | docs | config | tooling
**Statuses**: pending | in_progress | resolved | wont_fix | promoted | promoted_to_skill | promoted_to_memory

## Status Definitions

| Status | Meaning |
|--------|---------|
| `pending` | Not yet addressed |
| `in_progress` | Actively being worked on |
| `resolved` | Issue fixed or knowledge integrated |
| `wont_fix` | Decided not to address (reason in Resolution) |
| `promoted` | Elevated into reusable conventions or guidance |
| `promoted_to_skill` | Extracted as a reusable skill |
| `promoted_to_memory` | Written into CatPaw memory (`longterm` or `daily`) |

## Skill Extraction Fields

When a learning is promoted to a skill, add:

```markdown
**Status**: promoted_to_skill
**Skill-Path**: .catpaw/skills/skill-name
```

When a learning is promoted to memory, add:

```markdown
**Status**: promoted_to_memory
**Memory-Type**: longterm | daily
```

Example:

```markdown
## [LRN-20260302-001] best_practice

**Logged**: 2026-03-02T10:00:00Z
**Priority**: high
**Status**: promoted_to_skill
**Skill-Path**: .catpaw/skills/reliable-mcp-calls
**Area**: tooling

### Summary
Standardize MCP call preparation by reading schema first
...
```

---
