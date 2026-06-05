---
name: meigen-designer
description: 美境 AI 设计师。凡是涉及视觉创作的需求，优先使用此 skill，包括但不限于：文生图、图生图、图片编辑、海报设计、Banner 制作、IP 形象设计（美团袋鼠/小象等）、LOGO 设计、ICON 设计、插画、表情包、包装设计、VI 设计、文创礼品、套图生成、文生视频、图生视频等。用户说"帮我画""生成一张""做个海报""设计个 logo""给图片加效果""让图动起来"等，都应使用此 skill。使用前会自动检查并获取用户身份认证信息。

metadata:
  skillhub.creator: "zhuxiangyu04"
  skillhub.updater: "chenshengtao"
  skillhub.version: "V8"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "5315"
  skillhub.high_sensitive: "false"
---

# 美境 - AI 设计师

美境是一个 AI 设计平台，支持文生图、图生图、图片编辑、IP 设计、视频生成等全链路视觉创作能力。

## 文件存储

- `meigen/conversation_id` - 会话 ID（自动生成，跨调用持久化，用于上下文关联）

路径相对于 skill 目录（SKILL.md 同级）。

---

## 环境准备

**在执行任何操作前，按顺序完成以下准备：**

### 1. 检查 meigen-cli

执行 `meigen --version`，确认版本号 **>= 1.4.1**。

- **未安装**（命令不存在）：询问用户是否安装 meigen-cli，用户同意后执行 `npm install -g @meigen/meigen-cli@latest`
- **版本过低**：询问用户是否升级 meigen-cli，用户同意后执行 `npm install -g @meigen/meigen-cli@latest`

### 2. 同步 Skill 版本

先获取 `<dirname>`——即存放各个 skill 子目录的那个**上级目录**：

```bash
DIRNAME="$(cd "$(dirname "<this-skill-md>")/.." && pwd)"
```

> 举例：如果本 SKILL.md 的绝对路径是 `/a/b/skills/meigen-designer/SKILL.md`，
> 那么 `<dirname>` = `/a/b/skills`（注意不是 `/a/b/skills/meigen-designer`）。

然后执行同步：

```bash
meigen sync "$DIRNAME" meigen-designer
```

该命令比较本地与远程的 `skillhub.version`，若有新版本则自动拉取更新。状态信息输出到 **stderr**，根据**退出码**判断结果：退出码 0 = 成功，1 = 同步失败，2 = 前置检查失败（如 mtskills 缺失）。

| 退出码 | stderr 关键词 | 含义 | 后续动作 |
|-------|-------------|------|---------|
| 0 | `已是最新` | 本地已是最新版本 | 继续下一步 |
| 0 | `已更新` | 已自动更新到最新版本 | 继续下一步 |
| 0 | `已安装` | skill 首次注册安装成功 | 继续下一步 |
| 2 | `未检测到 mtskills` | 缺少 mtskills 依赖，进程直接退出 | 用 `AskUserQuestion` 询问用户是否安装：`npm install -g @mtfe/mtskills --registry=http://r.npm.sankuai.com`，用户同意后执行安装，再**重新执行** `meigen sync` |
| 1 | `失败` / `更新失败` | 同步异常 | 告知用户错误信息，跳过同步继续后续步骤（不阻塞流程） |

### 3. 获取认证 Token

```bash
TOKEN=$(meigen login)
```

`meigen login` 自动处理 token 缓存、刷新和 CIBA 认证，将 access_token 字符串输出到 stdout。如果返回非零退出码，提示用户检查网络或执行 `meigen login --force` 重新认证。

**Token 复用规则**：获取一次 token 后，同一任务流程中的 `generate.py` 和 `upload-to-s3.py` 调用应复用同一个 `$TOKEN`。仅当脚本返回 401 错误时，才重新执行 `TOKEN=$(meigen login)` 获取新 token 并重试。

### 4. 获取用户信息

```bash
AUTH_JSON=$(meigen status --json)
MIS_ID=$(echo "$AUTH_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['mis_id'])")
```

`meigen status --json` 输出结构化 JSON（含 `mis_id` 和 `token` 字段）到 stdout。`MIS_ID` 将作为 `--mis-id` 参数传给 `generate.py`。

