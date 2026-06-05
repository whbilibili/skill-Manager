---
name: meijing-image-gen
version: "V12"
description: "美团内部AI生图平台（美境 aidesign.meituan.com）的浏览器自动化调用。当用户需要生成图片、插画、海报、封面等视觉内容，且希望直接出图（而非仅获取prompt文本）时使用此skill。支持选择模型、设置比例、填入prompt、触发生成、等待出图并获取结果图片。依赖浏览器已登录美团SSO。可与 image-gen-prompt skill 配合：先用后者编写高质量prompt，再用本skill执行生图。"

metadata:
  skillhub.creator: "sunjian46"
  skillhub.updater: "sunjian46"
  skillhub.version: "V12"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "1822"
  skillhub.high_sensitive: "false"
---

# 美境平台 AI 生图

通过美团内部 AI 生图平台（美境）实现端到端的文生图能力。**优先走直接 API 调用链路（更稳定、更省 token）；若 API 链路失败，自动降级到浏览器 DOM 操作链路。**

## 前置条件

- 浏览器已登录美团 SSO（访问 sankuai.com 域名不弹登录页）
- 使用 MCP browser_action 工具（非 agent-browser CLI）


## 平台信息

- 地址：`https://aidesign.meituan.com/aiCreate`
- 可用模型（截至 2026.04）：

| 模型 | type code | batchSize | 特点 | 适用场景 | 出图速度 | 支持比例 |
|------|-----------|-----------|------|---------|---------|---------|
| 即梦 5.0 | 106 | 4 | 画质与创意双升，指令遵循精准 | 复杂指令、多元素融合 | 中（15-30s） | 1:1、4:3、3:4、16:9、9:16 |
| LongCat-Image | 401 | 4 | 出图快，复杂中文渲染 | 菜品展示、中文渲染 | 快（10-20s） | 1:1、3:2、2:3、4:3、3:4、16:9、9:16 |
| Qwen-Image | 601 | 1 | 图片编辑能力佳 | 文字海报、局部修改 | 中（15-30s） | 1:1、3:2、2:3、4:3、3:4、16:9、9:16 |
| Qwen-Image-Turbo | 602 | 1 | 极速出图 | 文字海报快速生成 | 快（5-15s） | 1:1、3:2、2:3、4:3、3:4、16:9、9:16 |
| GPT-image-1.5 | 7012 | 1 | 正确的指令理解 | 创意探索、视觉草图 | 中（20-40s） | 1:1、3:2、2:3 |
| Nano Banana 2 | 7013 | 1 | 顶级真实感 | 真实摄影、精准编辑 | 慢（30-120s） | 1:1、3:2、2:3、4:3、3:4、16:9、9:16 |

**模型选择建议**：默认推荐 `Nano Banana 2`（顶级真实感，综合质量最高）；复杂指令/多元素融合用 `即梦 5.0`；中文文字渲染用 `LongCat-Image`；追求速度用 `Qwen-Image-Turbo`。

**比例建议**：PPT/汇报配图 `16:9`，手机壁纸/海报 `9:16`，社交媒体头图 `4:3`，头像/图标 `1:1`。注意：GPT-image-1.5 仅支持 1:1、3:2、2:3，若用户指定其他比例需提示并自动选最接近的。

---

## 链路一：API 直接调用（优先）

**优先走此链路**。只需浏览器保持登录态，全程通过 `evaluate` 调用 fetch，无需任何 DOM 点击操作。

### 第一步：导航到美境并确认登录

```
browser_action: navigate to https://aidesign.meituan.com/aiCreate
```

检查页面标题是否为"美境"。若跳转到登录页，提示用户扫码登录后再继续。

```bash
_log_step "step_navigate" 1
```

### 第二步：提交生图任务

**先在终端设置模型变量**（供打点使用）：

```bash
MODEL="Nano Banana 2"   # 替换为实际模型名
RATIO="16:9"            # 替换为用户指定比例
```

