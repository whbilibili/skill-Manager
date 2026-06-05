# 任务排期参考手册

## 核心行为规则

### 创建任务

1. **先执行再补全**：必须先执行 `fsd task create`（拼上用户已给参数），由 CLI 输出告知缺失信息（需求/空间/排期阶段）
2. **任务类型**：用户话语中包含类型名或别名时必须加 `--task-type`，否则 CLI 按角色自动判断可能与用户意图不符
3. **排期阶段**：
   - 禁止不执行 CLI 就自行编造阶段名称——不同任务类型的阶段不同，只有 CLI 输出才是准确的
   - CLI 输出的阶段表必须完整展示，不得省略、重排或丢弃任何阶段
   - 有必填阶段时至少填写一个必填阶段（**非全部必填阶段都要填**），没有必填阶段时任意阶段均可
   - 多个阶段用 `--schedule`（时间段传 `["开始日期","结束日期"]`，单日传 `"日期"`）
4. **排期时间**：禁止 AI 自行填充，必须等用户明确提供日期。直接传日期字符串（如 `--start-time 2026-03-01`），禁止自行计算毫秒时间戳，CLI 内部自动处理时区转换。用户未给年份时默认当年
5. **创建成功后**必须以 `[任务链接](URL)` 格式展示

### 任务类型（6种）

| 英文 key | 中文名 | 别名 |
|----------|--------|------|
| developOnline | 开发任务 | 开发 |
| qaOnline | 测试任务 | 测试、QA |
| product | 产品任务 | 产品、PM |
| design | 设计任务 | 设计、UI、UX |
| algorithm | 算法任务 | 算法 |
| default | 默认任务 | 默认 |

> **"默认任务"是正式类型名（key=default），不等于"不指定类型"。**
> - 用户说"创建默认任务" → 必须传 `--task-type default`
> - 用户说"创建一个任务"（未提及类型） → 不传 `--task-type`，由 CLI 自动判断

### 类型 vs 状态（易混淆）

- `--subtype` 是任务分类（开发任务/测试任务/产品任务等）
- `-s` 是任务进度（待处理/进行中/已完成）
- 示例："查进行中的测试任务" → `-s 进行中 --subtype 测试任务`

### 排期筛选

用户说"查今天/本周/下周/某天有排期的任务"时，必须使用 `--schedule-range`，禁止先拉全量再手动过滤。

---

## 创建任务决策树

```
用户说「创建任务」
  ↓
步骤1：提取用户已给参数，执行 fsd task create
  ⚠ 话语含类型名/别名 → 必须加 --task-type
    "创建开发任务" → --task-type developOnline
    "帮我建测试任务" → --task-type qaOnline
    "创建默认任务" → --task-type default  ← 是类型名！
    只说"创建一个任务" → 不传 --task-type
  ↓
步骤2：CLI 返回缺失信息（需求/空间/排期阶段）
  ↓
步骤3：原样转述 CLI 输出的所有缺失信息
  → 排期阶段表必须完整展示，不得省略
  → 等待用户提供日期
  ↓
步骤4：用户给齐后，拼上所有参数重新执行 fsd task create
  ↓
步骤5：创建成功 → 展示 [任务链接](URL)
```

---

## CLI 参数详情

### fsd task create

参数均可选，缺必填信息时 CLI 打印候选表后退出。

| 参数 | 说明 |
|------|------|
| `--task-type <type>` | 任务类型（支持英文 key/中文名/别名） |
| `-r, --req-id <reqId>` | 父需求 ID（developOnline/qaOnline/product/design 必需） |
| `-p, --project-id <id>` | ONES 空间 ID（有 -r 时优先从需求带出） |
| `-n, --name <name>` | 任务名称（不传则自动生成） |
| `-a, --assigned <mis>` | 负责人 MIS（不传则用 SSO） |
| `--start-time <time>` | 排期开始时间，支持日期字符串（如 `2026-03-01`、`3.1`）或毫秒时间戳 |
| `--end-time <time>` | 排期结束时间，支持日期字符串（如 `2026-03-02`、`3.2`）或毫秒时间戳 |
| `--schedule <json>` | 多阶段排期 JSON |
| `--module-name <name>` | 模块名称 |
| `--expect-time <pd>` | 预计工时（人天） |
| `--bind-branch` | 创建成功后绑定当前 Git 分支 |
| `-v, --verbose` | 输出完整 JSON |

