---
name: test-architect
description: >-
  测试架构师：从 feature-list.json / PRD / 代码自动生成结构化测试计划（test-plan.json），
  按测试用例逐条执行并跨会话断点续传，测试失败自动调用 issue-triage 写入 issues.json，
  最终输出结构化测试报告。深度集成 harness 工程体系，是"功能清单→编码→测试→缺陷"
  闭环中的测试环节。当用户提到测试计划、生成测试用例、执行测试、测试报告、跑测试、
  test plan、测试覆盖、回归测试、冒烟测试、验收测试、帮我测一下、检查功能是否正常、
  测试进度、功能验收、上线前检查、测试覆盖率、回归验证、改动影响评估时必须使用。
  即使用户只是说"帮我测一下这个功能"或"这个改动会不会影响已有功能"也应触发本技能。
  不用于：CI/CD 流水线配置（用 building-ci-pipelines）、代码质量审查（用 coding-reviewer）、
  修复 Bug（用 backend-architect 排期后编码者修复）、部署验证（用 fsd）。
metadata:
  version: "1.0.0"
  author: "wanghong52"
  skillhub.creator: "wanghong52"
  changelog: "初始版本：完整测试架构师技能，含五大模式和跨会话执行"
---

# 测试架构师（Test Architect）

> **定位**：harness 工程体系中的测试环节——从功能清单生成测试计划，按计划逐条执行测试，
> 失败自动分诊写入缺陷工单，最终输出测试报告。如同 `backend-architect` 管理功能清单，
> 本技能管理测试清单，同样支持跨会话断点续传。

---

## 一、职责边界（严格遵守）

### 本技能做什么

- 从 feature-list.json / PRD / 代码 **生成测试计划**（test-plan.json）
- 按测试用例 **逐条执行测试**，支持跨会话断点续传
- 测试失败时 **自动创建缺陷工单**（调用 issue-triage 写入 issues.json）
- 生成 **结构化测试报告**（Markdown）
- 维护 **测试进度追踪**（test-progress.txt）
- 分析 **测试覆盖率** 并给出改进建议

### 本技能不做什么

- **不修复 Bug**——发现缺陷后写入 issues.json，修复由架构师排期、编码者执行
- **不修改业务代码**——只生成/执行测试代码和测试配置
- **不替代 coding-reviewer**——代码质量审查是 reviewer 的职责
- **不做部署测试**——CI/CD 流水线测试由 fsd / building-ci-pipelines 负责

---

## 二、核心数据结构

### 2.1 test-plan.json（测试计划 —— 核心产物）

路径：`docs/exec-plans/test-plan.json`

```json
{
  "project": "项目名称",
  "created_at": "YYYY-MM-DD",
  "updated_at": "YYYY-MM-DD",
  "test_strategy": {
    "pyramid": { "unit": 70, "integration": 20, "e2e": 10 },
    "tools": {
      "unit": "vitest | jest | junit | go test | pytest",
      "integration": "supertest | testcontainers | spring-boot-test",
      "e2e": "playwright | cypress"
    },
    "coverage_target": { "line": 80, "branch": 60, "function": 80 }
  },
  "test_suites": [
    {
      "suite_id": "TEST-001",
      "title": "用户注册 - 邮箱格式校验",
      "type": "unit | integration | e2e | smoke | regression",
      "priority": "P0 | P1 | P2 | P3",
      "status": "planned | generated | passing | failing | blocked | skipped",
      "related_task_ids": ["AUTH-001"],
      "related_issue_ids": [],
      "description": "验证用户注册接口对邮箱格式的校验逻辑",
      "preconditions": ["数据库已初始化", "用户表为空"],
      "test_cases": [
        {
          "case_id": "TEST-001-C01",
          "title": "有效邮箱应注册成功",
          "category": "positive | negative | boundary | exception",
          "input": { "email": "user@example.com", "password": "Str0ng!Pass" },
          "expected_output": { "status": 201, "body": { "id": "non-null" } },
          "actual_output": null,
          "result": "pending | pass | fail | error | skip",
          "failure_reason": null,
          "created_issue_id": null
        }
      ],
      "test_files": [],
      "verification_command": "pnpm exec vitest run user-register",
      "last_run_at": null,
      "run_count": 0,
      "metadata": {
        "acceptance_criteria_ref": ["AUTH-001.acceptance_criteria[0]"],
        "modules": ["auth"],
        "files_affected": ["src/services/auth.ts", "src/__tests__/auth.test.ts"],
        "estimated_effort": "30min",
        "created_at": "YYYY-MM-DD",
        "created_by": "test-architect"
      }
    }
  ],
  "execution_summary": {
    "total_suites": 0,
    "total_cases": 0,
    "passed": 0,
    "failed": 0,
    "blocked": 0,
    "skipped": 0,
    "not_run": 0,
    "pass_rate": "0%",
    "last_full_run_at": null,
    "issues_created": 0
  }
}
```

