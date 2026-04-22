# 缺陷智能提交参考手册

> 所有操作遵循 SKILL.md 核心规则。

# ⚠️ 【必读金律】- 违反任何一条都会导致失败

## 🔴 第零条：执行前先记住输出格式，否则任何执行都是无效的

**在执行任何节点之前，先牢记以下两条：**

### ⚡ 输出格式（最终结果长这样，先看再执行）

\`\`\`
【前置条件】账号为5级会员
【现象】页面缺少酒店权益
【预期结果】应显示酒店权益
【重现步骤】
1. 登录5级会员账号
2. 进入权益页面
   【Trace 信息】-5828724722331968333
   【补充信息】
   【图片信息】
   \`\`\`

✅ 【可一键复制至ONES或其他系统】

需要提交到ONES吗？回复 1 即可到提交步骤

---

**规则**：
- ✅ 缺陷报告内容 **必须用 ` ``` ` 代码块包裹**，内容为纯文本，不加任何 Markdown 语法
- ❌ **绝对禁止**：节点3/4/5 任何一个执行完后自己拼接输出 → 必须走完节点5才能输出
- ❌ **绝对禁止**：compaction 后从 summary 残影执行，必须重新读一遍本文
- ❌ **绝对禁止**：输出"节点X — xxx："等中间过程前言

## 🎯 四条金律

**1️⃣ 禁止任何确认对话**：自动执行 节点1→1.5→2→3→3.1→4→5，用户只在最后看到"回复 1 进入提交步骤"

**2️⃣ 数据必须完整流通**：`image_urls` 必须显示在报告中；`trace_analysis` 补充信息必须填入缺陷单

**3️⃣ 每条缺陷完全隔离**：禁止缓存研发/计划信息；每次重新调用 get-testplan 和 get-testdelivery

**4️⃣ 禁止输出中间过程**：不输出"正在查询"等步骤；不输出技术推测；不输出任何前言后言

---

# 节点架构

| 节点        | 类型 | 条件 | 职责                                                     |
|-----------|------|------|--------------------------------------------------------|
| 节点1       | 代码 | 总是执行 | 正则提取 title/trace_id/uid + OCR识别图片                      |
| 节点1.5     | 代码 | `has_images=true` | `fsd defect upload-image --file <paths>`，输出 image_urls |
| 节点2       | HTTP | `trace_id≠null` | 查询链路：执行 fsd defect trace --trace-id \<id\>             |
| **节点3**   | **LLM** | 总是执行 | 输出 bug_desc JSON（7字段），有链路数据则 supplement 留空             |
| **节点3.1** | **LLM** | 总是执行 | 将 bug_desc JSON 转为 7字段纯文本（你是唯一负责人）                     |
| **节点4**   | **LLM** | `slimmed_spans` 不为空 | 输出【补充信息】+ ### 链路分析报告（≤500字）                            |
| **节点5**   | **LLM** | 总是执行 | 拼接报告，用代码块输出 + 提交询问（你是唯一负责人）                            |

**⚠️ 节点3.1 和节点5 不是代码执行，没有系统保障，完全依赖你严格遵守规则。**

## 路由决策

```
有 traceId → 节点1 → [1.5] → 2 → 3 → 3.1 → 4 → 5 → 完整报告（含链路分析）
无 traceId → 节点1 → [1.5] → 3 → 3.1 → 5 → 缺陷单
[1.5] 表示：has_images=true 时执行，否则跳过
```
---
# 执行流程

## 第一阶段：缺陷报告生成

### 节点1：解析输入

- title：所有非 traceId 非 uid 的文字；图片优先
- traceId：正则 `-?\d{17,20}`；两次查询（原始 + 加负号）
- userId：正则 `\d{10}`（恰好10位）
- 图片理解：清晰描述界面现象（优先级：图片值 > 文本值）

