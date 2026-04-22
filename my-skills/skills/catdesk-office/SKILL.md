---
name: catdesk-office
description: >
  CatDesk 办公自动化 CLI。支持大象消息发送（含 @ 人、超链接）、群成员查询、邮件发送/联系人搜索、会议室查询/预订/取消/监测、查看已有日程。
  命令由 services.json 动态生成，运行 `catdesk --help` 查看最新命令列表。
  当用户提到发大象消息、@ 某人、发链接/发超链接、搜索联系人/群、查群成员、发邮件、发送邮件、搜索邮件联系人、订会议室、查会议室、取消会议室预订、查看我的日程/会议、监测空闲会议室时使用。
---

# catdesk -- CatDesk 办公自动化 CLI

> **Windows (CMD)**: Replace `catdesk` with `%USERPROFILE%\.catpaw\bin\catdesk.cmd` in all commands below.
>
> **Windows (PowerShell)**: `catdesk.cmd` is a CMD batch script. PowerShell 5.x strips quotes from JSON arguments when calling `.cmd` files. **Store JSON in a variable with escaped quotes:**
>
> ```powershell
> # 简单命令直接调用
> & "$env:USERPROFILE\.catpaw\bin\catdesk.cmd" daxiang search --keyword "zhangsan"
>
> # 含 JSON 参数的命令（如 --mentions），必须先存变量并转义双引号
> $mentions = '[{\"uid\":\"12345\",\"name\":\"张三\"}]'
> & "$env:USERPROFILE\.catpaw\bin\catdesk.cmd" daxiang send --group-id 67890 --message "请看一下" --mentions $mentions
> ```
>
> **PowerShell 续行**: 用 `` ` ``（反引号）替代 bash 的 `\`。**换行符**: PowerShell 中 `\n` 不会被解释为换行，邮件正文用 `` `n `` 替代。

命令从 `services.json` 动态生成，随时可能新增服务。首次使用或不确定参数时，先运行 `catdesk <service> <command> --help` 查看最新选项。

> ⚠️ 本文档所有示例中的 ID（user-id、group-id、uid、room-id、schedule-id 等）和 URL 均为虚构占位值，**绝对不要直接复制使用**。搜索不到目标、匹配到多个结果、或用户描述不明确时，**必须停下来向用户确认**，不得自行猜测或使用文档中的示例 ID。

在 CatPaw 内运行时自动连接内置浏览器（免登录）。

## 大象消息

### 发送流程

**判断是否需要搜索：**

- **已有精确 ID** —— 用户直接提供了 `user-id` 或 `group-id` → **跳过搜索，直接用 `--user-id` / `--group-id` 发送**
- **已有大象链接** —— 用户给出了 `https://x.sankuai.com/chat/<id>?type=chat` 或 `?type=groupchat` 形式的链接 → 从 URL 中提取 ID，**跳过搜索，直接用 `--user-id` / `--group-id` 发送**
  - `?type=chat` → 私聊，ID 即 `user-id`
  - `?type=groupchat` → 群聊，ID 即 `group-id`
- **只有名字或 MIS** —— 需要先搜索确认：
  1. **先搜索**：用 `catdesk daxiang search --keyword` 搜索目标用户或群
  2. **确认目标**：检查搜索结果中的 `name`、`mis`、`id` 字段
     - 如果有且仅有一个结果完全匹配（name 或 MIS 精确一致），可直接发送
     - 如果有多个结果，**必须停止发送先询问用户确认具体发给谁**
  3. **用 ID 发送**：确认后使用 `--user-id` 或 `--group-id` 发送

> ⚠️ **多人私聊必须串行发送**：如果需要依次给多个用户发送私聊消息，**必须逐个串行执行**（等前一个 `send` 命令完成后再执行下一个），**严禁并行发送**。因为底层实现依赖内置浏览器页面的会话定位，并行操作会导致页面状态互相干扰，出现消息发错人的严重问题。

