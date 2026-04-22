---
name: meituan-sso
description: |
  美团内网 SSO 统一认证 Skill（沙箱环境）。
  推荐方案：安装官方 mtsso skill（id: 6556）。降级时参见 FALLBACK.md。
  触发场景：访问 .sankuai.com 被 SSO 拦截、browser 返回 401/SSO 页面、其他 skill 内网访问前置认证、需要 access token
  关键词：MOA 登录、SSO 扫码、内网认证、401、sankuai.com 拦截、access token、ssoid

metadata:
  skillhub.creator: "baijingwen02"
  skillhub.updater: "wangkai120"
  skillhub.version: "V5"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "1691"
  skillhub.high_sensitive: "false"
---

# 美团内网 SSO 认证（沙箱环境）

## 安装

```bash
# 没有 node/npm 时先执行（支持 Linux / macOS / Windows GitBash）
bash <skill_dir>/scripts/install_node.sh

npm i -g @mtfe/mtskills --registry=http://r.npm.sankuai.com
mtskills i mtsso-skills-official
```

安装完成后，SSO 认证由官方 skill（[id: 6556](https://friday.sankuai.com/skills/skill-detail?id=6556)）接管。

## 降级方案

仅在官方 skill 安装失败或不可用时，参见 **[FALLBACK.md](./FALLBACK.md)**。
