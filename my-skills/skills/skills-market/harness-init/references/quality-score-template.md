# docs/QUALITY_SCORE.md Template

> 使用说明：根据检测到的语言/框架选择对应检查项，删除不适用的部分。

---

# {PROJECT_NAME} — 质量标准

## 代码质量目标

| 指标 | 目标 | 当前 | 说明 |
|------|------|------|------|
| 编译通过率 | 100% | — | `{BUILD_CMD}` 零错误 |
| 测试覆盖率 | {COVERAGE_TARGET} | — | 核心业务逻辑 ≥{COVERAGE_TARGET} |
| 静态检查 | 0 blocker/critical | — | {LINT_TOOL_OR_NA} |

## 代码审查检查清单

### 通用

- [ ] 单一职责：每个类/函数只做一件事
- [ ] 命名清晰：变量名、方法名自解释
- [ ] 无硬编码：配置走配置中心或 profiles
- [ ] 无密钥泄露：凭据不入仓库
- [ ] 错误处理：异常不吞掉，有结构化日志
- [ ] 边界检查：空值、越界、并发安全

### Java 专用

- [ ] Lombok 使用得当：`@Slf4j`, `@Data`, `@Builder`
- [ ] MyBatis Mapper 由 Generator 生成，不手写
- [ ] Spring Bean 通过构造器注入
- [ ] 方法参数不使用 Object 类型
- [ ] DTO 跨服务传输时有 Thrift 注解

### Node.js 专用

- [ ] TypeScript strict mode
- [ ] async/await 错误有 try-catch
- [ ] 依赖版本锁定（package-lock.json）
- [ ] 无 any 类型逃逸到生产代码

### Python 专用

- [ ] 类型注解覆盖公共 API
- [ ] 虚拟环境隔离依赖
- [ ] 格式化工具统一（black/ruff）

### Go 专用

- [ ] go vet 通过
- [ ] golangci-lint 零警告
- [ ] error 不忽略

## 反模式清单

| 反模式 | 说明 | 修复方式 |
|--------|------|---------|
| 上帝类 | 单个类超过 500 行 | 按职责拆分 |
| 深嵌套 | if/for 嵌套 >3 层 | 提取方法 / 早返回 |
| 魔法数字 | 未命名常量 | 提取为命名常量 |
| 复制粘贴 | 重复代码块 >10 行 | 提取公共方法 |
| 过度抽象 | 只有一个实现的接口 | 删除接口，直接使用实现 |

## 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 类名 | PascalCase | `WorkItemService` |
| 方法名 | camelCase | `findWorkIdBySessionId()` |
| 常量 | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| 包名 | 全小写 | `com.dianping.bizarch.df.gateway` |
| 数据库表 | snake_case | `work_item` |
| REST 路径 | kebab-case | `/api/work/create-pr` |
