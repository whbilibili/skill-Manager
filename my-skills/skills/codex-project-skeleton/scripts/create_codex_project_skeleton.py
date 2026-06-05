#!/usr/bin/env python3
"""Create a Codex-friendly project scaffold."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


PROFILES = {"full", "code", "knowledge", "agent"}


@dataclass(frozen=True)
class FileSpec:
    path: str
    content: str
    profiles: frozenset[str] = frozenset(PROFILES)
    executable: bool = False


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-zA-Z0-9]+", "-", value.strip().lower()).strip("-")
    return slug or "codex-project"


def render(template: str, project_name: str, project_slug: str, role: str) -> str:
    return (
        template.replace("{{PROJECT_NAME}}", project_name)
        .replace("{{PROJECT_SLUG}}", project_slug)
        .replace("{{ROLE}}", role)
    )


def files() -> list[FileSpec]:
    all_profiles = frozenset(PROFILES)
    code_agent = frozenset({"full", "code", "agent"})
    knowledge_agent = frozenset({"full", "knowledge", "agent"})
    code_only = frozenset({"full", "code"})
    knowledge_only = frozenset({"full", "knowledge"})
    agent_only = frozenset({"full", "agent"})

    return [
        FileSpec(
            "AGENTS.md",
            """# {{PROJECT_NAME}} Agent Instructions

## Mission

This repository is a Codex-friendly workspace for: {{ROLE}}.

## Working Agreements

- Read `README.md`, `docs/INDEX.md`, and `.codex/memory/project.md` before substantial changes.
- Prefer small, reviewable edits with explicit verification.
- Preserve user changes. Do not revert unrelated work.
- Keep root instructions concise; put durable detail in `.codex/memory`, `docs`, `prompts`, and `templates`.
- Update `CHANGELOG.md` for user-visible changes.

## Project Map

- `docs/`: architecture, operations, onboarding, and decisions.
- `.codex/memory/`: durable project memory and continuity notes.
- `.codex/agents/`: optional custom subagent definitions.
- `.codex/hooks/`: hook script examples; inactive until wired from `.codex/hooks.json`.
- `.codex/rules/`: command policy examples.
- `.agents/skills/project-context/`: repo-scoped project skill.
- `tasks/`: active work, backlog, completion notes, and task templates.
- `prompts/`: reusable prompts for planning, review, research, and handoff.
- `templates/`: reusable project artifacts.
- `scripts/`: deterministic local commands.

## Verification

- Run `scripts/check.sh` before delivery after implementation work.
- If a check is not implemented yet, explain that gap and update `scripts/check.sh` when the command becomes known.
""",
        ),
        FileSpec(
            "README.md",
            """# {{PROJECT_NAME}}

{{PROJECT_NAME}} is a Codex-friendly project scaffold for {{ROLE}}.

## Start Here

1. Read `AGENTS.md` for agent-facing working agreements.
2. Read `docs/INDEX.md` for the project knowledge map.
3. Capture durable facts in `.codex/memory/project.md`.
4. Track work in `tasks/active.md` and `tasks/backlog.md`.

## Common Commands

```bash
scripts/bootstrap.sh
scripts/check.sh
```

## Structure

- `docs/` contains human-readable project knowledge.
- `.codex/` contains Codex configuration, memory, hooks examples, rules examples, and custom agents.
- `.agents/skills/` contains repo-scoped skills.
- `prompts/`, `templates/`, and `tasks/` keep repeatable work explicit.
""",
        ),
        FileSpec(
            "CHANGELOG.md",
            """# Changelog

All notable changes to this project should be documented here.

## Unreleased

- Initialized Codex-friendly project scaffold.
""",
        ),
        FileSpec(
            "LICENSE",
            """Copyright (c) {{PROJECT_NAME}}

All rights reserved unless a project owner replaces this placeholder with an explicit license.
""",
        ),
        FileSpec(
            ".gitignore",
            """.DS_Store
.env
.env.*
!.env.example
node_modules/
dist/
build/
coverage/
.pytest_cache/
.ruff_cache/
.mypy_cache/
__pycache__/
*.py[cod]
.venv/
venv/
.idea/
.vscode/
*.log
tmp/
temp/
""",
        ),
        FileSpec(
            ".gitattributes",
            """* text=auto
