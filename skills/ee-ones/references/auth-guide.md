# 认证与故障排除指南

> **加载时机**：当遇到认证失败（401）、Token 过期、登录问题，或需要了解认证原理时，读取本文件。

---

## 认证流程

```
ones sso login [--ciba]
    ↓
获取 SSO opaque token（8 小时有效）
    ↓
首次调用 ONES 子命令 → 自动换票 ONES FE token
                        （audience=meituan.ee.ones.fe，缓存 2 小时）
```

### SSO 登录方式

| 方式 | 命令 | 说明 |
|------|------|------|
| CIBA（推荐） | `ones sso login --ciba` | 命令行发起，大象 App 收到推送后确认 |
| 浏览器 | `ones sso login` | 自动打开浏览器完成 SSO |
| 手动输入 | `ones sso login --manual` | 手动粘贴 Token |

### Token 时效

| Token 类型 | 有效期 | 刷新方式 |
|-----------|--------|---------|
| SSO opaque token | 8 小时 | `ones sso refresh` |
| ONES FE token | 2 小时（自动缓存） | 自动换票，无需手动 |

### 认证头/Cookie

- ONES 系统使用 **Cookie 认证**：`Cookie: ssoid=...; meituan.ee.ones.fe_ssoid=...`

---

## 常见认证问题

| 症状 | 原因 | 解决方案 |
|------|------|---------|
| `command not found: ones` | 未安装 CLI | `npm i -g @ee/ones-cli --registry=http://r.npm.sankuai.com` |
| 401 / 认证失败 | Token 过期或无效 | `ones sso refresh` → 若仍失败 → `ones sso login --ciba` |
| `Token 已过期` 提示 | SSO Token 超过 8 小时 | `ones sso login --ciba` 重新登录 |
| CIBA 超时无响应 | 大象 App 未确认或网络问题 | 检查大象 App 推送，或换用 `ones sso login`（浏览器方式） |
| 换票失败 | ONES FE audience 配置问题 | `ones sso login --ciba` 重新获取完整 Token |

---

## 常见操作问题

| 问题 | 解决 |
|------|------|
| 不知道空间 ID | `ones sp -n "关键词"` 搜索，或从 ONES URL `/project/48465/` 提取 |
| 不知道命令参数 | `ones <命令> --help` |
| 删除不可恢复 | 所有 delete 操作不可撤销，务必先确认 |
| 子类型更新报错 | 子类型只能更新为相同工作项类型下的合法子类型 |
| 工时记录 ID 怎么获取 | `ones wtd -i <工作项ID>` 查询工时日志 |
| 工时校验不通过 | 检查空间是否要求填写投入类型，或日期是否在允许范围内 |
| 迭代查询返回空 | 确认空间 ID 正确，且空间内已创建迭代 |
| 迭代创建失败 | 开始日期不能晚于结束日期，格式须为 YYYY-MM-DD |
| 测试计划搜索无结果 | 确认空间 ID，可用 `--no-interactive` 跳过筛选 |
| 提测状态无可流转选项 | 当前提测单可能已是终态，或用户无权限 |
| 空间查询返回空 | 确认登录状态正常，尝试 `--no-interactive` |
| 评论查询失败 | 确认空间 ID、工作项 ID 和类型参数正确 |

---

## 参考资源

- CIBA 认证文档：https://km.sankuai.com/collabpage/2732221228
- ONES API 文档：https://s3plus-bj02.vip.sankuai.com/supabase-bucket/ones-api-skill.md
- 内部 npm 源：http://r.npm.sankuai.com

