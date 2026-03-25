---
name: meijing-video
description: 通过美境(MeiJing)平台生成AI视频和图片。支持IP形象LoRA生图、首尾帧AI视频生成、通用图片生成，以及为无声视频自动生成旁白、字幕并合成最终视频。当需要AI生成视频、AI生成图片、文生视频、图生视频、AI视频制作、视频加旁白、视频加字幕时使用。触发词：AI视频、AI生图、生成视频、美境、meijing、文生视频、图生视频、视频制作、AI动画、旁白、字幕、配音。
---

# MeiJing Video & Image Generation

通过美境平台（aidesign.meituan.com）的内部API生成AI图片和视频。

## 前置条件

- 浏览器已打开并登录 `aidesign.meituan.com`（需要SSO认证）
- 使用 `browser` 工具的 `evaluate` action 在页面上下文中调用 `fetch`，借用浏览器cookie认证

## API 概览

| 功能 | API | Method |
|------|-----|--------|
| IP图片生成 | `/api/aidesign/sd/create` | POST |
| AI视频生成 | `/api/aidesign/ai/generate` | POST |
| IP图片历史 | `/api/aidesign/sd/create/history` | GET |
| AI视频历史 | `/api/aidesign/ai/generate/history` | POST |

详细参数见 [references/api.md](references/api.md)。

## 核心工作流程（必须遵守！）

### ⚠️ 视频制作标准流程

**严格按以下顺序执行，不可跳步：**

1. **拆解剧本** → 明确每个场景的画面内容、镜头语言
2. **生成关键帧图片** → 用AI（LoRA/602）为每段视频生成首帧和尾帧图片
3. **检查图片质量（必须逐张检查！）** → 每组生成4张，必须逐张查看后挑选最佳，不可直接用第一张。检查清单：
   - ✅ 角色外观与标准参考图一致（耳朵形状、服装颜色、配件）
   - ✅ 场景环境细节统一（背景风格、道具颜色、光线方向）
   - ✅ 视角与上下帧衔接自然（不要突然跳视角）
   - ✅ 动作/姿态合理（不像"漂浮""挣扎"等非预期状态）
   - ✅ 无文字乱码（必要时Pillow修复）
   - ❌ 如果4张都不达标，调整prompt后重新生成
4. **提交视频生成** → 用确认OK的首帧+尾帧提交视频任务
5. **下载+标准化** → 统一分辨率（1344×768, 24fps）
6. **拼接+上传** → ffmpeg concat → S3Plus上传
7. **视频质检（必须执行！）** → 拼接完成后，用 `ffmpeg -vf "fps=2"` 提取关键帧逐帧检查：
   - ✅ 角色在过渡帧中是否变形（中间帧比首尾帧更容易变形）
   - ✅ 转场是否自然流畅，无明显跳切
   - ✅ 动作是否符合预期（如"游泳"是否真的像在游泳）
   - ❌ 如果发现严重问题，定位到具体段落重新生成该段视频后替换拼接

**❌ 禁止直接用主体人物图生成视频！** 必须先生成场景化的首帧/尾帧图片，保证每帧都有正确的背景、构图和场景元素。主体人物图只能作为参考图/LoRA输入，不能直接做视频首帧。

**❌ 禁止用 type 602 生成团团（袋鼠IP）图片！** 凡是涉及团团/袋鼠角色的图片，必须使用 LoRA 方式（type 101, styleId 30001）生成，以保证IP形象一致性。type 602 只用于纯人类角色/通用场景/无团团的背景图。

**📝 旁白时长匹配规则：** 每段视频5秒，但旁白可能超过5秒。评估旁白/台词的朗读时长，如果超出单段视频长度，需要用相同首帧+尾帧再生成一段视频做连续拼接（后续段省略动画/转场效果，保持画面稳定即可）。

**📝 文字后期叠加规则：** 所有需要展示的文字信息（名片卡内容、标签、字幕等）统一用Pillow/ffmpeg后期叠加到视频上，不依赖AI生成文字。

### 1. IP图片生成（袋鼠LoRA）

```
页面: https://aidesign.meituan.com/ip?type=1&styleId=30001
```

1. 确保浏览器在美境IP页面（或aiCreate页面均可，API相同域）
2. 调用 `/api/aidesign/sd/create` 提交生图任务
3. 每次生成4张图（batchSize: 4）
4. 通过历史API轮询结果（status=3 表示完成）
5. 从返回的 `images[]` 数组获取CDN URL

