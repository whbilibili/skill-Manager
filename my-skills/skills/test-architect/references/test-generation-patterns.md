# 测试用例生成模式参考

本文档提供从不同来源自动生成测试用例的模式和策略。

---

## 一、从 acceptance_criteria 生成

feature-list.json 中每个 Task 的 acceptance_criteria 是测试用例的第一来源。

### 转化规则

每条 acceptance_criteria 至少生成 1 个 positive case + 1 个 negative case。

示例：
```
acceptance_criteria: "用户输入有效邮箱和密码后应返回 201 和 JWT token"

生成的 test cases:
  - positive: 有效邮箱 + 有效密码 → 201 + JWT
  - negative: 无效邮箱 → 400 + 错误信息
  - negative: 空密码 → 400 + 错误信息
  - boundary: 邮箱最大长度 254 字符 → 201
  - boundary: 邮箱超过 254 字符 → 400
  - boundary: 密码最短长度 → 201 或 400（取决于规则）
```

### 关键词触发规则

| acceptance_criteria 关键词 | 额外生成的用例类型 |
|---------------------------|------------------|
| "必须"/"required" | negative: 缺少该字段 |
| "唯一"/"unique" | negative: 重复值；boundary: 并发插入 |
| "范围"/"between" | boundary: min-1, min, max, max+1 |
| "格式"/"format" | negative: 各种非法格式 |
| "权限"/"permission" | negative: 未授权访问；exception: token 过期 |
| "分页"/"pagination" | boundary: page=0, page=负数, size=0, size=超大值 |
| "排序"/"sort" | positive: 每种排序字段；boundary: 空列表排序 |

---

## 二、从 contracts.backend_api 生成

API 契约是集成测试的来源。

### HTTP 方法映射

```
GET    → 正常查询 + 不存在的资源(404) + 未授权(401) + 参数校验
POST   → 正常创建 + 重复创建 + 缺少必填字段 + 类型错误 + 超长字段
PUT    → 正常更新 + 更新不存在的资源 + 并发更新
DELETE → 正常删除 + 删除不存在的资源 + 删除有依赖的资源
PATCH  → 部分更新 + 空 body + 更新只读字段
```

### 请求体生成规则

```
对 request_body 的每个字段:
  - required 字段: 正常值 + 缺失 + null + 空字符串
  - string 字段: 正常 + 空 + 超长 + 特殊字符(<script>、SQL注入片段)
  - number 字段: 正常 + 0 + 负数 + 小数 + 超大数 + NaN
  - array 字段: 正常 + 空数组 + 超大数组 + 元素类型错误
  - enum 字段: 每个有效值 + 无效值
  - date 字段: 正常 + 过去日期 + 未来日期 + 非法格式
```

### 响应验证规则

```
对 response 的每个字段:
  - 字段存在性检查
  - 字段类型检查
  - 字段值范围检查（如 status code）
  - 嵌套对象结构检查
```

---

## 三、从 contracts.database 生成

数据库契约是数据层测试的来源。

### 表结构测试生成

```
对每个表:
  - NOT NULL 约束: 尝试插入 NULL → 期望失败
  - UNIQUE 约束: 尝试插入重复值 → 期望失败
  - FOREIGN KEY: 引用不存在的外键 → 期望失败
  - DEFAULT 值: 不传该字段 → 检查默认值正确
  - 索引: 有索引的查询 → 验证查询计划使用了索引
```

---

## 四、从 issues.json (resolved) 生成回归测试

已修复的 Bug 是回归测试的来源。

### 转化规则

```
对每个 status == "resolved" 的 issue:
  suite_id: "TEST-REG-{issue.id}"
  type: "regression"
  priority: 继承 issue 的 severity
  test_cases:
    - 重现用例: 按 issue.reproduction 步骤，期望不再复现
    - 边界用例: 在 issue 场景附近的边界条件
```

---

## 五、从 caveats.md 生成防护测试

已知坑点是防护测试的来源。

### 转化规则

每条 caveat 生成至少 1 个 test case，验证"踩坑场景不会再发生"。

示例：
```
caveat: "并发创建用户时可能出现重复 ID"

生成:
  suite_id: "TEST-CAV-001"
  type: "regression"
  test_cases:
    - 并发 10 个请求同时创建用户 → 验证无重复 ID
    - 数据库 UNIQUE 约束存在 → 验证 DDL
```

---

## 六、从代码直接分析生成（Mode 2）

当没有 feature-list.json 时，直接分析代码生成测试。

### 函数级分析

```
对每个 public 函数/方法:
  1. 分析参数类型 → 生成类型边界测试
  2. 分析分支逻辑（if/switch/ternary）→ 每个分支至少 1 个用例
  3. 分析异常处理（try/catch/throw）→ 每个异常路径 1 个用例
  4. 分析返回类型 → 验证返回值结构
  5. 分析副作用（DB操作/API调用/文件写入）→ 验证副作用正确性
```

### 类/模块级分析

```
对每个类/模块:
  1. 构造函数/初始化 → 正常初始化 + 缺少必要参数
  2. 状态转换 → 每个有效状态转换路径
  3. 依赖注入 → Mock 依赖后的隔离测试
  4. 生命周期 → setup/teardown 的资源清理
```
