---
name: calendar-mcp
description: 美团日历（日程管理）工具集。支持创建/查询/编辑/取消日程、搜索日程、查询忙闲、创建/编辑会议室日程，以及释放/转让会议室，并自动将 mis 转换为 empId。当用户想“安排会议/新建日程/改期/取消/查忙闲/查这段时间有哪些会/查会议室/找会议室/订会议室/钉会议室/安排会议地点/换会议室/释放会议室/转让会议室”时激活。通过 oa-skills calendar-mcp CLI 执行。若其他会议室 skill 也支持预订或编辑会议室，calendar-mcp 已支持的日程和会议室写操作优先使用本 skill；room-booking-helper 仅作为查询空闲会议室、找会议室和获取 roomId 的辅助。不支持会议室跨天预订、历史时间预订和周期性预订。

metadata:
  skillhub.creator: "pangjingwei02"
  skillhub.updater: "dongjie21"
  skillhub.version: "V3"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "11092"
  skillhub.high_sensitive: "false"
---

## [MANDATORY] SKILLHUB_METRIC_REPORTER_START
执行本 Skill 的任何操作之前，必须先执行 Skill：`skill-metric-reporter`。
按照 `skill-metric-reporter` 的要求完成 `skill_start` 上报后，再去继续本 Skill 正文。
如果 `skill-metric-reporter` 不可用或执行失败，跳过上报，继续执行本 Skill 正文——不得因上报失败而阻塞审阅流程。
本 Skill 全部操作完成后，同样按照 `skill-metric-reporter` 的要求完成 `skill_end` 上报。
## [MANDATORY] SKILLHUB_METRIC_REPORTER_END

# 📅 Calendar MCP（日程管理）操作指南（CLI 版）

本 skill 以 MCP Hub（SSE Session）方式调用日历服务，目标是：低误操作风险、可直接执行、结果可验证。创建/编辑日程和会议室日程继续走 MCP；释放/转让会议室走开放平台 HTTP 接口。

MCP Server：
- 日历服务（Schedule）：`http://mcphub-server.sankuai.com/mcphub-b/8781956a2daf4d`
- 身份映射（mis → empId）：`http://mcphub-server.sankuai.com/mcphub-api/5ef912172ad244`

换票 audience（clientId）：
- 日历（Schedule）：`9f890de0db`
- 身份映射（xm-xai）：`xm-xai`

## 当前可用能力（已按 calendar-manager 平移到 CLI）

- 创建日程：`create_primary_schedule`
- 查询详情：`query_primary_schedule`
- 选择性编辑：`update_primary_schedule_by_selective`
- 取消日程：`delete_primary_schedule`
- 搜索日程：`search_calendar`
- 查询忙闲：`list_busy_period`
- mis → empId 映射：`get_uid_and_empid_by_mis`（lookup MCP）
- 创建会议室日程：`createSchedule --roomId`，仍调用 `create_primary_schedule`
- 编辑会议室：`updateSchedule --meetingRoomOperateType [--roomId]`，仍调用 `update_primary_schedule_by_selective`
- 释放会议室：`releaseMeetingRoom`，调用开放平台 HTTP 接口
- 转让会议室：`transferMeetingRoom`，调用开放平台 HTTP 接口
- 查询空闲会议室 / 获取 `roomId`：`skills-administrative room-booking-helper query`
- 创建候补监测任务：`skills-administrative room-booking-helper monitor`
- 按关键词查会议室信息：`skills-administrative room-booking-helper find-room`

## Skill 路由优先级

- `calendar-mcp` 是日历日程和日程绑定会议室操作的主入口。只要用户意图包含创建会议/日程、给日程预订会议室、给已有日程加会议室、换会议室、改会议室占用时间、移除会议室、释放会议室、转让会议室、取消会议室日程，优先使用 `oa-skills calendar-mcp`。
- `skills-administrative room-booking-helper` 只作为会议室查询和候补监测辅助使用：查空闲会议室、按关键词找会议室、确认会议室楼宇/楼层/容量/设备、获取 `roomId`；query 无结果且用户明确同意创建候补监测任务时，使用它的 `monitor`。
- 即使 `room-booking-helper` 也支持 `book` 预订能力，默认不要用它完成 `calendar-mcp` 已支持的创建/编辑/释放/转让流程，避免同一会议室资源出现两个写入口。
- `room-booking-helper book` 也是创建带会议室日程的写入口，和 `calendar-mcp createSchedule --roomId` 语义重叠；只有用户明确指定“使用会议室官方 skill / room-booking-helper / skills-administrative 预订”，或 `calendar-mcp` 当前能力无法覆盖且用户确认转交时，才考虑 `room-booking-helper book`；否则按本 skill 的 `createSchedule --roomId` / `updateSchedule --meetingRoomOperateType` 流程处理。