```javascript
// 在 browser evaluate 中执行
const resp = await fetch('/api/aidesign/sd/create', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    type: 101,
    styleId: 30001,           // 三维袋鼠IP
    modelVersion: 'flux',
    modelPath: 'Flux/flux1-dev.safetensors',
    lora: [],
    prompt: '你的画面描述',
    promptReinforce: true,
    referenceImages: { variants: 0.6, images: [], mode: 'union' },
    sampler: 'euler',
    strength: '3.5',
    seed: -1,
    width: '1344',            // 16:9
    height: '768',
    batchSize: 4,
    context: { ratio: '16:9', styleActive: 0 }
  })
});
const data = await resp.json();
// data.result = taskId (number)
```

### 2. AI视频生成（即梦视频3.0）

```
页面: https://aidesign.meituan.com/aiCreate
```

支持首帧图 + 尾帧图 → 5秒插值视频。

1. 准备首帧/尾帧图片的URL（美团CDN aigchub URL 或 S3Plus URL 均可）
2. 调用 `/api/aidesign/ai/generate` 提交视频任务
3. 通过历史API轮询结果
4. 结果包含 `videoUrl` 字段

```javascript
const resp = await fetch('/api/aidesign/ai/generate', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    promptReinforce: true,
    sampler: 'euler',
    seed: -1,
    strength: '3.5',
    batchSize: 1,
    type: 503,                // 视频生成类型
    prompt: '画面运动描述',
    aspectRatio: '原图比例',
    referenceImages: {
      images: [startFrameUrl, endFrameUrl]
    },
    width: 1344,
    height: 768,
    videoLength: 5,           // 5秒
    context: {
      input: JSON.stringify({
        generateType: 'video',
        type: 503,
        prompt: '画面运动描述',
        width: 1344, height: 768,
        videoList: [
          { id: 'start', preview: startFrameUrl, uploadType: 'image', flag: true,
            loadProcess: 100, url: startFrameUrl, file: {}, frameType: 'start',
            ratio: 1.75, width: 1344, height: 768, isSucceed: true },
          { id: 'end', preview: endFrameUrl, uploadType: 'image', flag: true,
            loadProcess: 100, url: endFrameUrl, file: {}, frameType: 'end',
            ratio: 1.75, width: 1344, height: 768, isSucceed: true }
        ]
      })
    }
  })
});
const data = await resp.json();
// data.data = taskId (number)
```

### 3. 查询任务状态

#### IP图片历史
```javascript
const resp = await fetch('/api/aidesign/sd/create/history?page=1&pageSize=10&endTime=' + Date.now() + '&type=101');
const data = await resp.json();
// data.result.results[] 每项包含: id, status, images[], inputs.prompt
// status: 3=完成, 其他=进行中
```

#### AI视频历史
```javascript
const resp = await fetch('/api/aidesign/ai/generate/history', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    page: 1, pageSize: 10,
    endTime: Date.now(),
    typeList: [503]  // 仅视频
  })
});
const data = await resp.json();
// data.data.list[] 每项包含: id, status, videoUrl, videoPreviewUrl, images[]
```

### 4. 质量控制

- 每个视频任务最多重试 **3次**
- 检查要点：画面连贯性、角色一致性、文字正确性
- 图片生成每次出4张，人工挑选最佳

## 常用参数速查

| 参数 | 图片生成 | 视频生成 |
|------|---------|---------|
| type | 101 | 503 |
| API | /api/aidesign/sd/create | /api/aidesign/ai/generate |
| batchSize | 4 | 1 |
| 模型 | flux | 即梦视频3.0 |
| 常用比例 | 16:9 (1344×768) | 原图比例 |

## 双模型策略（人类角色 vs 团团）

袋鼠LoRA（styleId=30001）会将所有角色都融合成袋鼠，无法生成纯人类角色。解决方案：

| 场景类型 | API | type | 说明 |
|---------|-----|------|------|
| 团团场景 | `/api/aidesign/sd/create` | 101 + styleId:30001 | 袋鼠LoRA，自动融合袋鼠 |
| 人类角色/通用场景 | `/api/aidesign/ai/generate` | 602 | 无LoRA，可生成正常人类 |

### Type 602 参数（无LoRA通用生成）

