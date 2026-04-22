# PR 管理参考手册

> 所有操作遵循 SKILL.md 核心规则。

## 命令

| 命令 | 用途 | 关键参数 |
|------|------|----------|
| `fsd pr create` | 创建 PR | `-j` 应用名；`-f` 源分支；`-t` 目标分支；`--reviewer` 审核人；`--draft` 草稿 PR |

---

## 执行流程

`fsd pr create` 自动串联三步内部接口，用户只需提供三个参数：

```
Step 1: getPrConfigBatch     → 获取应用 PR 配置，取出 prReviewer 作为默认审核人
Step 2: getDiffCommitMessage → 获取两分支间 Commit 差异，生成 title / description
Step 3: createPrPost         → 提交 PR（reviewers 为必填字段）
```

### 审核人（reviewers）处理逻辑

`reviewers` 是 `createPrPost` 接口的**必填参数**，处理优先级如下：

1. **用户通过 `--reviewer` 手动指定** → 直接使用，跳过自动获取
2. **未手动指定** → 自动调用 `getPrConfigBatch` 获取该应用配置的 `prReviewer` 字段作为默认审核人
3. **自动获取也为空** → 报错退出，提示用户必须通过 `--reviewer` 手动指定，**禁止编造或随意填充审核人**

---

## 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--job` / `-j` | string | 是 | 应用名称，如 `AIE-XGPT` |
| `--from` / `-f` | string | 是 | 源分支（要合入的来源分支） |
| `--to` / `-t` | string | 是 | 目标分支（要合入的目标分支） |
| `--reviewer` / `—` | string | 条件必填 | 审核人 MIS 账号，多人用逗号分隔；若接口自动获取到默认审核人则可省略，否则必填 |
| `--draft` / `—` | string | 否 | 创建草稿 PR，默认创建正式 PR（`Normal`） |
| `--pretty` / `—` | string | 否 | 以人类可读格式输出结果 |

---

## PR 决策树

```
用户请求创建 PR
├─ 缺 -j / -f / -t 任意一项
│   ├─ 缺 -j → 先执行 fsd app find 自动获取应用名，禁止追问用户
│   └─ 缺 -f / -t → 必须追问用户
├─ 审核人处理
│   ├─ 用户指定了 --reviewer → 直接使用
│   ├─ 未指定 → 自动获取默认审核人（getPrConfigBatch 返回的 prReviewer）
│   │   ├─ 获取成功且非空 → 自动填入，无需追问
│   │   └─ 获取失败或为空 → 必须追问用户提供审核人 MIS 账号
│   └─ 禁止编造审核人
├─ 用户说"草稿/draft" → 加 --draft
└─ 默认创建正式 PR（type=Normal）
```

---

## 输出结果

| 情况 | 说明 |
|------|------|
| 成功 | `code: 0`，PR 创建完成 |
| 失败 | `code: -1`，`msg` 说明原因，如"PR 已存在"、"分支无差异无法创建"等 |

加 `--pretty` 显示人类可读摘要（应用名、分支、类型、标题、审核人）。

---

## 使用示例

### 示例1：创建正式 PR（默认审核人自动获取）

**用户**: "帮我给 AIE-XGPT 从 feat-xxx 到 staging 创建 PR"

**执行**:
```bash
fsd pr create -j AIE-XGPT -f feat-xxx -t staging --pretty
```

> 系统自动从 `getPrConfigBatch` 获取默认审核人（如 `zhuhongji,mashilei,jimengfei`），无需用户额外指定。

---

### 示例2：手动指定审核人

**用户**: "帮我给 AIE-XGPT 从 feat-xxx 到 staging 创建 PR，审核人是 zhangsan 和 lisi"

**执行**:
```bash
fsd pr create -j AIE-XGPT -f feat-xxx -t staging --reviewer zhangsan,lisi --pretty
```

---

### 示例3：创建草稿 PR

**用户**: "给 AIE-XGPT 从 feat-xxx 到 qa 创建一个草稿 PR"

**执行**:
```bash
fsd pr create -j AIE-XGPT -f feat-xxx -t qa --draft --pretty
```

---

### 示例4：失败场景

**场景A（PR 已存在）**：
```
错误: 创建 PR 失败 —— 创建失败，pr已存在
```
→ 直接告知用户，无需重试。

**场景B（分支无差异）**：
```
错误: 获取 Commit 差异失败 —— 目标分支 qa 的 commit 已经包含源分支 feat-xxx 的最新 commit，无法创建 pr
```
→ 提示用户检查分支是否已合并或提交是否推送。

**场景C（审核人获取失败）**：
```
错误: 未能自动获取审核人（reviewers），请通过 --reviewer <mis1,mis2> 手动指定审核人后重试。
```
→ 追问用户提供审核人 MIS 账号，然后加上 `--reviewer` 重新执行。