## 前置检查：确保 CLI 可用

每次 skill 激活时，先检查 `oa-skills` 是否存在；不存在时再执行安装。

```bash
node -e "const cp=require('child_process'); const probe=process.platform==='win32'?'where oa-skills':'command -v oa-skills'; try{cp.execSync(probe,{stdio:'ignore',shell:true})}catch{cp.execSync('npm install -g @it/oa-skills@latest --registry=http://r.npm.sankuai.com',{stdio:'inherit',shell:true})}"
```

首次执行时先判断 `oa-skills` 是否存在；不存在才安装。安装后或已存在时，再静默校验 CLI 可用性：

```bash
node -e "require('child_process').execSync('oa-skills --version',{stdio:'ignore',shell:true})"
```

**首次执行时必须先完成这一步；若 `oa-skills` 不存在则先安装，已存在则无需重复安装。**

会议室查询依赖 `skills-administrative room-booking-helper`。涉及查会议室、订会议室、加会议室、换会议室、改会议室占用时间时，先检查 `@cap/skills-administrative` 是否为最新正式版本；只有版本不一致或未安装时才升级：

```bash
LOCAL=$(npm list -g @cap/skills-administrative --depth=0 2>/dev/null | grep '@cap/skills-administrative' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+[^ ]*'); \
REMOTE=$(npm view @cap/skills-administrative dist-tags.latest --registry=http://r.npm.sankuai.com 2>/dev/null); \
if [ "$LOCAL" != "$REMOTE" ]; then \
  echo "版本不一致（本地: ${LOCAL:-未安装}, 远端: $REMOTE），开始升级..."; \
  npm install -g @cap/skills-administrative@latest --registry=http://r.npm.sankuai.com; \
else \
  echo "已是最新版本 $REMOTE，无需升级。"; \
fi
```

## 核心约束

- 所有调用必须通过 `oa-skills calendar-mcp ...` 执行；不要在回复里拼接长段 SSE / curl。
- 底层 MCP Tool 的参与人相关字段实际要求 `empId`，但 `calendar-mcp` CLI 对外支持传 `mis` 或纯数字 `empId`：
  - `createSchedule --attendees`
  - `searchSchedule --attendees`
  - `listBusyPeriod --users`
  - `updateSchedule --addAttendees / --removeAttendees`
  - `transferMeetingRoom --receiver`
  上述参数传入 `mis` 时，CLI 会先自动转换为 `empId` 再调用对应后端能力。
- 时间参数统一使用 `--startTime / --endTime / --minTime / --maxTime`，对大模型和示例一律传日期时间字符串：
  - `2026-04-07`
  - `2026-04-07 10:00`
  - `2026-04-07 10:00:00`
  CLI / client 会先通过 `convertToTimestamp` 转成毫秒时间戳；`list_busy_period` 再内部转换为工具需要的 `YYYY-MM-DD HH:mm:ss`。内部仍兼容 10 位秒级和 13 位毫秒级时间戳，以及旧参数名 `--startMs / --endMs / --minMs / --maxMs`，但对大模型不要这样传。