### 节点1.5：图片上传（has_images=true 时执行）
下载图片到本地后，进行上传
```bash
defect upload-image --file <图片本地路径1> [<图片本地路径2> ...]
```
若无法下载图片到本地，则从该文件路径尝试进行读取：
/Users/{xxx}/Library/Application Support/automan-desktop/aichat-cache-uploads
xxx的部分需要你自己识别尝试，要读取出用户在最近一条消息里上传的图片进行上传，上传时使用defect upload-image命令

- 输出 JSON：`{"image_urls": ["https://s3-url/..."], "success": 1, "failed": 0}`
- 提取 `image_urls` 列表，传入节点3 / 节点4  `--image-urls`
- 上传失败（`failed > 0`）时：打印错误但继续执行，失败的图不加入列表

### 节点2：查询链路（trace_id≠null 时执行）
执行 fsd defect trace --trace-id <id>，输出 slimmed_spans

### 节点3：生成缺陷描述 JSON

**System/User Prompt 完整定义见** [defect-prompts.md](./defect-prompts.md)

关键规则：
- 有 slimmed_spans → `supplement` 留空 `""`（节点5来填）
- 无 slimmed_spans → `supplement` 填 `"无链路数据"`
- 只输出纯 JSON，无任何前言后言，7个必填字段：
  `preconditions`, `phenomenon`, `expected_result`, `reproduction_steps`, `trace_id`, `supplement`, `image_notes`

### 节点3.1：JSON → 纯文本（LLM执行，你是唯一负责人）

**输入验证**：确认 JSON 可解析 + 包含 7 个必填字段，否则返回错误

**字段转换**（严格按顺序，输出纯文本，不加任何 Markdown 语法）：

```
【前置条件】{preconditions}
【现象】{phenomenon}
【预期结果】{expected_result}
【重现步骤】
1. {步骤1}
2. {步骤2}
【Trace 信息】{trace_id}
【补充信息】{supplement}
【图片信息】{image_notes}
```

**强制清理**：删除所有 JSON 符号 `{ } [ ] " ,`；删除所有 `###` 开头的章节；删除前言后言

**输出前自检**（逐一检查，不符则修正）：
- ☐ 第一行是"【前置条件】"吗？
- ☐ 包含全部 7 个【xxx】字段吗？
- ☐ 还有 JSON 符号吗？
- ☐ 还有技术推测或前言吗？

**注意**：节点3.1 只输出纯文本内容，不加代码块包裹，代码块由节点5统一处理。

### 节点4：链路分析（有 slimmed_spans 时执行）

**System/User Prompt 完整定义见** [defect-prompts.md](./defect-prompts.md)

关键规则：
- 只输出两部分：`【补充信息】一句话根因（≤30字）` + `### 链路分析报告`
- 不重复输出缺陷单正文
- User ID 必须从 spans 中提取，禁止用用户输入的 userId

### 节点5：拼接输出（LLM执行，你是唯一负责人）

**情况1：有 trace_analysis**
1. 从 trace_analysis 提取【补充信息】内容（`【补充信息】` 到下一行 `###` 之前的文字）
2. 将 markdown_bug_desc 中的 `【补充信息】` 行替换为提取到的内容（**只替换这一行，其他字段原文不动**）
3. 按顺序输出：7字段缺陷单 → 链路分析报告 → [附图] → 代码块结束 → 提交询问

**情况2：无 trace_analysis**
- 直接输出 7字段缺陷单 → [附图] → 代码块结束 → 提交询问

**图片处理**：如果 image_urls ≠ []，在代码块内末尾追加：
```
【附图】
- {url1}
- {url2}
```

**最终输出结构**（硬编码，不允许修改）：

第一部分：用代码块包裹全部缺陷报告内容