### fsd task list

| 参数 | 说明 |
|------|------|
| `--page <n>` | 页码（默认 1） |
| `--size <n>` | 每页大小（默认 20） |
| `-n, --name <keyword>` | 任务名称关键词 |
| `-s, --status <status>` | 状态过滤（逗号分隔） |
| `--subtype <type>` | 任务类型过滤（支持中文/英文/别名） |
| `--assigned <mis>` | 负责人 MIS |
| `--created-by <mis>` | 创建人 MIS |
| `-p, --project-id <id>` | 空间 ID |
| `-r, --req-id <reqId>` | 父需求 ID |
| `--schedule-range <range>` | 排期筛选：`today`/`this-week`/`next-week`/`YYYY-MM-DD`/`YYYY-MM-DD~YYYY-MM-DD` |
| `--pretty` | 表格格式输出 |

### fsd task detail

| 参数 | 说明 |
|------|------|
| `-i, --id <taskId>` | 必填，任务 ID |
| `--pretty` | 人类可读格式输出 |
| `-v, --verbose` | 输出完整 JSON |

### fsd task update

| 参数 | 说明 |
|------|------|
| `-i, --id <issueId>` | 必填，任务 ID |
| `-n, --name <name>` | 修改名称 |
| `--priority <n>` | 优先级（1-低, 2-中, 3-高, 4-紧急） |
| `-a, --assigned <mis>` | 负责人 MIS |
| `--data <json>` | 其他字段以 JSON 传入 |
| `-v, --verbose` | 输出完整 JSON |

`--data` 常用字段：

| 字段名 | 类型 | 说明 |
|--------|------|------|
| description | String | 任务描述（HTML） |
| cc | List\<String\> | 抄送人 MIS |
| tester | String | 测试人员 MIS |
| developer | String | 开发人员 MIS |
| expectStart | Long | 预计开始（毫秒） |
| expectClose | Long | 预计结束（毫秒） |
| expectTime | Double | 预计工作量（人天），清空传 `0` |
| parentId | Integer | 父需求 ID |
| iterationId | Long | 迭代 ID，`-1` 清空 |
| customField14076 | String | 研发负责人（rdMaster） |
| customField12144 | String | 测试负责人（qaMaster） |

### fsd task delete

| 参数 | 说明 |
|------|------|
| `-i, --id <issueId>` | 必填，任务 ID |

### fsd task edit-schedule

| 参数 | 说明 |
|------|------|
| `-i, --id <issueId>` | 必填，任务 ID |
| `--task-type <type>` | 任务类型（不传则使用已有类型） |
| `--start-time <ts>` | 排期开始时间 |
| `--end-time <ts>` | 排期结束时间 |
| `--schedule <json>` | 多阶段排期 JSON |
| `--clear <fields>` | 清空指定阶段（逗号分隔阶段名） |
| `-v, --verbose` | 输出完整 JSON |

### fsd task stage

| 参数 | 说明 |
|------|------|
| `-i, --id <issueId>` | 必填，任务 ID |
| `--to <targetState>` | 目标状态名称（不传则展示可流转列表） |
| `--form <json>` | 表单字段 JSON |
| `-v, --verbose` | 输出完整 JSON |

### fsd task create-branch

| 参数 | 说明 |
|------|------|
| `-b, --branch <name>` | 必填，目标分支名称 |
| `-f, --from <branch>` | 迁出分支（默认 master） |
| `-j, --job-name <name>` | 服务名称（默认从 Git 推导） |
| `-i, --id <issueId>` | 关联工作项 ID（自动绑定） |

### fsd task bind-branch

