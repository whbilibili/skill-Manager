# 发起单据路由

> 当用户意图为"发起/提交/提报单据"时，按本文件流程执行路由判断。
> 本路由仅负责**识别和分发**，不执行具体发起逻辑。

---

## Step 1：有链接时（优先判断）

用户提供了链接，按以下规则匹配：

| 链接特征 | 判定 | 动作 |
|---------|------|------|
| `shenpi.sankuai.com/p/submit?pdId=xxx` | 快搭审批 | 告知用户：「这是快搭审批流程，请使用「快搭助手」skill 发起。」→ 若已安装则直接调用，未安装则推荐安装 |
| `kuaida.sankuai.com/app-*/form/create` 或含 `form-` | 快搭应用表单 | 同上 |
| 其他域名（如 hr.sankuai.com、contract.sankuai.com 等） | 三方流程 | → 查 `references/third-party-flows.md` 匹配 |

---

## Step 2：无链接，只有模糊描述

按以下顺序逐步尝试，命中即停：

### 2a. 搜索快搭审批流程

```bash
oa-skills shenpi queryAllowSubmitProcess --keyword "<用户关键词>"
```

> ⚠️ 该接口耗时约 20 秒，可在调用前简短告知用户「稍等，帮你查一下...」（不要暴露具体 API 调用细节）

- **有结果**：
  - 单条 → 确认后告知用户使用「快搭助手」skill 发起
  - 多条 → 展示列表让用户选择，选定后同上
- **无结果** → 进入 2b

### 2b. 搜索快搭应用表单

```bash
oa-skills shenpi queryAppList --keyword "<用户关键词>"
```

- **有结果** → 展示应用列表，用户选定后告知使用「快搭助手」skill 发起
- **无结果** → 进入 2c

### 2c. 匹配三方流程路由表

查 `references/third-party-flows.md`，用用户关键词匹配路由表中的「识别关键词」列。

- **有匹配** → 按路由表中的回复模板回复
- **无匹配** → 回复兜底话术（见下方）

---

## Step 3：兜底回复

```
该流程暂不支持通过 AI 发起。你可以：
1. 前往对应系统手动操作
2. 告诉我具体是哪个系统，我帮你查找是否有对应的 skill 可用

如有疑问，欢迎加入快搭&审批官方Skill-用户交流群反馈：
📌 [点击加入交流群](https://applink.neixin.cn/profile?gid=70425539850)
```

---

## 快搭助手 Skill 引导

当路由判定为快搭流程时，按以下逻辑处理：

- **已安装「快搭助手」（kuaida）**：直接告知用户「已识别为快搭流程，正在为你转到快搭助手...」，然后调用该 skill
- **未安装**：
  ```
  这是快搭流程，需要「快搭助手」skill 来帮你发起。
  👉 [安装快搭助手](https://friday.sankuai.com/skills/skill-detail?id=32795)
  安装后直接告诉我你要发起什么单据即可。
  ```

---

## 注意事项

1. **不要在 approval skill 内执行发起逻辑**——approval 只做路由判断和分发
2. **queryAllowSubmitProcess 只搜得到快搭审批（platformId=1）**，快搭应用表单（platformId=14）需要通过 queryAppList 搜索
3. **三方流程只做推荐引导**，不尝试代替发起
4. **禁止向用户输出路由判断过程**（如"Step 2a → 0 条 → Step 2b → 0 条"）。只输出最终结果：匹配到的推荐话术 或 兜底话术。中间的搜索、匹配步骤对用户不可见
