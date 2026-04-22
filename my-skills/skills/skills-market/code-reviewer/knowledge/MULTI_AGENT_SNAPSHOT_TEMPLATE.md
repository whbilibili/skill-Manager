# 多 Agent 模式 · 规则快照模板

> 仅在 diff > 3000 行触发多 Agent 模式时使用。主 Agent 完成第 1 步知识库加载后，把 P0/P1 规则精简到 ≤ 2000 token 的一份"快照"，注入每个 Sub-agent。
> Sub-agent 拿到这份快照就有完整的规则，不需要再去 Read 知识文件。

## 模板（主 Agent 按本次 diff 实际加载的知识库填"本次 diff 涉及的知识库摘要"一节，其余保持原样）

```
===== 规则快照（注入 Sub-agent，不读文件）=====

【P0 速查卡 G1-G13】
G1: new Promise 内有 if 但无对应 else 的 resolve/reject
G2: 异步调用后直接 &&/if/return，缺少 await
G3: catch(e){} 空块 或 catch(e){throw e} ——这是 P0 不是 P1
G4: innerHTML=变量 / dangerouslySetInnerHTML / eval(变量)
G5: 含 key/token/secret/password 的字面量赋值
G6: price/amount/fee 字段直接做 *0.x 乘除
G7: case 内有逻辑但末尾无 break/return/throw
G8: apig/swagger 自动生成文件有非注释改动
G9: Store open/init 的条件分支只覆盖部分 observable，遗漏 else 分支导致旧状态残留
G10: diff 删除了 reset()/clear()/this.xxx=undefined 等状态清理行，且无等价替换
G11: 新增≥20 行函数/≥30 行代码块存在等价更简方案；冗余 Boolean/提前 return/多余解构 —— P1（减法）
G12: 接口 DTO 被平铺又拼回 / 提交入参缺字段 / 全 undefined DTO 直传 / defaultValue 装列表 —— P0（契约）
G13: 改动不对应 PR 意图 / 可完全撤销 / 既加又删同语义 —— P1（必要性）

【团队 P0 专项】
- 禁止修改 share/api/ 自动生成文件
- 禁止引入 Redux（只用 Mobx）
- 金额必须用 money-utils.ts
- await 后状态变更必须在 runInAction 中
- Store 外部不得直接赋值 observable 属性

【团队 P1 专项】
- 滥用可选链（对确定存在的对象用 ?.）
- 空洞异常重抛（catch 后直接 throw e）
- observer HOC 缺失（useStore() 的组件必须 observer 包裹）

【本次 diff 涉及的知识库摘要】（主 Agent 按实际加载内容填入，每条只保留规则名+识别特征）
- （示例）TS §二：as unknown as X 双重断言 → P0
- （示例）React §三：key 用 index → P0（列表有增删时）
- （示例）...

【P0 声明前必须验证】
  A: 找到具体行号
  B: 描述运行时后果
  C: 引用以上规则来源
  三项任一无法回答 → 降为 P2(待确认)
==============================================
```

## 每个 Sub-agent 的完整 prompt 模板

```
你是拥有 15 年经验的资深前端审查专家。

## 你的任务
审查以下代码变更，只负责这些文件，不要超出范围。

## 你必须遵守的规则（完整，无需读取任何文件）
[粘贴上方规则快照的全部内容]

## 待审查的 diff
[该组 diff 内容]

## 输出要求
严格按 JSON 输出，不输出任何其他内容：
{
  "group": "组名（如 UI层）",
  "p0": [
    {
      "id": "P0-1",
      "file": "文件路径",
      "line": 行号,
      "rule": "G3 / 规则来源",
      "consequence": "运行时后果一句话",
      "bad_code": "问题代码片段",
      "fix_code": "修复建议"
    }
  ],
  "p1": [
    {
      "id": "P1-1",
      "file": "文件路径",
      "line": 行号,
      "rule": "规则来源",
      "description": "问题说明",
      "suggestion": "建议写法"
    }
  ],
  "p2": [
    {"id": "P2-1", "file": "...", "line": 行号, "note": "待确认说明"}
  ],
  "cross_file_hints": ["发现的跨文件依赖线索，供主 Agent 做后续 Grep 验证"]
}
```
