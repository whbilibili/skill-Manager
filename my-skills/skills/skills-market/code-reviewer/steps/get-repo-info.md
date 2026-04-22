# Step: 获取仓库信息（用于生成可点击代码链接）

> AI 用自己的 `Bash` 工具跑两个 git 命令，然后在 context 里正则解析。不需要 Node 脚本。

## 目标

从 `git remote` 和 `git branch` 解析出：

```json
{
  "codeBaseUrl": "https://dev.sankuai.com/code/repo-detail/<org>/<repo>",
  "branch":      "refs/heads/<currentBranch>",
  "org":         "<org>",
  "repo":        "<repo>",
  "currentBranch": "<currentBranch>",
  "remoteUrl":  "<原始 remote URL>"
}
```

这两个值最终用来拼报告里的代码行链接：

```
[src/components/Foo.tsx:45]($codeBaseUrl/file/detail?path=src/components/Foo.tsx&branch=$branch#L45)
```

## 执行步骤

### 1. 拿 remote URL 和当前分支

```bash
git remote get-url origin
git branch --show-current
```

失败（没有 origin / detached HEAD） → 走"降级方案"：`codeBaseUrl=""`、`branch="refs/heads/master"`，报告里的"位置"字段改用反引号纯文本格式：`` `src/components/Foo.tsx:45` ``。**不要因此停止 CR。**

### 2. 解析 org / repo

对 `remoteUrl` 依次尝试两个正则：

**SSH 格式** `git@domain:org/repo.git`：
```
/^git@[^:]+:([^/]+)\/(.+?)(?:\.git)?$/
```

**HTTPS 格式** `https://domain/org/repo.git`：
```
/^https?:\/\/[^/]+\/([^/]+)\/(.+?)(?:\.git)?$/
```

匹配到的第一个捕获组是 `org`，第二个是 `repo`。两个都不匹配 → 降级方案（同上）。

### 3. 拼 URL

```
codeBaseUrl = "https://dev.sankuai.com/code/repo-detail/${org}/${repo}"
branch      = "refs/heads/${currentBranch}"
```

> **⚠️ 平台特化**：`https://dev.sankuai.com/code/repo-detail/...` 是美团内部 code 平台的 URL。
> 如果仓库 origin 指向 GitHub / GitLab / 其他内部平台，AI 需要识别并替换为对应平台的"文件查看 URL 模板"，或直接降级为反引号格式。

### 4. 把两个值记住

在本次 CR 的 context 里把 `codeBaseUrl` 和 `branch` 记下来，后续每个问题条目的"位置"字段都要用。

## 示例

```
remoteUrl = "git@git.sankuai.com:nibfe/msfex-partner.git"
↓
org  = "nibfe"
repo = "msfex-partner"
currentBranch = "feature/add-dto"
↓
codeBaseUrl = "https://dev.sankuai.com/code/repo-detail/nibfe/msfex-partner"
branch      = "refs/heads/feature/add-dto"
↓
报告里一条位置链接：
[src/pages/foo.tsx:45](https://dev.sankuai.com/code/repo-detail/nibfe/msfex-partner/file/detail?path=src/pages/foo.tsx&branch=refs/heads/feature/add-dto#L45)
```

## 失败处理

- `git remote get-url origin` 报错 / 输出为空 → 降级方案，不阻塞
- 正则两个都不匹配 → 降级方案，不阻塞
- **唯一要做的事**：告诉用户"链接生成失败，本次 CR 的代码位置将以纯文本显示"，然后继续 CR