### 2.2 test-progress.txt（测试进度 —— 跨会话断点）

路径：`docs/exec-plans/test-progress.txt`

格式与 progress.txt 对齐，四个固定区块，200 行硬上限：

```
[Test Execution Focus]
当前正在执行的测试套件及进度。
- 正在执行: TEST-003 (用户登录 - Token 验证)
- 上次断点: TEST-003-C04 (Token 过期场景)
- 总体进度: 12/30 suites passed, 3 failing, 15 remaining

[Test Findings]
保留最近 5 条关键发现，旧条目迁移到测试报告。
- [YYYY-MM-DD] TEST-002 发现 P1 缺陷: 并发注册无幂等校验 → BUG-005
- [YYYY-MM-DD] TEST-007 发现 P2 缺陷: 分页参数边界未校验 → BUG-006

[Blockers]
阻塞测试继续的问题及解决方案。
- Mock 服务未启动导致 TEST-010~TEST-015 全部 blocked
- 解决方案: 先执行 docker-compose up -d mock-server

[Next Test Steps]
下一个会话应该从哪里继续。
- 从 TEST-003-C04 断点继续执行 Token 过期测试
- 待 Mock 服务就绪后执行 TEST-010~TEST-015 集成测试
- 所有测试通过后生成最终测试报告
```

### 2.3 测试状态机

```
Suite 级别:
  planned → generated → passing / failing / blocked → skipped

Case 级别:
  pending → pass / fail / error / skip

Suite 状态判定规则:
  - 所有 case 为 pass          → suite 状态为 passing
  - 任一 case 为 fail/error    → suite 状态为 failing
  - 因外部依赖无法执行         → suite 状态为 blocked
  - 主动跳过（低优先级/不适用） → suite 状态为 skipped
```

---

## 三、五大工作模式

进入技能后，根据用户意图判断使用哪种模式。如果用户意图模糊，按以下优先级尝试：
**已有 test-plan.json？→ Mode 3/4/5** ；**已有 feature-list.json 但无 test-plan？→ Mode 1** ；
**什么都没有？→ Mode 2**

---

### Mode 1：从功能清单生成测试计划（Generate）

**触发条件**：已有 feature-list.json，尚未生成 test-plan.json
**触发词**："生成测试计划"、"为功能清单生成测试"、"test plan"

#### Step 1 — 静默读取上下文（不向用户输出）

```
必须读取:
  docs/exec-plans/feature-list.json    # 功能清单 → 测试来源
  docs/exec-plans/issues.json          # 已知缺陷 → 回归测试
  ARCHITECTURE.md                       # 架构约束 → 测试边界

可选读取:
  docs/exec-plans/progress.txt         # 开发进度 → 判断哪些 Task 可测
  docs/product-specs/PRD.md            # 需求文档 → 补充业务场景
  AGENTS.md                             # 导航地图
  docs/caveats.md                       # 已知坑点 → 针对性测试
```

读取失败处理：
- feature-list.json 不存在 → 切换到 Mode 2
- issues.json 不存在 → 跳过回归测试用例生成
- ARCHITECTURE.md 不存在 → 使用通用测试策略

#### Step 2 — 分析功能清单，规划测试策略

遍历 feature-list.json 中每个 Task：

1. **提取可测点**：从 `acceptance_criteria` 提取每一条验收标准，每条至少对应 1 个 test case
2. **提取契约**：从 `contracts.backend_api` 提取 API 签名，生成接口测试用例
3. **提取数据库契约**：从 `contracts.database` 提取表结构，生成数据层测试用例
4. **交叉引用 caveats.md**：已知坑点必须有对应的回归测试用例
5. **交叉引用 issues.json**：`resolved` 状态的 Bug 必须有对应的回归测试防止复发

