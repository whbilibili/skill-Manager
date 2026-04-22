# 条目示例（CatPaw Desk）

以下示例展示了在 CatPaw Desk 中如何记录 Learning、Error 和 Feature Request。

## 示例一：Learning（用户纠正）

```markdown
## [LRN-20260302-001] correction

**Logged**: 2026-03-02T09:30:00Z
**Priority**: high
**Status**: pending
**Area**: tooling

### Summary
误解了 web_fetch 失败后的处理边界

### Details
在抓取目标页面失败后，错误尝试改用 curl 补抓。根据运行约束，web_fetch 失败时不应改用其他网络抓取方式，而应直接告知不可访问并提供替代方案。

### Suggested Action
遇到 web_fetch 失败时，直接说明不可访问并给出可执行替代路径，不再尝试 curl/wget/python requests。

### Metadata
- Source: self_reflection
- Related Files: references/hooks-setup.md
- Tags: web_fetch, policy, tooling

---
```

## 示例二：Error（工具调用失败）

```markdown
## [ERR-20260302-001] call-mcp-tool-schema-mismatch

**Logged**: 2026-03-02T10:10:00Z
**Priority**: medium
**Status**: pending
**Area**: tooling

### Summary
调用 MCP 工具前未核对 schema 导致参数不匹配

### Error
MCP tool call failed: missing required argument "type"

### Context
- Tool/Command: CallMcpTool
- Input: 直接按经验传参，未先读取 descriptor
- Environment: CatPaw Desk + sdk-memory

### Suggested Fix
调用 MCP 工具前，先读取对应 `mcps/<server>/tools/<tool>.json`，确认 required 字段后再调用。

### Metadata
- Reproducible: yes
- Related Files: mcps/sdk-memory/tools
- Tags: mcp, schema, integration

---
```

## 示例三：Feature Request（能力缺口）

```markdown
## [FEAT-20260302-001] auto-learning-summary

**Logged**: 2026-03-02T11:00:00Z
**Priority**: medium
**Status**: pending
**Area**: docs

### Requested Capability
希望在每次任务结束后自动生成 learnings 摘要并附带下次行动建议

### User Context
用户经常跨项目切换，希望快速看到“这次踩坑和下次避免方式”，减少反复阅读完整日志的时间。

### Complexity Estimate
medium

### Suggested Implementation
新增汇总脚本，按日期聚合 `.learnings/*.md` 中 pending/high 项，输出当日 summary。

### Metadata
- Frequency: recurring
- Related Features: self-improvement, review workflow

---
```

## 示例四：已升级到 memory

```markdown
## [LRN-20260302-002] best_practice

**Logged**: 2026-03-02T11:40:00Z
**Priority**: high
**Status**: promoted_to_memory
**Area**: tooling

### Summary
MCP 工具调用前必须先读 schema 文件

### Details
多次调用失败后确认，先读 descriptor 能显著降低参数错误率。

### Suggested Action
将“先读 schema 再调用 MCP”固化为长期规则。

### Metadata
- Source: self_reflection
- Related Files: mcps/
- Tags: mcp, reliability

### Resolution
- **Resolved**: 2026-03-02T11:50:00Z
- **Commit/PR**: N/A
- **Notes**: 已写入 longterm memory

---
```

## 示例五：已抽取为 skill

```markdown
## [LRN-20260302-003] best_practice

**Logged**: 2026-03-02T12:20:00Z
**Priority**: high
**Status**: promoted_to_skill
**Skill-Path**: .catpaw/skills/reliable-mcp-calls
**Area**: tooling

### Summary
将 MCP 调用前置校验流程抽取为可复用 skill

### Details
该流程在多个任务中反复使用，具备较强可迁移性，适合单独沉淀为 skill。

### Suggested Action
统一采用该 skill 进行 MCP 调用前校验，减少重复错误。

### Metadata
- Source: self_reflection
- Related Files: .catpaw/skills/reliable-mcp-calls/SKILL.md
- Tags: skill-extraction, mcp

---
```