在浏览器中执行以下 JS，直接调用生图接口：

```javascript
// 根据模型填入对应参数（type code 和 batchSize 参考上方模型表格）
(() => {
  const TYPE = 7013;           // 替换为对应 type code
  const BATCH = 1;             // 替换为对应 batchSize
  const RATIO = "16:9";        // 与上方 bash 变量保持一致
  const PROMPT = "你的prompt"; // 替换为实际 prompt

  return fetch("/api/aidesign/ai/generate", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      promptReinforce: true,
      sampler: "euler",
      seed: -1,
      strength: "3.5",
      batchSize: BATCH,
      type: TYPE,
      prompt: PROMPT,
      aspectRatio: RATIO,
      referenceImages: { images: [] },
      context: {
        input: JSON.stringify({
          generateType: "image",
          type: TYPE,
          prompt: PROMPT,
          imageList: [],
          sizeActive: RATIO
        }),
        ratio: RATIO
      }
    })
  }).then(r => r.json()).then(d => JSON.stringify(d));
})()
```

**成功响应**：`{"code":0,"data":19705256,"success":true}`，`data` 字段即为 `taskId`。

**失败判断**：`code !== 0` 或请求本身抛出异常 → 记录错误，**进入链路二（DOM 降级）**。

```bash
SUBMIT_MS=$(python3 -c "import time; print(int(time.time()*1000))")
_log_step "step_submit" 1 0
```

### 第三步：轮询任务状态

用 `taskId` 精确查询任务状态，无需时间戳匹配：

```javascript
// 将 TASK_ID 替换为第二步拿到的 taskId
(() => {
  const TASK_ID = 19705256;
  const TYPE = 106;  // 替换为对应 type code
  return fetch("/api/aidesign/ai/generate/history", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      page: 1,
      pageSize: 5,
      typeList: [TYPE],
      taskId: TASK_ID
    })
  }).then(r => r.json()).then(d => {
    const item = d.data && d.data.list && d.data.list[0];
    if (!item) return JSON.stringify({ status: "not_found" });
    return JSON.stringify({
      taskId: item.id,
      status: item.status,   // 1=生成中, 3=完成, 4=失败
      images: item.images || [],
      imgCount: (item.images || []).length
    });
  });
})()
```

**status 含义**：
- `1` → 仍在生成，等待 10 秒后重试
- `3` → 生成完成，`images` 数组即为 S3 链接列表
- `4` 或其他 → 生成失败，进入重试流程

**轮询策略**：
1. 首次等待 15 秒
2. 查询状态，status=1 则继续等待 10 秒再查
3. 最多轮询至总等待 120 秒
4. 超时视为失败

```bash
POLL_MS=$(python3 -c "import time; print(int(time.time()*1000))")
POLL_DURATION=$((POLL_MS - SUBMIT_MS))
_log_step "step_polling" 1 "$POLL_DURATION"
```

**失败重试规则**：
1. status=4 或超时 → 自动重试（重新执行第二步）
2. 最多重试 **3 次**
3. 3 次均失败 → 打 `end` 失败节点并更新主记录，向用户报告失败原因，建议切换到即梦 5.0 或 LongCat-Image

```bash
_log_step "end" 0 0 "生成失败，已重试3次"
_finish_invocation false "生成失败，已重试3次"
```

### 第四步：获取结果并汇报

status=3 时，直接从响应的 `images` 数组获取 S3 链接，**无需任何 DOM 操作**。

```bash
END_MS=$(python3 -c "import time; print(int(time.time()*1000))")
TOTAL_DURATION=$((END_MS - SKILL_START_MS))
IMG_COUNT=4  # 替换为实际出图数量
_log_step "step_result" 1 "$TOTAL_DURATION"
_log_step "end" 1 "$TOTAL_DURATION"
_finish_invocation true
```

---

## 链路二：DOM 降级（API 链路失败时使用）

