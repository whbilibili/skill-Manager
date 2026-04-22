# Step: 安全扫描（Grep 驱动，不跑 Node 脚本）

> AI 用自己的 `Grep` 工具（允许正则、`glob` 过滤、`type` 过滤）对**本次 diff 涉及的 JS/TS 文件**扫一遍危险模式。
> 发现 `critical` / `high` 命中就直接进第 3 步的 P0 列表候选；`medium` 进 P2 候选。

## 目标

找出以下 7 类高风险代码模式，每条命中必须带上"文件:行号 + 代码片段"。

## 危险模式清单

| # | 模式 | 正则 | 级别 | 建议 |
|---|------|------|------|------|
| S1 | 硬编码 API Key / Token | `(api[_-]?key\|apikey\|access[_-]?token\|secret[_-]?key)\s*[:=]\s*['"\`][\w\-]{20,}['"\`]` | critical | 用环境变量 `process.env.API_KEY` |
| S2 | 硬编码密码 | `password\s*[:=]\s*['"\`][^'"\`]{6,}['"\`]` | critical | 用环境变量 / 密钥管理服务 |
| S3 | 动态 innerHTML | `\.innerHTML\s*=\s*(?!['"\`])` | high | 用 textContent 或框架安全方法 |
| S4 | React dangerouslySetInnerHTML | `dangerouslySetInnerHTML\s*=\s*\{\{?\s*__html:` | high | 必须 DOMPurify 清洗 |
| S5 | eval() 调用 | `\beval\s*\(` | critical | 用 JSON.parse / 其他安全替代 |
| S6 | new Function 构造器 | `new\s+Function\s*\(` | high | 避免动态生成函数 |
| S7 | console.log 敏感字段 | `console\.log\(.*?(password\|token\|secret\|key\|credential)` | medium | 移除 / 换专门日志系统 |

> **定级规则**：
> - `critical` + `high` → **第 3 步 P0 候选**（S1 / S2 / S5 对 G5；S3 / S4 对 G4；S6 对 G4 变种）
> - `medium` → **第 3 步 P2 候选**（S7）
> - 命中进候选后还要过第 4 步的反向核验（Q1-Q5），假阳性会被删除或降级

## 执行步骤

### 1. 只扫本次 diff 的 JS/TS 文件

从 `steps/list-changed-files.md` 已经得到的文件列表，按扩展名过滤：

- **保留**：`.js` / `.jsx` / `.ts` / `.tsx`
- **排除**：
  - 包含 `node_modules` / `/dist/` / `/build/`
  - `.test.` / `.spec.` / `.stories.`
  - `__mocks__`
  - `/api/` / `.generated.ts` / `.auto.ts` （这些是自动生成的 DTO，不在安全扫描范围；G8 另外管）

如果过滤后列表为空 → 输出"⚠️ 无变更的 JS/TS 文件，跳过安全扫描"，结束。

### 2. 对每个保留的文件用 Grep 工具扫

对上表 7 条模式，逐条跑一次 `Grep`：

```
Grep(
  pattern: <上表正则>,
  output_mode: "content",
  -n: true,
  path: <具体文件路径>   # 或对整个列表循环
)
```

> **性能优化**：如果要扫的文件超过 10 个，可以一次性用 `path: "."` + `glob: "**/*.{ts,tsx,js,jsx}"` 跑一次全仓库扫描，然后在结果里过滤出 diff 涉及的文件。但这样 noise 会变大，一般**逐文件扫更精确**。

### 3. 大文件跳过

如果某个文件大小 > 500KB，跳过并输出 `⏭️ 跳过大文件: <path> (<size>KB)`。大文件基本都是 auto-generated，扫描噪声大。

> 判断文件大小：`wc -c <path>` 或 `du -k <path>`。

### 4. 组装扫描报告（中间产物，进候选，不直接进最终报告）

对每条命中，AI 在 context 里记一条：

```json
{
  "file": "src/components/Foo.tsx",
  "line": 45,
  "pattern_id": "S4",
  "severity": "high",
  "message": "dangerouslySetInnerHTML 可能导致 XSS",
  "code": "<div dangerouslySetInnerHTML={{ __html: content }} />",
  "suggestion": "必须 DOMPurify 清洗"
}
```

把全部命中按 severity 分三组：`critical` / `high` / `medium`，每组最多列 10 条（多了合并为"另外 N 处同类"）。

### 5. 输出扫描结论（进最终报告的"🤖 自动化检测结果"节）

格式：

```
🤖 自动化检测结果（安全扫描）：
  - 扫描文件数：<n>
  - 🔴 critical：<n> 条（详见 P0 节）
  - 🟠 high：<n> 条（详见 P0 节）
  - 🟡 medium：<n> 条（详见 P2 节）
  - 无命中时：✅ 未发现安全问题
```

然后把每条 critical/high 命中转成 P0 候选（交给第 3 步的必要性五问和第 4 步的反向核验核验后进报告）；medium 转成 P2 候选。

## 失败处理

- `Grep` 工具调用失败（极少见） → 改用 `Bash` 里的 `grep -nE '<pattern>' <file>` 跑
- 所有方式都失败 → 降级人工审查：AI 直接读完整文件，人眼扫描上表 7 类模式
- 无论如何**不阻塞 CR**：安全扫描失败时，在报告"🤖 自动化检测结果"节写 `⚠️ 安全扫描未执行（原因），依赖人工审查覆盖`
