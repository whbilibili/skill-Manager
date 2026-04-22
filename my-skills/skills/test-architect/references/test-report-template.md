# 测试报告模板

本模板供 Mode 5 生成测试报告时参考。报告用自然语言段落撰写，避免过度格式化。

---

```markdown
# 测试报告 — {project}

**报告日期**：{date}
**测试周期**：{start_date} ~ {end_date}
**生成工具**：test-architect v1.0.0

## 执行概要

本轮测试共执行 {total_suites} 个测试套件、{total_cases} 个测试用例。
其中通过 {passed} 个（{pass_rate}），失败 {failed} 个（{fail_rate}），
阻塞 {blocked} 个，跳过 {skipped} 个，未执行 {not_run} 个。
本轮共发现 {issues_created} 个缺陷，已全部写入 issues.json。
按严重程度分布：P0 {p0_count} 个、P1 {p1_count} 个、P2 {p2_count} 个、P3 {p3_count} 个。

## 测试覆盖分析

功能清单共 {total_tasks} 个 Task（排除 skipped），本轮测试覆盖了 {covered_tasks} 个，
覆盖率 {task_coverage}。未覆盖的 Task 及原因如下。

{对每个未覆盖的 Task，说明 task_id、description 和未覆盖原因}

验收标准共 {total_criteria} 条，本轮验证了 {verified_criteria} 条（{criteria_coverage}）。
未验证的标准主要集中在 {未覆盖模块}，原因是 {原因说明}。

## 按类型分布

单元测试 {unit_count} 个（通过率 {unit_pass_rate}），
集成测试 {integration_count} 个（通过率 {integration_pass_rate}），
端到端测试 {e2e_count} 个（通过率 {e2e_pass_rate}），
冒烟测试 {smoke_count} 个（通过率 {smoke_pass_rate}），
回归测试 {regression_count} 个（通过率 {regression_pass_rate}）。

## 失败用例详情

{对每个 failing suite，输出以下段落}

### {suite_id}: {title}（{priority}）

本套件包含 {case_count} 个用例，其中 {fail_count} 个失败。

**{case_id}: {case_title}**
分类：{category}。输入：{input}。
预期结果：{expected_output}。实际结果：{actual_output}。
失败原因：{failure_reason}。
关联缺陷：{created_issue_id}（严重程度 {severity}）。

{重复以上段落直到所有失败 case 列完}

## 缺陷统计

本轮测试共创建 {issues_created} 个缺陷工单。

按严重程度：P0（阻塞发布）{p0} 个，P1（本迭代修复）{p1} 个，
P2（建议修复）{p2} 个，P3（可延后）{p3} 个。

按模块分布：{module_name} {count} 个，{module_name} {count} 个，...

{如有 P0 缺陷，强调需要立即处理}

## 回归测试覆盖

issues.json 中共有 {resolved_issues} 个已修复缺陷。
其中 {regressed_covered} 个有对应回归测试，{regressed_uncovered} 个尚未覆盖。

回归测试结果：通过 {reg_passed} 个，失败 {reg_failed} 个。
{如有回归失败，列出具体 issue id 和失败详情}

## 风险评估与建议

{基于测试数据给出结论性段落}

**发布风险评级**：{高/中/低}

{如果通过率 > 95% 且无 P0 缺陷}
综合测试结果，项目测试通过率 {pass_rate}，无 P0 级阻塞缺陷，
核心功能（{列出关键模块}）全部通过验证。建议可以进入发布流程，
但需关注以下 {count} 个 P1 缺陷的修复进度。

{如果通过率 < 95% 或有 P0 缺陷}
测试发现 {p0_count} 个 P0 级缺陷，通过率 {pass_rate} 未达到发布标准。
建议暂缓发布，优先修复以下阻塞缺陷：{列出 P0 缺陷 id 和标题}。
修复后需要执行 {需要重跑的 suite 数量} 个测试套件的回归验证。

**高风险模块**：{列出失败率最高的模块，分析风险原因}

**改进建议**：
{针对测试过程中发现的系统性问题给出改进建议}
```
