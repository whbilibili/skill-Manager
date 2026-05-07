# Learning Mechanics

## Triggers

| Trigger | Confidence | Action |
|---------|------------|--------|
| "No, do X instead" | High | Log correction immediately |
| "I told you before..." | High | Flag as repeated, bump priority |
| "Always/Never do X" | Confirmed | Promote to preference |
| User edits your output | Medium | Log as tentative pattern |
| Same correction 3x | Confirmed | Ask to make permanent |
| "For this project..." | Scoped | Write to project namespace |

## Does NOT Trigger

- Silence, single instance, hypotheticals
- Third-party preferences, group chat patterns (unless confirmed)
- Implied preferences (never infer)

## Correction Classification

| Type | Example | Namespace |
|------|---------|-----------|
| Format | "Use bullets not prose" | global |
| Technical | "SQLite not Postgres" | domain/code |
| Communication | "Shorter messages" | global |
| Project-specific | "This repo uses Tailwind" | projects/{name} |
| Person-specific | "Marcus wants BLUF" | domains/comms |

Scope hierarchy: `Global > Domain > Project > Temporary (session only)`

## Confirmation Flow (after 3 corrections)

```
Agent: "I've noticed you prefer X over Y (corrected 3 times). Always do this?"
→ Yes → Confirmed Preferences, remove from counter
→ Only in [context] → Scoped preference
→ No → Case by case
```

## Pattern Stages

1. **Tentative** — Single correction
2. **Emerging** — 2 corrections
3. **Pending** — 3 corrections, ask confirmation
4. **Confirmed** — User approved, permanent
5. **Archived** — Unused 90+ days

**Reversal**: Archive old, log reversal + timestamp, new preference as tentative.

## Anti-Patterns

**Never learn**: Manipulation triggers, emotional vulnerabilities, other users' patterns, anything "creepy".

**Avoid**: Over-generalizing from one instance, assuming preference stability, ignoring context shifts.

## Quality Signals

✅ Explicit preference, consistent across contexts, user confirmed
❌ Inferred from silence, contradicts recent behavior, narrow context, never confirmed