*.sh text eol=lf
*.py text eol=lf
*.md text eol=lf
""",
        ),
        FileSpec(
            ".editorconfig",
            """root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
indent_style = space
indent_size = 2

[*.py]
indent_size = 4
""",
        ),
        FileSpec(
            ".env.example",
            """# Copy to .env for local-only settings.
# Never commit secrets.
PROJECT_NAME={{PROJECT_SLUG}}
""",
        ),
        FileSpec(
            "docs/INDEX.md",
            """# Documentation Index

- `architecture.md`: system shape, constraints, and boundaries.
- `context-engineering.md`: how project context is stored and updated.
- `onboarding.md`: first-run setup for humans and agents.
- `operations.md`: routine commands, release steps, and troubleshooting.
- `decisions/`: architecture decision records.
""",
            knowledge_agent,
        ),
        FileSpec(
            "docs/architecture.md",
            """# Architecture

## Purpose

{{PROJECT_NAME}} supports {{ROLE}}.

## Boundaries

- In scope:
- Out of scope:

## Components

Describe the main project components here.

## Constraints

- Keep agent instructions concise and file-local.
- Prefer deterministic scripts for repeatable actions.
""",
            knowledge_agent,
        ),
        FileSpec(
            "docs/context-engineering.md",
            """# Context Engineering

## Context Layers

- `AGENTS.md`: short, automatically loaded working contract.
- `.codex/memory/project.md`: durable project facts.
- `.codex/memory/decisions.md`: important decisions and their rationale.
- `.codex/memory/lessons.md`: lessons learned from mistakes or recurring friction.
- `docs/`: stable human-facing knowledge.
- `prompts/`: repeatable task prompts.
- `templates/`: reusable output structures.

## Update Policy

- Update memory when a fact should survive future sessions.
- Update docs when a human needs durable explanation.
- Update prompts or templates when a workflow repeats.
""",
            knowledge_agent,
        ),
        FileSpec(
            "docs/onboarding.md",
            """# Onboarding

## First Run

```bash
scripts/bootstrap.sh
scripts/check.sh
```

## For Codex

1. Read `AGENTS.md`.
2. Read `.codex/memory/project.md`.
3. Inspect `tasks/active.md`.
4. Run targeted checks before delivery.
""",
            knowledge_agent,
        ),
        FileSpec(
            "docs/operations.md",
            """# Operations

## Routine Checks

Use `scripts/check.sh`.

## Release Notes

Record user-visible changes in `CHANGELOG.md`.

## Troubleshooting

Capture repeated failures and fixes in `.codex/memory/lessons.md`.
""",
            knowledge_agent,
        ),
        FileSpec(
            "docs/decisions/0001-record-architecture-decisions.md",
            """# ADR 0001: Record Architecture Decisions

## Status

Accepted

## Context

Agentic projects need durable rationale so future sessions do not rediscover the same decisions.

## Decision

Store architecture decisions under `docs/decisions/` and summarize durable facts in `.codex/memory/decisions.md`.

## Consequences

- Important decisions remain reviewable.
- Agents can quickly recover project intent in later sessions.
""",
            knowledge_agent,
        ),
        FileSpec(
            ".codex/config.toml",
            """# Project-local Codex configuration.
# Keep this conservative. Project-local hooks and rules require trust.

[agents]
max_threads = 6
max_depth = 1

# Uncomment only after reviewing hook commands.
# [features]
# hooks = true
""",
            agent_only,
        ),
        FileSpec(
            ".codex/hooks.example.json",
            """{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "/usr/bin/python3 \\"$(git rev-parse --show-toplevel)/.codex/hooks/session_start.py\\"",
            "timeout": 10,
            "statusMessage": "Loading project context"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/usr/bin/python3 \\"$(git rev-parse --show-toplevel)/.codex/hooks/stop_summary.py\\"",
            "timeout": 10,
            "statusMessage": "Checking session handoff"
          }
        ]
      }
    ]
  }
}
""",
            agent_only,
        ),
        FileSpec(
            ".codex/memory/README.md",
            """# Project Memory

Use this folder for durable project continuity.

- `project.md`: stable facts and constraints.
- `decisions.md`: decision summaries.
- `lessons.md`: recurring pitfalls and fixes.
- `daily/`: date-based notes when useful.

Do not store secrets here.
""",
            knowledge_agent,
        ),
        FileSpec(
            ".codex/memory/project.md",
            """# Project Memory: {{PROJECT_NAME}}

