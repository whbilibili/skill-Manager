---
name: agent-browser
description: "通过 agent-browser CLI 进行 headless 浏览器自动化。当需要浏览器交互（表单填写、模拟点击、页面截图、JS 执行），且 web_fetch 纯文本抓取无法满足时使用。触发词：agent-browser、浏览器自动化、headless 浏览器、网页截图、页面快照 snapshot、表单自动填写、模拟点击操作、网页交互自动化、浏览器抓取动态页面、CDP 连接浏览器。跳过：纯文本/静态页抓取用 web_fetch；用户指定 Chrome extension / Browser Relay 时用内置 browser tool。"
version: 1.0.0

metadata:
  skillhub.creator: "yeshaozhi"
  skillhub.updater: "yeshaozhi"
  skillhub.version: "V11"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "1783"
  skillhub.high_sensitive: "false"
---

## [MANDATORY] SKILLHUB_METRIC_REPORTER_START
执行本 Skill 的任何操作之前，必须先执行 Skill：`skill-metric-reporter`。
按照 `skill-metric-reporter` 的要求完成 `skill_start` 上报后，才可继续本 Skill 正文。
本 Skill 全部操作完成后，同样按照 `skill-metric-reporter` 的要求完成 `skill_end` 上报。
## [MANDATORY] SKILLHUB_METRIC_REPORTER_END

# agent-browser — Headless 浏览器自动化

**IRON LAW: 每次交互前必须 `snapshot -i` 获取 @ref，禁止盲操作。**

## 安装检查

```bash
command -v agent-browser &>/dev/null || npm i -g agent-browser
```

## 环境初始化（每次会话首次使用必做）

```bash
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
export AGENT_BROWSER_ARGS="--no-sandbox,--ignore-certificate-errors"
```

访问美团内网加代理：
```bash
export AGENT_BROWSER_ARGS="--no-sandbox,--ignore-certificate-errors,--proxy-server=http://nocode-supabase-squid.sankuai.com:443"
```

| 报错 | 修复 |
|------|------|
| `ERR_INVALID_AUTH_CREDENTIALS` | 去掉 `--proxy-server` |
| `ERR_CERT_AUTHORITY_INVALID` | 加 `--ignore-certificate-errors` |

## 工作流程

**所有自动化都遵循：Navigate → Snapshot → Interact → Re-snapshot**

### 步骤 1: 打开页面 → 步骤 2: Snapshot → 步骤 3: 交互 → 步骤 4: Re-snapshot

```bash
# 1. 打开页面
agent-browser open "<url>" --timeout 15000

# 2. 获取交互元素（必做！拿到 @ref）
agent-browser snapshot -i

# 3. 用 @ref 交互
agent-browser fill @e1 "user@example.com"
agent-browser click @e3
agent-browser press Enter

# 4. 页面变化后重新 snapshot
agent-browser snapshot -i
```

## 常用命令速查

| 命令 | 用途 |
|------|------|
| `open <url>` | 导航 |
| `snapshot -i` | 交互元素 + @ref（⚠️ 必用） |
| `snapshot` | 完整可访问性树 |
| `click @ref` | 点击 |
| `fill @ref "text"` | 清空并填入 |
| `type @ref "text"` | 追加输入 |
| `press Enter/Tab/...` | 按键 |
| `select @ref "option"` | 下拉选择 |
| `scroll down 500` | 滚动 |
| `wait 2000` | 等待毫秒 |
| `wait @ref` | 等待元素出现 |
| `wait --load networkidle` | 等待网络空闲 |
| `get text @ref` | 获取文本 |
| `get url` | 当前 URL |
| `screenshot [path]` | 截图 |
| `screenshot --full` | 全页截图 |
| `screenshot --annotate` | 带标注截图（给视觉模型） |
| `pdf <path>` | 导出 PDF |
| `eval '<js>'` | 执行 JS |
| `close` | 关闭浏览器 |

## @ref 生命周期（重要）

@ref 在页面变化后失效。以下操作后**必须重新 snapshot**：
- 点击导航链接/按钮
- 表单提交
- 动态内容加载（下拉、弹窗）

## 已知坑（Chromium ≤117）

| ❌ 有 bug | ✅ 替代方案 |
|-----------|-----------|
| `keyboard type "text"` | `fill @ref "text"` |
| `keyboard inserttext "text"` | `fill @ref "text"` |
| `wait --url "**/glob"` | `wait --fn "location.pathname.includes('/path')"` |
| `find role button --name "x"` | `find text "x" click` |

## CDP 连接已有浏览器

```bash
agent-browser connect <port|ws-url>
```

⛔ CDP 模式禁忌：
- 禁止 `open`（会导航当前 tab，丢登录态）
- 禁止 `close`（丢登录态）
- 禁止 `screenshot`（会卡住）
- ✅ 用 `eval` + `snapshot` 最安全

## 微信公众号文章

```bash
agent-browser open "https://mp.weixin.qq.com/s/xxx" \
  --user-agent "Mozilla/5.0 (Linux; Android 14; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/120.0.0.0 Mobile Safari/537.36 MicroMessenger/8.0.50 WeChat/arm64"
```

## Anti-Pattern

| ❌ 禁止 | ✅ 正确 |
|---------|--------|
| 不看 snapshot 直接操作 | 先 `snapshot -i` 拿 @ref |
| 用 CSS 选择器猜 | 用 `@ref` 或 `find text` |
| screenshot 当阅读工具 | `snapshot` 或 `get text` |
| CDP 模式下 close/open | CDP 用 eval + snapshot |
| 忘记 unset 代理 | 首行 unset proxy |
| 复杂 JS 用引号包裹 | `eval --stdin <<'EOF'` |

## 深入文档

| 参考 | 场景 |
|------|------|
| [references/full-commands.md](references/full-commands.md) | 完整命令参考 |
| [references/authentication.md](references/authentication.md) | 登录持久化、state save/load |
| [references/advanced.md](references/advanced.md) | 网络拦截、设备模拟、录制、安全策略 |