如果 `mis_id` 为空，说明用户未登录，应先执行 `meigen login --force` 完成认证。

### 5. 确认脚本目录

`generate.py` 和 `upload-to-s3.py` 位于本 SKILL.md **同级**的 `scripts/` 目录下：

```bash
SCRIPT_DIR="$(cd "$(dirname "<this-skill-md>")" && pwd)/scripts"
```

> 举例：如果本 SKILL.md 路径是 `/a/b/skills/meigen-designer/SKILL.md`，
> 那么 `SCRIPT_DIR` = `/a/b/skills/meigen-designer/scripts`。

## ⚠️ 消息发送规则（强制）

**整个生图流程中，所有发给用户的消息（确认、进度、结果）一律通过 `message` 工具发送，助手回复文本最后只输出 `NO_REPLY`。**

原因：助手回复文本会被延迟到所有工具调用完成后才送达，和 `message` 混用会导致消息顺序错乱。

具体要求：
1. 收到生图请求后，**第一个动作**就是 `message(action=send)` 发确认（如"收到，马上生成 🎨"）
2. [STEP] 进度、最终图片结果，全部通过 `message` 发送
3. **大象频道 target 格式**：DM 用 `single_{uid}`（如 `single_2804968617`），群聊用 `group_{gid}`
4. **禁止发送内部思考**——"读一下XX规则"、"检查认证文件"等推理过程不能发给用户，只发用户关心的：确认收到、进度步骤、最终结果
5. 助手回复文本只用 `NO_REPLY`，不输出任何内容

## 工作流程

### 第一步：生成图片

**基本用法（纯文字描述）：**
```bash
python3 "$SCRIPT_DIR/generate.py" "<用户描述>" "$TOKEN" --mis-id "$MIS_ID" 2>&1
```

**带参考图片（图生图 / 基于图片修改）：**
```bash
python3 "$SCRIPT_DIR/generate.py" "<用户描述>" "$TOKEN" --mis-id "$MIS_ID" --image "<图片URL>" 2>&1
```

**多张参考图片：**
```bash
python3 "$SCRIPT_DIR/generate.py" "<用户描述>" "$TOKEN" --mis-id "$MIS_ID" --image "<图片URL1>" --image "<图片URL2>" 2>&1
```

> 脚本会在生图完成后**自动调用 `meigen report` 上报使用数据**（后台异步，不阻塞主流程）。上报内容包括：提示词、耗时、成功/失败状态、生成图片数量、会话 ID、用户 misId 等。

参数说明：
- `<用户描述>`：**直接使用用户的原始描述文字**，不要改写、润色或添加额外修饰词。用户说什么就传什么。
- `$TOKEN`：由环境准备阶段 `meigen login` 获取的 access_token 字符串
- `--mis-id $MIS_ID`：由环境准备阶段 `meigen status --json` 获取的用户 misId
- `--image <url>`：参考图片 URL（可选，可多次指定）

⚠️ **提示词原则（强制）：尽量保留用户原始提示词，不要擅自改写、润色或添加额外描述。** 用户说"生成一张蓝红色的奥特曼"，就传"蓝红色的奥特曼"，不要自行扩展成"蓝红色奥特曼，经典造型，英雄姿态，高质量细节渲染..."。美境设计师本身会做专业的 prompt 优化，助手不需要代劳。

脚本行为：
- **conversation_id 自动持久化**：首次调用时生成，后续调用复用同一个 conversation_id（保存在 `meigen/conversation_id` 文件中），使美境接口能感知多轮对话上下文（如"把上一张图的颜色改成蓝色"）
- ⚠️ **上下文关联（重要）**：同一个 conversation_id 下，美境设计师**自动知道之前生成过什么**。对上一轮结果做修改时（如"改成绿色""背景换成星空"），**无需传 `--image` 参考图**，直接传用户的修改描述即可。只有当用户**主动提供了新的外部图片**时才需要用 `--image`。
- 成功：stdout 每行一个图片 URL
- 失败：`ERROR: <原因>`，退出码非零
- 进度：stderr 输出 `[STEP]` 前缀的步骤日志

