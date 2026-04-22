---
name: harness-engineering-guide
description: "驾驭工程（Harness Engineering）— AI Agent 行为治理实战手册。基于 Mitchell Hashimoto 六大支柱理论（上下文架构/架构约束/自验证循环/上下文隔离/熵治理/可拆卸性），融合真实 Agent 运营中的 22 条规则、7 个防幻觉自验证机制和持续改进闭环。让 Agent 不犯已知的错：犯错→识别模式→固化规则→回测验证→永不再犯。适用于所有使用 OpenClaw/CatClaw/Claude Code 等 AI Agent 框架的开发者和运维者。"
version: 1.0.0
appkey: com.sankuai.raptor.iconfont.websdk
tags: ai,agent,guardrails,harness

metadata:
  skillhub.creator: "pengwenrui"
  skillhub.updater: "pengwenrui"
  skillhub.version: "V1"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "38977"
---

# Harness Engineering — 驾驭工程实战手册

> **"Every time an agent makes a mistake, that's not a failure — it's an unwritten rule."**
> — Mitchell Hashimoto, 2026.2.5

## 理论基础

**驾驭工程（Harness Engineering）** 是继 Prompt Engineering → Context Engineering 之后的第三次范式跃迁。

核心思想：不是让 AI 更聪明，而是让 AI **不犯已知的错**。每次犯错都工程化地修正，使错误永不再犯。

### 六大支柱

| # | 支柱 | 核心问题 | 一句话 |
|---|------|---------|--------|
| 1 | **上下文架构**（Context Architecture） | Agent 该看到什么？ | 分层加载，按需注入，不是什么都塞进去 |
| 2 | **架构约束**（Architectural Constraints） | Agent 不能做什么？ | 红线规则 + 工具禁令，硬编码不可绕过 |
| 3 | **自验证循环**（Self-Verification Loop） | Agent 怎么知道自己对不对？ | 输出前先证伪，不确定就不说 |
| 4 | **上下文隔离**（Context Isolation） | Agent 的子任务怎么不互相污染？ | 独立会话 + 最小权限 + 断点续传 |
| 5 | **熵治理**（Entropy Governance） | 知识怎么不腐烂？ | 写入门控 + 老化检测 + 蒸馏晋升 |
| 6 | **可拆卸性**（Detachability） | 能力怎么复用和替换？ | Skill 化 + 完整安装步骤 + 冲突检测 |

---

## 支柱 1：上下文架构

### 原则
不是把所有信息都塞给 Agent，而是**按场景、按角色、按任务**精确加载。

### 规则

**R1.1 分层加载**
```
Session Start →
  1. SOUL.md（人格，必加载）
  2. USER.md（用户画像，必加载）
  3. memory/today.md（近期上下文，必加载）
  4. MEMORY.md（长期记忆，仅主会话加载）
```

**R1.2 群聊隔离**
- 群聊/共享会话：禁止加载 MEMORY.md（含隐私信息）
- 仅主会话（direct chat）可加载完整记忆

**R1.3 子 Agent 最小注入**
- Spawn 子 agent 时，只注入该任务所需的：skill 路径 + 关键规则 + 输出格式
- 禁止把整个 MEMORY.md 塞进子 agent 的 task 描述

**R1.4 上下文预算感知**
- 当前占比 > 80%：主动将低价值上下文委托给子 agent
- 当前占比 > 90%：系统自动触发 compaction
- 重任务（预估 5+ tool calls）：一律 spawn 子 agent

### 反面案例
> ❌ 把 MEMORY.md 全量（200+ 行）注入每个子 agent → 子 agent 上下文爆炸，真正有用的 task 描述被淹没
> ✅ 只注入 "参考 MEMORY.md 中 insurancesettlement 向量库召回规则" 一行引用

---

## 支柱 2：架构约束

### 原则
有些错误不应该靠 Agent 的"判断力"来避免，而应该**硬编码禁止**。

### 规则

**R2.1 工具禁令（不可协商）**

| 禁止 | 原因 | 替代 |
|------|------|------|
| `repo cat` | 经常挂死无响应 | `mtcurl` REST API |
| `& ... wait` 并行下载 | mtcurl 挂起时整个 exec 永久卡死 | 串行逐个 + `timeout=30` |
| CIBA 认证 | 沙箱不可靠 | CDP 浏览器 SSO |
| `web_search` | 沙箱网络不通 | `catclaw-search` |
| `browser` tool 访问内网 | 不可靠 | CDP 直连 port 9222 |
| `dx search` | 沙箱超时 | `daxiang-uid-lookup` HTTP API |

**R2.2 错误→规则固化流程**
当 Agent 犯错被用户纠正时：
1. 识别错误模式（什么条件下犯了什么错）
2. 提取为一条可执行规则（If X then Y / 禁止 Z）
3. 写入对应位置：
   - 工具相关 → MEMORY.md 对应章节
   - 行为相关 → SOUL.md
   - 全局禁令 → AGENTS.md 安全规则
