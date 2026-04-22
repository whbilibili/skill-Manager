# docs/RELIABILITY.md Template

> 使用说明：根据项目实际情况填充。对于早期项目，标注"待定"比编造数字更诚实。

---

# {PROJECT_NAME} — 可靠性

## SLO（服务水平目标）

| 指标 | 目标 | 测量方式 | 说明 |
|------|------|---------|------|
| 可用性 | {AVAILABILITY_TARGET} | {HOW_MEASURED} | {NOTES} |
| 延迟 P99 | {LATENCY_P99} | {HOW_MEASURED} | {NOTES} |
| 错误率 | {ERROR_RATE_TARGET} | {HOW_MEASURED} | {NOTES} |

## 错误处理模式

### 原则

1. **不吞掉错误** — 每个异常都有结构化日志（包含关键 ID）
2. **快速失败** — 前置校验在入口处拒绝，不在深层抛出
3. **可恢复 > 可重试 > 失败** — 按此优先级设计错误路径
4. **幂等** — 关键操作支持安全重试

### 错误分类

| 类型 | 处理策略 | 示例 |
|------|---------|------|
| 参数校验错误 | 立即返回 4xx，不重试 | 缺少必填字段 |
| 下游超时 | 重试 1-2 次，指数退避 | RPC 调用超时 |
| 下游不可用 | 降级/熔断，报警 | 依赖服务宕机 |
| 数据不一致 | 记录日志，人工介入 | 状态机异常跳转 |
| 未知异常 | 兜底处理，结构化日志 | NullPointerException |

### 关键 ID 日志规范

每条关键日志必须包含以下字段（根据上下文选择）：

```
{KEY_ID_FIELDS}
```

## 可观测性

### 日志

| 类型 | 路径/配置 | 说明 |
|------|---------|------|
| 应用日志 | {APP_LOG_PATH} | 业务逻辑日志 |
| 错误日志 | {ERROR_LOG_PATH} | ERROR 级别日志 |
| 访问日志 | {ACCESS_LOG_PATH} | HTTP 请求日志 |

### 监控

| 指标 | 工具 | 告警阈值 |
|------|------|---------|
| {METRIC_1} | {TOOL_1} | {THRESHOLD_1} |
| {METRIC_2} | {TOOL_2} | {THRESHOLD_2} |

### 链路追踪

- 追踪系统: {TRACING_SYSTEM}
- 采样率: {SAMPLING_RATE}
- 关键 Span: {KEY_SPANS}

## 韧性模式

### 已采用

| 模式 | 应用场景 | 配置 |
|------|---------|------|
| {PATTERN_1} | {SCENARIO_1} | {CONFIG_1} |

### 待引入

| 模式 | 预期场景 | 优先级 |
|------|---------|--------|
| {FUTURE_PATTERN_1} | {FUTURE_SCENARIO_1} | {PRIORITY_1} |

## 故障恢复

### 恢复手册

| 故障场景 | 影响 | 恢复步骤 |
|---------|------|---------|
| {FAILURE_1} | {IMPACT_1} | {RECOVERY_STEPS_1} |

### 回滚策略

- 部署回滚: {DEPLOY_ROLLBACK}
- 数据回滚: {DATA_ROLLBACK}
- 配置回滚: {CONFIG_ROLLBACK}
