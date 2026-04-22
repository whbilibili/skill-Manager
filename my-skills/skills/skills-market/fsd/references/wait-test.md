# 提测管理参考手册

> 所有操作遵循 SKILL.md 核心规则。

## 命令速查

| 命令 | 用途 | 关键参数 |
|------|------|----------|
| `fsd waitTest list` | 获取待提测列表 | `--me` 只看与我相关；`--org` 组织ID；`--page/--size` 分页 |
| `fsd waitTest back` | 提测打回 | `-i` 提测单ID；`-r` 打回原因 |
| `fsd waitTest accept` | **仅**：把提测单挂到**已有**测试计划 | 必填：`-i`、`-w`；其余参数可省略，由 CLI 拉计划详情自动补全 |

---

## 接受提测意图路由

- 未指定要并进哪条**已有**计划 → `fsd test create --delivery-ids <提测单ID>`。
- 已锁定计划 ID（或先用 `test list` 解析名称）且要**追加**提测单 → `fsd waitTest accept -i <计划ID> -w <提测单ID>`；可选参数缺省时由 CLI 拉计划详情补全，**不必**为补参单独跑 `test detail`。`test update --delivery-ids` 传的是**整单**关联集合，适合明确要替换全集的场景，不等同于 join 的默认路径。

---

## fsd waitTest list — 获取待提测列表

### 参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--page <n>` | string | 否 | (默认值: 1) 页码，从 1 开始 |
| `--size <n>` | string | 否 | (默认值: 10) 每页条数 |
| `--me` | string | 否 | (默认值: false) 只看与我相关 |
| `--org <orgId>` | string | 否 | (默认值: 空) 按组织 ID 过滤 |
| `--status <s>` | string | 否 | (默认值: 空（全部）) 状态过滤 |
| `--pretty` | string | 否 | (默认值: —) 人类可读格式输出 |

### 决策树

```
用户请求查看待提测
├─ 说"与我相关/我的提测" → 加 --me
├─ 说"第N页/每页X条" → 加 --page / --size
└─ 默认查全部（第1页，每页10条）
```

### 输出（--pretty 模式）

```
待提测列表（共 6 条）：

  [25615] 测试标准交付度量1011
    提测单ID: 76530  状态: 待接收
    环境: staging  创建人: wanghe40  提测时间: 2023/10/11 18:30:36
    RD: liguan03,lixuesong05,mouyufei  QA: wanghe40
    链接: https://fsd.sankuai.com/deliveryDetail/76530
```

---

## fsd waitTest back — 提测打回

### 参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--id <deliveryPlanId>` / `-i` | string | 是 | 提测单 ID（list 结果中的 `id` 字段） |
| `--reason <reason>` / `-r` | string | 是 | 打回原因 |
| `--pretty` / `—` | string | 否 | 人类可读格式输出 |

### 输出结果

| 情况 | 说明 |
|------|------|
| 成功 | `code: 0`，打回完成 |
| 失败 | `code: -1`，`msg` 说明原因 |

---

## fsd waitTest accept — 将提测单加入已有测试计划

**前置**：用户已明确要并入某个**已有**测试计划；若用户只说「接受提测」而未指定计划，应走 **`fsd test create --delivery-ids`**（见 [接受提测意图路由](#接受提测意图路由)）。

### 参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `-i, --plan-id <id>` | string | 是 | 测试计划 ID（fsdTestplanId） |
| `-w, --wait-ids <ids>` | string | 是 | 待提测记录 ID 列表，多个逗号分隔（list 结果中的 `id` 字段） |
| `--env <env>` | string | 否 | `staging` / `test`；省略则从计划详情 `env` 补全，仍缺省则 `staging` |
| `--qa <mis>` | string | 否 | 测试参与人；省略则从计划详情 `qa` 补全，仍缺省则用当前 SSO 登录 mis |
| `--rd <mis>` | string | 否 | 研发参与人；省略则从计划详情 `rd` 补全，仍缺省则用当前 SSO 登录 mis |
| `--start <time>` | string | 否 | `YYYY-MM-DD HH:mm:ss`；省略则从计划详情 `expectStartTime` 补全 |
| `--finish <time>` | string | 否 | 同上，对应 `expectFinishTime` |
| `--online <time>` | string | 否 | 同上，对应 `onlineProjectTime` |
| `--cc <mis>` | string | 否 | 抄送人；不传且已拉取详情时尝试用计划详情 `cc` |
| `--auto-deploy` | string | 否 | 是否自动部署（默认否） |
| `--pretty` | string | 否 | 人类可读格式输出 |

### 决策树

```
并入已有计划：缺计划 ID → test list 按名称查；有 -i、-w 即可跑 accept（缺参由 CLI 补）
用户指定环境/人/时间 → 传对应可选参数；自动部署 → --auto-deploy
```

### 输出结果

| 情况 | 说明 |
|------|------|
| 成功 | `code: 0`，加入测试计划完成 |
| 失败 | `code: -1`，如"请排除掉提测打回或已加入测试计划的交付" |

---

## 使用示例

### 示例1：查看待提测列表

```bash
fsd waitTest list --pretty
fsd waitTest list --me --pretty          # 只看与我相关
fsd waitTest list --size 20 --pretty     # 每页 20 条
```

### 示例2：提测打回

```bash
fsd waitTest back -i 39983 -r "功能未完成，请修复后重新提测" --pretty
```

### 示例3：将提测单加入已有测试计划（waitTest accept）

最简（推荐，由 CLI 按计划详情补全 env/qa/rd/时间）：

```bash
fsd waitTest accept -i 64703 -w 25470 --pretty
```

显式传入（与旧版一致，用于覆盖计划默认值）：

```bash
fsd waitTest accept \
  -i 64703 \
  -w 25470 \
  --env staging \
  --qa lidongyan05,wanghong52 \
  --rd liguan03,lixuesong05 \
  --start "2025-12-03 15:00:00" \
  --finish "2025-12-04 18:00:00" \
  --online "2025-12-05 00:00:00" \
  --pretty
```

### 示例4：失败场景

```
错误: 接受测试计划失败 —— 请排除掉提测打回或已加入测试计划的交付:[开发任务-xxx]
```
→ 提示用户先通过 `waitTest list` 确认提测单状态，剔除已打回或已加入计划的条目。