**仅在以下情况触发**：
- 链路一第二步 fetch 返回 `code !== 0`
- fetch 请求本身抛出异常（网络错误、跨域等）
- 连续 3 次 API 调用均失败

降级时在对话中告知用户："API 链路不可用，切换到浏览器操作模式..."，然后执行以下流程。

### 第一步：导航到美境

```
browser_action: navigate to https://aidesign.meituan.com/aiCreate
```

### 第二步：选择模型

```javascript
// 1. 点击模型选择器展开下拉
document.querySelector('.ai-create-select .mtd-input').click();
// 2. 等待 500ms 让下拉渲染
// 3. 从下拉菜单中选择目标模型
const items = document.querySelectorAll('.ai-model-select .mtd-dropdown-menu-item');
items.forEach(item => {
  if (item.innerText.includes('目标模型名称')) item.click();
});
```

### 第三步：选择比例

```javascript
const allSelects = document.querySelectorAll('.mtd-select');
if (allSelects.length > 1) allSelects[1].querySelector('input').click();
// 等待 500ms
const items = document.querySelectorAll('.ai-model-ratio-select .mtd-dropdown-menu-item');
items.forEach(item => {
  if (item.innerText.includes('16:9')) item.click();
});
```

### 第四步：填入 Prompt

```javascript
// 必须使用 nativeInputValueSetter 确保 Vue 响应式更新
const textarea = document.querySelector('textarea');
const nativeInputValueSetter = Object.getOwnPropertyDescriptor(
  window.HTMLTextAreaElement.prototype, 'value'
).set;
nativeInputValueSetter.call(textarea, 'prompt文本内容');
textarea.dispatchEvent(new Event('input', { bubbles: true }));
textarea.dispatchEvent(new Event('change', { bubbles: true }));
```

### 第五步：记录提交时间并触发生成

**提交前先记录当前时间**（精确到分钟），作为后续匹配结果的依据：

```javascript
(() => {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  const h = String(now.getHours()).padStart(2, '0');
  const min = String(now.getMinutes()).padStart(2, '0');
  return y + '年' + m + '月' + d + '日 ' + h + ':' + min;
})()
```

记录返回值（如 `2026年04月16日 16:09`），然后点击"立即生成"按钮。

```bash
SUBMIT_MS=$(python3 -c "import time; print(int(time.time()*1000))")
_log_step "step_submit" 1 0
```

### 第六步：等待出图与失败重试

采用**轮询检测**策略，基于提交时间戳精确定位本次任务的状态：

```javascript
// 获取所有批次概览（用于状态检查）
(() => {
  const groups = document.querySelectorAll('.history-item-container');
  const results = [];
  groups.forEach((group, i) => {
    const timeEl = group.querySelector('.info-time');
    const time = timeEl?.innerText?.replace('｜', '').trim() || 'no time';
    const imgs = group.querySelectorAll('.image-card-container img');
    let imgCount = 0;
    imgs.forEach(img => {
      if (img.src && img.src.includes('aidesign-warehouse')) imgCount++;
    });
    const hasLoading = !!group.querySelector('[class*=loading] .mtd-loading-indicator');
    const hasError = group.innerText.includes('生成失败') || group.innerText.includes('资源紧张');
    results.push({ group: i, time, imgCount, hasLoading, hasError });
  });
  return JSON.stringify(results);
})()
```

```
轮询策略：
1. 首次等待 20 秒
2. 用批次概览函数检查是否出现了匹配提交时间的批次
3. 检查该批次状态：
   - hasLoading=true, imgCount=0 → 仍在生成，继续等待 15 秒
   - hasError=true → 生成失败，进入重试流程
   - imgCount>0 → 生成完成，进入结果提取
4. 最多轮询至总等待时间 120 秒
5. 超过 120 秒仍未完成，视为超时
```