```javascript
const resp = await fetch('/api/aidesign/ai/generate', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    promptReinforce: true,
    sampler: 'euler',
    seed: -1,
    strength: '3.5',
    batchSize: 4,
    type: 602,
    prompt: '你的描述',
    aspectRatio: '16:9',
    referenceImages: { images: [] },
    width: 1344,
    height: 768,
    context: {
      input: JSON.stringify({
        generateType: 'image',
        type: 602,
        prompt: '你的描述',
        width: 1344, height: 768,
        imageList: [],
        sizeActive: '16:9'
      }),
      ratio: '16:9'
    }
  })
});
```

**注意：** type 106(SEEDREAM5) 和 105 目前不可用（全部 status=4 失败）。type 104 可用但风格更Q版。推荐用 type 602。

### 参考图生成（角色一致性）

美境aiCreate页面支持上传参考图来保持角色一致性。在 `referenceImages.images[]` 中传入参考图CDN URL。

#### ⚠️ 角色一致性保障流程（必须遵守！）

多帧生成时角色外观容易不一致（服饰细节变化、配件丢失/变色、耳朵形状变形等）。**必须执行以下流程：**

1. **先生成"标准形象图"** — 第一批生成时不带参考图，从4张候选中选出角色形象最满意的一张作为标准参考图
2. **后续所有帧都传入参考图** — 在 `referenceImages.images[]` 中传入标准形象图URL
3. **`variants` 设为 0.8** — 默认 0.6 约束力度不够，容易跑偏。建议 0.8 以上
4. **prompt 中固定关键外观细节** — 不能只描述动作/场景，必须同时固定角色的核心外观特征（服装颜色、配件描述、道具等）。例如：`wearing white warrior robe, pink swim goggles, red and white lane dividers`
5. **逐张比对检查** — 生成后对比标准参考图，检查角色是否走样

```javascript
// 示例：带参考图生成
referenceImages: {
  variants: 0.8,           // 提高到0.8保证一致性
  images: [standardRefUrl], // 传入标准形象图
  mode: 'union'
}
```

## 场景难度评估

袋鼠LoRA在不同场景下的表现差异很大。生成前应先评估场景难度，对困难场景采用替代方案。

### 袋鼠IP擅长的场景 ✅
| 场景类型 | 说明 |
|---------|------|
| 站立/行走 | 静态或简单移动，效果稳定 |
| 武打/战斗 | 夸张动作、飞踢、持剑，AI表现好 |
| 表情特写 | 开心/愤怒/惊讶等面部表情 |
| 庆祝/挥手 | 简单的肢体动作 |
| 场景切换 | 从A场景走到B场景，跟随镜头 |

### 袋鼠IP困难的场景 ⚠️
| 场景类型 | 问题 | 替代方案 |
|---------|------|---------|
| 游泳/水上运动 | 圆润身体无法做出标准泳姿，看起来像"漂浮" | 改用跳水→水下冲刺→出水的物理过渡，绕开水面泳姿 |
| 精细手部动作 | 袋鼠手臂短，精细操作（写字、弹琴）不自然 | 用特写镜头只拍手部局部 |
| 跨环境过渡 | 水下→水面、室内→室外等大视角变化 | 拆成多个小过渡段，每段只变一个维度 |
| 写实运动姿态 | 跑步、体操等需要标准人体比例的动作 | 用卡通夸张风格替代写实，加大水花/烟尘/速度线等动态效果 |

### 通用规避策略
1. **扬长避短** — 不强求AI画不擅长的写实动作，用替代场景表达同样的故事
2. **视角变化要小** — 相邻帧之间最多变一个维度（视角/场景/光线），不要同时变多个
3. **大视角过渡要拆段** — 例如水下→水面，拆成"水下→水面半身"+"水面半身→庆祝"两小段

---

## 旁白+字幕生成流程（Post-Production）

为已生成的无声视频添加旁白语音和字幕。

### 触发条件

当用户有已完成的视频（无声/无字幕），需要添加旁白或字幕时触发。**旁白生成是可选流程，必须先询问用户：**

> "需要为视频自动生成旁白吗？还是你来提供旁白文案/字幕？"

用户有三种选择：
1. **自动生成** — 我来分析视频内容、撰写旁白、合成语音
2. **用户提供文案** — 用户给出旁白文字（带或不带时间轴），我负责 TTS + 合成
3. **只加字幕** — 用户提供字幕文案，我只烧录字幕，不加语音

---

### 完整 Pipeline

