# Code Reviewer Skill —— 全面审查 & 改善计划

> 审查对象：`code-reviewer` Skill V8（dongjiali02）
> 审查日期：2026-04-17
> 审查者：Claude (Opus 4.7)
> 参考：Karpathy-Skills（forrestchang）、Ralph（snarktank）

---

## 一、五维度打分（满分 5）

| 维度 | 分数 | 一句话结论 |
|------|------|-----------|
| 1. 严谨性 | **3.5** | 有 P0 三步验证骨架，但缺"输出后再反向自证"的闭环 |
| 2. 质量检查 | **3.0** | 报告格式严，但没有自我反驳机制，AI 容易走形式 |
| 3. 大分支处理 | **3.5** | 多 Agent + 规则锚点设计先进，但缺少持久化 checkpoint |
| 4. 误报控制（可改可不改） | **2.5** | 信噪比无门禁，P1/P2 容易刷数量 |
| 5. 漏报控制 | **2.5** | 速查卡之外覆盖薄，且没有"已修改函数全调用方扫描"硬约束 |

**整体：3.0 / 5** —— 框架优秀，执行层缺"自我审查回路"和"持久化记忆"。

---

## 二、维度详解（带证据）

### 维度 1 · 严谨性 — 3.5 / 5

**做得好：**
- `SKILL.md` 第 51-58 行 P0 三步验证（A: 行号 / B: 运行时后果 / C: 规则来源）—— 这是非常硬的强约束
- `置信度原则`（330-334 行）写得明确："禁止仅凭 diff 片段推测"
- `常见误判纠正表`（427-433 行）显式列出"空 catch 是 P0 不是 P1"等高频错判

**不够好：**
- **强约束只在"输出前"，没有"输出后再过一遍"**：AI 可能把"凭印象编出来的行号"当成"找到的行号"，没有反向 Read 文件验证
- **A/B/C 的 C 缺少"引用整段规则原文"的要求** → 容易出现"依据：G3" 但说不清 G3 到底说了什么
- **五项自检门禁是结论性自报**（355-362 行）→ 比如"⚠️ 涉及，精度已核实"，但"已核实"具体核实了什么没记录
- 缺少 **adversarial pass**：没有"如果我是对方开发者，这条结论我能不能反驳掉"的挑刺步骤

---

### 维度 2 · 质量检查 — 3.0 / 5

**做得好：**
- 知识库分层：始终加载 (TEAM_STANDARDS + CODE_DESIGN) + 按文件类型触发 + 按内容特征触发
- 报告格式标准化（每条问题必含 位置 + 依据 + 后果 + bad/fix code）
- `FEEDBACK_LOG.md` 三类信号收集（误报/漏报/新模式）

**不够好：**
- **FEEDBACK_LOG 是被动收集**，目前只有示例没有真实记录 → 没有形成"用过 → 反馈 → 升级规则"的闭环
- **没有 eval 集**：无法量化"V7 → V8 规则触发率/误报率到底是涨是跌"
- **报告生成完没有 self-critique 步骤** → AI 写完就交，不会回看说"这条 P1 真的有价值吗？开发者会同意吗？"
- 缺少 **价值评估模板**：每条 P1/P2 应该明确"如果不修，3 个月后会发生什么" → 没价值的就不该出现

---

### 维度 3 · 大分支代码处理 — 3.5 / 5

**做得好：**
- 四档模式（标准 / 分组 / 两阶段 / 多 Agent）按 diff 行数自动切换，门槛清晰
- 规则锚点机制（85-95 行）明确防止 context 截断丢规则
- Sub-agent 携带"规则快照"而非"读文件"，避免每个子 agent 重复消化知识库
- Context 自恢复信号表（251-263 行）有 5 种触发场景

