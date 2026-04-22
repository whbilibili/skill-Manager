# test-plan.json 完整 Schema 参考

本文档是 test-plan.json 每个字段的详细说明，供 Agent 在生成测试计划时参考。

---

## 顶层字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| project | string | 是 | 项目名称，与 feature-list.json 的 project 一致 |
| created_at | string | 是 | 首次生成日期 YYYY-MM-DD |
| updated_at | string | 是 | 最近更新日期 YYYY-MM-DD |
| test_strategy | object | 是 | 测试策略配置 |
| test_suites | array | 是 | 测试套件列表 |
| execution_summary | object | 是 | 执行统计摘要 |

## test_strategy 字段

### pyramid（测试金字塔比例）

默认比例 Unit 70% / Integration 20% / E2E 10%。可根据项目实际调整：
- API 密集型项目：Unit 50% / Integration 40% / E2E 10%
- UI 密集型项目：Unit 40% / Integration 20% / E2E 40%
- 纯后端服务：Unit 60% / Integration 35% / E2E 5%

### tools（工具链映射）

必须与项目实际安装的工具一致。判断方法：
- 读取 package.json 的 devDependencies 确认 vitest/jest/playwright
- 读取 pom.xml 确认 JUnit 版本
- 读取 go.mod 确认 Go 版本
- 读取 requirements.txt 确认 pytest

### coverage_target（覆盖率目标）

默认值：line 80% / branch 60% / function 80%。
这是目标值而非硬性门槛，测试报告中会对比实际覆盖率与目标值。

## test_suites[*] 字段详解

### suite_id 命名规则

格式：`TEST-{三位序号}`，例如 TEST-001、TEST-042。
追加测试时从现有最大序号 +1。

### type 类型说明

- **unit**：单元测试，测试单个函数/方法，不依赖外部服务
- **integration**：集成测试，测试模块间协作或 API 端点
- **e2e**：端到端测试，模拟用户完整操作流程
- **smoke**：冒烟测试，核心功能快速验证
- **regression**：回归测试，防止已修复 Bug 复发

### priority 优先级说明

- **P0**：核心功能，阻塞发布。如支付、登录、数据完整性
- **P1**：重要功能，本迭代必须测试。如列表、搜索、筛选
- **P2**：常规功能，应该测试。如排序、分页、格式校验
- **P3**：边缘场景，有余力测试。如极端并发、罕见输入

### status 状态转换

```
planned     — 测试计划已制定，但测试代码尚未编写
generated   — 测试代码已生成/编写完成，等待执行
passing     — 所有 case 通过
failing     — 存在失败的 case
blocked     — 因外部依赖（Mock/DB/网络）无法执行
skipped     — 主动跳过（低优先级、场景不适用、被其他 suite 覆盖）
```

### test_cases[*] 字段详解

#### case_id 命名规则

格式：`{suite_id}-C{两位序号}`，例如 TEST-001-C01、TEST-001-C12。

#### category 分类

- **positive**：正常输入，期望成功
- **negative**：异常输入，期望失败（并返回正确错误信息）
- **boundary**：边界值输入（最小值、最大值、空值、超长值）
- **exception**：异常场景（超时、断连、并发）

#### result 结果

- **pending**：未执行
- **pass**：执行通过，actual_output 符合 expected_output
- **fail**：执行完成但结果不符合预期
- **error**：执行过程中发生异常（非业务逻辑错误）
- **skip**：跳过执行

### verification_command 编写规范

必须是可直接在终端执行的命令，返回非零退出码表示测试失败：

```bash
# Vitest（Node.js）
pnpm exec vitest run auth --reporter=verbose

# Jest（Node.js）
npx jest --testPathPattern=auth --verbose

# JUnit（Java）
mvn test -pl module-name -Dtest=AuthServiceTest

# Go
go test ./internal/auth/... -v -run TestRegister

# Pytest（Python）
python -m pytest tests/test_auth.py -v
```

## execution_summary 字段

所有计数字段必须与 test_suites 中的实际数据保持一致。
每次更新 test_suites 后必须重新计算 execution_summary。

计算规则：
```
total_suites = len(test_suites)
total_cases = sum(len(s.test_cases) for s in test_suites)
passed = count(cases where result == "pass")
failed = count(cases where result in ("fail", "error"))
blocked = count(cases in blocked suites)
skipped = count(cases where result == "skip")
not_run = count(cases where result == "pending")
pass_rate = f"{passed / total_cases * 100:.1f}%" if total_cases > 0 else "0%"
issues_created = count(cases where created_issue_id is not null)
```