```
无声视频
  ↓
[可选] 视频内容理解
  ↓
旁白文案 + 时间轴（JSON）
  ↓
TTS 语音合成（Edge TTS）
  ↓
音频合成（ffmpeg adelay + amix）
  ↓
字幕生成（ASS格式）+ 烧录
  ↓
成品视频（ffmpeg）
  ↓
S3Plus 上传
```

---

### Step 1：确认用户意图

```
询问：
"有以下几种方式，你想选哪种？
1. 自动理解视频内容，AI生成旁白（推荐，我来做）
2. 你提供旁白文案，我来配音+加字幕
3. 只加字幕，不加语音
音色推荐：云夏（可爱男声）、小艺（活泼女声）、晓晓（温暖女声），有偏好吗？"
```

---

### Step 2：视频内容理解（仅自动模式）

```bash
# 按帧率抽帧，短视频(≤60s)用0.5fps，长视频(>60s)用0.33fps
ffmpeg -i input.mp4 -vf "fps=0.5" -q:v 2 frames/frame_%03d.jpg
```

- 用 `read` 工具逐帧读取图片，分析画面内容
- 结合已有剧本（breakdown.md）交叉验证
- 识别场景切换点，估算每段起止时间

---

### Step 3：旁白文案 + 时间轴

**用户提供格式（任意格式均可接收）：**

- 纯文本（我根据视频时长自动分配时间轴）
- SRT格式（直接使用）
- JSON时间轴格式（直接使用）

**AI自动生成格式（输出JSON）：**

```json
[
  {"id": 1, "start": 0.5, "end": 5.0, "text": "旁白内容"},
  {"id": 2, "start": 6.0, "end": 11.0, "text": "旁白内容"},
  ...
]
```

**文案原则：**
- 文字量适配时间窗口（不要过多，留呼吸空间）
- 每段建议留0.5s静默间隔
- 根据画面节奏写，不逐帧描述
- 关键信息要点，语言简洁口语化

---

### Step 4：TTS 语音合成

使用 node-edge-tts（通过沙箱代理连接微软服务）：

```javascript
// 工作目录: /tmp/edge-tts-test（已预装 node-edge-tts）
const { EdgeTTS } = require('node-edge-tts');
const tts = new EdgeTTS({
  voice: 'zh-CN-YunxiaNeural',   // 云夏（默认推荐）
  proxy: process.env.HTTPS_PROXY || 'http://squid-admin:catpaw@nocode-supabase-squid.sankuai.com:443',
  timeout: 15000,
  rate: '-5%'   // 稍慢，更自然
});
await tts.ttsPromise(text, '/path/to/seg_01.mp3');
```

**可用中文音色（Edge TTS）：**

| 音色ID | 名称 | 风格 | 适用场景 |
|---|---|---|---|
| zh-CN-YunxiaNeural | 云夏 | 可爱男声 | 卡通/活泼视频 ✅ 推荐 |
| zh-CN-XiaoyiNeural | 小艺 | 活泼女声 | 卡通/活泼视频 |
| zh-CN-XiaoxiaoNeural | 晓晓 | 温暖女声 | 宣传/叙述视频 |
| zh-CN-YunxiNeural | 云希 | 阳光男声 | 青春/励志视频 |
| zh-CN-YunyangNeural | 云扬 | 新闻男声 | 正式/播报场景 |

生成后验证每段时长 vs 时间窗口，如果超出目标时间则适当延长对应段的 `end` 时间。

---

### Step 5：音频合成

```bash
# 用 adelay 把各段语音按时间轴精确定位，再 amix 合并
ffmpeg -y \
  -i seg_01.mp3 -i seg_02.mp3 \
  -filter_complex "
    [0]adelay=500|500[d0];
    [1]adelay=6000|6000[d1];
    [d0][d1]amix=inputs=2:duration=longest:dropout_transition=0[out]" \
  -map "[out]" -ac 1 -ar 44100 narration_full.mp3
```

---

### Step 6：生成 ASS 字幕

```
[Script Info]
PlayResX: 1344
PlayResY: 768

[V4+ Styles]
Style: Default,Noto Serif CJK SC,40,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,1,2,20,20,50,1

[Events]
Dialogue: 0,0:00:00.50,0:00:05.00,Default,,0,0,0,,旁白内容
Dialogue: 0,0:00:06.00,0:00:11.00,Default,,0,0,0,,旁白内容
```