**不够好：**
- **拆分按"行数+文件类型"，不按依赖图**：A.tsx 改了，调用它的 B.tsx 没改，但被分进不同组 → Sub-agent 看不到全貌
- **多 Agent 模式没有持久化中间结果**：所有 Sub-agent 的 JSON 只在主 Agent context 里合并；主 Agent context 一爆就全没
- **没有"分批确认"控制**：报告应该分段产出 → 等用户/CI 确认 → 再继续下一段，目前是一气呵成全部输出
- 缺少 Ralph 那种 **`.code-review-progress.json`** 持久化进度文件 → 中断了无法继续

---

### 维度 4 · 误报控制（可改可不改的吹毛求疵）— 2.5 / 5 ⚠️ 用户重点反馈

**做得好：**
- 置信度原则禁止"建议考虑重构"
- P0 三步验证降级机制（任一不满足 → 降为 P2）

**不够好（这是当前最大痛点）：**
- **没有信噪比门禁**：报告允许出现 N 条 P1 + N 条 P2，没有"P1+P2 总数上限"
- **没有"价值过滤器"**：缺少"如果这条不修，会发生什么具体后果？" 强制字段 → 写不出后果就该删掉
- **stylistic 类问题没单独限流**：命名 / 注释 / 格式问题特别容易刷 P2 数量
- **没有"开发者视角反向挑刺"步骤**：AI 写完一份报告，应该自问"如果我是 PR owner，看到这条会不会觉得是 AI 在凑数？"
- **缺少"修改成本 vs 收益"评估**：P1 只标"建议"，没说"改一处 vs 改全文件 vs 重构组件"的工作量

---

### 维度 5 · 漏报控制（实质问题被忽略）— 2.5 / 5

**做得好：**
- 团队 BadCases 库 7 个真实 COE 案例
- CRITICAL_CONCERNS 5 大关注点统计了事故次数 + 资损金额

**不够好：**
- **"已修改函数全调用方扫描"是建议而非硬约束**：第 3 步表格说"Grep 搜调用方，抽样 Read 2-3 处"，但没有"必须 Grep 后才能继续输出"的门禁
- **测试文件直接被跳过深度审查**（306 行）—— 但 mock 假设错误本身就是漏报源
- **知识库覆盖薄**：
  - 没有 React 18 Concurrent Mode / Suspense / startTransition 相关坑
  - 没有 Mobx 6 makeAutoObservable 相关错配
  - 没有 TS 5.x const generics、satisfies 等新特性误用
  - 没有微前端 / qiankun 相关跨应用陷阱
- **没有"反 diff 视角"**：很多漏报源于"AI 只看 diff，不看完整文件" → 缺少"diff 改动的函数，必须 Read 完整文件再判"的强约束（虽然提了，但没有执行验证）
- **不主动检查"应该改但没改"**：比如改了 A 但 A 的旁路 B 没改 → 当前 skill 不会主动报"你应该顺手改 B"

---

## 三、改善计划（按 ROI 排序，分 3 期）

### Phase 1 · 立即可做（1-2 天，性价比最高）

#### 改进 1：引入"自我反驳"步骤（Self-Critique Pass）

> **借鉴 Karpathy "Senior engineer test"** + **Opus 4.7 extended thinking**

在"输出报告"之前，强制插入一个 self-critique pass：

```markdown
## 第 4 步：自我反驳（强制，不可跳过）

写完报告草稿后，必须再走一遍以下 5 个反问。每条 P0/P1 都要过这 5 关：

| 反问 | 通过标准 | 不通过的处理 |
|------|---------|-------------|
| Q1：行号能用 Read 工具确认吗？ | 实际 Read 该文件该行验证一次 | 删除该条 |
| Q2：运行时后果能写成一句"什么场景下用户看到什么"？ | 含具体场景+具体表现 | 降级 P2 |
| Q3：依据是某条规则的哪一句话？ | 能贴出规则原文片段 | 降级 P2 |
| Q4：如果我是 PR owner，会不会觉得是吹毛求疵？ | 有真实风险/损失 | P1→P2 或删除 |
| Q5：修改成本是 1 行 / 1 函数 / 全文件？ | 与收益相符 | 标注 cost 字段 |
```

