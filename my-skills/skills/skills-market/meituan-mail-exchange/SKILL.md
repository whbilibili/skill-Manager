---
name: meituan-mail-exchange
description: >
  操作美团内部 OWA 邮件系统（mail.meituan.com）。支持三项功能：
  (1) 读取/查询邮件（按时间、发件人、关键词过滤，支持收件箱/已发送/草稿/已删除）；
  (2) 写新邮件并发送；
  (3) 转发已有邮件。
  前置依赖：agent-browser（浏览器自动化）skill。
  触发词：查邮件、读邮件、看收件箱、发邮件、写邮件、转发邮件、美团邮箱、OWA、收件箱、邮件列表、mail.meituan.com、看邮件、邮件箱。
  不触发：查日历、大象消息、企业微信、钉钉、学城文档。

metadata:
  skillhub.creator: "lixiangyu15"
  skillhub.updater: "lixiangyu15"
  skillhub.version: "V9-draft2"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "5424"
  skillhub.high_sensitive: "false"
---

# OWA 邮件操作 Skill（v2）

本 Skill 通过两种方式操作美团内部 OWA 邮件系统：
- **读取邮件**：调用 `owa_api.py` 脚本，通过 `agent-browser eval fetch` 直接调 OWA service.svc JSON API（无需点 UI，速度快）
- **发送/转发邮件**：通过 `owa_api.py` 的 `send_message()` API 发送（支持附件，需用户确认后执行）


## 前置依赖