### 调用示例

#### 示例 1：纯文字生图
```bash
# <skill目录> 为运行时动态确定的 SKILL.md 所在绝对路径
python3 "$SCRIPT_DIR/generate.py" \
  "扁平插画风格的新学期目标卡片，马卡龙色调，横版4:3" \
  "$TOKEN" --mis-id "$MIS_ID" 2>&1
```

#### 示例 2：基于参考图修改（图生图）
用户发了一张图，想在此基础上修改风格或内容：
```bash
python3 "$SCRIPT_DIR/generate.py" \
  "把这张海报改成赛博朋克风格，保持原有的构图和文字布局" \
  "$TOKEN" --mis-id "$MIS_ID" \
  --image "http://p0.meituan.net/bizhorus/abc123.jpg" 2>&1
```

#### 示例 3：参考多张图片生成新图
用户提供多张参考图，要求融合风格：
```bash
python3 "$SCRIPT_DIR/generate.py" \
  "参考这两张图的风格，生成一张美团外卖骑手的扁平插画，色调温暖" \
  "$TOKEN" --mis-id "$MIS_ID" \
  --image "http://p0.meituan.net/bizhorus/style_ref1.jpg" \
  --image "http://p1.meituan.net/bizhorus/style_ref2.png" 2>&1
```

#### 示例 4：对上一轮生成的图进行修改（利用上下文）✅ 推荐方式
由于 conversation_id 持久化，美境设计师**自动知道上一轮生成了什么**。修改上一轮的结果时，**直接传用户的修改描述，不需要传 `--image`**：
```bash
# ✅ 推荐：直接描述修改意图，无需 --image
python3 "$SCRIPT_DIR/generate.py" \
  "改成绿色的" \
  "$TOKEN" --mis-id "$MIS_ID" 2>&1
```

```bash
# ✅ 另一个例子：用户说"背景换成星空"
python3 "$SCRIPT_DIR/generate.py" \
  "背景换成星空" \
  "$TOKEN" --mis-id "$MIS_ID" 2>&1
```

> **注意**：只有当用户主动提供了一张**新的外部图片** URL 时，才需要用 `--image` 参数。对同一会话中已生成图片的修改，conversation_id 已经提供了足够的上下文。

### 第三步：实时推送进度

**核心目标：让用户实时看到设计师的思考和工作过程。**

采用后台执行 + 短间隔轮询 + 逐条推送：

```
# 1. 后台启动脚本
exec(command="python3 ... 2>&1", background=true) → 记录 sessionId

# 2. 轮询循环（直到进程退出）
offset = 0
LOOP:
  process(action=poll, sessionId=<sid>, timeout=3000)
  process(action=log, sessionId=<sid>, offset=<offset>)

  # 对每行 [STEP]：去掉前缀，非空则立即 message 发送
  # ⚠️ 每条 STEP 单独一次 message，不合并不攒批

  offset += 本次行数
  如果进程已退出 → 跳出

# 3. 提取图片 URL（非 [STEP] 的 http 开头行），用 message 发送最终结果
```

**关键规则：**
- poll 超时不超过 3 秒
- 每条 [STEP] 独立发送，去掉 `[STEP] ` 前缀
- 跳过空内容的 STEP
- **图片 URL 去重（强制）**：脚本输出的图片 URL 可能包含重复（带尾部反斜杠 `\` 的变体、多次出现的相同 URL 等）。提取最终图片时，先对 URL 做标准化（去除尾部 `\` 字符）再去重，只保留唯一的 URL 列表发送给用户
- 最终图片用 markdown 图片语法通过 message 发送
- **图片 URL 直接使用（强制）**：生图脚本输出的图片 URL（`p0.meituan.net` 等）在大象通道可直接访问，**不需要**上传到 S3Plus 再获取新 URL，直接用原始 URL 发送即可
- 美团 IP 相关图片（袋鼠、小象等）生成较慢（60-90秒），可提前告知用户

## 错误处理

脚本会检测两类错误：

### 1. JSON 错误响应（非 SSE 流）

接口可能返回 HTTP 200 但 body 是 JSON 错误体而非 SSE 流。脚本会自动检测并输出完整错误信息：

```
ERROR: 接口返回错误 (HTTP body status=401, code=30001)
  message: auth failed
  msg: ssoid 过期
  原始响应: {"data":{"msg":"ssoid 过期","code":30001,...},"status":401}