**实现：** 在 SKILL.md 输出报告前增加"第 4 步"，配套一个 `self-critique-checklist.md` 模板。

---

#### 改进 2：引入"价值过滤器"治理 P1/P2 信噪比

> **解决用户反馈的"可改可不改"问题**

```markdown
## 信噪比门禁（输出前自检）

- 每份报告 P1 上限 5 条、P2 上限 8 条（超出必须按价值排序后截断）
- 每条 P1/P2 必填字段：
  * `不修后果`：3 个月后会发生什么具体损失（不能写"代码可读性下降"这种空话）
  * `修改成本`：1 行 / 1 函数 / 全文件 / 重构 四档之一
  * `优先级矩阵`：[高价值-低成本] 必报，[低价值-高成本] 必删，其他按 ROI 排
```

**实现：** 修改报告模板的 P1/P2 条目格式，增加 `不修后果`+`修改成本` 字段。

---

#### 改进 3：引入"持久化进度文件"（Ralph 风格）

> **解决长任务 context 易失忆的问题**

每次 CR 启动时创建 `.code-review-progress.json`：

```json
{
  "session_id": "2026-04-17-cr-xxxx",
  "branch": "feature/xxx",
  "base": "master",
  "diff_stats": { "files": 18, "lines": 3200 },
  "mode": "multi-agent",
  "phases": [
    { "name": "load_knowledge", "status": "done", "loaded_files": [...] },
    { "name": "group_1_review", "status": "done", "findings_file": ".cr-group-1.json" },
    { "name": "group_2_review", "status": "in_progress" }
  ],
  "findings_so_far": { "p0": 3, "p1": 4, "p2": 6 },
  "last_checkpoint": "2026-04-17T10:23:15Z"
}
```

**好处：**
- 单次 context 爆了，下一次 CR 可以读 progress 文件继续
- 主 Agent 合并阶段直接读各 group 的 JSON 文件，不依赖 context 内存
- 用户可以中途打断，随时看到进度

**实现：** 加一个 `scripts/cr-progress.js`，在第 0 步写入，每 phase 结束更新。

---

### Phase 2 · 中期改造（3-5 天）

#### 改进 4：引入 adversarial sub-agent（Opus 4.7 Task 工具）

> **借鉴 Opus 4.7 自我审查能力 + Ralph 的"verification" 思想**

在主报告输出前，**起一个独立的 Task agent**，prompt 是：

```
你是一位刻薄的资深 PR owner。下面是 AI 给你的 PR 写的 CR 报告。
你的任务是逐条挑刺：
- 找出"AI 在凑数 / 没看代码就判 / 误报"的条目
- 找出"运行时后果"写得含糊（没有具体场景）的条目
- 找出"依据"对不上号（规则原文不支持这个判断）的条目

输出 JSON：
{
  "to_remove": ["P1-3", "P2-5"],   // 该删
  "to_downgrade": [{"id": "P0-2", "to": "P2"}],
  "to_strengthen": [{"id": "P0-1", "missing": "具体哪个用户场景会触发"}]
}

主 Agent 收到后必须执行这些建议，不允许直接忽略。
```

**实现：**
- 在 SKILL.md 增加"第 5 步：Adversarial Review"
- 配套 `templates/adversarial-prompt.md`

---

#### 改进 5：硬化"已修改函数全调用方扫描"约束

> **解决漏报问题：跨文件影响**

把第 3 步的"上下文扩展表"从"建议"升级为"门禁"：