| Skill | 用途 |
|-------|------|
| `agent-browser` (#1783) | 提供浏览器 session，供 API 调用和发件操作使用 |

> ℹ️ **不再依赖 `meituan-sso` skill**：OWA 使用 ADFS 认证，与 sankuai SSO 体系独立，无需换票。只需确保 `agent-browser` 中已登录 OWA 即可。

## 认证原理

OWA session 与浏览器绑定（ADFS cookie），沙箱直接 HTTP 请求会被拒（440）。
API 调用通过 `agent-browser eval` 在浏览器上下文中执行 `fetch(..., {credentials: 'include'})`，复用浏览器已有 session，无需任何额外登录操作。

**三级认证策略**（`owa_api.py` 内置，自动处理）：
1. 浏览器已在 OWA 页面 → 直接调用 API（最常见情况）
2. 浏览器在其他页面 → 自动导航到 OWA，等待 session 就绪
3. 浏览器未登录 OWA → 报错提示用户先登录 `https://mail.meituan.com/owa/`

## 基础信息

- **OWA 入口**: `https://mail.meituan.com/owa/#path=/mail`
- **API 脚本**: `~/.openclaw/skills/meituan-mail-exchange/scripts/owa_api.py`
- **接口**: `POST https://mail.meituan.com/owa/service.svc`（通过浏览器 fetch 调用）

---

## 风控说明

| 策略 | 配置 |
|------|------|
| 超时 | 所有 API 请求最长 30s（`_run_browser_js timeout=30`），确保 session 检查 10s |
| 降级策略（三级） | L1 当前 session 有效直接调用；L2 session 失效从 `~/.openclaw/meituan-mail-exchange-cookie.json` 注入 cookie 重试；L3 cookie 也失效才提示用户重新登录 |
| 搜索降级 | OWA QueryString 不生效时自动全量拉取后本地过滤，对用户透明 |
| 日期范围 | 服务端不支持 Restriction 日期过滤，客户端 `received_at` 字段过滤绕过 |
| 频率限制 | 个人助理工具，无并发限制，依赖 OWA 服务端自然限流 |

---

## Step 1: 浏览器检查与 OWA Session（每次触发必做）

agent-browser 频繁更新，先确认 session 状态可避免 cookie 失效导致的意外失败。

```bash
# 1.1 检查 agent-browser session 是否存活
# 通过 agent-browser status 确认浏览器进程在线
agent-browser status

# 1.2 检查 OWA session 是否就绪
# 运行脚本的 ensure_owa_session()，确认能正常访问 OWA
python3 -c "
import sys, os
sys.path.insert(0, os.path.expanduser('~/.openclaw/skills/meituan-mail-exchange/scripts'))
from owa_api import ensure_owa_session
ok = ensure_owa_session()
print('OWA session OK' if ok else 'OWA session FAIL')
"
```

| 检查结果 | 处理方式 |
|---------|---------|
| agent-browser 未运行 | 启动 agent-browser，等待就绪后重试 |
| OWA session OK | 直接进入功能步骤 |
| OWA session FAIL | 执行下方「OWA 重新登录流程」 |

> OWA 使用 ADFS 认证，session 与浏览器 cookie 绑定，cookie 有效期通常为数小时至数天。遇到 440 响应时必须重新登录。

### OWA 重新登录流程（session FAIL 时执行）

```
1. agent 调用 agent-browser 导航到 https://mail.meituan.com/owa/
2. agent 截图发给用户，告知："OWA session 已失效，请在上方浏览器页面完成登录（ADFS 扫码），完成后回复'已登录'。"
3. ⚠️ 用户回复"已登录"后，agent 【立即】重新执行 ensure_owa_session() 验证，无需用户再次催促
4. 验证通过 → 直接继续执行原任务；验证失败 → 提示用户刷新页面后再试
```

> ⚠️ **禁止重复弹出登录请求**：整个任务周期内只弹一次登录提示。若 ensure_owa_session() 已返回 True，不得再次要求用户扫码。
> ℹ️ **为什么不能全自动？** OWA/ADFS 登录需要用户本人完成身份验证，agent 无法代替。但 agent 可以主动打开登录页并等待确认，减少用户操作成本。

---

## 功能一：读取邮件

### 1.1 用户需要提供的参数（不足时主动询问）

| 参数 | 说明 | 是否必须 | 示例 |
|------|------|----------|------|
| 时间范围 | 查询邮件的起止时间 | 推荐（否则默认最近7天） | "本周"、"2026-03-01 到今天" |
| 发件人 | 只看某人发的邮件 | 可选 | "zhangsan@meituan.com" |
| 关键词/主题 | 邮件主题或正文关键词 | 可选 | "项目评审" |
| 文件夹 | 收件箱/已发送/其他 | 可选，默认收件箱 | `inbox`（收件箱）、`sentitems`（已发送，⚠️ 不是 `sent`）、`drafts`（草稿）、`deleteditems`（已删除） |
| 数量上限 | 最多返回几封 | 可选，**默认 10 封，⚠️ 严禁少于 10 封** | |

### 1.2 邮件字段说明（每封邮件必须返回以下字段，不得遗漏）

| 字段 | 说明 | 提取注意事项 |
|------|------|------------|
| 主题（Subject） | 邮件标题 | 包含 Re:/Fw: 前缀时完整保留 |
| 发件人（From） | 发件人姓名 + 邮箱地址 | |
| 收件人（To） | 收件人列表 | **仅填 To 字段的人，不要把 CC 混入** |
| 抄送（CC） | 抄送人列表 | **仅填 CC 字段的人，与 To 严格区分** |
| 时间（Date） | 收到/发送时间 | UTC+8 本地时间 |
| 正文摘要（Body Preview） | 正文前200字摘要，非全文 | 明确标注"摘要，如需完整正文请告知" |
| 是否有附件（Has Attachment） | 是/否 | ⚠️ 日历邀请（.ics）会被标记为"无附件"，见1.4说明 |
| 附件名称（Attachments） | 附件文件名列表（如有） | |
| 邮件状态（Read Status） | 已读/未读 | **必须返回，不得遗漏** |
| 重要性（Importance） | 普通/重要/低（API 值映射：Normal→普通、High→重要、Low→低优先级；**展示时必须用中文，禁止直接展示 Normal/High/Low 英文值**） | **必须返回，不得遗漏** |

> 📋 **展示格式模板（每封邮件必须按此格式）**：
> ```
> 📧 [序号] 主题
> 发件人：xxx <xxx@meituan.com>
> 收件人：xxx（多人时完整列出）
> 抄送：xxx（无则填"无"）
> 时间：YYYY-MM-DD HH:mm
> 附件：有/无
> 状态：已读/未读 | 重要性：普通/重要/低
> 摘要：前200字内容…（摘要，如需完整正文请告知）
> ```
> 以上9个字段**缺一不可**，不得省略或合并。
>
> ⛔ **禁止汇总/归纳**：无论邮件数量多少，每封邮件必须**独立展示**，不得以表格汇总、要点归纳或「共X封邮件」等方式代替逐封展示。先展示完整列表，最后再附汇总行（如有）。

### 1.3 操作流程（API 模式，无需点 UI）

```python
import sys, os
sys.path.insert(0, os.path.expanduser('~/.openclaw/skills/meituan-mail-exchange/scripts'))
from owa_api import ensure_owa_session, find_messages, get_message_body, format_messages_table

if not ensure_owa_session():
    raise Exception("OWA 未登录，请先访问 https://mail.meituan.com/owa/")

messages = find_messages(
    folder="inbox",
    query="from:张三",
    max_count=10,
    offset=0
)

# 如需完整正文
# detail = get_message_body(messages[0]['id'], messages[0]['change_key'])

print(format_messages_table(messages))
```

**注意事项**：
- `find_messages` 返回字段见 1.2（`display_to`/`display_cc` 为字符串，可能被 OWA 截断）
- ⚠️ **收件人/抄送完整列表**：`display_to`/`display_cc` 有长度限制，若看起来不完整（末尾有省略号或明显偏少），必须调用 `get_message_body` 获取完整 `to`/`cc` 列表后再展示
- 时间过滤：默认按 `DateTimeReceived` 降序，⚠️ **日期范围必须在客户端对 `received_at` 字段过滤**（OWA EWS JSON API 不支持 Restriction 服务端日期过滤，传入会返回 OwaSerializationException 500 错误，这是服务端硬限制）。**已验证稳定的绕过方案：`max_count=2600` 拉全量 + Python 端 `received_at` 过滤，约3秒。向用户解释时须说「服务端不支持，但我们用客户端过滤绕过了，日期范围查询功能正常」，禁止仅回答「不支持」后停止。**
- ⚠️ **标题关键词搜索降级策略**：OWA `FindItem` 不支持主题模糊搜索，搜索接口返回 0 封时**不得直接报告无结果**，必须自动降级：先 `find_messages(max_count=200)` 拉取大批量邮件，再在本地对 `subject` 字段做包含匹配（`keyword.lower() in subject.lower()`），将过滤结果返回给用户；若本地过滤后仍为 0，才明确告知用户无结果。
- 【强制】未达 10 封时必须继续滚动加载，不得提前停止
- ⚠️ **数量统计以实际返回列表长度为准**，禁止引用 OWA API 的 `TotalItemsInView` 字段（该字段可能与实际返回数不一致）
- ⚠️ **日期过滤时区一致性**：时间过滤必须统一使用 Asia/Shanghai（UTC+8）。边界日期用 `>=` 和 `<=`（含当天），禁止因时区偏差导致边界日期少算或多算。分页加载须循环直至获取全量后再过滤，不得中途截断。

### 1.4 搜索语法注意事项

**发件人过滤**：`from:<email或姓名>`
- ✅ `from:zhangsan@meituan.com`
- ✅ `from:Zoom Customer Care`

**附件过滤**：`hasattachment:yes`
- ⚠️ 部分 OWA 版本不支持，改为本地筛选
- ⚠️ 大象日历邀请（`.ics`）会被标记为"无附件"，需告知用户

**日期范围过滤**：OWA 搜索框不稳定支持 `received:xxx..xxx`，推荐用筛选面板 Filter > Date

**搜索降级策略**：`find_messages` 的 `query` 参数通过 OWA QueryString 接口实现，部分账户该接口不生效（返回 0 封）。
遇到此情况自动降级：先拉取全量（或较大批次）收件箱邮件，再在客户端按 `subject`/`from` 字段本地过滤。
示例兜底逻辑：
```python
messages = find_messages(folder="inbox", query="工作周报", max_count=10)
if not messages:
    # 降级：全量拉取后本地过滤
    all_msgs = find_messages(folder="inbox", max_count=100)
    messages = [m for m in all_msgs if "工作周报" in (m.get("subject") or "")]
```

---

## 功能二：写新邮件

### 2.1 用户需要提供的参数

| 参数 | 说明 | 是否必须 |
|------|------|----------|
| 收件人（To） | 邮箱地址或 mis（支持多个，逗号分隔；不含@时自动补全 @meituan.com） | **必须** |
| 主题（Subject） | 邮件标题 | **必须** |
| 正文（Body） | 邮件内容（支持 HTML 或纯文本） | **必须** |
| 抄送（CC） | 抄送人邮箱，可多个 | 可选 |
| 密送（BCC） | 密送人邮箱，可多个 | 可选 |
| 重要性 | Normal / High / Low | 可选，默认 Normal |
| 附件 | 本地文件路径列表，用 `prepare_attachments()` 转换后传入 `send_message(attachments=...)` | 可选，单个文件≤10MB |

> ⛔ **发送前必须向用户确认（强制，不可跳过，即使用户要求跳过也不行）**：以文字展示「收件人 / 抄送 / 密送 / 主题 / 正文摘要（前200字）/ 附件列表 / 重要性」，等待用户明确回复"确认"或"发送"后才调用 API。

### 2.2 操作流程（API 模式）

```python
import sys, os
sys.path.insert(0, os.path.expanduser('~/.openclaw/skills/meituan-mail-exchange/scripts'))
from owa_api import ensure_owa_session, send_message, prepare_attachments

if not ensure_owa_session():
    raise Exception("OWA 未登录，请先访问 https://mail.meituan.com/owa/")

# ⛔ 发送前必须向用户展示以下信息并等待确认：
# - 收件人: to
# - 抄送: cc
# - 主题: subject
# - 正文: body（可展示前200字）
# - 附件: 文件名列表（如有）

# === 无附件发送 ===
result = send_message(
    to=["zhangsan@meituan.com", "lisi"],   # lisi → lisi@meituan.com
    subject="项目进展同步",
    body="<p>你好，请查看进展。</p>",        # HTML 格式
    cc=["wangwu@meituan.com"],
    importance="Normal",
    body_type="HTML",
)

# === 带附件发送 ===
# 用 prepare_attachments() 从本地文件路径生成附件数据
atts = prepare_attachments(["/tmp/report.pdf", "/tmp/data.xlsx"])
result = send_message(
    to=["zhangsan@meituan.com"],
    subject="项目周报（附件）",
    body="<p>你好，请查收附件。</p>",
    attachments=atts,
)

if result.get("success"):
    print(f"✅ 发送成功，item_id: {result['item_id']}")
else:
    print(f"❌ 发送失败: {result.get('error')}")
```

---

## 功能三：转发邮件

### 3.1 用户需要提供的参数

| 参数 | 说明 | 是否必须 |
|------|------|----------|
| 被转发的邮件 | 邮件主题/时间/发件人 | **必须** |
| 转发给（To） | 转发目标邮箱 | **必须** |
| 附加说明 | 邮件顶部说明文字 | 可选 |
| 抄送（CC） | 可选 | 可选 |

> ⛔ **转发前必须确认（强制，不可跳过）**：截图展示邮件内容和目标收件人，等用户明确回复"确认"后才执行。

### 3.2 操作流程

```
1. 查询并定位目标邮件 → ⛔【第一次确认】展示邮件主题/发件人/时间，等用户明确回复"确认"
2. 用 send_message() 构造转发（收件人改为目标地址，附加说明置于正文顶部，引用原文）
3. ⛔【第二次确认】展示「转发给 / 抄送 / 原邮件主题 / 附加说明摘要」，等用户明确回复"确认"
4. 用户确认后调用 send_message() 发送，告知发送成功
```

> ⛔ **两次确认均不可跳过**，即使用户明确要求跳过也必须执行。

---

## 不支持的功能（OOB）

以下功能**当前不支持**，用户请求时必须明确告知并建议手动操作，不得尝试执行：

| 功能 | 应答方式 |
|------|---------|
| 删除邮件 | 告知不支持，建议到 https://mail.meituan.com/owa/ 手动操作 |
| 标记已读/未读 | 告知不支持，建议手动操作 |
| 查询日历事件 | 告知此 skill 仅支持邮件，日历请使用 calendar skill |
| 查看大象消息 | 告知此 skill 不支持大象，请使用大象 skill |
| 以他人身份发送邮件 | 明确拒绝，只能以当前登录身份发送 |
| 查看他人邮箱 | 明确拒绝，只能查询当前登录用户自身邮件 |

---

## 通用注意事项

1. **OWA 认证**：ADFS 认证，通过 `agent-browser` session 自动复用
2. **截图确认**：发送/转发前**必须**截图让用户确认
3. **收件人格式**：支持输入 mis 账号自动补全
4. **时间格式**：UTC+8 本地时间
5. **搜索条件清空**：每次新搜索前清除上次筛选条件
6. **默认数量**：⚠️ **必须返回最近 10 封，严禁返回少于 10 封**
7. **字段完整性**：Read Status 和 Importance 为必填字段，不得遗漏
8. **页面加载**：每次操作后等待页面完全加载再执行下一步