- `search_calendar` 的 `attendUser` 必填且为 empId long 数组；CLI 负责生成 `tid`（UUID），用户无需提供。
- 用户没提供 `scheduleId` 但要改/取消/看详情：应先用 `searchSchedule` 搜索候选，再内部继续调用（不要向用户索要 `scheduleId`）。
- 默认回复只给用户关心结果（中文摘要），不贴原始 RPC；仅在排障或用户明确要求时用 `--raw`。
- 创建日程的必填参数只有 `--title`、`--attendees`、`--startTime`、`--endTime`；`--location` 和 `--memo` 都是可选参数。用户没有提供地点或备注时，不要追问，也不要臆造默认值；直接不传即可。
- 更新日程时，`--location` 和 `--memo` 也是可选更新字段。只有用户明确要求修改地点或备注时才传；不传表示不更新对应字段。
- `--roomId` 和 `--location` 是两个不同字段：`--roomId` 用于预订/占用会议室资源；`--location` 只是用户自填的普通地点展示信息，不会预订会议室。用户明确要“订会议室/钉会议室/预订会议室”时，必须通过会议室查询拿到 `roomId` 后传 `--roomId`，默认不要传 `--location`，也不要把会议室名称、楼宇或楼层写进 `--location` 来代替会议室预订。
- 会议室能力分流：
  - 普通日程创建：不调用会议室查询 CLI，不传 `--roomId`。
  - 创建会议室日程：先获得可用会议室 `roomId`，再使用 `createSchedule --roomId`，继续走 MCP；不要为了展示会议室而额外传 `--location`。
  - 添加/换房/改会议室占用时间/移除会议室：先查日程详情并按 `detail.roomDetail` 分流，再使用 `updateSchedule --meetingRoomOperateType`，继续走 MCP。
  - 释放/转让会议室：先查日程详情确认是会议室日程，再使用 `releaseMeetingRoom` / `transferMeetingRoom`，走开放平台 HTTP。
- 循环日程相关会议室操作当前不支持，直接说明暂不支持，不要继续追问循环规则。
- 会议室名称、楼宇、楼层、容量等条件不能直接当 `roomId` 使用；当用户没有给明确数字 `roomId` 时，先用 `skills-administrative room-booking-helper query` 查询目标时间段的空闲会议室并取得 `roomId`。查询不到可用会议室时，直接告知不可用，不要继续调用写接口。
- 如果当前环境没有 `skills-administrative` 命令，或 `room-booking-helper query --help` 无法确认参数和返回结构，应停止并说明无法按会议室名称自动查询空闲会议室；不要猜测 `roomId`，也不要绕过会议室查询直接写入。
- 用户只说“钉会议室”但缺少时间段、目标对象或会议室条件时，先补齐必要信息；缺少开始/结束时间时不能调用会议室查询或写接口。
- 普通编辑不进入会议室分支：只改标题、备注、参与人、普通地点等，不调用会议室查询 CLI，不传 `--roomId` / `--meetingRoomOperateType`。
- 编辑日程时间时，如果可能是会议室日程，必须先 `querySchedule --raw` 判断 `detail.roomDetail`；普通日程按普通改期，会议室日程按会议室占用时间修改处理。
- 所有会议室编辑、释放、转让前必须先 `querySchedule --raw`，用 `detail.roomDetail != null` 判断是否为会议室日程：
  - `roomDetail == null`：普通日程。
  - `roomDetail != null`：会议室日程。
- 释放/转让是有副作用的写操作，必须先明确目标日程。如果用户没提供 `scheduleId`，先用 `searchSchedule` 定位候选；候选不唯一时必须让用户确认具体日程。
- 转让会议室成功后，后续内部操作应使用返回的 `handoverEventId`；旧 `scheduleId` 可能失效，这是预期行为。面向用户回复时不要展示 `handoverEventId` 或新日程 ID，只说明已转让给接收人。
- `updateSchedule` 不支持 `--attendees`。编辑参与人时只能使用：
  - `--addAttendees "mis1,mis2"`
  - `--removeAttendees "mis3,mis4"`
