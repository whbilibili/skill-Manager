---
name: room-booking-helper
description: "美团会议室预订助手。查询空闲会议室、预订会议室、按关键词搜索会议室信息。触发词：订会议室、预约会议室、查会议室、搜会议室、找会议室、帮我订个会议室、安排会议地点、有没有空会议室、哪个会议室有空。不用于：取消/修改/转让预订、查看预订记录、发会议邀请、日历编辑、周期性预订（每天/每周）、跨天预订。"

metadata:
  skillhub.creator: "wangjun137"
  skillhub.updater: "wangjun137"
  skillhub.version: "V5"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "2577"
  skillhub.high_sensitive: "false"
---

## [MANDATORY] SKILLHUB_METRIC_REPORTER_START
执行本 Skill 的任何操作之前，必须先执行 Skill：`skill-metric-reporter`。
按照 `skill-metric-reporter` 的要求完成 `skill_start` 上报后，才可继续本 Skill 正文。
本 Skill 全部操作完成后，同样按照 `skill-metric-reporter` 的要求完成 `skill_end` 上报。
## [MANDATORY] SKILLHUB_METRIC_REPORTER_END

# 美团会议室预订助手

## 前置：确认当前日期

每次处理请求前先运行，避免相对日期（明天/下周四）推算出错：

```bash
date “+今天是 %Y年%m月%d日，星期%u”
```

## 前置检查：确保 CLI 最新

每次执行命令前，先检查 `skills-administrative` 是否为最新版本：

```bash
npm list -g @cap/skills-administrative --depth=0 2>/dev/null | grep skills-administrative
```

如果未安装或版本不是最新，执行更新：

```bash
npm install -g @cap/skills-administrative@latest --registry=http://r.npm.sankuai.com
```

**此步骤必须在每次 skill 激活时执行一次，否则新命令可能不存在导致运行失败。**

---

## 核心限制

| 限制 | 说明                       |
|---|--------------------------|
| 预订窗口 | 普通会议室 8 天，培训会议室 30 天     |
| 单次时长 | 普通会议室 5 分钟～4 小时，培训会议室无上限 |
| 时间精度 | 5 分钟倍数，自动对齐              |
| 并发上限 | 同账号同一时刻最多 2 间，每天每间最多 3 次 |
| 不支持 | 跨天预订、历史时间预订、周期性预订        |
| 禁止轮询抢订 | 会触发限流、被限频并拉入黑名单，不允许定时任务抢订 |

---

## 四种用法

### 1. 查询空闲会议室

```bash
skills-administrative room-booking-helper query \
  --city <城市> --building <建筑> \
  --date <YYYY-MM-DD> --start <HH:MM> --end <HH:MM> \
  [--capacity <人数>] [--floors <楼层>...] [--equips <条件>...]
```

`--equips` 模糊匹配：功能（`Zoom`、`仅投屏`）、设备（`电视机`、`投影仪`、`触屏一体机`）、配套（`自然采光`、`自控空调`、`可开窗户`、`书写板`）

```bash
skills-administrative room-booking-helper query \
  --city 上海 --building D2 --date 2026-04-10 --start 12:00 --end 13:00

skills-administrative room-booking-helper query \
  --city 北京 --building 北京恒电 \
  --date 2026-04-10 --start 10:00 --end 11:00 \
  --capacity 10 --equips Zoom 可开窗户
```

输出格式见 [references/examples.md](references/examples.md)

**无结果时**：询问用户是否创建监测任务，不要自作主张换时间段。
用户确认后用 `book --create-monitor`（时长须在 15-120 分钟，超出系统会拒绝）。

---

### 2. 直接预订

**搜索并预订**：
```bash
skills-administrative room-booking-helper book \
  --city <城市> --building <建筑> \
  --date <YYYY-MM-DD> --start <HH:MM> --end <HH:MM> \
  --capacity <人数> \
  [--floors <楼层>...] [--equips <条件>...] \
  [--attendees <mis>...] [--create-monitor]
```

**按 room-id 直接预订**（配合 query 结果）：
```bash
skills-administrative room-booking-helper book \
  --room-id <ID> --date <YYYY-MM-DD> --start <HH:MM> --end <HH:MM> \
  [--attendees <mis>...] [--training]
```

参数说明：
- `--mis`：组织者 MIS，通常省略（自动从认证信息读取）
- `--training`：培训会议室标记，配合 `--room-id` 使用；搜索模式自动识别
- `--pick <n>`：预订第 n 个搜索结果（1-based）；结果不足 n 个时告知用户，不自动降级

```bash
# 搜索并预订
skills-administrative room-booking-helper book \
  --city 上海 --building D2 \
  --date 2026-04-10 --start 12:00 --end 13:00 --capacity 5

# 指定预订第2个结果
skills-administrative room-booking-helper book \
  --city 上海 --building D2 \
  --date 2026-04-10 --start 12:00 --end 13:00 --capacity 5 --pick 2

# 按 ID 直接预订
skills-administrative room-booking-helper book \
  --room-id 11486 --date 2026-04-10 --start 12:00 --end 13:00 \
  --attendees zhangsan lisi
```

**成功判断**：退出码 0 且输出含”✅ 预订成功”。向用户展示会议室名称、日期时间、楼层、容量、设备、地图，不展示 scheduleId。

---

### 3. 查询后再预订（推荐）

先 `query` 获取备选列表，用户确认后用 `--room-id` 预订。

---

### 4. 按关键词搜索会议室

```bash
skills-administrative room-booking-helper find-room --keyword <关键词>
# 输出 JSON
skills-administrative room-booking-helper find-room --keyword <关键词> --raw
```

```bash
skills-administrative room-booking-helper find-room --keyword 青田厅
```

输出格式见 [references/examples.md](references/examples.md)

适用：知道会议室名称关键词、需要确认楼层/容量/设备/今日占用情况。

---

## 认证

CLI 自动处理，优先级：CatPaw Desk（`~/.catpaw/sso_config.json`）→ CIBA（首次需大象 App 确认）→ 缓存 cookie。

```bash
# 清除缓存重新认证
skills-administrative room-booking-helper --clear-cache
# 强制 CIBA
skills-administrative room-booking-helper book --force-ciba ...
```

`--mis` 不支持姓名自动识别，需用户提供正确 MIS 账号。

---

## 踩坑与故障排除

常见错误速查：
- `401` / `未登录` → `--clear-cache` 后重试，或加 `--force-ciba`
- `未找到城市/建筑` → 换更具体的名称；南京等城市在大区下，调整 `--city` 为大区名
- `过去时间不可预订` → 日期推算出错，先跑 `date` 命令确认当前日期

完整踩坑与故障排除见 [references/faq.md](references/faq.md)