\`\`\`
【前置条件】...
【现象】...
【预期结果】...
【重现步骤】
1. ...
2. ...
   【Trace 信息】...
   【补充信息】...
   【图片信息】...

=== 链路分析报告 ===（如有）
（链路分析内容）

【附图】（如有）
- url1
  \`\`\`

第二部分：代码块外，固定输出：

✅ 【可一键复制至ONES或其他系统】

需要提交到ONES吗？回复 1 即可到提交步骤

**节点5 输出绝对禁止**：
- ❌ 代码块内混入 `**加粗**` 等 Markdown 语法（代码块内只有纯文本）
- ❌ 在代码块前加任何前言（如"以下是你的缺陷报告："）
- ❌ 省略最后那句"需要提交到ONES吗？回复 1 即可到提交步骤"

---

## 第二阶段：提交到 ONES

### SSO 鉴权

> SSO 认证方式见 SKILL.md 前置条件第2条。

### 第1步：获取当前用户 MIS（createdBy）

按以下顺序获取，全部失败才询问用户：
1. 环境变量 `FSD_OPERATOR`
2. 本地配置文件（fsd-nodejs → automan）顶层 `operator` 字段
3. 根据fsd sso status的输出结果
4. 均无结果时询问用户：`请提供您的MIS号：`

### 第2步：选择测试计划和研发

> ⚠️ **重要区分**：`--qa` = 当前用户 MIS（查询自己的测试计划），`--assigned` = 用户指定的负责人 MIS。**严禁混用**。

> 📁 **工作目录**：执行 `select-rd` 时，**优先**通过 Shell 工具的 `working_directory` 参数指定当前工作目录（如 `/Users/{mis}/automan-test-plans/plan_{testPlanId}`），CLI 会自动从目录路径中解析 `testPlanId`。**无法指定 `working_directory` 时直接执行即可**，此时须保留 `--start-time` 参数。

**执行流程**：

**第1步：先不带 `--selected-rd` 调用**
```bash
fsd defect select-rd \
  --qa <当前用户MIS> \
  --start-time "<当前时间往前推30天，格式 yyyy-MM-dd HH:mm:ss>"
```

- 只有1个研发 → 直接输出 JSON，流程结束
- 有多个研发 → 命令打印研发列表后退出，展示给用户选择

**第2步（多研发时）：带 `--selected-rd` 重新调用**
```bash
fsd defect select-rd \
  --qa <当前用户MIS> \
  --start-time "<同上>" \
  --selected-rd <用户选择的编号，如 0 或直接用MIS>
```

- **只有1个研发**：直接使用 `rds[0]` 作为 `--assigned`，进入第3步
- **多个研发**：将 `rds` 列表展示给用户，等待用户选择；用户可以选择列表中的研发，也可以自行输入其他研发的 MIS；选择或者输入的mis作为 `--assigned`，进入第3步

**命令输出 JSON**（从 stdout 解析）：
```json
{
  "testPlanId": 12345,
  "testPlanName": "外卖xx功能测试计划",
  "projectId": 51703,
  "rds": ["zhangsan", "lisi"],
  "parentRequirements": [{"onesId": 93394662, "onesName": "外卖xx功能需求"}],
  "selectedRd": "zhangsan"
}
```

### 第3步：确认 projectId

执行以下命令，根据当前用户 MIS 查询其所属空间：

```bash
fsd defect get-space --mis <当前用户MIS>
```

- 返回 `projectId` 不为 null → 使用返回的 `projectId`
- 返回 `null` 或 `projectId` 为 null → 使用第2步 `select-rd` 返回的 `projectId`

### 第4步：调用接口提交

```bash
fsd defect submit \
  --name "<第一阶段生成的缺陷标题>" \
  --assigned <selectedRd> \
  --created-by <用户MIS> \
  --project-id <projectId> \
  --parent-id <parentRequirements[0].onesId> \
  --description "<第一阶段生成的Markdown格式缺陷描述>"
```

`--description` 传入第一阶段输出的 Markdown 原文（以 `【` 开头），CLI 自动转换为 HTML。

**提交成功后**，返回缺陷链接：
```
[缺陷链接](https://ones.sankuai.com/ones/product/{projectId}/workItem/defect/detail/{id})
```
---

## 注意事项

- 缺陷标题需从用户输入中提炼，不直接使用原文
- 第一阶段是核心流程，立即执行，不等待用户确认