- 当前只支持 `mis -> empId` 转换，不支持“姓名 -> mis”自动转换；如果用户只提供人员姓名，除非能从当前上下文唯一确定对应 `mis`，否则必须要求用户补充 `mis`。
- 示例命令中的人员参数都只是占位符；不要把文档里的示例 MIS 当作默认参会人、查询对象或转让接收人。`--attendees`、`--addAttendees`、`--removeAttendees`、`--users`、`--receiver` 只能来自用户明确输入、当前对话上下文唯一确认的信息；缺少必要人员信息时先追问。
- 若一句话中包含多个动作，例如“先查忙闲再建会”“先搜这周的会再取消其中一条”，要拆成串行步骤执行；每一步只调用一个 CLI 方法。
- 查询其他人的日程时，不要表述成“对方全部日程”；应理解为“你当前有权限看到的、与输入条件匹配的日程/交集日程”。
- 删除或更新日程后，优先用 `querySchedule --raw` 或再次按 `scheduleId` 验证；`searchSchedule` 的检索结果可能有短暂延迟，不要用刚删除后的一次搜索结果直接判定删除失败。
- 涉及会议室查询或预订时，先执行 `date "+今天是 %Y年%m月%d日，星期%u，当前时间 %H:%M"`，再推算“明天/这周六/下周五”等相对日期；推算后必须验证星期一致。
- 会议室时间限制：普通会议室预订窗口不超过 8 天，培训会议室不超过 30 天；普通会议室单次时长 5 分钟到 4 小时；时间粒度为 5 分钟倍数；不支持历史时间、跨天预订、周期性预订；禁止轮询抢订。
- `room-booking-helper query` 返回的会议室 `id` 就是后续传给 `calendar-mcp` 的 `roomId`。不要臆造字段名；如果输出里无法确认 `id` / `roomId`，停止并说明无法继续写入。
- `room-booking-helper book` 不作为 `calendar-mcp` 默认创建会议室日程流程的一部分；默认仍使用 `createSchedule --roomId`，避免双入口创建日程。

## 认证

认证由 CLI 自动处理，根据运行环境选择合适的策略，优先 SSO 无感登录。Token 自动缓存。

常见自查：
- 认证失败/过期：`oa-skills calendar-mcp --clear-cache` 后重试
- mis 无法解析：需要用户提供正确 mis（不支持"姓名 → mis"自动识别）

## CLI 使用

所有命令格式：`oa-skills calendar-mcp <method> [options]`

```bash
# 查看帮助
oa-skills calendar-mcp --help

# mis -> empId
oa-skills calendar-mcp resolveEmpIdsByMis --misCsv "<用户mis1>,<用户mis2>"

# 创建日程（CLI 接受 mis 或 empId，内部自动转换为 MCP 需要的 empId；location/memo 可选）
oa-skills calendar-mcp createSchedule --title "项目周会" --attendees "<参会人mis1>,<参会人mis2>" --startTime "2026-03-03 09:00" --endTime "2026-03-03 10:00" --location "A3-09木星"

# 查询空闲会议室 / 获取 roomId（query 结果的 id 用作 calendar-mcp 的 roomId）
skills-administrative room-booking-helper query \
  --building 互联D2 --date 2026-03-03 --start 09:00 --end 10:00

skills-administrative room-booking-helper query \
  --city 北京 --building 恒电 --date 2026-03-03 --start 09:00 --end 10:00 \
  --capacity 10 --equips Zoom 可开窗户

# 已知具体会议室名时，先查会议室信息，再用 query 校验目标时间是否空闲
skills-administrative room-booking-helper find-room --keyword 青田厅 --raw

# 创建会议室日程（先通过会议室查询拿 roomId；创建仍走 MCP，只额外传 roomId）
oa-skills calendar-mcp createSchedule --title "项目周会" --attendees "<参会人mis1>,<参会人mis2>" --startTime "2026-03-03 09:00" --endTime "2026-03-03 10:00" --roomId 573

# 搜索日程（CLI 接受 mis 或 empId，内部自动转换为 MCP 需要的 empId）
oa-skills calendar-mcp searchSchedule --attendees "<查询对象mis1>,<查询对象mis2>" --startTime "2026-03-03 00:00" --endTime "2026-03-03 23:59:59" --title "周会"

# 查忙闲（CLI 接受 mis 或 empId，内部自动转换为 MCP 需要的 empId）
oa-skills calendar-mcp listBusyPeriod --users "<用户mis1>,<用户mis2>" --minTime "2026-03-03 09:00" --maxTime "2026-03-03 18:00"

# 查详情 / 改期 / 取消（内部优先用搜索结果的 scheduleId，不对外展示）
oa-skills calendar-mcp querySchedule --scheduleId "schedule-id"
oa-skills calendar-mcp updateSchedule --scheduleId "schedule-id" --title "改期" --startTime "2026-03-03 11:00" --endTime "2026-03-03 12:00"
oa-skills calendar-mcp updateSchedule --scheduleId "schedule-id" --addAttendees "<新增参会人mis1>,<新增参会人mis2>"
oa-skills calendar-mcp updateSchedule --scheduleId "schedule-id" --removeAttendees "<移除参会人mis>"
oa-skills calendar-mcp deleteSchedule --scheduleId "schedule-id"

# 编辑会议室（先 querySchedule --raw 判断 roomDetail；仍走 MCP；meetingRoomOperateType: 1=ADD, 2=UPDATE, 3=REMOVE）
oa-skills calendar-mcp updateSchedule --scheduleId "schedule-id" --meetingRoomOperateType 1 --roomId 573
oa-skills calendar-mcp updateSchedule --scheduleId "schedule-id" --meetingRoomOperateType 2 --roomId 574
oa-skills calendar-mcp updateSchedule --scheduleId "schedule-id" --startTime "2026-03-03 11:00" --endTime "2026-03-03 12:00" --meetingRoomOperateType 2
oa-skills calendar-mcp updateSchedule --scheduleId "schedule-id" --meetingRoomOperateType 3

# 释放 / 转让会议室（走开放平台 HTTP）
oa-skills calendar-mcp releaseMeetingRoom --scheduleId "schedule-id"
oa-skills calendar-mcp transferMeetingRoom --scheduleId "schedule-id" --receiver "<接收人mis>"

```