4. 下一次遇到相同模式 → 自动触发规则，不再犯错

**R2.3 约束分级**

| 级别 | 含义 | 违反后果 |
|------|------|---------|
| 🔴 红线 | 绝对禁止，无例外 | 立即停止，向用户报告 |
| 🟡 护栏 | 默认禁止，用户明确要求可放行 | 警告后执行 |
| 🟢 建议 | 推荐做法，可根据场景变通 | 正常执行 |

### 反面案例
> ❌ Agent 记得"repo cat 好像有问题"，但这次觉得"应该没事吧" → 挂死 30s
> ✅ 硬编码禁止 repo cat，遇到就直接走 mtcurl，零犹豫

---

## 支柱 3：自验证循环

### 原则
**Agent 的每个技术结论，在输出前必须经过验证。不确定的结论不输出，不是输出后打标签。**

### 机制 1：触发器 — 何时启动验证
满足**任一**条件，必须先验证再回答：

```
□ 结论含具体数值/金额/比例/状态码/错误码
□ 结论含字段名/表名/方法名
□ 结论含"应该"/"推断"/"大概"/"可能"/"我认为"
□ 知识库召回相似度 < 0.60
□ 结论涉及写操作（trigger/delete/update）
□ 用户问题含明确时间节点（今天/本周/昨天）
```

### 机制 2：反例挑战 — 证伪优先
给出任何技术结论前，**先尝试推翻它**：

```
Step 1: 搜索是否存在与结论矛盾的证据
Step 2: 找调用方代码确认实际行为
Step 3: 反例不存在 → 结论成立
         反例存在 → 结论推翻，重新推理
规则：禁止先找支持证据，必须先找反对证据
```

**为什么证伪优先？** 因为 LLM 天然有 confirmation bias（确认偏误），会优先找支持自己结论的证据。强制先找反证是对抗这个偏误的工程手段。

### 机制 3：反向提问 — 防止暗示污染
检测到以下模式时，先反驳假设再给结论：

```
用户说："recordId 就是 id 吧？"
❌ "是的，recordId 就是..."（被暗示带偏）
✅ "先假设不是，找反证... → 查源码发现 recordId = mall_installment_record_id，不是 id"
```

触发词：`应该是` / `对吧` / `是不是` / `肯定是` / 问题中预设了答案

### 机制 4：低分拒答 — 防止幻觉

```
知识库相似度 < 0.45 → ⛔ "知识库无覆盖，无法给出可靠结论"
相似度 0.45-0.60   → ⚠️ 触发自愈（读源码补充），自愈后重新判断
相似度 > 0.60      → 正常回答
多步推理任一步无依据 → 标注"此步需验证"，不输出完整链条
```

### 机制 5：推断结论禁止输出
**核心：不确定的结论直接不输出，不是输出后加 ⚠️ 标注。**

```
❌ "withhold_status=200 表示成功 ⚠️（推断）"  ← 把验证责任转嫁给用户
✅ 不确定 → 查源码确认 → 确认后才输出          ← 自己承担验证责任
```

适用范围：表名、字段名、枚举值、SQL 条件、调用链任一节点、状态码含义

### 机制 6：自愈快捷判断
以下细节**向量库天然存不下**，问到直接读源码，跳过自愈补写：

```
- SQL 的 ORDER BY / WHERE 条件
- 方法体内的 if/else 分支
- 计算公式/数值参数
- 枚举值的具体含义
```

### 机制 7：方案设计强制规则

```
1. 方法名/字段名先验后写 — 未经源码确认的不能出现在方案里
2. 前提假设显式说明 — 方案第一行写清前提
3. 风险点给完整代码 — 资金路径必须给出位置+触发条件+释放时机
4. 字段值追到赋值处 — 禁止看枚举类/DO注释/语义"猜"值
5. DO 类 ≠ 真相 — 赋值调用链才是真相（setXxx → submitXxx → buildXxx）
```

### 反面案例
> ❌ 用户问 "recordId 是什么？" → Agent 看 DO 类注释 `// 记录ID` → 回答 "recordId = id 字段"
> ✅ Agent 查 `autoTriggerWithhold()` 方法 → 发现 `request.setRecordId(schedule.getMallInstallmentRecordId())` → 回答 "recordId = mall_installment_record_id"

---

## 支柱 4：上下文隔离

### 原则
子任务之间不互相污染，主会话保持轻量响应。

### 规则

**R4.1 子 Agent 分流阈值**

| 条件 | 处理方式 |
|------|---------|
| 预估 ≤5 次 tool call | 主会话直接处理 |
| 预估 >5 次 tool call | spawn 子 agent |
| 预估 >30s 耗时 | spawn 子 agent |
| 批量文件操作 | spawn 子 agent，按需并行 |