测试用例生成策略：
- **正向用例**（positive）：每个 acceptance_criteria 至少 1 个
- **负向用例**（negative）：每个输入参数至少 1 个 invalid 输入
- **边界用例**（boundary）：数值参数的 min/max/溢出、字符串的空/超长/特殊字符
- **异常用例**（exception）：网络超时、数据库连接失败、并发冲突
- **回归用例**（regression）：每个 resolved 的 issue 对应 1 个

#### Step 3 — 确定测试工具链

自动检测项目技术栈（读取 package.json / pom.xml / go.mod / requirements.txt / Cargo.toml）：

| 技术栈 | Unit | Integration | E2E |
|--------|------|-------------|-----|
| Node.js/TS | vitest / jest | supertest | playwright |
| Java/Spring | JUnit 5 | Spring Boot Test + Testcontainers | — |
| Go | go test | httptest + testcontainers-go | — |
| Python | pytest | pytest + httpx | playwright |
| Rust | cargo test | — | — |

**关键约束**：verification_command 必须使用项目实际安装的工具。
Vitest 项目用 `pnpm exec vitest run <关键词>`，
Jest 项目用 `npx jest --testPathPattern=<pattern>`，绝不从模板复制粘贴。

#### Step 4 — 生成 test-plan.json 并校验

将分析结果写入 `docs/exec-plans/test-plan.json`，同时创建 `docs/exec-plans/test-progress.txt`。

生成后必须执行幂等校验脚本：

```python
import json, sys
tp = json.load(open("docs/exec-plans/test-plan.json"))
fl = json.load(open("docs/exec-plans/feature-list.json"))
# 校验 1: 每个非 skipped 的 Task 都有对应的 test suite
task_ids = {t["task_id"] for t in fl["tasks"] if t["status"] != "skipped"}
tested_ids = set()
for s in tp["test_suites"]:
    tested_ids.update(s.get("related_task_ids", []))
untested = task_ids - tested_ids
if untested:
    print(f"WARNING 以下 Task 缺少测试覆盖: {untested}")
# 校验 2: execution_summary 数字一致性
total_cases = sum(len(s["test_cases"]) for s in tp["test_suites"])
total_suites = len(tp["test_suites"])
assert tp["execution_summary"]["total_cases"] == total_cases, "total_cases 不一致"
assert tp["execution_summary"]["total_suites"] == total_suites, "total_suites 不一致"
print("OK test-plan.json 校验通过")
```

#### Step 5 — 向用户输出摘要

用自然语言段落输出测试计划概要，包含：总 suite 数、总 case 数、按优先级分布、
按类型分布、回归用例数、坑点覆盖数。

---

### Mode 2：从 PRD / 代码直接生成测试计划（Generate from Scratch）

**触发条件**：没有 feature-list.json，用户提供 PRD 或指向代码
**触发词**："帮我测一下这个功能"、"对这段代码生成测试"

#### Step 1 — 分析输入来源

- 用户提供 PRD → 提取功能模块和用户故事，转化为测试场景
- 用户指向代码文件 → 分析函数签名、分支逻辑、边界条件
- 用户描述功能 → 追问关键细节（最多 2 个问题），然后生成

#### Step 2 — 生成 test-plan.json

流程同 Mode 1 的 Step 3~5，但 `related_task_ids` 留空。

---

### Mode 3：执行测试（Execute）—— 支持跨会话断点续传

**触发条件**：已有 test-plan.json
**触发词**："执行测试"、"跑测试"、"继续测试"、"从断点继续"

这是本技能最核心的模式。设计理念与 feature-list.json 的任务执行一致：
**进度在文件里，不在上下文里。每次会话开始先读断点，结束前必须保存断点。**

#### Step 1 — 读取断点状态

```python
import json
tp = json.load(open("docs/exec-plans/test-plan.json"))
# 找到第一个需要执行的 suite（按优先级排序：P0 > P1 > P2 > P3）
priority_order = {"P0": 0, "P1": 1, "P2": 2, "P3": 3}
executable = [s for s in tp["test_suites"]
              if s["status"] in ("planned", "generated", "failing")]
executable.sort(key=lambda s: priority_order.get(s["priority"], 99))

if not executable:
    print("ALL DONE - 所有测试已执行完毕，请使用 Mode 5 生成测试报告")
else:
    # 优先恢复上次中断的 failing suite（有 pending cases 的）
    interrupted = [s for s in executable
                   if s["status"] == "failing"
                   and any(c["result"] == "pending" for c in s["test_cases"])]
    if interrupted:
        current = interrupted[0]  # 上次中断的 suite 最优先
    else:
        current = executable[0]   # 否则按 priority 排序
    pending_cases = [c for c in current["test_cases"] if c["result"] == "pending"]
    if pending_cases:
        print(f"RESUME {current['suite_id']} from {pending_cases[0]['case_id']}")
    else:
        print(f"RERUN {current['suite_id']} (所有 case 需重跑)")
```