| 参数 | 说明 |
|------|------|
| `-i, --id <onesId>` | 必填，任务 ID |
| `-b, --branch <name>` | 分支名称（默认当前分支） |
| `-g, --git <url>` | Git 仓库地址（默认当前工程） |
| `-j, --job-name <name>` | 服务名称 |

> 在 Git 仓库目录下执行时，`-b` 和 `-g` 自动获取，只需传 `-i`。

---

## 排期时间规则

1. 禁止 AI 自行生成任何时间值（包括"今天"、"一周后"等）
2. 用户明确说出日期后，直接将日期字符串传给 CLI，禁止自行计算毫秒时间戳
3. 用户给出的日期没有年份时默认当年，CLI 支持短格式（`3.1`、`3/1`、`3-1`）
4. 有必填阶段时，至少填写一个必填阶段（**非全部必填阶段都要填**）；没有必填阶段时任意阶段均可
5. `--start-time`/`--end-time` 只传一对时间，自动写入第一个必填阶段；多阶段用 `--schedule`
6. 产品/设计任务给了时间段但未给工作量时，CLI 自动按工作日计算 PD

---

## 错误处理

| 错误类型 | 建议 |
|----------|------|
| taskType 为空 | 指定 --task-type |
| 缺少父需求 | developOnline/qaOnline/product/design 须传 -r |
| 无法获取空间 | 传 -p 或确保 -r 对应的需求存在 |
| 排期记录不存在 | `任务对应的排期id不能为空` |
| 排期被删除 | `排期id不存在，请刷新后重试` |
| 目标状态不可达 | 检查 --to 是否与 nextStateName 一致 |
| 401/403 | 确认登录态有效 |

---

## 使用示例

### 创建任务

```bash
# 开发任务（关联需求）
fsd task create -p 48364 -n "开发登录模块" --task-type developOnline -r 90689902

# 测试任务
fsd task create --task-type 测试 -r 90689902

# 默认任务（无需关联需求）
fsd task create --task-type 默认
```

### 创建任务（带排期）

```bash
# 简单模式（填入第一个必填阶段）
fsd task create --task-type qaOnline -r 93990227 --start-time 2026-04-01 --end-time 2026-04-05

# 多阶段模式
fsd task create --task-type 开发 -r 90689902 --schedule '{"techDesign":["2026-04-01","2026-04-05"],"rdStartEndTime":["2026-04-06","2026-04-16"]}'

# 短日期格式
fsd task create --task-type qaOnline -r 93990227 --start-time 4.1 --end-time 4.5
```

### 查询任务列表

```bash
# 全部任务
fsd task list --pretty

# 进行中的测试任务
fsd task list -s "进行中" --subtype 测试任务 --pretty

# 按排期筛选
fsd task list --schedule-range today --pretty
fsd task list --schedule-range this-week --pretty
fsd task list --schedule-range 2026-03-25~2026-03-30 --pretty
```

### 修改任务

```bash
# 快捷字段
fsd task update -i 93972200 -n "接口联调V2" --priority 4 -a zhangsan

# 通过 --data 修改其他字段
fsd task update -i 93972200 --data '{"description":"<p>接口联调</p>","expectTime":3.5}'

# 混合使用
fsd task update -i 93972200 -n "支付重构" --priority 3 --data '{"cc":["lisi","wangwu"]}'
```

### 修改排期

```bash
# 单阶段
fsd task edit-schedule -i 93972200 --task-type developOnline --start-time 2026-04-01 --end-time 2026-04-05

# 多阶段
fsd task edit-schedule -i 93972200 --task-type developOnline --schedule '{"techDesign":["2026-04-01","2026-04-05"],"rdStartEndTime":["2026-04-05","2026-04-15"]}'

# 清空排期
fsd task edit-schedule -i 93972200 --task-type developOnline --clear techDesign,rdStartEndTime
```

### 流转状态

```bash
# 查看可流转状态
fsd task stage -i 93972200

# 流转到进行中
fsd task stage -i 789012 --to "进行中"
```

### 分支操作

```bash
# 创建分支
fsd task create-branch -b feature/login -i 93972182

# 绑定分支到任务（Git 仓库下执行）
fsd task bind-branch -i 93972182
```