字幕样式：白字 + 黑色描边（Outline=3，Shadow=1），底部居中，字号40。

---

### Step 7：合成最终视频

```bash
# 视频 + 音频 + ASS字幕一步合成
ffmpeg -y \
  -i input.mp4 \
  -i narration_full.mp3 \
  -filter_complex "[0:v]ass=narration.ass[v]" \
  -map "[v]" -map "1:a" \
  -c:v libx264 -preset medium -crf 18 \
  -c:a aac -b:a 192k \
  -shortest \
  output_narrated.mp4
```

如果用户只要字幕不要语音：
```bash
ffmpeg -y -i input.mp4 \
  -filter_complex "[0:v]ass=narration.ass[v]" \
  -map "[v]" -c:v libx264 -preset medium -crf 18 \
  output_subtitle.mp4
```

---

### Step 8：上传 S3Plus

使用 s3plus-upload skill 上传，获取下载链接发给用户。

---

### 常见问题

**Q: Edge TTS 连不上微软服务？**
A: 沙箱需要走代理。使用 node-edge-tts（npm包），在构造函数中传入 `proxy`：
```javascript
const PROXY = process.env.HTTPS_PROXY;  // 环境变量中已有代理配置
new EdgeTTS({ voice: '...', proxy: PROXY })
```
注意：python 的 edge-tts 不支持 proxy 参数，必须用 node 版本。

**Q: 语音太快怎么办？**
A: ① 减少每段文字量；② rate 改为 `-10%` 或 `-15%`；③ 延长时间窗口（end时间推后）

**Q: 中文字幕乱码/不显示？**
A: ASS 字体指定 `Noto Serif CJK SC`，沙箱已安装。

**Q: 用户提供的是 SRT 格式字幕？**
A: ffmpeg 支持直接使用 SRT：
```bash
ffmpeg -i input.mp4 -vf "subtitles=narration.srt:force_style='FontSize=40,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,Outline=3,MarginV=50'" output.mp4
```

---

## 注意事项

### Prompt 规则
- prompt中不需要写"袋鼠"，LoRA会自动融合袋鼠形象

- 人类角色prompt加"Pixar style"/"cute 3D C4D"效果好，加"skin-colored round face"强调人类特征

### ⚠️ 文字错误处理（重要！）
- **AI生成的图片中文字几乎必然有拼写错误**，包括英文！如 "Gateway" → "GATWAY"，"Security Booth" → "Security Both"，"Temporary" → "Temnorary"
- **图片里绝对不能有错字** — 需要逐张检查每张生成的图片
- **处理策略：**
  1. 首选：prompt中加 "NO TEXT" / "NO READABLE TEXT" 避免生成文字（但AI可能把"NO TEXT"本身写上去😂）
  2. 对有错字的图：最多重试5次，从多次生成中挑选无错字版本
  3. 实在无法避免：用Pillow覆盖错误文字区域，再叠加正确标签
  4. 所有中文标签必须用代码（Pillow/ffmpeg drawtext）后期叠加，绝不依赖AI生成
- **prompt中绝对不要要求生成中文文字**，模型会产生乱码
- 视频字幕用ffmpeg drawtext后期添加，不靠AI生成

### 镜头语言（视频生成）
- 视频生成的motion prompt中加入镜头描述可提升效果：
  - "Camera slowly zooms in" / "Camera pulls back"
  - "Camera transitions from left to right"
  - "Camera follows the path"
  - "Slight camera movement, characters wave"
- 场景切换：用首帧A+尾帧B生成5秒过渡视频
- 特写镜头：prompt中加 "close-up shot"
- 俯视镜头：prompt中加 "aerial birds-eye view"

### URL 和 CDN 规则
- **美境视频API只接受自家CDN URL**（aigchub/aidesign域名），S3Plus URL会导致生成失败(status=4)
- 图片URL格式：`https://p0.meituan.net/aigchub/xxx.png`（CDN地址可直接用于视频首帧）
- type 602 生成的图也返回CDN URL，可直接用于视频生成

### 其他
- 视频生成耗时约1-3分钟，轮询间隔建议30秒
- type 602 每次只返回1张图（不像LoRA返回4张），需要多图时多次提交
- 所有API调用必须在浏览器页面上下文中通过 `fetch` 执行（依赖cookie认证）
- 每段视频需同时上传带字幕版和不带字幕版到S3