#### Step 2 — 逐条执行测试用例

**有 verification_command 的 suite**（自动化测试）：
1. 执行 verification_command，捕获标准输出和标准错误
2. 解析测试结果（pass/fail/error），更新 case 的 result 和 actual_output
3. 命令执行失败（环境问题非测试失败）→ 标记 suite 为 blocked

**没有 verification_command 的 suite**（手动/探索性测试）：
1. API 测试 → 用 curl 或项目 HTTP client 发请求，对比 expected 与 actual
2. UI 测试 → **引用 catdesk-browser 技能** 执行浏览器操作并截图
3. 数据库测试 → 直接执行 SQL 验证数据状态
4. 无法自动执行 → 标记为 manual，输出手动测试步骤

**关键约束**：
- 同一时刻只执行 1 个 test suite（与 feature-list 的单 in_progress 约束一致）
- 每执行完 1 个 suite，**立即写入** test-plan.json 和 test-progress.txt
- 每 3 个 suite 后，输出一次阶段性进度摘要

#### Step 3 — 测试失败自动创建缺陷工单

当 test case 的 result 为 fail 或 error 时：

1. 收集失败信息：input、expected_output、actual_output、failure_reason
2. **尝试引用 issue-triage 技能**：读取 `~/.catpaw/skills/issue-triage/SKILL.md`
   - 成功 → 按 issue-triage 流程执行完整的缺陷分诊（含根因分析）
   - 失败 → 降级为直接写入 issues.json（精简版）

降级写入 issues.json 的格式：
```json
{
  "id": "BUG-{next_id}",
  "title": "测试失败: {case.title}",
  "status": "analyzing",
  "severity": "{suite.priority}",
  "reported_at": "{today}",
  "reported_by": "test-architect",
  "symptom": "预期: {expected}, 实际: {actual}",
  "expected": "{case.expected_output}",
  "reproduction": "执行 {suite.verification_command}",
  "impact": "影响模块 {suite.metadata.modules}，关联功能 {suite.related_task_ids}",
  "root_cause_analysis": {
    "candidates": [],
    "most_likely": "待分析",
    "evidence": "{failure_reason}",
    "fix_direction": "待分析"
  },
  "affected_modules": "{suite.metadata.modules}",
  "related_task_ids": "{suite.related_task_ids}",
  "resolved_at": null,
  "notes": "由 test-architect 自动创建（降级模式，未经 issue-triage 深度分析）"
}
```

3. 将 issue id 回写到 case 的 `created_issue_id` 和 suite 的 `related_issue_ids`

#### Step 4 — 保存断点

每个 suite 执行完毕后 + 会话结束前，更新三个文件：

1. **test-plan.json**：suite/case 状态、actual_output、last_run_at、run_count、execution_summary
2. **test-progress.txt**：完整替换四个区块（不追加），记录当前断点位置
3. **progress.txt**（如果存在）：在 [Current Focus] 追加一行测试进度摘要

---

### Mode 4：增量追加测试用例（Append）

**触发条件**：已有 test-plan.json，需要追加新测试
**触发词**："追加测试用例"、"补充测试"、"新增测试场景"、"这个场景也需要测"

#### Step 1 — 读取现有 test-plan.json 和触发来源

触发来源：用户手动描述 / feature-request 追加了新 Task / issue-triage 新增了 Bug / coding-reviewer 发现未覆盖的验收标准。

#### Step 2 — 冲击评估

- **场景重复**：新用例的 input/expected 与已有用例高度相似 → 提示用户
- **Mock 冲突**：新测试需要的 Mock 行为与已有测试矛盾 → 标记需要隔离
- **依赖冲突**：preconditions 与正在执行的测试互斥 → 标记执行顺序

#### Step 3 — 追加到 test-plan.json