```markdown
## 输出 P0/P1 前的强制 Grep 验证

任何报告条目涉及以下情况，必须**先用 Grep 工具搜调用方**，
没搜过 → 不允许输出该条：

| 触发条件 | 必须执行 |
|---------|---------|
| 改动了导出函数 / Hook / Component | `Grep` 搜该 export 的所有 import 处，抽样 Read 2 处 |
| 修改了类型定义 / 接口 | `Grep` 搜所有 `as XXX` 和 `: XXX` 引用 |
| 改了 Store 的 observable 字段 | `Grep` 搜所有读写该字段的位置 |
| 改了 RouteParams / API 入参出参 | `Grep` 搜调用方 |

执行结果必须写在报告 `📋 上下文分析` 节里，未执行 → 该条降级 P2(待确认)
```

**实现：** 修改 SKILL.md 第 3 步表格，再加一个 `scripts/check-callers.js` 自动统计调用方数量。

---

#### 改进 6：建立 eval 集（量化质量基线）

> **借鉴 skill-creator 的 measure performance 思路**

在 `.spec/eval/` 下放 10-20 个**已知答案的 diff 样本**：

```
.spec/eval/
  ├── case-01-promise-pending.diff
  ├── case-01-expected.json       # { "p0": ["G1 命中行号 24"], "p1": [], "p2": [] }
  ├── case-02-money-float.diff
  ├── case-02-expected.json
  ...
```

每次 skill 升级前跑一遍：
```bash
node scripts/eval.js
# 输出：
# Case 01: ✅ P0 命中 / 0 误报
# Case 02: ❌ 漏报 G6 浮点
# 通过率：8/10，回归对比 V7：+1 case
```

---

### Phase 3 · 长期演进（按需）

#### 改进 7：引入 ralph 风格的"PR.json"任务分解

把一份大 CR 分解成可枚举的 atomic stories：

```json
{
  "review_id": "cr-2026-04-17",
  "stories": [
    { "id": "S1", "scope": "src/store/", "checks": ["G1", "G2", "G3", "store-rules"], "passes": false },
    { "id": "S2", "scope": "src/components/", "checks": ["react-rules"], "passes": false }
  ]
}
```

每个 story 独占一个 sub-agent 上下文，做完 mark `passes: true`。
全部 pass → 主 agent 合并出最终报告。

#### 改进 8：定期把 FEEDBACK_LOG 反哺知识库

设一个 `consolidate-feedback` 子流程（参考 consolidate-memory skill）：
- 每月跑一次，把 FEEDBACK_LOG 里的 "误报" 加入"白名单例外"
- "漏报"加入对应知识库章节
- "新模式"提议为新规则草稿

---

## 四、Opus 4.7 自我审查特性的具体引入方案

> Opus 4.7 在 extended thinking、sub-agent orchestration、tool-grounded verification 上能力增强，
> 这些特性可以系统性地解决"AI 自嗨 / 一步错步步错"问题。

| Opus 4.7 特性 | 在 CR Skill 中的落地 | 解决的痛点 |
|--------------|---------------------|-----------|
| **Extended Thinking** | 在每条 P0 输出前，在 `<thinking>` 块里走完 A/B/C 三步验证再输出 | AI 不假思索 → 强制慢思考 |
| **Sub-agent (Task tool)** | 改进 4：起 adversarial reviewer | AI 自嗨 → 引入对手视角 |
| **Tool-grounded verification** | 改进 1 Q1：每条结论必须 Read 工具反查 | 凭印象编造 → 必须有证据链 |
| **Multi-pass review** | Pass 1 (草稿) → Pass 2 (Adversarial) → Pass 3 (终稿) | 一次输出无法回退 → 三轮修订 |
| **Persistent scratchpad** | 改进 3：`.code-review-progress.json` | 长任务 context 失忆 → 状态持久化 |

---

## 五、对照 Karpathy & Ralph 理念的具体借鉴

### 来自 Karpathy-Skills