注意：
- `createSchedule` 使用 `--attendees`
- `createSchedule` 的必填参数是 `--title`、`--attendees`、`--startTime`、`--endTime`；`--location`、`--memo` 可选，用户未说明时不要补传。
- `updateSchedule` 不接受 `--attendees`，只能用 `--addAttendees` / `--removeAttendees`
- `updateSchedule` 的 `--location`、`--memo` 可选；不传表示不更新地点/备注。
- `--location` 只用于用户明确给出的普通地点信息，例如外部地址、线下地点或视频会议链接；它不等于会议室预订。会议室预订、添加、换房和占用时间修改都应使用 `--roomId` / `--meetingRoomOperateType`。
- `createSchedule --roomId` 和 `updateSchedule --roomId/--meetingRoomOperateType` 继续走 MCP；`releaseMeetingRoom` / `transferMeetingRoom` 走开放平台 HTTP
- `meetingRoomOperateType=1` 添加会议室时必须传 `--roomId`；`meetingRoomOperateType=3` 移除会议室时不能传 `--roomId`
- 已订会议室日程只改占用时间时使用 `--meetingRoomOperateType 2`，不传 `--roomId`，由后端沿用原会议室
- `room-booking-helper query` 的基础参数是 `[--city] --building --date --start --end`；可选 `--capacity`、`--floors`、`--equips`、`--training`
- 如果用户给的是 `mis`，CLI 会自动做 `mis -> empId` 转换；如果用户直接给纯数字 `empId`，也可以直接透传
- 对大模型传参时，统一使用 `YYYY-MM-DD HH:mm` 或 `YYYY-MM-DD HH:mm:ss` 字符串，不要传时间戳

## 执行策略

### 创建：按风险分流

以下场景，创建前优先执行 `listBusyPeriod`：
- 多人会议
- 用户明确要求避冲突 / 找都空的时间
- 需要向用户推荐候选时间

以下场景可跳过忙闲检查：
- 单人提醒
- 用户明确要求“直接创建，不用查忙闲”

### 只查会议室：不创建日程

适用场景：
- 用户问“有没有空会议室”“哪个会议室有空”“找个有 Zoom 的会议室”“青田厅在哪”
- 用户明确说“帮我查会议室”，未表达创建日程或预订动作

执行规则：
- 先明确日期、开始时间、结束时间、建筑/城市/楼层/人数/设备。
- 已知具体会议室名时，先用 `find-room --keyword <关键词> --raw` 确认会议室信息；用户给建筑或楼宇时，直接用 `query --building`。
- 只展示查询结果，不调用 `createSchedule` / `updateSchedule` / `room-booking-helper book`。
- 查询结果应展示会议室名称、日期时间、楼层、容量、设备、地图等用户关心信息；默认不展示 `scheduleId`。
- query 无结果时，告诉用户当前条件无空闲会议室，不要自作主张换时间段；可询问是否调整查询条件，或是否通过 `skills-administrative room-booking-helper monitor` 创建候补监测任务。`monitor` 是新的副作用，必须用户明确同意后才执行。