- suite_id 从当前最大序号 +1
- 新 suite 默认 status 为 planned
- 更新 execution_summary 统计数字
- 更新 test-progress.txt 的 [Next Test Steps]

---

### Mode 5：生成测试报告（Report）

**触发条件**：测试执行完毕或用户要求
**触发词**："测试报告"、"生成报告"、"测试总结"、"测试结果"

#### Step 1 — 读取 test-plan.json 全量数据

#### Step 2 — 生成结构化测试报告

输出路径：`docs/exec-plans/test-report-YYYY-MM-DD.md`

报告包含以下章节（用自然语言段落，不过度格式化）：

**执行概要**：总 suite/case 数、通过/失败/阻塞/跳过统计、通过率、发现缺陷数及严重程度分布。

**测试覆盖分析**：功能清单覆盖率（多少 Task 有测试覆盖）、验收标准覆盖率（多少条 criteria 被验证）、未覆盖项及原因。

**失败用例详情**：每个失败 suite 的失败原因、预期结果、实际结果、关联缺陷 ID、影响模块。

**缺陷统计**：按严重程度分布、按模块分布、与 issues.json 的关联关系。

**回归测试覆盖**：针对已修复 Bug 的回归测试结果，是否有回归失败。

**风险评估与建议**：基于测试结果给出是否达到上线标准、高风险模块、重点关注建议。

#### Step 3 — 更新关联文件

- 更新 test-progress.txt 标记报告已生成
- 如果 progress.txt 存在，追加报告摘要到 [Key Decisions]
- 通过率 100% 时标记 execution_summary.last_full_run_at

---

## 四、外部技能引用链

本技能在不同场景下引用其他技能协作，采用"委托 + 降级"模式：

### 必要引用（核心流程依赖）

**issue-triage**（测试失败创建缺陷）：
- 读取 `~/.catpaw/skills/issue-triage/SKILL.md` 或 `{workspace}/.catpaw/skills/issue-triage/SKILL.md`
- 成功 → 按 issue-triage 完整流程分诊
- 失败 → 降级为直接写入 issues.json（精简版，无深度根因分析）

**catdesk-browser**（E2E 浏览器测试）：
- 读取 `~/.catpaw/skills/catdesk-browser/SKILL.md`
- 成功 → 用 catdesk browser-action 执行浏览器操作
- 失败 → 输出手动测试步骤，标记 suite 为 manual

**session-handoff**（会话结束时的断点保存）：
- 读取 `~/.catpaw/skills/session-handoff/SKILL.md`
- 成功 → 按完整交接流程保存（包括 CHANGELOG）
- 失败 → 自行更新 test-progress.txt 和 test-plan.json（最小化断点保存）

### 可选引用（增强测试质量）

**coding-reviewer**：测试代码写完后请 reviewer 审查测试质量。不可用时跳过。

**papi-mock-generator**：美团项目可用此技能生成 PAPI 接口 Mock。不可用时使用内置 Mock 策略。

**testing-strategies**：需要测试方法论参考时读取。不可用时使用内置测试金字塔策略。

**webapp-testing**：前端组件需要服务器生命周期管理时读取。不可用时降级为 API 级别测试。

---

## 五、与 Harness 体系的集成

### 数据流关系

```
feature-list.json ─[Task + acceptance_criteria]─→ test-plan.json
                                                       │
test-plan.json ───[failing cases]───→ issues.json      │
                                         │             │
issues.json ───[resolved bugs]───→ test-plan.json (回归用例)
                                         │
progress.txt ←──[测试进度摘要]── test-progress.txt
                                         │
caveats.md ←──[测试发现的规律性陷阱]──────┘
```

### 与 feature-list.json 的双向关联

- 正向：test-plan 的 related_task_ids → feature-list 的 task_id
- 反向：feature-list 的 verification 字段可引用 test-plan 中的 verification_command
- 覆盖率校验：每个 status != skipped 的 Task 必须有至少 1 个 test suite 覆盖

### 与 issues.json 的双向关联

- 正向：测试失败在 issues.json 创建工单，case 的 created_issue_id 记录关联
- 反向：issues.json 中 resolved 的 Bug 必须有 regression test suite 覆盖

### 文件路径约定

所有产物统一放在 `docs/exec-plans/` 目录下：