| 原则 | CR Skill 当前状态 | 借鉴改造 |
|------|------------------|---------|
| Think Before Coding | ❌ 直接执行 | 第 0 步前加"先输出 review plan，列出本次要查什么" |
| Simplicity First | △ 报告字段已收敛 | P1/P2 引入"价值过滤器"，砍掉无价值条目 |
| Surgical Changes | ❌ 没有边界 | 加约束："只评估 diff 涉及的文件，不评估它没改的东西" |
| Goal-Driven Execution | △ 有自检表 | 把每条 P0 写成"如果我写一个 test 复现，怎么写"的可验证形式 |
| Clarification-First | ❌ 缺失 | 不确定的场景应该向用户问而不是猜 |

### 来自 Ralph

| 机制 | CR Skill 当前状态 | 借鉴改造 |
|------|------------------|---------|
| Ephemeral context, Persistent memory | ❌ 全靠 in-context 记忆 | 改进 3：`.code-review-progress.json` |
| Right-sized decomposition | △ 多 Agent 模式有拆 | 改进 7：PR.json 任务分解 |
| Tight feedback loops | ❌ 没有 phase 验证 | 每个 phase 后自检 + 写 progress 文件 |
| Deliberate scratchpad updates | ❌ FEEDBACK_LOG 是被动收集 | 改进 8：每次 CR 强制 append 至少一条"本次学到的" |
| Verification gate | △ 有自检 5 项但是结论性 | 改进 1：每条 P0 强制 Read 工具反查 |
| Observable progress | ❌ 黑盒 | progress.json + phase status 可读 |

---

## 六、防"AI 长任务 4 大病"对策表

| 病症 | 当前 Skill 暴露点 | 改造对策 |
|------|------------------|---------|
| **上下文分散** | 多 Agent 模式合并阶段全靠主 Agent 内存 | 改进 3 + 改进 7：每个 phase 输出落盘到 .json |
| **无持久记忆** | session 结束所有积累归零 | 改进 3 持久化进度 + 改进 8 反哺知识库闭环 |
| **一步错步步错** | P0 误判 → 后续讨论都基于错误判断 | 改进 4 adversarial pass + 改进 1 Q1 Read 反查 |
| **AI 糊弄自嗨** | 报告写完就交，没有反向挑刺 | 改进 1 self-critique + 改进 2 价值过滤器 + 改进 4 adversarial sub-agent |

---

## 七、推荐落地顺序

| 优先级 | 项目 | 工作量 | 立即收益 |
|-------|------|-------|---------|
| P0 | 改进 1 自我反驳 + 改进 2 价值过滤器 | 1 天 | 直接降低误报、消除"凑数"感 |
| P0 | 改进 3 持久化 progress.json | 1 天 | 大分支不再"前功尽弃" |
| P1 | 改进 4 adversarial sub-agent | 2 天 | 引入"对手视角"，质量跃升 |
| P1 | 改进 5 硬化调用方扫描 | 1 天 | 直接降低漏报 |
| P2 | 改进 6 eval 集 | 3 天 | 让"V8 → V9 是不是真的更好"可量化 |
| P3 | 改进 7/8 任务分解 + 知识库反哺 | 持续投入 | 让 skill 长期演进 |

---

## 八、附：可立即动手的 SKILL.md 补丁清单

1. 在 "输出报告" 节前插入新章节 `## 第 4 步：自我反驳（强制）`
2. 在 "P0/P1/P2 常见误判纠正" 后追加 `## 信噪比门禁`
3. 修改报告模板 P1/P2 条目格式，增加 `不修后果` + `修改成本` 字段
4. 第 0 步追加 `node $SKILL_DIR/scripts/cr-progress.js init` 命令
5. 第 3 步上下文扩展表前加红色提示框："以下是门禁，不是建议"

——

**总结**：当前 V8 框架先进、规则齐全，但执行层"自我审查回路"和"持久化记忆"还没建立。
按 Phase 1 三个改进做完，预计可以解决用户反馈的 80% 问题（误报、漏报、长任务失忆）。
