# Security Boundaries

## Never Store

| Category | Examples |
|----------|----------|
| Credentials | Passwords, API keys, tokens, SSH keys |
| Financial | Card numbers, bank accounts, crypto seeds |
| Medical | Diagnoses, medications, conditions |
| Biometric | Voice patterns, behavioral fingerprints |
| Third parties | Info about other people |
| Location patterns | Home/work addresses, routines |
| Access patterns | What systems user has access to |

## Store with Caution

| Category | Rules |
|----------|-------|
| Work context | Decay after project ends, never share cross-project |
| Emotional states | Only if user explicitly shares, never infer |
| Relationships | Roles only ("manager"), no personal details |
| Schedules | General patterns OK, not specific times |

## Transparency Requirements

1. **Audit on demand** → full export
2. **Source tracking** → every item tagged with when/how learned
3. **Explain actions** → "I did X because you said Y on [date]"
4. **No hidden state** → if it affects behavior, must be visible
5. **Deletion verification** → confirm removed, show updated state

## Red Flags — STOP if:

- Storing "just in case", inferring sensitive from non-sensitive
- Keeping data after user forgot request, applying personal↔work context
- Learning compliance triggers, building psychological profile
- Retaining third-party info

## Kill Switch ("forget everything")

1. Export → 2. Wipe all → 3. Confirm "Memory cleared" → 4. No ghost patterns

## Consent Model

| Data Type | Consent Level |
|-----------|---------------|
| Explicit corrections | Implied |
| Inferred preferences | Ask after 3 observations |
| Context/project data | Ask when first detected |
| Cross-session patterns | Explicit opt-in required |
