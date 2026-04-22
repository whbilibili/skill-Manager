# agent-browser 完整命令参考

## 导航

```bash
agent-browser open <url>              # 导航（别名: goto, navigate）
agent-browser back                    # 后退
agent-browser forward                 # 前进
agent-browser reload                  # 刷新
agent-browser close                   # 关闭当前页
agent-browser close --all             # 关闭所有
```

## Snapshot

```bash
agent-browser snapshot -i             # 交互元素 + @ref（推荐）
agent-browser snapshot -i -C          # 含 cursor:pointer 元素
agent-browser snapshot -s "#selector" # 限定范围
agent-browser snapshot -i --json      # JSON 输出
```

## 交互

```bash
agent-browser click @ref              # 点击
agent-browser click @ref --new-tab    # 新标签页打开
agent-browser dblclick @ref           # 双击
agent-browser fill @ref "text"        # 清空并填入
agent-browser type @ref "text"        # 追加输入
agent-browser select @ref "option"    # 下拉选择
agent-browser check @ref              # 勾选
agent-browser uncheck @ref            # 取消勾选
agent-browser press Enter             # 按键
agent-browser hover @ref              # 悬停
agent-browser focus @ref              # 聚焦
agent-browser drag @src @dst          # 拖放
agent-browser scroll down 500         # 滚动
agent-browser scroll down 500 --selector "div.content"  # 容器内滚动
agent-browser scrollintoview @ref     # 滚动到可见
agent-browser upload @ref /path/file  # 上传文件
agent-browser download @ref ./dir     # 点击下载
```

## 获取信息

```bash
agent-browser get text @ref           # 文本
agent-browser get html @ref           # HTML
agent-browser get value @ref          # 表单值
agent-browser get attr href @ref      # 属性
agent-browser get title               # 页面标题
agent-browser get url                 # 当前 URL
agent-browser get count "css=li"      # 元素计数
agent-browser get box @ref            # 位置尺寸
agent-browser get cdp-url             # CDP WebSocket URL
```

## 等待

```bash
agent-browser wait @ref               # 等待元素出现
agent-browser wait "#spinner" --state hidden  # 等待消失
agent-browser wait --load networkidle # 网络空闲
agent-browser wait --text "Welcome"   # 等待文本出现
agent-browser wait --fn "location.pathname.includes('/done')"  # JS 条件
agent-browser wait 2000               # 固定等待（毫秒）
agent-browser wait --download ./out   # 等待下载完成
```

## 状态检查

```bash
agent-browser is visible @ref
agent-browser is enabled @ref
agent-browser is checked @ref
```

## 语义查找

```bash
agent-browser find text "Sign In" click
agent-browser find label "Email" fill "user@test.com"
agent-browser find placeholder "Search" type "query"
agent-browser find testid "submit-btn" click
# ⚠️ find role --name 不可靠，优先用 find text
```

## 截图与导出

```bash
agent-browser screenshot              # 临时目录
agent-browser screenshot /path.png    # 指定路径
agent-browser screenshot --full       # 全页
agent-browser screenshot --annotate   # 带标注（视觉模型用）
agent-browser screenshot --screenshot-format jpeg --screenshot-quality 80
agent-browser pdf output.pdf
```

## JavaScript 执行

```bash
# 简单表达式
agent-browser eval 'document.title'

# 复杂 JS 用 --stdin 避免 shell 转义问题
agent-browser eval --stdin <<'EVALEOF'
JSON.stringify(Array.from(document.querySelectorAll("a")).map(a => a.href))
EVALEOF

# base64 编码方式
agent-browser eval -b "$(echo -n 'document.title' | base64)"
```

## 鼠标操作

```bash
agent-browser mouse move 100 200
agent-browser mouse down
agent-browser mouse up
agent-browser mouse wheel 300         # 滚轮
```

## 命令链

```bash
# && 链接多个命令（浏览器守护进程保持运行）
agent-browser open example.com && agent-browser wait --load networkidle && agent-browser snapshot -i
```

## 会话管理

```bash
agent-browser --session site1 open https://a.com
agent-browser --session site2 open https://b.com
agent-browser session list
agent-browser --session site1 close
```

## Diff 对比

```bash
agent-browser diff snapshot                        # 当前 vs 上次 snapshot
agent-browser diff snapshot --baseline before.txt  # 当前 vs 文件
agent-browser diff screenshot --baseline before.png  # 视觉对比
agent-browser diff url <url1> <url2>               # 两页对比
```

## 视口与设备

```bash
agent-browser set viewport 1920 1080
agent-browser set viewport 1920 1080 2    # 2x retina
agent-browser set device "iPhone 14"
agent-browser set media dark              # 暗色模式
```
