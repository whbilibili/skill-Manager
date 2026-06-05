# 审批授权管理（委托代办人）

通过审批中心内部 HTTP 接口，实现审批授权的创建、查询和终止。

> **鉴权方式**：本章节所有接口通过 agent-browser 在 `shenpi.sankuai.com` 域下执行 fetch（需 SSO Cookie 登录态），**非 CLI 方式**。

---

## 前置条件

通过 `agent-browser` 访问审批中心获取 SSO 登录态：

```bash
agent-browser open "https://shenpi.sankuai.com/p/home"
agent-browser wait --load networkidle
```

登录态获取后，后续所有接口通过 `agent-browser eval --stdin` 执行 fetch 调用。

---

## 接口清单

| 接口 | 方法 | 用途 |
|------|------|------|
| `/v1.1/auth/list` | POST | 查询授权列表 |
| `/v1.1/auth/new` | POST | 创建新授权 |
| `/v1.1/auth/new/process_list` | POST | 获取可授权的流程列表 |
| `/v1.1/auth/terminate/{id}` | GET | 终止授权 |
| `/service/console/bpm/v2/dataSet/users` | POST | 通过 MIS 查询用户 userId |
| `/service/aplc/workspace/userinfo` | GET | 获取当前登录用户信息 |

---

## 一、创建审批授权

### Step 1：收集必要信息

向用户确认以下信息（已提供的无需重复询问）：

| 参数 | 必填 | 说明 |
|------|------|------|
| 代办人 | ✅ | MIS 账号或姓名（需通过接口反查 userId） |
| 开始时间 | ✅ | 支持自然语言（如"明天"、"下周一"） |
| 结束时间 | ✅ | 支持自然语言（如"持续7天"、"到5月20号"） |
| 授权范围 | 可选 | 默认触发「智能流程推荐」，也可由用户直接指定 |
| 是否过滤自己发起的 | 可选 | 默认 false |

---

### Step 1.5：智能流程推荐（授权范围未指定时触发）

> **触发条件**：用户未明确指定授权流程范围时自动执行。
> **跳过条件**：用户已明确指定了具体流程名称（如"zy0513测试、项目申请"），直接进入 Step 2。

**流程：**

1. 调用审批 Skill CLI 获取近 30 天已审批单据：
   ```bash
   oa-skills shenpi getHandledApprovals --starttime '<30天前日期> 00:00' --endtime '<今天日期> 23:59' --limit 50
   ```

2. 按流程名称（`name` 字段）去重，统计各流程审批次数

3. 按频次降序排列，展示 TOP 10（不足 10 个则全部展示）：
   ```
   你最近 30 天审批了以下流程（按频次排序）：

   | # | 流程名称 | 审批次数 |
   |---|----------|----------|
   | 1 | 项目申请 | 12 |
   | 2 | 设备借用 | 8 |
   | 3 | 出差申请 | 5 |

   可以选择：
   A. 以上全部纳入授权范围
   B. 选几个（输入编号，如 1,2,4）
   C. 授权全部流程（不限范围）
   D. 自己指定流程名称
   ```

4. 根据用户选择：
   - **选 A**：将所有列出流程的名称逐个调用 `/v1.1/auth/new/process_list` 匹配，取完整字段填入 processList，`allProcess: false`
   - **选 B**：仅匹配用户选中的编号对应流程
   - **选 C**：`processList: [], allProcess: true`
   - **选 D**：按用户提供的流程名走常规的 process_list 查询逻辑

5. **匹配失败处理**：若某流程在 process_list 中查不到（三方流程等），告知用户该流程暂不支持单独授权，其余正常流程继续填入

6. **匹配策略（process_list 返回多条结果时）**：
   - 优先精确匹配：在 `pageList[].processList[].pdName` 中找与原始流程名完全相同的项
   - 若精确匹配唯一命中 → 直接使用
   - 若精确匹配命中多条（不同 appCode 下有同名流程）→ 全部列出让用户选择
   - 若无精确匹配 → 告知用户"未找到完全匹配的流程，以下是模糊结果"并列出前 5 条供选择

**边界情况：**