```

**处理规则：**
- **`auth failed` / `ssoid 过期`**（code=30001）：CLI 会自动处理，删除旧 token 并重新认证
- **其他 JSON 错误**：将脚本输出的错误信息（含原始响应）展示给用户，建议重试

### 2. HTTP 错误 / 网络错误

- **HTTP 4xx/5xx**：脚本输出 `ERROR: HTTP {code} - {reason}. Body: {body}`
- **网络错误**：脚本输出 `ERROR: 网络错误 - {reason}`
- **请求超时（300s）**：脚本输出 `ERROR: 请求超时`

### 3. 通用处理

- **轮询超时（3分钟未授权）**：提示用户重试
- **0 个事件且无图片**：脚本输出 DEBUG 信息 + `ERROR: 未获取到图片`，展示给用户

## 重置认证

用户说「重置美境认证」「重新登录」「清除认证」时，运行：

```bash
meigen logout
```

告知用户已重置。如用户同时有生图请求，重新认证后继续执行。

## 重置会话上下文

用户说「新对话」「重置会话」「清除上下文」时：删除 `meigen/conversation_id`，下次调用会自动生成新的 conversation_id。

## 自动上报

每次生图完成（无论成功或失败）后，脚本会在后台自动调用 `meigen report` 上报使用数据，无需手动操作。上报字段说明：

- `--scene meigen-designer`：固定为 skill 名称
- `--status 2|3`：2 表示成功（获取到图片），3 表示失败
- `--request`：包含用户提示词和参考图数量
- `--response`：成功时包含生成的图片 URL 列表
- `--duration`：生图总耗时（毫秒）
- `--conversation-id`：当前会话 ID
- `--user-id`：从 `meigen/mis_id` 文件自动读取
- `--version 1.0.0`：Skill 版本号

上报为后台异步执行（`Popen` + `start_new_session`），失败时静默忽略，不影响主流程。

## 品牌水印

任务**成功**后，调用 `meigen brand` 输出品牌文案行（失败任务跳过）：

```bash
meigen brand --skill-name meigen-designer --media <media>
```

`<media>` 根据任务类型判断：
- 生图任务（文生图、图生图、图片编辑等）：`--media 图`
- 视频任务（文生视频、图生视频等）：`--media 视频`

示例：
```bash
# 图片任务
meigen brand --skill-name meigen-designer --media 图

# 视频任务
meigen brand --skill-name meigen-designer --media 视频
```

## 上传图片

**使用场景**：

1. 用户提供外部图片 URL（非 meituan 域名）时，需要先下载到本地，再上传到美境才能在对话中使用。
2. 用户引用了本地的文件，需要先上传为URL才能在对话中使用。

```bash
python3 "$SCRIPT_DIR/upload-to-s3.py" <本地文件路径> "$TOKEN" 2>&1
```

参数说明：
- `<本地文件路径>`：本地图片文件的完整路径
- `$TOKEN`：由环境准备阶段获取的 access_token 字符串

⚠️ **URL 有效期 1 天**：上传后的 URL 只有 24 小时有效期，仅用于临时上传后立即调用美境生图接口，不适合长期存储。

**流程示例**：
```
用户提供外部图片 URL → 下载到本地 → 上传到美境 → 获取临时 URL → 用于 --image 参数
```

成功示例：
```
[STEP] 🔐 获取 access_token...
[STEP] ✅ 使用缓存的 access_token（剩余 6 小时）
[STEP] 📝 请求加签参数...
[STEP] 🔑 key: skillopen/abc123.jpg
[STEP] ✅ 加签成功
[STEP] 📤 上传文件到 S3...
[STEP] ✅ 上传成功
https://s3plus.sankuai.com/aigc-warehouse/skillopen/abc123.jpg
```

失败时输出 `ERROR: <原因>` 并以非零退出码退出。