**失败重试规则**：
1. 检测到目标批次 hasError=true → 自动重试（重新填入 prompt + 点击"立即生成"）
2. 重试时**重新记录提交时间**，并重置 `SUBMIT_MS`
3. 最多重试 **3 次**
4. 3 次均失败 → 打 `end` 失败节点并更新主记录后停止

### 第七步：获取结果并汇报

```javascript
// 提取指定提交时间的批次图片（精确匹配）
(() => {
  const targetTime = '目标时间字符串'; // 如 '2026年04月16日 16:09'
  const groups = document.querySelectorAll('.history-item-container');
  const results = [];
  groups.forEach(group => {
    const timeEl = group.querySelector('.info-time');
    const time = timeEl?.innerText?.replace('｜', '').trim() || '';
    if (time.includes(targetTime)) {
      const imgs = group.querySelectorAll('.image-card-container img');
      imgs.forEach(img => {
        if (img.src && img.src.includes('aidesign-warehouse')) {
          results.push({ src: img.src, width: img.naturalWidth, height: img.naturalHeight, time });
        }
      });
    }
  });
  return JSON.stringify(results);
})()
```

```bash
END_MS=$(python3 -c "import time; print(int(time.time()*1000))")
TOTAL_DURATION=$((END_MS - SKILL_START_MS))
IMG_COUNT=4  # 替换为实际出图数量
_log_step "step_result" 1 "$TOTAL_DURATION"
_log_step "end" 1 "$TOTAL_DURATION"
_finish_invocation true
```

---

## 汇报格式（两条链路通用）

**直接将 S3 链接提供给用户，无需下载到本地。**

示例：
> 使用即梦 5.0 生成完成，共 4 张图片：
> 1. [图片1链接]
> 2. [图片2链接]
> 3. [图片3链接]
> 4. [图片4链接]
> 你挑一张最满意的，不满意我调整 prompt 重新生成。

---

## 批量生成（多任务流水线）

### API 链路（优先）

API 链路下批量生成无需等待间隔，可连续提交：

```
1. 依次调用第二步（提交任务），每次记录返回的 taskId
2. 维护任务映射表：{ 任务1: taskId1, 任务2: taskId2, ... }
3. 所有任务提交完毕后，统一轮询各 taskId 的状态
4. 全部 status=3 后，按映射表收集图片并汇报
```

### DOM 链路（降级）

DOM 链路下需要时间戳隔离：

```
1. 相邻任务提交间隔 ≥ 1 分钟（页面时间精度为分钟级）
2. 维护任务映射表：{ 任务1: 时间戳1, 任务2: 时间戳2, ... }
3. 全部提交后统一等待，用时间戳逐个提取结果
```

---

## 与 image-gen-prompt skill 的配合

推荐工作流：用户描述需求 → 调用 `image-gen-prompt` skill 编写 prompt → 调用本 skill 生图 → 将 S3 链接提供给用户 → 根据反馈迭代。

---

## 常见问题

**Q: API 链路什么情况下会失败？**
A: 主要是 SSO 登录态过期（cookie 失效）。此时 fetch 会返回 302 重定向到登录页，或 code 非 0。降级到 DOM 链路后，页面会自动跳转登录，提示用户扫码即可。

**Q: Nano Banana 2 总是失败？**
A: 该模型资源紧张，失败率较高。3 次重试后仍失败，切换到即梦 5.0。

**Q: 生成的中文文字乱码？**
A: 优先选 `LongCat-Image`（中文渲染最好），或减少画面文字量，后期用设计工具叠加。

**Q: GPT-image-1.5 不支持用户指定的比例怎么办？**
A: GPT-image-1.5 仅支持 1:1、3:2、2:3。若用户指定了其他比例，告知限制并自动选最接近的（如 16:9 → 3:2，9:16 → 2:3）。

**Q: DOM 链路批量生成时时间戳冲突？**
A: 严格确保相邻任务提交间隔 ≥ 1 分钟。如果不慎冲突，可通过批次在页面中的位置顺序（新在上旧在下）辅助区分。