**R4.2 并发安全**
- 多子 agent 写同一个 DB → WAL 模式 + fcntl 文件锁
- 多子 agent 写同一个文件 → 禁止并行，串行执行
- 每个子 agent 独立进度文件 → 断点续传

**R4.3 子 Agent 故障恢复**
- spawn 后检查返回状态，非 `accepted` 立即重试
- 进度文件持久化到 /tmp（非 DB），即使 agent 被 abort 也能续跑
- 批次 ID 避免与旧任务冲突（续跑用新 batch ID）

### 反面案例
> ❌ 5 个子 agent 同时 INSERT 到 SQLite → 频繁 `database is locked` 报错
> ✅ entity_graph.db 开启 WAL 模式 + fcntl 排他锁，4008 条零冲突写入

---

## 支柱 5：熵治理

### 原则
知识会腐烂。写入要有门槛，存量要有清理，质量要有度量。

### 规则

**R5.1 写入门控（importance 分级）**

| 知识类型 | importance | 是否写入 |
|---------|-----------|---------|
| 源码验证的业务公式 | 0.98 | ✅ |
| 状态机/调用链 | 0.92 | ✅ |
| RDS 表结构 | 0.90 | ✅ |
| 工具踩坑经验 | 0.88 | ✅ |
| 推断/猜测 | — | ❌ 不写入 |

**R5.2 自愈 SOP**
```
触发: 相似度<60% / 结论含数值 / 自己用了"推断/应该"
执行:
  1. 承认盲区（"知识库未覆盖，正在查源码确认"）
  2. mtcurl 读源码（分块 ≤200 行）
  3. 提取结论
  4. vm-remember 写入（importance ≥ 0.95）
  5. 回复附 "✅ 已自动存入知识库 key=xxx"
```

**R5.3 知识蒸馏**
```
Daily Log（memory/YYYY-MM-DD.md）
  → 原始记录，事无巨细
  
MEMORY.md
  → 蒸馏精华，定期从 daily log 中提取高价值条目
  → 过期信息及时清理
  
向量库
  → 结构化知识，门控写入
  → 实体图谱补充精确导航（22k 实体 / 30k 关系）
```

**R5.4 双层图谱架构**
```
Layer 1: entity_graph.db（实体图 — 精确导航）
  "谁调谁" "谁读这张表" → 图遍历 → source_keys 映射回文本块

Layer 2: graph.db + vectors.db（文本块图 — 语义理解）
  "代扣流程怎么走" → 向量+BM25+RRF → 图扩展

桥接: 实体的 source_keys 字段 = 两层图谱的多对多映射
路由: auto 模式自动识别意图（实体名/关键词 → entity；语义问题 → graph）
```

### 反面案例
> ❌ 向量库写入 "withhold_status=200 应该是成功"（推断，importance 未标注）→ 后续被召回当真相用
> ✅ 只有源码确认 `withhold_status: 100=待代扣, 300=已缴` 后才写入，importance=0.95

---

## 支柱 6：可拆卸性

### 原则
能力以 Skill 为单位封装，可独立安装/卸载/替换，不依赖特定环境状态。

### 规则

**R6.1 Skill 自包含**
- SKILL.md 必须包含完整安装步骤（沙箱重启后可从零恢复）
- 依赖声明完整（npm/pip/apt），不假设环境已有
- 命令丢失时：重新读 SKILL.md → 执行安装 → 重试

**R6.2 Skill 冲突管理**
- 安装前检测触发词是否与已有 Skill 重叠
- 同类 Skill 保留最精确的一个
- 符号链接 Skill 设策略为 skip（不自动更新）

**R6.3 持久化纪律**
```
✅ ~/.openclaw/     — 唯一持久化目录
❌ ~/、/tmp/、/root/ — 重启即消失

规则：
- 所有跨会话状态 → ~/.openclaw/ 下
- /tmp/ 仅用于临时工作文件
- 脚本/配置/备份 → ~/.openclaw/workspace/ 或 ~/.openclaw/skills/
```

---

## 元规则：驾驭工程的驾驭

### 规则演化
1. **新规则来源**：用户纠正 > 自己踩坑 > 理论推导
2. **规则冲突**：新规则与旧规则矛盾时，以更近期、更具体的为准
3. **规则退役**：环境变化导致规则失效时，标记 deprecated + 原因，不直接删除
4. **规则回测**：定期用历史 case 验证规则是否仍然有效

### 持续改进闭环
```
犯错 → 识别模式 → 固化规则 → 回测验证 → 规则生效
                                  ↑                |
                                  └────── 反馈 ←───┘
```

这是驾驭工程最核心的价值：**把每一次错误变成系统的免疫力**。

---

_Based on Mitchell Hashimoto's Harness Engineering (2026.2.5) + 实战经验 from pengwenrui & Jarvis (2026.3~4)_
