# 降级工单模板

> 当 issue-triage 技能不可用时，fullstack-coordinator 直接使用此模板在 issues.json 中创建工单。
> 该模板兼容 issue-triage 和 test-architect 的 issues.json schema。

---

## 完整模板

```json
{
  "id": "BUG-{自增编号}",
  "title": "{缺陷标题 — 简明扼要描述现象}",
  "description": "{详细描述：复现步骤、预期行为、实际行为}",
  "reported_by": "{frontend | backend}",
  "source": "fullstack-coordinator/{XFER-id}",
  "severity": "{P0 | P1 | P2 | P3}",
  "status": "open",
  "root_cause_analysis": {
    "most_likely": {
      "layer": "{数据层 | 服务层 | 接口层 | 配置层 | 渲染层 | 状态层 | 网络层 | 构建层}",
      "description": "{从 cross-issues.json 的 root_cause_hint.evidence 中提取}",
      "confidence": 0.6
    },
    "evidence": [
      "{证据1：接口响应/日志/截图等}",
      "{证据2：对比 API-CONTRACT.md 的预期定义}"
    ]
  },
  "related_task_id": null,
  "impact": "{对用户或功能的影响描述}",
  "resolved_at": null,
  "notes": "由 fullstack-coordinator 从 {XFER-id} 创建，原始工程: {source_project}"
}
```

---

## 字段说明

### 必须字段

- **id**：`BUG-` 前缀 + 在当前 issues.json 中自增编号。读取现有文件获取最大编号后 +1。
- **title**：20 字以内的缺陷标题。
- **description**：包含复现条件的详细描述。
- **severity**：根据 cross-issues.json 中 root_cause_hint 的信息判断：
  - P0：核心流程不可用（用户无法完成关键操作）
  - P1：核心流程受损（功能异常但有 workaround）
  - P2：非核心功能异常
  - P3：体验问题或边缘场景
- **status**：固定为 `"open"`
- **root_cause_analysis.most_likely**：从 cross-issues.json 的 `root_cause_hint` 直接映射
- **impact**：描述此缺陷对最终用户的可见影响
- **resolved_at**：初始为 `null`，缺陷修复后由处理者填写日期
- **notes**：标明来源是跨工程转交，方便追溯

### 可选字段

- **related_task_id**：如果能关联到 feature-list.json 中的某个 Task，填写 Task id；否则 null
- **root_cause_analysis.evidence**：数组，每个元素是一条证据字符串

---

## ID 生成逻辑

```python
import json, os

def next_issue_id(issues_path):
    """从已有 issues.json 中获取下一个 BUG id"""
    if os.path.exists(issues_path):
        data = json.load(open(issues_path))
        issues = data.get('issues', [])
        nums = []
        for issue in issues:
            iid = issue.get('id', '')
            if iid.startswith('BUG-'):
                try:
                    nums.append(int(iid.split('-')[1]))
                except ValueError:
                    pass
        return f"BUG-{max(nums, default=0) + 1:03d}"
    return "BUG-001"
```

---

## 与 issue-triage 的差异

降级模板相比 issue-triage 的完整分诊流程，缺少以下部分：

- 无多层根因分析（只有 most_likely，没有 alternative）
- 无修复方案建议（fix_suggestion）
- 无自动关联代码文件（affected_files）
- confidence 固定为 0.6（中等置信度）

这些缺失是可接受的，因为跨工程转交的缺陷在目标工程拾取后，可以由 issue-triage 进行完整的二次分诊来补全信息。
