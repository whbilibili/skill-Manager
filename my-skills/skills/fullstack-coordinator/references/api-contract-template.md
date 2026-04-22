# API-CONTRACT.md 模板

> 本模板用于 fullstack-coordinator Mode 0 初始化时生成 `../.agents/API-CONTRACT.md`。
> 后端窗口负责维护接口定义，前端窗口负责检查变更。

---

## 使用说明

将以下模板内容复制到 `../.agents/API-CONTRACT.md`，替换 `{placeholder}` 为实际值。

---

## 模板正文

```markdown
# API 接口契约 — {项目名称}

> 本文件是前后端接口的唯一真相来源（Single Source of Truth）。
> 后端窗口负责维护接口定义和登记变更，前端窗口负责检查变更并同步。
> 全局版本：v{major}.{minor}    最后更新：{YYYY-MM-DD}

---

## 一、接口清单

| # | Path | Method | 后端状态 | 前端状态 | 后端 Task | 前端 Task | 版本 |
|---|------|--------|----------|----------|-----------|-----------|------|
| 1 | /api/v1/example | GET | developing | mocked | BE-TASK-001 | FE-TASK-001 | v1.0 |

**后端状态**：not_started / developing / deployed / verified
**前端状态**：mocked / integrating / verified

---

## 二、接口详情

### GET /api/v1/example

**描述**：接口功能简述

**Request**

```typescript
// Query Parameters
interface GetExampleQuery {
  page?: number;     // 页码，默认 1
  pageSize?: number; // 每页条数，默认 20
}
```

**Response**

```typescript
interface GetExampleResponse {
  code: number;       // 0 成功，非 0 失败
  message: string;    // 提示信息
  data: {
    list: ExampleItem[];
    total: number;
  };
}

interface ExampleItem {
  id: number;
  name: string;
  createdAt: string;  // ISO 8601
}
```

**错误码**

| code | 含义 | 前端处理建议 |
|------|------|-------------|
| 0 | 成功 | 正常渲染 |
| 40001 | 参数校验失败 | 提示用户修改输入 |
| 50001 | 服务内部错误 | 展示兜底页 |

---

## 三、变更记录

> 每次接口变更，后端在此追加一条记录。
> 版本规则：新增接口 minor+1，修改已有字段 minor+1，删除接口/必填字段 major+1。

### v1.0 — {YYYY-MM-DD}
**变更接口**：全部接口
**变更内容**：初始版本，定义所有接口
**变更原因**：项目初始化
**影响评估**：无
**BREAKING**：否

---

## 四、数据类型公共定义

> 多个接口复用的类型定义放在这里。

```typescript
// 分页请求通用参数
interface PaginationQuery {
  page?: number;
  pageSize?: number;
}

// 分页响应通用结构
interface PaginationResponse<T> {
  list: T[];
  total: number;
  page: number;
  pageSize: number;
}

// 通用响应包装
interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}
```
```