```bash
# 已有精确 ID —— 直接发送，无需搜索
catdesk daxiang send --user-id 12345 --message "Hi!"
catdesk daxiang send --group-id 67890 --message "Hello!"

# 已有大象链接 —— 从 URL 提取 ID 后直接发送
# https://x.sankuai.com/chat/1234567?type=chat → --user-id 1234567
catdesk daxiang send --user-id 1234567 --message "Hi!"
# https://x.sankuai.com/chat/7654321?type=groupchat → --group-id 7654321
catdesk daxiang send --group-id 7654321 --message "Hello!"

# 只有名字/MIS —— 先搜索确认，再用 ID 发送
catdesk daxiang search --keyword "zhangsan"
# 确认匹配后，用搜索结果中的 ID 发送
catdesk daxiang send --user-id 12345 --message "Hi!"

# 也支持按名字直接发送（内部会自动 API 搜索 + 精确匹配，但多结果时可能选错）
catdesk daxiang send --user "zhangsan" --message "Hi!"
catdesk daxiang send --group "前端技术群" --message "Hello!"
```

### 发送 @ 消息

**@ 消息需要目标用户的 UID。** 获取 UID 有两种方式：

1. `catdesk daxiang search --keyword` 搜索用户，返回结果中包含 `id`（即 UID）
2. `catdesk daxiang members --group-id` 获取群成员列表，每个成员包含 `uid` 和 `name`

```bash
# Step 1: 获取群成员列表（找到目标人的 uid）
catdesk daxiang members --group-id 67890
# → { members: [{ uid: "12345", name: "张三", mis: "zhangsan" }, ...] }

# Step 2: 用 uid 发送 @ 消息
catdesk daxiang send --group-id 67890 --message "请看一下这个问题" \
  --mentions '[{"uid":"12345","name":"张三"}]'

# @ 多人
catdesk daxiang send --group-id 67890 --message "请大家看下" \
  --mentions '[{"uid":"12345","name":"张三"},{"uid":"67890","name":"李四"}]'

# @所有人（uid 使用 -1）
catdesk daxiang send --group-id 67890 --message "全员注意" \
  --mentions '[{"uid":"-1","name":"所有人"}]'
```

**--mentions 格式**：JSON 数组，每个元素为 `{"uid":"<UID>","name":"<显示名>"}`。UID 可从 `search` 或 `members` 命令获取。

### 发送超链接消息

消息中的 URL **默认自动转为可点击的超链接**。系统会自动获取页面标题作为链接显示文本，获取不到则保持 URL 原文。

```bash
# 默认：URL 自动变成超链接（自动获取页面标题）
catdesk daxiang send --group-id 67890 --message "请看 https://km.sankuai.com/collabpage/2750990140"
# → 发送: "请看 [页面标题|URL]"（标题可点击）

# 指定标题（跳过自动获取）
catdesk daxiang send --group-id 67890 \
  --message "请看 https://km.sankuai.com/collabpage/2750990140" \
  --link-title "技术方案文档"

# 发送纯文本（URL 不做超链接转换）
catdesk daxiang send --group-id 67890 \
  --message "请看 https://km.sankuai.com/collabpage/2750990140" \
  --plain-links
```

| 参数 | 说明 |
|------|------|
| （默认） | URL 自动识别，获取页面标题后转为 `[标题\|URL]` 超链接；获取不到则保持原文 |
| `--link-title <title>` | 指定标题（仅消息中只有一个 URL 时生效；多个 URL 时忽略，全部自动获取） |
| `--plain-links` | URL 原样发送为纯文本 |

### 查询群成员

```bash
# 获取群成员列表（返回 uid、name、mis）
catdesk daxiang members --group-id 67890
```

返回结果包含群内所有成员的 `uid`、`name`、`mis`，可用于构造 `--mentions` 参数。

### 发送文件/图片

#### 发送前必须确认文件路径

在执行发送命令之前，**必须完成以下检查，任一检查不通过则直接告知用户原因，禁止执行发送命令**：

1. **路径必须是绝对路径** —— `--file` 只接受以 `/` 开头的绝对路径（如 `/Users/xxx/Documents/report.pdf`）。如果用户给的是相对路径，**不要执行**，提示用户提供绝对路径
2. **模糊描述必须先确认** —— 如果用户说「桌面上的 xxx 文件」「下载目录里的 yyy」等模糊描述，**必须先用 `ls` 或 `find` 确认文件的完整绝对路径**，如果无法确定则**询问用户确认**，确认前**不要执行**
3. **发送前验证文件存在** —— 拿到绝对路径后，先用 `ls -la <path>` 确认文件确实存在。如果文件不存在，**不要执行**，告知用户文件未找到
4. **文件必须是单个文件（非目录）** —— `--file` 只接受单个文件路径，不支持目录。用 `ls -la` 确认目标是文件而非目录
5. **路径格式限制** —— 路径中不能包含未转义的特殊字符；如果路径含空格，需要用引号包裹