会议室日程：
- 用户明确给出 `roomId` 时，可使用 `createSchedule --roomId` 创建会议室日程。
- 用户只给会议室名称、楼宇、楼层、容量等条件时，先用 `skills-administrative room-booking-helper query` 查询目标时间段空闲会议室并取得 `roomId`；不要猜测 `roomId`。如果用户给的是具体会议室名，可先用 `find-room` 确认建筑/楼层/容量，再用 `query` 校验目标时间空闲。
- 会议室预订场景默认只传 `--roomId`，不传 `--location`；不要把会议室名称或楼宇信息作为普通地点写入 `location` 来模拟会议室。
- 用户只说“钉会议室”时，先补齐时间段、目标对象和会议室条件。缺少时间段时不能查会议室，也不能创建/更新。
- 查询结果为空时，直接告诉用户目标会议室或目标时间不可用，不调用 `calendar-mcp` 写接口，不要自动改时间段；可询问是否调整条件。
- 查询结果多条且无法唯一匹配时，先让用户选择具体会议室。
- 创建会议室日程前如用户要求避开冲突，仍可先查参与人忙闲；会议室自身空闲用 `room-booking-helper query` 前置确认，后端写接口返回的业务失败也必须透传。
- 如果用户有容量/设备/楼层偏好，优先选择最匹配的 query 结果；没有偏好时可推荐第一条候选，但在真正写入 `createSchedule --roomId` 前应确认用户意图是“订/创建”，不是“查询”。

### 编辑：先分流普通编辑和会议室编辑

普通编辑保持普通 `updateSchedule` 流程，不触发会议室查询：
- 改标题、备注、普通地点、参与人：不传 `--roomId` / `--meetingRoomOperateType`。
- 普通日程改时间且用户没有会议室资源意图：按普通改期处理。
- 已经是会议室日程但只改标题、备注、参与人等不影响会议室占用的字段：按普通编辑处理，不传 `meetingRoomOperateType`。

以下场景才进入会议室编辑分支：
- 给普通日程添加会议室。
- 把已有会议室日程换到另一个会议室。
- 修改已有会议室日程的会议室占用时间。
- 移除会议室但保留日程。

会议室编辑前置：
- 如果用户没有 `scheduleId`，先用 `searchSchedule` 搜索候选；候选不唯一时让用户确认。
- 拿到唯一 `scheduleId` 后，先 `querySchedule --raw`。
- 用 `detail.roomDetail != null` 判断原日程类型。

会议室编辑决策：
- 普通日程添加会议室：原日程 `roomDetail == null`，先用 `skills-administrative room-booking-helper query` 查目标时间可用会议室，拿到 `roomId` 后执行 `updateSchedule --meetingRoomOperateType 1 --roomId <id>`。
- 会议室日程换房：原日程 `roomDetail != null`，先查目标会议室在目标时间是否空闲，拿到 `roomId` 后执行 `updateSchedule --meetingRoomOperateType 2 --roomId <newRoomId>`。
- 会议室日程只改时间：原日程 `roomDetail != null`，必须先按“已订会议室日程改时间”规则判断是否需要查新增占用区间；只有缩短时间或新增占用区间确认空闲后，才能执行 `updateSchedule --startTime <newStart> --endTime <newEnd> --meetingRoomOperateType 2`，不传 `--roomId`。
- 会议室日程移除会议室：原日程 `roomDetail != null`，执行 `updateSchedule --meetingRoomOperateType 3`，不传 `--roomId`。
- 普通日程不能执行换房、只改会议室占用时间或移除会议室；应直接说明当前日程没有绑定会议室。