| 场景 | 处理 |
|------|------|
| 近 30 天无已审批记录 | 跳过推荐，告知"未找到近期审批记录"，直接询问用户选择"全部流程"或手动指定 |
| getHandledApprovals 调用失败 | 静默跳过推荐，不阻断主流程，直接询问授权范围 |
| 用户中途改主意说"算了全部流程吧" | 尊重用户最终选择，设 `allProcess: true` |

---

### Step 2：获取当前用户信息

```bash
agent-browser eval --stdin <<'EVALEOF'
(async () => {
  const resp = await fetch('/service/aplc/workspace/userinfo', {credentials: 'include'});
  const data = await resp.json();
  return JSON.stringify(data);
})()
EVALEOF
```

取 `data.data.userId` 作为 `authorizerId`。

---

### Step 3：查询代办人 userId

```bash
agent-browser eval --stdin <<'EVALEOF'
(async () => {
  const resp = await fetch('/service/console/bpm/v2/dataSet/users', {
    method: 'POST',
    credentials: 'include',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({misList: ['<代办人MIS>']})
  });
  const data = await resp.json();
  return JSON.stringify(data);
})()
EVALEOF
```

取 `data.data[0].id` 作为 `agentUserId`，`data.data[0].name` 作为 `agentUserName`。

---

### Step 4：查询并匹配流程（指定流程时）

```bash
agent-browser eval --stdin <<'EVALEOF'
(async () => {
  const resp = await fetch('/v1.1/auth/new/process_list', {
    method: 'POST',
    credentials: 'include',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({searchContent: '<流程名称关键词>'})
  });
  const data = await resp.json();
  return JSON.stringify(data);
})()
EVALEOF
```

**返回结构示例：**
```json
{
  "data": {
    "pageList": [
      {
        "platform": "APE",
        "appCode": "BPM_V2_APP_22414d1b612c45",
        "appName": "zy0513测试",
        "processList": [
          {
            "platform": "APE",
            "appCode": "BPM_V2_APP_22414d1b612c45",
            "id": 17398,
            "pdCode": "BPM_V2_PD_9a1598594ccc4a3",
            "pdName": "zy0513测试"
          }
        ]
      }
    ]
  },
  "code": 200
}
```

> 从 `pageList[].processList[]` 中取完整字段（id, pdName, pdCode, platform, appCode）填入创建授权的 processList。

---

### Step 5：创建授权

```bash
agent-browser eval --stdin <<'EVALEOF'
(async () => {
  const payload = {
    processList: [
      // 指定流程时，每项必须包含完整字段：
      {id: 17398, pdName: 'zy0513测试', pdCode: 'BPM_V2_PD_9a1598594ccc4a3', platform: 'APE', appCode: 'BPM_V2_APP_22414d1b612c45'}
    ],
    allProcess: false,            // true=全部流程，false=指定流程
    startTs: 1778774400000,       // 开始时间（毫秒时间戳）
    endTs: 1780329599000,         // 结束时间（毫秒时间戳）
    agentUserId: '20575469',      // 被授权人 userId（数字字符串）
    agentUserName: '李晓旭',      // 被授权人姓名
    authorizerId: '60549382',     // 授权人 userId（必传！）
    filterStarter: false          // 是否过滤自己发起的审批
  };

  const resp = await fetch('/v1.1/auth/new', {
    method: 'POST',
    credentials: 'include',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify(payload)
  });
  const result = await resp.json();
  return JSON.stringify(result);
})()
EVALEOF
```

> ⚠️ **processList 字段格式**：指定流程时，每项必须包含 id/pdName/pdCode/platform/appCode 全部字段。仅传 pdName/pdCode 会导致 400「授权失败，请重试」。

---

### Step 6：验证创建结果

```bash
agent-browser eval --stdin <<'EVALEOF'
(async () => {
  const resp = await fetch('/v1.1/auth/list', {
    method: 'POST',
    credentials: 'include',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({
      page: {pageNo: 1, pageSize: 10},
      authStatus: 'ALL'
    })
  });
  const data = await resp.json();
  return JSON.stringify(data);
})()
EVALEOF
```

确认 `pageList` 中最新一条 `agentState: "ACTIVE"` 即创建成功。

---

## 二、查询授权列表