> **典型场景**：用户说「把桌面那个 PDF 发给张三」→ 先 `ls ~/Desktop/*.pdf` 列出候选 → 如果只有一个 PDF 则确认路径 → 如果有多个则询问用户选择 → 确认后再发送

#### 支持的文件类型

- **支持发送绝大多数单文件**，包括但不限于：图片、文档、压缩包、日志、代码文件、安装包等
- **图片类型**（上传后会弹出编辑确认框，脚本自动处理）：png、jpg、jpeg、gif、webp、bmp、svg
- **其他文件**：pdf、doc(x)、xls(x)、ppt(x)、zip、rar、tar、gz、7z、txt、csv、log、json、xml、yaml、yml、md、dmg、pkg、apk、ipa、mp3、mp4、mov、avi、sh、py、js、ts、java、go、sql 等——**只要是单个文件且文件存在即可发送**
- 无文件大小限制（底层使用本地 CDP 协议传输）

#### 文件和消息分开发送

**文件和文字消息是两次独立的发送操作。** 如果需要同时发文件和附带说明：

- **先发文件**：`catdesk daxiang send --user-id xxx --file /path/to/file`
- **再发文字**：`catdesk daxiang send --user-id xxx --message "请查看附件"`
- 两条命令**必须串行执行**（等文件发送完成后再发文字）
- 只发文件时**不需要** `--message` 参数

```bash
# 发送图片
catdesk daxiang send --user-id 12345 --file /Users/zhangsan/Desktop/screenshot.png

# 发送文件
catdesk daxiang send --group-id 67890 --file /Users/zhangsan/Documents/report.pdf

# 发送文件 + 附带说明（分两条命令，串行执行）
catdesk daxiang send --group-id 67890 --file /Users/zhangsan/Documents/report.pdf
catdesk daxiang send --group-id 67890 --message "请查看附件"

# 按名字发送图片（会先 API 搜索匹配）
catdesk daxiang send --user "zhangsan" --file /Users/lisi/Desktop/design.png
```

## 邮件发送

通过美团 OWA (Outlook Web App) 发送邮件。首次使用时会自动在内置浏览器中打开 mail.meituan.com 完成 SSO 登录。

**推荐：直接用 MIS 号发送。** `--to zhangsan` 会自动补全为 `zhangsan@meituan.com`，无需先搜索联系人。

> ⚠️ `search-contact` 依赖 OWA FindPeople API，该 API **已知不稳定**（可能返回 500 或空结果）。大多数场景直接用 MIS 号即可。

### 发送邮件

```bash
# 基本发送（MIS 号会自动补全为 @meituan.com）
catdesk mail send --to zhangsan --subject "会议纪要" --body "请查收今天的会议纪要。"

# 发送给多人（逗号分隔）
catdesk mail send --to "zhangsan,lisi,wangwu" --subject "项目通知" --body "明天下午 3 点开会。"

# 使用完整邮箱地址
catdesk mail send --to "zhangsan@meituan.com" --subject "测试" --body "这是一封测试邮件。"

# 带抄送和密送
catdesk mail send --to zhangsan --cc lisi --bcc wangwu \
  --subject "周报" --body "本周工作总结如下。"

# 高优先级邮件
catdesk mail send --to zhangsan --subject "紧急" --body "请尽快处理。" --importance High

# 多行正文（使用 \n 换行）
catdesk mail send --to zhangsan --subject "汇报" --body "你好，\n\n请查收附件。\n\n谢谢！"

# "姓名 <邮箱>" 格式
catdesk mail send --to "张三 <zhangsan@meituan.com>" --subject "Hi" --body "Hello!"
```

### 搜索联系人

当不确定收件人的完整邮箱时，先搜索：

```bash
# 按 MIS 号搜索
catdesk mail search-contact --keyword "zhangsan"

# 按姓名搜索
catdesk mail search-contact --keyword "张三"
```

返回结果包含 `name`（显示名）和 `email`（邮箱地址），可直接用于 `--to` 参数。

### 邮件发送参数说明

