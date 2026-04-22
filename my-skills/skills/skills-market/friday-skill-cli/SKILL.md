---
name: friday-skill-cli
description: Friday Skills 广场 CLI 工具。认证优先级：(1) MOA 无感登录（@mtfe/mtsso-auth-official，无需确认）(2) CIBA 降级（需大象确认）(3) --browser（浏览器 cookie）(4) --app-auth（client credentials，无用户身份）。
version: 2.3.0
tags: 技术开发,CLI

skill-dependencies:
  mtsso-skills-official:
    user_access_token_placeholder: ${user_access_token}
    audience:
      - 0968168675   # Friday MCP Hub SSO client_id
    prompt: 本技能所需的token占位符，请参考mtsso-skills-official的相关说明进行获取和注入

metadata:
  skillhub.creator: "yeshaozhi"
  skillhub.updater: "yeshaozhi"
  skillhub.version: "V28"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "2030"
  skillhub.high_sensitive: "false"
---

# friday-skill — Friday Skills 广场 CLI

通过命令行管理 Friday MCP 广场上的 Skill。

## 安装

```bash
cp {baseDir}/scripts/friday-skill /usr/local/bin/friday-skill && chmod +x /usr/local/bin/friday-skill
```

## 触发条件 / 适用场景

- **Skill 开发者**：需要上传、更新、删除 Friday Skills 广场上的 Skill
- **Skill 使用者**：需要搜索、下载 Skill 到本地使用
- **运维场景**：批量管理多个 Skill，查看下载统计
- **CI/CD 集成**：在自动化流程中发布 Skill（配合 `--app-auth`）

## 工作流程

### 1. 搜索 Skill
```bash
friday-skill search --query "AI coding"
```

### 2. 下载 Skill
```bash
friday-skill download --id 123 --extract
```

### 3. 创建新 Skill
```bash
# 在 Skill 目录中准备 SKILL.md 和脚本
friday-skill create --dir ./my-skill --appkey com.sankuai.xxx
```

### 4. 更新已有 Skill
```bash
friday-skill update --id <SKILL_ID> --dir ./my-skill
```

### 5. 查看 Skill 详情
```bash
friday-skill info --id <SKILL_ID>
friday-skill list --mine
```

## 认证

### 默认（MOA 无感登录 → CIBA 降级）
- 优先通过 `@mtfe/mtsso-auth-official` MOA 无感取票，**无需任何操作**
- 认证前自动探测 MOA 支持情况（`npx mtsso-moa-feature-probe`）
- MOA 不可用时自动降级为 CIBA（需大象 App 确认）
- 两者均传递用户身份
- CIBA 等待进度输出到 stderr，避免污染 stdout JSON

```bash
friday-skill list --mine
```

### --browser（浏览器 cookie）
- 有用户身份
- 需要 Chrome 已登录 Friday

```bash
friday-skill update --id <ID> --dir ./my-skill --browser
```

### --app-auth（client credentials）
- 无用户身份（应用票）
- 无需确认

```bash
friday-skill list --app-auth "clientId,secret"
```

## 命令速查

```bash
friday-skill create  --dir ./my-skill --appkey com.sankuai.xxx
friday-skill update  --id <ID> --dir ./my-skill
friday-skill delete  --id <ID>
friday-skill info    --id <ID>
friday-skill list    [--mine]
friday-skill search  --query "关键字"
friday-skill download --id <ID> [--out skill.zip]
```