## Role

{{ROLE}}

## Stable Facts

- Project slug: `{{PROJECT_SLUG}}`

## Preferences

- Keep generated instructions concise.
- Prefer reusable scripts for repeatable checks.

## Open Questions

- What validation commands should `scripts/check.sh` run?
- Which custom agents should be enabled for this project?
""",
            knowledge_agent,
        ),
        FileSpec(
            ".codex/memory/decisions.md",
            """# Decisions

Record decisions that should survive future sessions.

| Date | Decision | Rationale |
| --- | --- | --- |
| TBD | Use Codex-friendly scaffold | Keep context, tasks, prompts, and automation explicit. |
""",
            knowledge_agent,
        ),
        FileSpec(
            ".codex/memory/lessons.md",
            """# Lessons

Record recurring mistakes, fixes, and workflow improvements.
""",
            knowledge_agent,
        ),
        FileSpec(".codex/memory/daily/.gitkeep", "", knowledge_agent),
        FileSpec(
            ".codex/agents/explorer.toml",
            '''name = "project_explorer"
description = "Read-only explorer that maps project structure, evidence, and relevant files before implementation."
sandbox_mode = "read-only"
developer_instructions = """
Stay in exploration mode.
Use fast search and targeted file reads.
Return concise findings with file paths, symbols, and uncertainty.
Do not modify files.
"""
''',
            agent_only,
        ),
        FileSpec(
            ".codex/agents/implementer.toml",
            '''name = "project_implementer"
description = "Implementation-focused worker for scoped changes after requirements and affected files are clear."
developer_instructions = """
Make focused, minimal changes.
Follow AGENTS.md and file-local conventions.
Run or recommend targeted checks.
Report changed files and verification results.
"""
''',
            agent_only,
        ),
        FileSpec(
            ".codex/agents/reviewer.toml",
            '''name = "project_reviewer"
description = "Reviewer focused on correctness, security, regressions, and missing tests."
sandbox_mode = "read-only"
developer_instructions = """
Review like an owner.
Lead with concrete findings ordered by severity.
Cite file paths and line numbers.
Avoid style-only comments unless they hide real risk.
Do not modify files.
"""
''',
            agent_only,
        ),
        FileSpec(
            ".codex/agents/docs-researcher.toml",
            '''name = "docs_researcher"
description = "Documentation and source-verification specialist for APIs, frameworks, and project docs."
sandbox_mode = "read-only"
developer_instructions = """
Verify claims against primary sources or project documentation.
Return concise answers with links, file references, or exact source locations.
State clearly when a claim is an inference.
Do not modify files.
"""
''',
            agent_only,
        ),
        FileSpec(
            ".codex/hooks/README.md",
            """# Hook Examples

These scripts are examples. They are inactive until you copy `.codex/hooks.example.json` to `.codex/hooks.json`, review every command, and trust the hooks through Codex.

