# 高级功能

## 网络拦截

```bash
# Mock API 响应
agent-browser network route "https://api.example.com/*" --body '{"mock": true}'

# 阻断请求
agent-browser network route "https://ads.example.com/*" --abort

# 取消拦截
agent-browser network unroute "https://api.example.com/*"

# 请求日志
agent-browser network requests --filter "api"
agent-browser network requests --clear
```

## HAR 录制

```bash
agent-browser network har start
# ... 操作页面 ...
agent-browser network har stop ./output.har
```

## 设备模拟

```bash
agent-browser set viewport 1920 1080      # 桌面
agent-browser set viewport 375 812        # 手机
agent-browser set viewport 1920 1080 2    # Retina
agent-browser set device "iPhone 14"      # 设备模拟（视口+UA）
agent-browser set geo 39.9042 116.4074    # 地理位置（北京）
agent-browser set offline on              # 离线模式
agent-browser set headers '{"X-Custom": "value"}'  # 自定义请求头
agent-browser set credentials admin pass  # HTTP 认证
agent-browser set media dark              # 暗色模式
```

## 视觉调试

```bash
agent-browser --headed open https://example.com  # 有头模式
agent-browser highlight @e1                       # 高亮元素
agent-browser inspect                             # 打开 DevTools
agent-browser record start demo.webm              # 录屏
agent-browser profiler start                      # 性能分析
agent-browser profiler stop trace.json
```

环境变量: `AGENT_BROWSER_HEADED=1` 开启有头模式。

## 安全策略

### Domain 白名单

```bash
export AGENT_BROWSER_ALLOWED_DOMAINS="example.com,*.example.com"
```

### Action Policy

```json
{ "default": "deny", "allow": ["navigate", "snapshot", "click", "scroll", "wait", "get"] }
```

```bash
export AGENT_BROWSER_ACTION_POLICY=./policy.json
```

### Content Boundaries（推荐 AI Agent 场景）

```bash
export AGENT_BROWSER_CONTENT_BOUNDARIES=1
# 输出会被标记为页面内容，帮助 LLM 区分工具输出和网页内容
```

### 输出限制

```bash
export AGENT_BROWSER_MAX_OUTPUT=50000
```

## 本地文件

```bash
# ⚠️ 必须先关闭已有守护进程
agent-browser close
agent-browser --allow-file-access open file:///path/to/doc.pdf
```

## 引擎选择

```bash
# Lightpanda（10x 更快更省内存，但功能有限）
agent-browser --engine lightpanda open example.com
# 不支持 --extension, --profile, --state, --allow-file-access
```

## 超时配置

```bash
# 默认 25s，可通过环境变量调整
export AGENT_BROWSER_DEFAULT_TIMEOUT=60000

# 守护进程空闲自动关闭
AGENT_BROWSER_IDLE_TIMEOUT_MS=60000 agent-browser open example.com
```

## 配置文件

创建 `agent-browser.json`：
```json
{
  "headed": true,
  "proxy": "http://localhost:8080",
  "profile": "./browser-data"
}
```

优先级（低→高）：`~/.agent-browser/config.json` < `./agent-browser.json` < 环境变量 < CLI 参数

## iOS 模拟器（仅 macOS + Xcode）

```bash
agent-browser -p ios --device "iPhone 16 Pro" open https://example.com
agent-browser -p ios snapshot -i
agent-browser -p ios tap @e1
agent-browser -p ios swipe up
agent-browser -p ios close
```

⚠️ Linux 不支持 iOS，`-p ios` 会静默回退到 Chrome。