```
docs/exec-plans/
├── feature-list.json        # ← backend/frontend-architect 产出
├── progress.txt             # ← 开发进度
├── issues.json              # ← issue-triage 产出 + test-architect 追加
├── test-plan.json           # ← 本技能核心产物
├── test-progress.txt        # ← 本技能测试进度（跨会话断点）
├── test-report-YYYY-MM-DD.md  # ← 本技能测试报告
└── tech-debt-tracker.md     # ← 技术债务
```

---

## 六、幂等校验与安全约束

### 幂等性保证

- test-plan.json 的读写操作幂等：同一 suite 多次执行时 run_count 递增，但 status 只根据最新一次结果判定
- test-progress.txt 采用完整替换而非追加，防止无限增长
- 200 行硬上限，超限触发裁剪（旧 findings 迁移到测试报告）

### 安全约束

- **只读业务代码**：本技能可以读取业务代码分析测试点，但绝不修改业务代码
- **只写测试文件**：生成的测试代码只放在 __tests__ / test / spec 等测试目录
- **issues.json 只追加**：不修改已有 issue 的任何字段，只追加新工单
- **feature-list.json 只读**：不修改功能清单的任何字段

### 前置校验（每次执行前）

```python
import json, os, sys

# 校验 1: test-plan.json 存在且 JSON 合法
if os.path.exists("docs/exec-plans/test-plan.json"):
    try:
        tp = json.load(open("docs/exec-plans/test-plan.json"))
        assert "test_suites" in tp, "缺少 test_suites 字段"
        assert "execution_summary" in tp, "缺少 execution_summary 字段"
    except (json.JSONDecodeError, AssertionError) as e:
        print(f"ERROR test-plan.json 损坏: {e}")
        sys.exit(1)

# 校验 2: suite_id 唯一性
ids = [s["suite_id"] for s in tp["test_suites"]]
assert len(ids) == len(set(ids)), f"存在重复的 suite_id: {[x for x in ids if ids.count(x) > 1]}"

# 校验 3: execution_summary 一致性
total_cases = sum(len(s["test_cases"]) for s in tp["test_suites"])
assert tp["execution_summary"]["total_cases"] == total_cases, \
    f"total_cases 不一致: summary={tp['execution_summary']['total_cases']}, actual={total_cases}"

print("OK 前置校验通过")
```

---

## 七、跨会话工作流示例

### 会话 1：生成测试计划

```
用户: 帮我生成测试计划
Agent: [Mode 1] 读取 feature-list.json → 分析 12 个 Task → 生成 45 个 test suite / 180 个 test case
       → 写入 test-plan.json + test-progress.txt → 输出摘要
```

### 会话 2：执行测试（第一轮）

```
用户: 开始执行测试
Agent: [Mode 3] 读取 test-plan.json → 从 TEST-001 开始逐条执行
       → 执行到 TEST-015 时会话即将结束 → 保存断点到 test-progress.txt
       → 15/45 suites done, 2 failing (BUG-001, BUG-002 已写入 issues.json)
```

### 会话 3：从断点继续测试

```
用户: 继续测试
Agent: [Mode 3] 读取 test-progress.txt → 从 TEST-016 断点继续
       → 执行到 TEST-030 → 1 个 blocked (Mock 服务未启动)
       → 保存断点，输出进度
```

### 会话 4：补充测试 + 继续执行

```
用户: 新加了一个需求，需要补充测试
Agent: [Mode 4] 追加 3 个 test suite → 冲击评估无冲突
       → [Mode 3] 继续执行剩余 suite → 全部完成
用户: 生成测试报告
Agent: [Mode 5] 生成 test-report-2026-04-21.md → 输出概要
```

---

## 八、与 session-handoff 的协作

当用户说"我要结束了"或"保存进度"时，session-handoff 技能会被触发。
本技能产生的状态需要被 session-handoff 正确处理：

- session-handoff 读取 test-progress.txt 时，应将其中的 [Test Execution Focus] 纳入交接报告
- session-handoff 更新 progress.txt 时，应在 [Current Focus] 区块包含测试进度一行摘要
- session-handoff 的 CHANGELOG 应包含本次会话的测试执行统计

建议在 AGENTS.md 中添加如下索引：
```
## 测试体系
- 测试计划: docs/exec-plans/test-plan.json
- 测试进度: docs/exec-plans/test-progress.txt
- 测试报告: docs/exec-plans/test-report-*.md
- 测试技能: test-architect（从功能清单生成测试 → 执行 → 报告 → 缺陷闭环）
```