Hooks receive JSON on stdin and should emit JSON on stdout when they need to influence Codex.
""",
            agent_only,
        ),
        FileSpec(
            ".codex/hooks/session_start.py",
            """#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def main() -> int:
    payload = json.load(sys.stdin)
    cwd = Path(payload.get("cwd") or ".")
    memory = cwd / ".codex" / "memory" / "project.md"
    if memory.exists():
        print(json.dumps({"systemMessage": f"Project memory is available at {memory}."}))
    else:
        print(json.dumps({"continue": True, "suppressOutput": True}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
""",
            agent_only,
            executable=True,
        ),
        FileSpec(
            ".codex/hooks/stop_summary.py",
            """#!/usr/bin/env python3
import json
import sys


def main() -> int:
    json.load(sys.stdin)
    print(json.dumps({"continue": True, "suppressOutput": True}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
""",
            agent_only,
            executable=True,
        ),
        FileSpec(
            ".codex/hooks/pre_tool_use_policy.py",
            """#!/usr/bin/env python3
import json
import sys


BLOCKED_FRAGMENTS = ("rm -rf /", "git reset --hard")


def main() -> int:
    payload = json.load(sys.stdin)
    command = str(payload.get("tool_input", {}).get("cmd", ""))
    if any(fragment in command for fragment in BLOCKED_FRAGMENTS):
        print(json.dumps({"continue": False, "stopReason": "Blocked dangerous command pattern."}))
        return 0
    print(json.dumps({"continue": True, "suppressOutput": True}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
""",
            agent_only,
            executable=True,
        ),
        FileSpec(
            ".codex/rules/README.md",
            """# Rules

Rules control which commands Codex can run outside the sandbox.

The files in `templates/` are examples. Copy one to `.codex/rules/default.rules` only after reviewing every prefix.
""",
            agent_only,
        ),
        FileSpec(
            ".codex/rules/templates/default.rules.example",
            '''# Example only. Rename to .codex/rules/default.rules after review.

prefix_rule(
    pattern = ["git", "status"],
    decision = "allow",
    justification = "Inspecting Git status is safe and useful.",
    match = ["git status", "git status --short"],
)

prefix_rule(
    pattern = ["rm"],
    decision = "prompt",
    justification = "Deletion should be reviewed before running outside the sandbox.",
    match = ["rm file.txt"],
)
''',
            agent_only,
        ),
        FileSpec(
            ".agents/skills/project-context/SKILL.md",
            """---
name: project-context
description: Use for work inside {{PROJECT_NAME}} when Codex needs project-specific context, role boundaries, memory conventions, task workflow, or repository navigation guidance.
---

# Project Context

Read these files before substantial work:

1. `AGENTS.md`
2. `.codex/memory/project.md`
3. `docs/INDEX.md`
4. `tasks/active.md`

Follow the project role: {{ROLE}}.

Keep durable findings in `.codex/memory` or `docs`, and keep task progress in `tasks`.
""",
            agent_only,
        ),
        FileSpec(
            ".agents/skills/project-context/references/project-map.md",
            """# Project Map

See root `AGENTS.md` and `docs/INDEX.md` for the current map. Update this file when the repo develops domain-specific structure that the local skill should remember.
""",
            agent_only,
        ),
        FileSpec(
            "tasks/README.md",
            """# Tasks

- `active.md`: current work.
- `backlog.md`: candidate work.
- `done.md`: completed work.
- `task-template.md`: reusable task shape.
""",
            all_profiles,
        ),
        FileSpec(
            "tasks/active.md",
            """# Active Tasks

No active tasks yet.
""",
            all_profiles,
        ),
        FileSpec(
            "tasks/backlog.md",
            """# Backlog

- Customize `AGENTS.md`.
- Fill in `.codex/memory/project.md`.
- Replace placeholder checks in `scripts/check.sh`.
""",
            all_profiles,
        ),
        FileSpec(
            "tasks/done.md",
            """# Done

- Initialized project scaffold.
""",
            all_profiles,
        ),
        FileSpec(
            "tasks/task-template.md",
            """# Task: <title>

## Goal

## Context

## Constraints

## Plan

## Verification

## Handoff
""",
            all_profiles,
        ),
        FileSpec(
            "prompts/README.md",
            """# Prompts

Reusable prompts for Codex or related agents. Keep prompts concrete, scoped, and easy to adapt.
""",
            knowledge_agent,
        ),
        FileSpec(
            "prompts/implementation-plan.md",
            """# Implementation Plan Prompt

Read `AGENTS.md`, `.codex/memory/project.md`, and the relevant files. Produce a scoped implementation plan with affected files, risks, and verification commands. Do not edit files until the plan is clear.
""",
            knowledge_agent,
        ),
        FileSpec(
            "prompts/code-review.md",
            """# Code Review Prompt

Review this branch for correctness, security, regressions, and missing tests. Lead with findings ordered by severity and cite file paths and line numbers.
""",
            code_agent,
        ),
        FileSpec(
            "prompts/research.md",
            """# Research Prompt

Research the question using primary sources where possible. Distinguish sourced facts from inferences. Summarize recommendations and cite links or project files.
""",
            knowledge_agent,
        ),
        FileSpec(
            "prompts/handoff.md",
            """# Handoff Prompt

Summarize what changed, what was verified, what remains uncertain, and the next concrete step. Update `tasks/active.md` or `.codex/memory` if the information should persist.
""",
            knowledge_agent,
        ),
        FileSpec(
            "templates/README.md",
            """# Templates

Reusable structures for documents, PRs, handoffs, ADRs, and feature specs.
""",
            knowledge_agent,
        ),
        FileSpec(
            "templates/adr.md",
            """# ADR NNNN: <decision>

## Status

Proposed

## Context

## Decision

## Consequences
""",
            knowledge_agent,
        ),
        FileSpec(
            "templates/feature-spec.md",
            """# Feature Spec: <name>

## Problem

## Goals

## Non-Goals

## Proposed Solution

## User Flows

## Technical Notes

## Risks

## Verification
""",
            knowledge_agent,
        ),
        FileSpec(
            "templates/pr-description.md",
            """## Summary

## Verification

## Risks

## Notes
""",
            code_agent,
        ),
        FileSpec(
            "templates/handoff.md",
            """# Handoff

## Current State

## Completed

## Verification

## Open Issues

## Next Step
""",
            knowledge_agent,
        ),
        FileSpec(
            "scripts/README.md",
            """# Scripts

Scripts should be deterministic and safe to run locally.

- `bootstrap.sh`: install or prepare local prerequisites.
- `check.sh`: run project verification.
- `new-task.sh`: create a task file from the template.
""",
            code_agent,
        ),
        FileSpec(
            "scripts/bootstrap.sh",
            """#!/usr/bin/env sh
set -eu

echo "Bootstrap placeholder for {{PROJECT_NAME}}."
echo "Add dependency installation or environment checks here."
""",
            code_agent,
            executable=True,
        ),
        FileSpec(
            "scripts/check.sh",
            """#!/usr/bin/env sh
set -eu

echo "No project-specific checks configured yet."
echo "Replace this with lint, test, typecheck, build, or documentation checks."
""",
            code_agent,
            executable=True,
        ),
        FileSpec(
            "scripts/new-task.sh",
            """#!/usr/bin/env sh
set -eu

title="${1:-new-task}"
slug=$(printf "%s" "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//')
file="tasks/${slug:-new-task}.md"

if [ -e "$file" ]; then
  echo "Task already exists: $file" >&2
  exit 1
fi

cp tasks/task-template.md "$file"
echo "Created $file"
""",
            code_agent,
            executable=True,
        ),
        FileSpec(
            ".github/pull_request_template.md",
            """## Summary

## Verification

## Risk

## Checklist

- [ ] Updated docs or memory when behavior/context changed.
- [ ] Updated `CHANGELOG.md` for user-visible changes.
""",
            code_only,
        ),
        FileSpec(
            ".github/workflows/ci.yml",
            """name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run checks
        run: scripts/check.sh
""",
            code_only,
        ),
    ]


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target_dir", help="Directory to create or update.")
    parser.add_argument("--project-name", help="Human-readable project name.")
    parser.add_argument("--role", default="general-purpose Codex-friendly engineering workspace")
    parser.add_argument("--profile", choices=sorted(PROFILES), default="full")
    parser.add_argument("--force", action="store_true", help="Overwrite existing files.")
    parser.add_argument("--dry-run", action="store_true", help="Preview writes without changing files.")
    parser.add_argument("--init-git", action="store_true", help="Run git init in the target directory.")
    return parser.parse_args(argv)


def write_file(path: Path, content: str, executable: bool, force: bool, dry_run: bool) -> str:
    existed = path.exists()
    if path.exists() and not force:
        return "skipped"
    if dry_run:
        return "would-create" if not existed else "would-overwrite"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    if executable:
        path.chmod(path.stat().st_mode | 0o111)
    return "written" if existed else "created"


def init_git(target: Path, dry_run: bool) -> str:
    if (target / ".git").exists():
        return "git already initialized"
    if dry_run:
        return "would run git init"
    if shutil.which("git") is None:
        return "git not found; skipped git init"
    subprocess.run(["git", "init"], cwd=target, check=True)
    return "git initialized"


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    target = Path(args.target_dir).expanduser().resolve()
    project_name = args.project_name or target.name
    project_slug = slugify(project_name)

    if not args.dry_run:
        target.mkdir(parents=True, exist_ok=True)

    counts: dict[str, int] = {}
    for spec in files():
        if args.profile not in spec.profiles:
            continue
        rendered = render(spec.content, project_name, project_slug, args.role)
        status = write_file(target / spec.path, rendered, spec.executable, args.force, args.dry_run)
        counts[status] = counts.get(status, 0) + 1
        print(f"{status}: {spec.path}")

    if args.init_git:
        print(init_git(target, args.dry_run))

    print("summary:", ", ".join(f"{key}={value}" for key, value in sorted(counts.items())))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
