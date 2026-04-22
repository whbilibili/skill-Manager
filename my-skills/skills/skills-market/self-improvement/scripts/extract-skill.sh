#!/bin/bash
# Skill Extraction Helper (CatPaw Desk)
# Creates a new skill from a learning entry.
# Usage: ./extract-skill.sh <skill-name> [--dry-run]

set -e

# Default to project-level CatPaw skill path
SKILLS_DIR="./.catpaw/skills"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
  cat << EOF
Usage: $(basename "$0") <skill-name> [options]

Create a new CatPaw Desk skill scaffold from a learning entry.

Arguments:
  skill-name     Name of the skill (lowercase, hyphens)

Options:
  --dry-run      Show what would be created without creating files
  --output-dir   Relative output directory (default: ./.catpaw/skills)
  -h, --help     Show this help message

Examples:
  $(basename "$0") reliable-mcp-calls
  $(basename "$0") release-checklist --dry-run
  $(basename "$0") api-patterns --output-dir ./.catpaw/skills/custom

The skill will be created in: \$SKILLS_DIR/<skill-name>/
EOF
}

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

SKILL_NAME=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --output-dir)
      if [ -z "${2:-}" ] || [[ "${2:-}" == -* ]]; then
        log_error "--output-dir requires a relative path argument"
        usage
        exit 1
      fi
      SKILLS_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      log_error "Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      if [ -z "$SKILL_NAME" ]; then
        SKILL_NAME="$1"
      else
        log_error "Unexpected argument: $1"
        usage
        exit 1
      fi
      shift
      ;;
  esac
done

if [ -z "$SKILL_NAME" ]; then
  log_error "Skill name is required"
  usage
  exit 1
fi

if ! [[ "$SKILL_NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  log_error "Invalid skill name format. Use lowercase letters, numbers, and hyphens only."
  exit 1
fi

if [[ "$SKILLS_DIR" = /* ]]; then
  log_error "Output directory must be a relative path under current workspace."
  exit 1
fi

if [[ "$SKILLS_DIR" =~ (^|/)\.\.(/|$) ]]; then
  log_error "Output directory cannot include '..' path segments."
  exit 1
fi

SKILLS_DIR="${SKILLS_DIR#./}"
SKILLS_DIR="./$SKILLS_DIR"
SKILL_PATH="$SKILLS_DIR/$SKILL_NAME"

if [ -d "$SKILL_PATH" ] && [ "$DRY_RUN" = false ]; then
  log_error "Skill already exists: $SKILL_PATH"
  exit 1
fi

if [ "$DRY_RUN" = true ]; then
  log_info "Dry run - would create:"
  echo "  $SKILL_PATH/"
  echo "  $SKILL_PATH/SKILL.md"
  echo ""
  echo "---"
  cat << TEMPLATE
name: $SKILL_NAME
description: "[TODO: concise capability + trigger description]"
---

# $(echo "$SKILL_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')

[TODO: one-paragraph purpose]

## Quick Reference

| Situation | Action |
|-----------|--------|
| [Trigger] | [Action] |

## Usage

[TODO: clear steps]

## Verification

[TODO: how to verify output]

## Source

- Learning ID: [TODO]
- Original File: .learnings/LEARNINGS.md
TEMPLATE
  echo "---"
  exit 0
fi

log_info "Creating skill: $SKILL_NAME"
mkdir -p "$SKILL_PATH"

cat > "$SKILL_PATH/SKILL.md" << TEMPLATE
---
name: $SKILL_NAME
description: "[TODO: concise capability + trigger description]"
---

# $(echo "$SKILL_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')

[TODO: one-paragraph purpose]

## Quick Reference

| Situation | Action |
|-----------|--------|
| [Trigger] | [Action] |

## Usage

[TODO: clear steps]

## Verification

[TODO: how to verify output]

## Source

- Learning ID: [TODO]
- Original File: .learnings/LEARNINGS.md
TEMPLATE

log_info "Created: $SKILL_PATH/SKILL.md"
echo ""
log_info "Next steps:"
echo "  1. Edit $SKILL_PATH/SKILL.md"
echo "  2. Replace TODO sections with proven learning content"
echo "  3. Add references/ or scripts/ if needed"
echo "  4. Update source learning status to promoted_to_skill"
echo "  5. Set Skill-Path to .catpaw/skills/$SKILL_NAME"
