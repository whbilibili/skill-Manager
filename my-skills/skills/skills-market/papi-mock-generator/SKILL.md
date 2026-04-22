---
name: papi-mock-generator
description: 美团 PAPI 接口 Mock 数据生成器。读取 PAPI 接口文档的请求/响应结构，自动生成覆盖正常、边界、错误三种场景的 Mock JSON 数据。支持通过 PAPI 链接或接口路径定位接口，输出可直接用于联调的 Mock 数据和 PAPI Mock URL。触发词：生成 Mock 数据、联调 Mock、PAPI mock、接口 Mock、mock json、生成测试数据、papi.sankuai.com。

metadata:
  skillhub.creator: "linyouren"
  skillhub.updater: "linyouren"
  skillhub.version: "V1"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "10575"
---

# PAPI Mock 数据生成

## 重要前置信息

PAPI 已内置 Friday AI 生成 Mock 功能（`Mock` 按钮），但该功能每次只生成一个 case，且需要手动操作。本 skill 补全了以下能力：
1. 自动批量生成多个场景的 Mock（正常/边界/错误）
2. 从对话中直接输出可复制的 Mock JSON，无需打开浏览器
3. 自动构造 PAPI Mock URL

## 输入参数

从用户描述中提取：
- `papi_url`（与 `interface_path` 二选一）：PAPI 页面链接，如 `https://papi.sankuai.com/index/#/papi/project/<projectId>?apiId=<apiId>`
- `interface_path`（与 `papi_url` 二选一）：接口路径，如 `/quickbuy/v1/prescription/medicare/loading`
- `project_id`（当只有 `interface_path` 时需要）：PAPI 项目 ID（UUID 格式）
- `scenarios`（选填，枚举：`success`/`error`/`boundary`/`all`，默认 `all`）：生成场景

## 安全与前置校验规则

- **SSO 检查**：打开 PAPI 页面后，若 URL 跳转至 `ssosv.sankuai.com`，立即挂起任务，触发 `sso-qrcode-login` skill，扫码登录后继续
- **敏感字段处理**：生成的 Mock 数据中，手机号用 `13800138000`，身份证用 `110101199003070571`，姓名用 `测试用户`，不使用真实个人信息
- **只读操作**：本 skill 只读取接口文档，不调用真实接口，不提交 Mock 到 PAPI 服务器

## 执行 SOP

### IF 提供了 papi_url

1. 用 `agent-browser` 打开链接
2. 等待：`wait --load networkidle` + `wait 2000`（等 Hash 路由渲染）
3. 执行接口信息提取：

```bash
agent-browser eval --stdin <<'EOF'
// 点击接口条目（若未选中）
const titleEl = document.querySelector('.title___EgXCr');
if(titleEl) {
  let el = titleEl.parentElement;
  while(el && getComputedStyle(el).cursor !== 'pointer') el = el.parentElement;
  el?.click();
}
EOF
agent-browser wait 2000
agent-browser get text body
```

4. 从页面文本提取：接口路径、请求参数（名称/类型/是否必填/说明）、响应体结构（字段/类型/说明）

### IF 只有 interface_path

1. 需要 `project_id` 才能定位 PAPI 接口，若用户未提供则询问
2. 打开：`https://papi.sankuai.com/index/#/papi/project/<project_id>`
3. 在接口列表搜索框中搜索路径关键词，找到对应接口后继续

### 生成 Mock 数据

拿到接口结构后，按以下规则生成三个场景：

**场景一：正常返回（success）**
- `code: 0`，`msg: "success"`
- `data` 字段填充合理的模拟值：
  - string → 有意义的示例字符串（不用 "string" 或 "xxx"）
  - int → 合理数值
  - boolean → `true`
  - 枚举字段 → 填一个有效枚举值
  - ID 类字段 → 模拟 ID（如 `"P20260319001"`）
  - **数组/列表字段 → 必须生成 3~5 条不同的模拟数据**，不能只返回 1 条或空数组，确保列表页渲染、滚动、间距可测试

**场景二：业务错误（error）**
- `code` 为非 0 错误码（从接口文档找，或用常见错误码如 `10000`）
- `data: null`
- `error_info` 或 `msg` 填具体错误文案（如"处方人员信息不一致"）

**场景三：边界数据（boundary）**
- 字符串字段填最大长度边界值
- 列表字段返回空数组 `[]`
- 可选字段全部省略
- 数值字段填 `0` 或负值

### IF 接口文档无法读取（页面报错/接口不存在）

回复："无法读取接口文档（<原因>）。请确认：① PAPI 链接或项目 ID 是否正确 ② 你是否有该项目的访问权限 ③ 接口是否已被删除"

## 输出格式

````
## PAPI Mock 数据：<接口路径>

**Mock URL（直接在代码中替换 baseURL 使用）**：
`https://papi.sankuai.com/api/req/<projectId><interface_path>`

---

### 场景一：正常返回
```json
{
  "code": 0,
  "msg": "success",
  "data": { ... }
}
```

### 场景二：业务错误
```json
{
  "code": 10000,
  "msg": "处方人员信息与美团账号不一致",
  "data": null
}
```

### 场景三：边界数据
```json
{ ... }
```

---

**使用说明**：
- 将以上 JSON 配置到 PAPI Mock 或本地 mock 服务器
- 联调时将接口 baseURL 替换为 Mock URL 即可
````
