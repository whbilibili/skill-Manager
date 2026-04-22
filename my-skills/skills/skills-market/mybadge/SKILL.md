---
name: mybadge
description: "美团工卡与门禁权限综合管理。支持：查看工卡状态、门禁权限列表、权限申请记录、人脸授权状态；挂失/补办工卡、申请门禁权限、获取通行二维码引导到手机端操作。触发词：工卡、门禁卡、挂失、补办、工卡状态、丢卡、卡丢了、补卡、我的工卡、通行二维码、扫码进门、人脸授权、人脸识别、人脸认证、人脸底图、门禁权限、权限申请、权限审批。不适用于：修改工卡信息、账号管理、非美团员工查询。通过 skills-administrative mybadge CLI 执行。"

metadata:
  skillhub.creator: "yuyonggui"
  skillhub.updater: "yanglin17"
  skillhub.version: "V7"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "3014"
  skillhub.high_sensitive: "false"
---

# 美团工卡与门禁权限综合管理

通过 CLI 查询工卡状态、人脸授权、门禁权限及申请记录。认证由 `@it/oa-skills-shared` 自动处理（SSO CIBA）。

## skill使用问题反馈

如果遇到 skill 的使用问题，请提 [TT|https://tt.sankuai.com/public/create?cid=17&tid=1615&iid=47000] 进行反馈

## 前置检查：确保 CLI 最新

**重要！！！ 每次 skill 激活时执行以下命令，对比cli本地版本与远端最新正式版本，仅在不一致时升级，否则新命令可能不存在，导致运行失败**

```bash
LOCAL=$(npm list -g @cap/skills-administrative --depth=0 2>/dev/null | grep '@cap/skills-administrative' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+[^ ]*'); \
REMOTE=$(npm view @cap/skills-administrative dist-tags.latest --registry=http://r.npm.sankuai.com 2>/dev/null); \
if [ "$LOCAL" != "$REMOTE" ]; then \
  echo "版本不一致（本地: ${LOCAL:-未安装}, 远端: $REMOTE），开始升级..."; \
  npm install -g @cap/skills-administrative@latest --registry=http://r.npm.sankuai.com; \
else \
  echo "已是最新版本 $REMOTE，无需升级。"; \
fi
```

---

## 系统信息

| 系统 | clientId | 说明 |
|------|----------|------|
| 工卡 | `19f22fb3d3` | 工卡综合信息 |
| 门禁 | `fbfe340900` | 门禁权限 / 申请记录 |
| 人脸授权 | `59d9fa12f6` | 人脸授权状态 |

## 工作流

**入口条件**：用户提出工卡、门禁、人脸授权相关问题
**出口条件**：CLI 命令退出码为 0 且已向用户展示关键信息摘要；或已向用户提供引导页面链接

## 路由表：意图 → 操作

| 用户意图 | 操作方式 | 命令 / 链接 |
|---------|---------|------------|
| 查看工卡状态 | CLI 查询 | `getBadgeInfo` |
| 查看人脸授权 | CLI 查询 | `getFaceAuth` |
| 查看门禁权限 | CLI 查询 | `getDoors` |
| 查看权限申请记录 | CLI 查询 | `getApplies` |
| 挂失 / 解除挂失 / 补办工卡 | 引导到页面 | [我的工卡（请使用手机端打开）](https://xz.sankuai.com/newworkcard/mobile/my-badge) |
| 通行二维码 | 引导到页面 | [通行二维码（请使用手机端打开）](https://xz.sankuai.com/cac/qr-code) |
| 申请门禁权限 | 引导到页面 | [权限申请（请使用手机端打开）](https://xz.sankuai.com/cac/application-list) |

## 命令使用方式

所有命令格式：`skills-administrative mybadge <command> [options]`

### `getBadgeInfo`

查看工卡综合信息（状态、卡号、类型）。

```bash
skills-administrative mybadge getBadgeInfo
```

**输出格式**（Markdown 表格）：

| 项目 | 内容 |
|------|------|
| 姓名 | `name` |
| 卡号 | `cardNum` |
| 工卡类型 | `cardTypeName` |
| 工卡状态 | `cardStatusName`（NORMAL→✅，LOSS→❌，其他→⚠️） |

如用户需要挂失/补办则给出页面链接：[我的工卡（请使用手机端打开）](https://xz.sankuai.com/newworkcard/mobile/my-badge)

### `getFaceAuth`

查看人脸授权状态。

```bash
skills-administrative mybadge getFaceAuth
```

**输出格式**（列表）：

- 授权状态：`state=1`→✅ 已授权，`state=0`→❌ 未授权
- 授权时间：`createTime`（已转换为可读格式）
- 人脸门禁照片：photoUrl 非空时展示可点击链接；为空则显示「暂无照片」

### `getDoors`

查看当前门禁权限列表（最多展示 50 条）。

```bash
skills-administrative mybadge getDoors --mis <mis> [--page 1] [--size 50]
```

**输出格式**：将权限按类型分为两个独立的 Markdown 表格展示（普通办公门 / 特殊功能门）。

**超限处理**：若总数 > 50，在所有表格后提示并引导用户前往页面端查看。

### `getApplies`

查看门禁权限申请记录（最多展示 50 条）。

```bash
skills-administrative mybadge getApplies --mis <mis> [--status PROCESSING|DRAFT|REJECTED|PROCESSED] [--type COMMON|SPECIAL]
```

**输出格式**（Markdown 表格）：

| 权限名称 | 类型 | 状态 | 申请时间 | 有效期 |
|---------|------|------|----------|--------|

状态映射：PROCESSING=审批中、DRAFT=草稿、REJECTED=已拒绝、PROCESSED=已完成。

## 引导到页面的操作

以下操作**不通过 API**，直接给用户发链接：

- **挂失 / 解除挂失 / 补办**（同义词：丢卡、卡丢了、补卡）：[我的工卡（请使用手机端打开）](https://xz.sankuai.com/newworkcard/mobile/my-badge)
- **通行二维码**（同义词：扫码进门、扫码通行）：[通行二维码（请使用手机端打开）](https://xz.sankuai.com/cac/qr-code)
- **申请门禁权限**：[权限申请（请使用手机端打开）](https://xz.sankuai.com/cac/application-list)

即使用户明确要求调用接口，以上三类也统一引导到页面。

## 认证

使用 SSO CIBA 认证（非 MOA 无感登录），三个子系统各自独立换票（clientId 不同）。首次调用需用户在大象 App 确认授权。Token 自动缓存。

- 认证失败 → `skills-administrative mybadge --clear-cache` 后重试
- 用户说"没法手机确认" → 解释 CIBA 必须手机确认，无法跳过

## API 速查

| 接口 | 方法 | 系统 | 命令 |
|------|------|------|------|
| `/api/newcard/app/myBadge/info` | POST | 工卡（`19f22fb3d3`） | `getBadgeInfo` |
| `/face/api/authorization` | GET | 人脸（`59d9fa12f6`） | `getFaceAuth` |
| `/cac/api/app/v2/my/doorGroup` | POST | 门禁（`fbfe340900`） | `getDoors` |
| `/cac/api/app/apply/list` | GET | 门禁（`fbfe340900`） | `getApplies` |

## 异常处理规范

### 认证失败

- 认证失败时提示：抱歉，认证失败，请稍后重试。
- 可尝试 `--clear-cache` 清除缓存后重试。

### 数据为空

| 命令 | 提示文案 |
|------|----------|
| `getBadgeInfo` | 暂未查询到工卡信息，请前往 [我的工卡（请使用手机端打开）](https://xz.sankuai.com/newworkcard/mobile/my-badge) 查看。 |
| `getFaceAuth` | 暂未查询到人脸授权信息，如需授权请前往 [人脸授权管理（请使用手机端打开）](https://xz.sankuai.com/face/authorizeDetail) 进行操作。 |
| `getDoors` | 暂无门禁权限记录，如需申请请前往 [权限申请（请使用手机端打开）](https://xz.sankuai.com/cac/application-list) 提交申请。 |
| `getApplies` | 暂无权限申请记录，如需申请请前往 [权限申请（请使用手机端打开）](https://xz.sankuai.com/cac/application-list) 提交申请。 |

## 约束

- 批量查询单次最多展示 50 条（`getDoors` / `getApplies`），超限引导用户前往页面端查看
- 不输出内部 clientId、token 等敏感信息
- `--mis` 为可选参数，缺失时默认使用当前认证用户；格式为字母开头的字母数字下划线组合（如 `yanglin17`），非法格式会报错退出
- 所有查询命令均只能查询**当前认证用户自己**的数据，传入他人 MIS 不会返回他人数据（服务端 SSO token 绑定当前用户）

## 验证

执行完成后确认：

1. 命令退出码为 0
2. 返回了相应数据（关键字段不为空）
3. 给用户简明总结关键信息，而非直接粘贴原始 JSON
