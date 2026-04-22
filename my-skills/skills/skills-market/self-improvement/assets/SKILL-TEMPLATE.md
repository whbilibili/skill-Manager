# Skill Template（CatPaw Desk）

Template for creating skills extracted from learnings. Copy and customize.

---

## SKILL.md Template

```markdown
---
name: skill-name-here
description: "Concise description of what this skill does and when to use it."
---

# Skill Name

Brief introduction explaining what this skill solves.

## Quick Reference

| Situation | Action |
|-----------|--------|
| [Trigger 1] | [Action 1] |
| [Trigger 2] | [Action 2] |

## Usage

Describe the recommended workflow in concise steps.

## Verification

Describe how to verify the expected output/result.

## Source

Extracted from learning entry.
- Learning ID: LRN-YYYYMMDD-XXX
- Extraction Date: YYYY-MM-DD
```

---

## Minimal Template

```markdown
---
name: skill-name-here
description: "What this skill does and when to use it."
---

# Skill Name

One-sentence problem statement.

## Solution

Direct solution with commands/code.

## Source

- Learning ID: LRN-YYYYMMDD-XXX
```

---

## Template with Scripts

```markdown
---
name: skill-name-here
description: "What this skill does and when to use it."
---

# Skill Name

Introduction.

## Quick Reference

| Command | Purpose |
|---------|---------|
| `./scripts/helper.sh` | Main action |
| `./scripts/validate.sh` | Validation |

## Usage

### Automated

```bash
./scripts/helper.sh [args]
```

### Manual

1. Step one
2. Step two

## Scripts

| Script | Description |
|--------|-------------|
| `scripts/helper.sh` | Main utility |
| `scripts/validate.sh` | Validation checker |

## Source

- Learning ID: LRN-YYYYMMDD-XXX
```

---

## Naming Conventions

- Skill name uses lowercase and hyphens, for example `reliable-mcp-calls`.
- Description should mention both capability and trigger.
- Required file is `SKILL.md`; optional folders include `scripts/`, `references/`, and `assets/`.

---

## Path Conventions（CatPaw Desk）

- Project skill: `<workspace>/.catpaw/skills/<skill-name>/SKILL.md`
- Global skill: `~/.catpaw/skills/<skill-name>/SKILL.md`

---

## Extraction Checklist

- Learning is verified or repeatedly observed
- Solution is reusable across tasks
- Name and description follow conventions
- Verification step is present
- Source learning ID is recorded
- Original learning updated with promotion status
