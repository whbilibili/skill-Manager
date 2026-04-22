# Mock 生命周期规范

> 前端工程专属规范。每一个 Mock 文件都有明确的出生时机、存活条件和死亡时机。

---

## 核心原则

**Mock 文件不是永久基础设施，是临时脚手架。**

每个 Mock handler 在 feature-list.json 中必须有一个且仅有一个「清理责任人 Task」。
当该 Task 完成时，Mock 文件必须被删除——这是 DoD 的强制条件。

---

## 生命周期状态机

```
CREATED（随 Task 创建）
    ↓ 开发阶段
ACTIVE（本地开发使用）
    ↓ 后端接口完成，开始联调
PENDING_REMOVAL（联调中，前后端数据结构对齐）
    ↓ 联调通过，DoD 验证
DELETED（Mock 文件从仓库删除）
```

---

## feature-list.json 中的 mock_schema 规范

```json
{
  "api_consumption": {
    "method": "GET",
    "path": "/api/v1/users",
    "response_shape": {
      "code": 0,
      "data": {
        "list": [{ "id": "string", "name": "string" }],
        "total": "number"
      }
    },
    "mock_schema": {
      "file": "src/mocks/handlers/users.ts",
      "removal_condition": "Task MODULE-003（用户列表联调）通过后删除",
      "status": "active | pending_removal | deleted"
    }
  }
}
```

**字段说明：**
- `file`：Mock handler 的相对路径，必须唯一
- `removal_condition`：指向具体的联调 Task ID，不允许写「等联调完成」这类模糊表述
- `status`：Mock 当前的生命周期状态，随联调进度更新

---

## Mock handler 文件规范

每个 handler 文件头部必须包含注释声明：

```typescript
/**
 * @mock-for GET /api/v1/users
 * @linked-task MODULE-001
 * @removal-task MODULE-003
 * @removal-condition MODULE-003（用户列表联调）通过后删除本文件
 * @created 2024-01-15
 */
import { http, HttpResponse } from 'msw';

export const usersHandler = http.get('/api/v1/users', () => {
  return HttpResponse.json({
    code: 0,
    data: {
      list: [
        { id: '1', name: '张三' },
        { id: '2', name: '李四' },
      ],
      total: 2,
    },
  });
});
```

---

## Mock 孤儿检查

在 `init.sh` 和 CI 中强制执行以下检查：

**孤儿 Mock（危险）**：存在于 `src/mocks/handlers/` 但未在任何 Task 的 `mock_schema.file` 中声明的文件。
→ 这意味着这个 Mock 已经脱离管控，不知道是否应该删除。

**残留 Mock（待清理）**：`mock_schema.status = "pending_removal"` 但文件仍然存在，且对应的清理 Task 已经 `completed`。
→ 这意味着有人忘记删 Mock 文件了。

---

## 联调清理流程

1. 后端接口部署完成，通知前端开始联调
2. 前端将对应 Task 的 `mock_schema.status` 更新为 `"pending_removal"`
3. 前端验证真实接口的响应结构与 `response_shape` 对齐（如不对齐，与后端协商修改 `response_shape`）
4. 联调通过后：
   - 删除 `src/mocks/handlers/xxx.ts` 文件
   - 从 `src/mocks/index.ts` 中移除 handler 引用
   - 将 `mock_schema.status` 更新为 `"deleted"`
   - 将对应 Task 标记为 `completed`
5. 运行 `init.sh --mock-check-only` 确认无孤儿 Mock

---

## 常见错误

| 错误 | 原因 | 解决方案 |
|------|------|----------|
| 联调后忘删 Mock，导致真实接口被拦截 | MSW 优先级高于真实请求 | 联调完成后立即删除 handler，不等「下次清理」 |
| Mock 数据结构与真实接口不一致 | `response_shape` 未更新 | 联调阶段以真实接口为准更新 `response_shape` |
| Mock 文件中直接写死了业务逻辑判断 | Mock 越权实现了后端逻辑 | Mock 只返回固定数据，复杂场景用 vitest mock factory |
| 生产环境打包时 MSW 被打入 bundle | `msw` 未放在 devDependencies | 检查 `package.json`，MSW 只能在 `devDependencies` |
