# 应用研发 / 测试负责人（fsd app job-owners）

## 用途

根据 **FSD 服务名（jobName）** 或 **octoAppKey**，查询该服务在 FSD 上配置的 **研发负责人**、**测试负责人**（平台字段 `adminRd`、`adminQa`，通常为逗号分隔的 MIS）。

## CLI

```bash
# 按服务名
fsd app job-owners -a <jobName>

# 按 octoAppKey（先 listPageAuth 精确匹配 octo，再 getInfoByName）
fsd app job-owners --appkey <octoAppKey>

# 机器可读 JSON
fsd app job-owners -a <jobName> --json
```

- **`-a` / `--app`** 与 **`--appkey` 二选一**，不可同时传。
- **`--appkey`**：仅当 `listPageAuth` 返回结果中 **`octoAppKey` 与传入值完全一致** 且对应 **唯一 jobName** 时解析成功；若命中多条或仅有模糊匹配，须改用 **`-a`** 指定服务名，或先用 **`fsd app find-by-appkey --appkey … --pretty`** 人工选对服务。

## 接口

| 步骤 | 方法 | 路径 / 说明 |
|------|------|-------------|
| 详情（负责人） | GET | `/api/qa/v1/job/getInfoByName?jobName=<jobName>` → `jobInfo.adminRd`、`jobInfo.adminQa` |
| appkey → 服务列表 | GET | `/api/qa/v1/job/listPageAuth`（同 `fsd app find-by-appkey`） |

认证与域名与其它 `fsd` 命令一致（`fsd sso login` 后 Cookie / 客户端自动带参）。

## 助手执行要点（个性化）

- 用户只给 **octoAppKey** 且未给 jobName：优先 **`fsd app job-owners --appkey <octoAppKey>`**；失败则 **`fsd app find-by-appkey`** 展示候选后再用 **`-a`**。
- 输出中 **RD** = 研发（`adminRd`），**QA** = 测试（`adminQa`）；与「SRE 负责人」等其它角色无关（本命令不返回 `adminSre`）。
- **禁止**把用户 curl 示例里的 Cookie 写进文档或技能正文；用户环境凭 SSO 即可。

## 与 SKILL.md 的关系

命令索引见 [deploy.md](deploy.md) 中「CLI 能力与边界」表「应用负责人」一行；本文件承载 **路由说明与助手个性化规则**，不重复写入 SKILL 主文。