| 参数           | 说明                             | 必填 | 示例                                        |
| -------------- | -------------------------------- | ---- | ------------------------------------------- |
| `--to`         | 收件人（逗号分隔多个）           | 是   | `zhangsan` 或 `a@meituan.com,b@meituan.com` |
| `--subject`    | 邮件主题                         | 是   | `"会议纪要"`                                |
| `--body`       | 邮件正文（纯文本，支持 \n 换行） | 是   | `"你好，\n请查收。"`                        |
| `--cc`         | 抄送（逗号分隔）                 | 否   | `lisi,wangwu`                               |
| `--bcc`        | 密送（逗号分隔）                 | 否   | `boss`                                      |
| `--importance` | 优先级：Low / Normal / High      | 否   | `High`                                      |

## 会议室查询

```bash
# 查询城市楼宇信息
catdesk meeting buildings --city 北京

# 查询空闲会议室（自动过滤下线和已占用的会议室，不传 capacity 查询所有容量）
catdesk meeting rooms --city 北京 --building "保利广场西座" --start 10:00 --end 11:00

# 指定日期、最低容量、楼层（capacity 表示最少能容纳的人数，会查询该容量及更大的会议室）
catdesk meeting rooms --city 上海 --building D2 --date 2026-03-15 --start 14:00 --end 15:00 --capacity 10 --floor 3层

```

## 会议室预订

```bash
# 一步查找并预订（自动使用当前登录用户作为组织者）
catdesk meeting quick-book --city 北京 --building "保利广场西座" --start 10:00 --end 11:00

# 预订并邀请参会人（空格分隔多个 MIS 账号）
catdesk meeting quick-book --city 上海 --building D2 --start 14:00 --end 15:00 \
  --attendees lisi wangwu zhaoliu

# 自定义会议标题、容量和楼层
catdesk meeting quick-book --city 北京 --building 保利 --start 10:00 --end 12:00 \
  --title "周会" --capacity 15 --floor 4层

# 按指定会议室 ID 预订（ID 从 rooms 命令获取）
catdesk meeting book --room-id 1234 --date 2026-03-15 --start 10:00 --end 11:00

# 按 ID 预订并邀请参会人
catdesk meeting book --room-id 1234 --date 2026-03-15 --start 10:00 --end 11:00 \
  --attendees lisi wangwu
```

**quick-book 智能行为：**

- 按容量匹配度排序，优先选最接近需求的会议室
- 某间会议室预订失败（已被抢占/已下线）时自动尝试下一间
- 所有会议室都不可用时，自动创建空闲监测任务（会在有空闲时通知你）

## 查看我的日程/会议

```bash
# 查看未来 7 天的日程（默认）
catdesk meeting list

# 查看指定日期开始的日程
catdesk meeting list --date 2026-03-15

# 查看未来 3 天的日程
catdesk meeting list --days 3

# 查看指定日期开始 14 天内的日程
catdesk meeting list --date 2026-03-10 --days 14
```

- 返回结果包含日程的 `id`（即 scheduleId），可用于 `cancel` 命令取消预订
- 自动使用当前登录用户查询

## 取消会议室预订

```bash
# 取消指定的会议室预订（scheduleId 从预订结果或预订情况查询中获取）
catdesk meeting cancel --schedule-id calendar1234567890
```

- 只有预订发起人可以取消自己的预订
- scheduleId 格式为 `calendar` + 数字 ID

## 空闲会议室监测

当没有空闲会议室时，可以手动创建监测任务。系统会持续监测，有空闲会议室时自动通知。

```bash
# 创建空闲监测（不指定楼层则监测整栋楼）
catdesk meeting monitor --city 北京 --building 保利 --start 14:00 --end 15:00

# 指定楼层和人数
catdesk meeting monitor --city 上海 --building D2 --date 2026-03-15 --start 10:00 --end 11:00 --capacity 10 --floor 3层
```

## 注意事项

- 所有命令默认返回结构化 JSON 输出，无需额外标志
- 文件路径必须使用绝对路径
- 楼宇名称支持模糊匹配（如 `保利`、`D2` 即可）
- 会议室预订自动使用当前登录用户作为组织者
- `--attendees` 支持空格分隔多个 MIS 账号，也支持逗号分隔（如 `lisi,wangwu`）
- `--date` 默认为今天，`--capacity` 可选（不传则查询所有容量的会议室，传了则筛选容量 ≥ 该值的会议室）
- 如果 `catdesk` 未找到，使用 `npx catdesk` 替代