已订会议室日程改时间：
- 先从 `querySchedule --raw` 的原日程详情读取 `oldStart`、`oldEnd` 和当前会议室信息；用户给出的目标时间作为 `newStart`、`newEnd`。只做下面 4 个固定分支，不要自由推导复杂区间。
- 缩短时间：`newStart >= oldStart` 且 `newEnd <= oldEnd`，例如 `10:00-11:00` 改成 `10:00-10:30`，可直接走 `meetingRoomOperateType=2` 更新。
- 只延后结束：`newStart == oldStart` 且 `newEnd > oldEnd`，必须先用当前会议室条件查询 `oldEnd` 到 `newEnd` 是否空闲；空闲才更新。
- 只提前开始：`newStart < oldStart` 且 `newEnd == oldEnd`，必须先用当前会议室条件查询 `newStart` 到 `oldStart` 是否空闲；空闲才更新。
- 两头都扩大：`newStart < oldStart` 且 `newEnd > oldEnd`，分别查询 `newStart` 到 `oldStart`、`oldEnd` 到 `newEnd` 两段；两段都空闲才更新。
- 其他平移或重叠复杂场景：不要直接调用更新接口，先说明需要确认当前会议室在目标完整时段可用；除非会议室查询结果能明确排除当前日程自身占用并确认当前会议室空闲，否则停止。
- 查询新增占用区间时，使用 `detail.roomDetail` 中能识别当前会议室的名称/楼宇/楼层等条件；如果无法从查询结果确认同一个会议室空闲，视为不可确认，不调用更新接口。
- 新增占用区间不可用或不可确认时，不调用更新接口，直接告诉用户会议室在扩展时间段不可用或无法确认可用。

### 搜索：用于先定位候选日程

适用场景：
- 用户只记得参与人、时间范围、标题关键词，想先列出候选日程
- 用户没有 `scheduleId`，但需要先搜索再决定查哪条详情、编辑或取消

约束：
- `searchSchedule` 是“按条件列出候选日程”，不是“按 ID 查详情”
- 当查询对象包含其他用户时，搜索结果应理解为“当前你有权限看到的匹配日程”，不要表述成对方全部日程

### 查询详情：内部依赖 `scheduleId`

适用场景：
- 用户要看某一条已知日程的详细信息

约束：
- 如果用户没有 `scheduleId`，先用 `searchSchedule` 找候选，再内部继续调用 `querySchedule`
- 不要向用户索要 `scheduleId`
- 对用户回复时默认不展示 `scheduleId`

### 会议室编辑、释放和转让

适用场景：
- 给普通日程添加会议室：`updateSchedule --meetingRoomOperateType 1 --roomId <id>`
- 会议室日程换房：`updateSchedule --meetingRoomOperateType 2 --roomId <newRoomId>`
- 会议室日程只改占用时间：`updateSchedule --startTime <newStart> --endTime <newEnd> --meetingRoomOperateType 2`
- 会议室日程移除会议室：`updateSchedule --meetingRoomOperateType 3`
- 释放会议室：`releaseMeetingRoom --scheduleId <id>`
- 转让会议室：`transferMeetingRoom --scheduleId <id> --receiver <misOrEmpId>`
- 取消整个会议室日程：`deleteSchedule --scheduleId <id>`

约束：
- 编辑会议室仍走 MCP；释放/转让会议室走开放平台 HTTP。
- 转让会议室的 `receiver` 可传 MIS 或数字 empId，CLI 会转换成开放接口要求的 empId。
- 释放/转让前必须明确唯一目标日程并先 `querySchedule --raw`；只有 `detail.roomDetail != null` 才能调用释放/转让。普通日程不能调用释放/转让会议室接口。
- 转让成功会返回 `handoverEventId`，后续内部围绕新承接日程操作；默认用户可见回复不展示该 ID，只展示接收人。
- “取消会议室”必须先澄清：取消整个会议室日程用 `deleteSchedule`；提前释放会议室用 `releaseMeetingRoom`；仅移除会议室但保留日程用 `updateSchedule --meetingRoomOperateType 3`。不要一律映射成释放会议室。

### 忙闲查询：用于找空档，不代替日程详情

适用场景：
- 创建多人会议前检查冲突
- 用户问“这几个人什么时候都有空”
- 需要给出候选会议时间

不适用场景：
- 用户已经提供 `scheduleId`，想确认具体某个日程的内容
- 用户只是想查看某一条日程详情

## 输出规则

- 默认输出中文摘要；`--raw` 才输出原始 JSON/文本
- 默认不对外展示 `scheduleId`
- 释放会议室成功时回复“会议室释放成功”；转让成功时回复“会议室转让成功，已转让给：<receiver>”，不要展示 `handoverEventId` 或新日程 ID。
