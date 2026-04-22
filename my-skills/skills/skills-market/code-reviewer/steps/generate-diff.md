# Step: 生成 diff

> 这是 AI 可直接执行的"步骤脚本"，不是 Node 脚本。
> AI 用自己的 `Bash` 工具跑 git 命令、用 `Read` 读结果。
> 只用 git（CLI 一般都在 allowlist 里），避开 `node scripts/*` 触发 auto-mode 拦截。

## 目标

在仓库根目录生成 `.code-review-diff.tmp`，内容是当前分支相对于 `master`（或指定基准分支）的完整 diff。

## 输入参数

| 参数 | 默认值 | 说明 |
|------|-------|------|
| `BASE_BRANCH` | `master` | 对比的基础分支；若用户指定 `develop`/`release` 等就换成指定值 |
| `OUTPUT` | `.code-review-diff.tmp` | 输出路径（一般不改） |

## 执行步骤（照着跑，出问题就报错）

### 1. 确认在 git 仓库里

```bash
git rev-parse --git-dir
```

失败 → 报错"当前目录不是 git 仓库"，停止本次 CR。

### 2. 取当前分支名

```bash
git branch --show-current
```

空结果 → 报错"处于 detached HEAD 状态，无法 CR"，停止。

### 3. 检查基准分支是否存在（本地 + 远程）

```bash
git branch -a | grep -E "(^|/)${BASE_BRANCH}$"
```

无任何匹配 → 报错"基础分支 `$BASE_BRANCH` 不存在"，停止。

### 4. 优先对齐远程版本（非阻塞）

```bash
git fetch origin "$BASE_BRANCH" 2>/dev/null || true
```

拉失败就算了（可能离线），用本地版本继续。

### 5. 选择 compareBase

- 如果 `git branch -a` 列出了 `remotes/origin/$BASE_BRANCH` → `compareBase="origin/$BASE_BRANCH"`
- 否则 → `compareBase="$BASE_BRANCH"`

### 6. 检查未提交改动（只提示，不阻止）

```bash
git status --porcelain
```

有输出 → 输出一行警告：
```
⚠️ 当前有未提交改动，这些改动不会包含在 diff 里；建议先 commit
```

### 7. 生成 diff

```bash
git diff "$compareBase...HEAD" > .code-review-diff.tmp
```

### 8. 校验 diff 非空

```bash
wc -c .code-review-diff.tmp
```

0 字节 → 报错"当前分支与 $compareBase 没有差异，无需 CR"，删除文件后停止。

### 9. 输出摘要

从文件里数出这三个数（可以用 `Read` 读文件再在 context 里数，也可以跑下面的命令）：

```bash
# 文件数
grep -c '^diff --git' .code-review-diff.tmp
# 行数
wc -l .code-review-diff.tmp
# 文件大小（KB）
du -k .code-review-diff.tmp | awk '{print $1}'
```

然后打印：

```
✅ Diff 已生成
   当前分支：<currentBranch>
   对比分支：<compareBase>
   文件数量：<n> 个
   改动行数：<n> 行
   文件大小：<n> KB
   输出路径：.code-review-diff.tmp
```

## 清理（审查完成后）

```bash
rm -f .code-review-diff.tmp
```

## 失败处理

任何一步 git 命令报 `permission denied` / `command not found` / 用户在交互式 prompt 拒绝 →
- 不要反复重试；
- 明确告知用户"生成 diff 失败：<原因>"；
- 如果用户可以手动跑，建议：`git diff master...HEAD > .code-review-diff.tmp`；
- 本次 CR 无法继续（没有 diff 就没有审查对象）。
