# Codex-Friendly Project Scaffold Spec

## Research Summary

- Codex discovers `AGENTS.md` from global and project scopes, then merges from root toward the current directory. Later, more local instructions override earlier guidance.
- Codex skips empty instruction files and stops once combined project guidance reaches `project_doc_max_bytes`, which defaults to 32 KiB. Keep `AGENTS.md` short and link to deeper files.
- Skills should be focused directories with `SKILL.md` plus optional `scripts`, `references`, `assets`, and `agents/openai.yaml`. Repo-scoped skills belong under `.agents/skills`.
- Project-local hooks live in `.codex/hooks.json` or `.codex/config.toml` and require trust review. Use example hook files by default.
- Project-local custom agents live under `.codex/agents/*.toml`; each file should include `name`, `description`, and `developer_instructions`.
- Rules live under `.codex/rules/*.rules` only when the project config layer is trusted. Keep rules examples conservative.

Primary references:

- OpenAI Codex AGENTS.md guide: https://developers.openai.com/codex/guides/agents-md
- OpenAI Codex hooks guide: https://developers.openai.com/codex/hooks
- OpenAI Codex subagents guide: https://developers.openai.com/codex/subagents
- OpenAI Codex rules guide: https://developers.openai.com/codex/rules

## Generated Layout

```text
<project>/
  AGENTS.md
  README.md
  CHANGELOG.md
  LICENSE
  .gitignore
  .gitattributes
  .editorconfig
  .env.example
  docs/
    INDEX.md
    architecture.md
    context-engineering.md
    onboarding.md
    operations.md
    decisions/
      0001-record-architecture-decisions.md
  .codex/
    config.toml
    hooks.example.json
    memory/
      README.md
      project.md
      decisions.md
      lessons.md
      daily/.gitkeep
    agents/
      explorer.toml
      implementer.toml
      reviewer.toml
      docs-researcher.toml
    hooks/
      README.md
      session_start.py
      stop_summary.py
      pre_tool_use_policy.py
    rules/
      README.md
      templates/default.rules.example
  .agents/
    skills/
      project-context/
        SKILL.md
        references/project-map.md
  tasks/
    README.md
    active.md
    backlog.md
    done.md
    task-template.md
  prompts/
    README.md
    implementation-plan.md
    code-review.md
    research.md
    handoff.md
  templates/
    README.md
    adr.md
    feature-spec.md
    pr-description.md
    handoff.md
  scripts/
    README.md
    bootstrap.sh
    check.sh
    new-task.sh
  .github/
    pull_request_template.md
    workflows/ci.yml
```

## Design Rationale

- `AGENTS.md` is the fast entry point for Codex. It should contain the operating contract, validation command, and where to look next.
- `.codex/memory` stores durable facts, decisions, lessons, and daily continuity notes. It is project-owned, not chat-owned.
- `.agents/skills/project-context` gives the repo a local skill that can be invoked explicitly or implicitly for project-specific work.
- `.codex/agents` defines specialized subagents without forcing parallel work; Codex still spawns subagents only when asked.
- `.codex/hooks` and `.codex/rules` ship as examples first because active hooks and rules affect local trust and approvals.
- `tasks`, `prompts`, and `templates` make repeatable work visible and editable by humans and agents.

## Customization Guidance

- For a software repo, fill `scripts/check.sh` with real `test`, `lint`, `typecheck`, and build commands.
- For a role-playing or research repo, rewrite `AGENTS.md` and `.agents/skills/project-context/SKILL.md` around role boundaries, source policy, output style, and memory rules.
- For multi-package repos, add nested `AGENTS.md` files near packages with different build commands or review rules.
- For enforced automation, copy `.codex/hooks.example.json` to `.codex/hooks.json`, review every command, then trust hooks through `/hooks`.
- For enforced command policy, copy `.codex/rules/templates/default.rules.example` to `.codex/rules/default.rules` and keep prefix rules narrow.