```bash
agent-browser eval --stdin <<'EVALEOF'
(async () => {
  const resp = await fetch('/v1.1/auth/list', {
    method: 'POST',
    credentials: 'include',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({
      page: {pageNo: 1, pageSize: 20},
      authStatus: 'ALL'   // 可选值：ALL | EXPIRED | EFFECTIVE
    })
  });
  const data = await resp.json();
  return JSON.stringify(data);
})()
EVALEOF
```

**展示格式：**

```
📋 你的审批授权记录：

| # | 被授权人 | 状态 | 时间范围 | 授权范围 |
|---|----------|------|----------|----------|
| 1 | 李晓旭/lixiaoxu07 | 生效中 | 05/15 ~ 06/01 | zy0513测试、项目申请 |
| 2 | 李晓旭/lixiaoxu07 | 已过期 | 03/10 ~ 03/12 | 全部流程 |
```

**字段映射：**
- `agentState`: ACTIVE=生效中, TIMEOUT=已过期, TERMINATED=已终止
- `allProcess: true` → 显示"全部流程"
- `allProcess: false` → 拼接 processList 中各项 pdName

---

## 三、终止授权

```bash
agent-browser eval --stdin <<'EVALEOF'
(async () => {
  // id 从 auth/list 返回记录的 id 字段获取
  const resp = await fetch('/v1.1/auth/terminate/<id>', {credentials: 'include'});
  const result = await resp.json();
  return JSON.stringify(result);
})()
EVALEOF
```

> ⚠️ terminate 是 **GET** 方法，不是 POST。

**操作前需二次确认：**
```
即将终止以下授权：
- 被授权人：李晓旭/lixiaoxu07
- 时间范围：05/15 ~ 06/01
- 授权范围：zy0513测试、项目申请

确认终止吗？终止后被授权人将无法继续代为审批。
```

---

## 时间处理

| 用户表达 | 转换逻辑 |
|----------|----------|
| "明天到下周五" | startTs=明天 00:00:00+08:00, endTs=下周五 23:59:59+08:00 |
| "生效7天" | startTs=今天 00:00:00+08:00, endTs=今天+6天 23:59:59+08:00 |
| "5月15日到6月1号" | startTs=5.15 00:00:00+08:00, endTs=6.1 23:59:59+08:00 |

**时间戳为毫秒级（Asia/Shanghai 时区）。** 结束时间统一设为当天 23:59:59。

---

## 错误处理

| 错误信息 | 原因 | 解决方案 |
|----------|------|----------|
| "Authorization to oneself is prohibited" | 代办人不能是自己 | 提示用户更换代办人 |
| "无代理授权权限" | 未传 authorizerId | 确保传入当前用户的 userId |
| "授权失败，请重试" (400) | processList 字段不完整 | 确保每项包含 id/pdName/pdCode/platform/appCode |
| "参数错误" (400) | auth/list 未传 authStatus | 补充 authStatus 参数 |
| "未指定被授权人" | agentUserId 格式错误 | 确保使用数字字符串格式的 userId |
| users 接口返回空数组 | MIS 不存在或拼写错误 | 提示用户确认 MIS 账号 |

---

## 完成后回复模板

```
✅ 审批授权设置成功！

📋 授权详情：
- 授权人：{当前用户姓名}
- 被授权人：{代办人姓名}/{代办人MIS}
- 生效时间：{开始日期} 至 {结束日期}
- 授权范围：{全部流程 / 指定流程名列表}

期间的审批将由 {代办人姓名} 代为处理。如需提前取消，告诉我即可。
```

---

## 注意事项

1. **authorizerId 必传**：最关键的参数，不传会返回"无代理授权权限"
2. **agentUserId 是数字字符串**：不是 MIS，需通过 users 接口转换
3. **auth/list 不传 userId**：查自己的授权记录时不要传 userId，否则返回空
4. **terminate 是 GET 方法**：不是 POST
5. **processList 需要完整字段**：仅传 pdName/pdCode 会 400
6. **eval 使用 async IIFE**：agent-browser eval 不支持顶层 await，需包裹在 `(async () => { ... })()`
7. **该接口仅覆盖快搭审批中心**：不包含将军令（阿波罗/魔数）和河图数据表的代办设置
