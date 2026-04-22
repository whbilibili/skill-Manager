# Step: 生成"文件覆盖矩阵"初始模板

> AI 从 `.code-review-diff.tmp` 里提取文件清单和 +/- 统计，直接塞进最终报告的"📁 文件覆盖矩阵"节。
> 不需要跑 Node 脚本，用 `Read` + `grep` / `Bash` 就够。

## 目标

输出一张 markdown 表格：

```markdown
### 📁 文件覆盖矩阵

| # | 文件 | 新增 | 删除 | 审查状态 | 问题数 |
|---|------|------|------|---------|-------|
| 1 | `src/pages/foo.tsx` | +25 | -3 | ❌ 未审（必须补） | — |
| 2 | `src/pages/bar.ts`  | +12 | -0 | ❌ 未审（必须补） | — |

> ⚠️ 所有 `❌ 未审` 的文件必须被审查后更新状态，否则本次 CR 不完整。
```

**作用**：这是 CR 的"点名册"。每个文件审完后 AI 必须回来更新对应行的"审查状态"和"问题数"。有任何一行仍是 `❌ 未审` → 本次 CR 失败，不得输出最终结论。

## 执行步骤

### 1. 确认 diff 文件存在

```bash
test -f .code-review-diff.tmp
```

不存在 → 报错"未找到 .code-review-diff.tmp，先执行 steps/generate-diff.md"。

### 2. 提取文件列表

用 Bash：

```bash
grep -E '^diff --git ' .code-review-diff.tmp
```

每行格式是：`diff --git a/<src> b/<dst>`。

对每行：
- `src === dst` → 该文件 `modified`，记为 `<src>`
- `src !== dst` → 该文件 `renamed`，记为 `<src> → <dst>`

### 3. 统计每个文件的 +/-

最简单的做法是 **Read `.code-review-diff.tmp` 进 context 直接解析**：

- 按 `/^diff --git /m` 切块；
- 每块里数 `^+`（不含 `^+++`）和 `^-`（不含 `^---`）的行数；
- 对应到上一步拿到的文件名。

> 如果 diff 超过 1MB，Read 进 context 不划算，改用命令行：
> ```bash
> awk '
>   /^diff --git / { if (f) print f"|"a"|"d; f=$0; a=0; d=0; next }
>   /^\+\+\+/ || /^---/ { next }
>   /^\+/ { a++ }
>   /^-/  { d++ }
>   END { if (f) print f"|"a"|"d }
> ' .code-review-diff.tmp
> ```

### 4. 组装表格

按上面"目标"章节的格式输出 markdown 表格。
- `审查状态` 初始统一写 `❌ 未审（必须补）`
- `问题数` 初始统一写 `—`
- 按 diff 中出现的顺序排列即可，不用排序

### 5. 也输出一个简短摘要（日志用，不进报告）

```
📁 本次 PR 改动文件数：<n>  总计 +<totalAdded> / -<totalRemoved>
```

## 使用说明

这张表是**动态更新**的：
- 第 3 步深度审查过程中，每审完一个文件立刻把对应行的 `审查状态` 改为：
  - `✅ 已审（N 条问题）` / `✅ 已审（无问题）` / `⚠️ 部分审查（说明未覆盖部分）`
- 最终报告里的矩阵**不允许**存在任何 `❌ 未审` 行

## 失败处理

- grep / awk 命令被拦 → 直接用 `Read` 读 `.code-review-diff.tmp` 全文，在 context 里人工数（适合 ≤ 200 行 diff）
- diff 文件本身不存在 → 回到 `steps/generate-diff.md`
