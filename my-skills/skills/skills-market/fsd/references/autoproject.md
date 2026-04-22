# 自动化工程管理（fsd autoproject）参考手册

> 所有操作遵循 SKILL.md 核心规则。

## 目录
- [fsd autoproject info](#fsd-autoproject-info)
- [fsd autoproject claw](#fsd-autoproject-claw)
- [fsd autoproject case-list](#fsd-autoproject-case-list)
- [项目状态映射](#项目状态映射)
- [项目信息字段](#项目信息字段)
- [爬取类型说明](#爬取类型说明)
- [用例信息字段](#用例信息字段)
- [常见错误码](#常见错误码)
- [使用示例](#使用示例)
- [退出码](#退出码)

---

## fsd autoproject info

根据项目名称查询 FST 自动化工程信息（精确匹配）。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--name` | string | 是 | 自动化工程名称（精确匹配） (默认: -) |
| `--fst-api-url` | string | 否 | FST API 地址 (默认: https://fst.sankuai.com) |
| `--fst-web-url` | string | 否 | FST Web 地址 (默认: https://fst.sankuai.com) |
| `--pretty` | boolean | 否 | 美化输出格式（人类可读） (默认: false) |
| `--debug` | boolean | 否 | 开启调试模式 (默认: false) |

**参数习惯**：AI 解析省略 `--pretty`（默认 JSON）；人工阅读可加 `--pretty`；排障加 `--debug`。

### 使用说明

1. **精确匹配**：项目名称必须完全匹配，不支持模糊查询（`case-list` 的用例搜索为模糊匹配，二者不同）
2. **自动认证**：使用 SSO 配置自动获取当前用户的 MIS ID，无需手动提供
3. **认证要求**：需要先执行 `fsd-sso login` 完成 SSO 登录
4. **输出格式**：不使用 `--pretty` 为 JSON（供解析）；使用 `--pretty` 为人类可读格式

---

## fsd autoproject claw

触发自动化测试工程爬取（增量或全量）。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--name` | string | 是 | 自动化工程名称（精确匹配） (默认: -) |
| `--parse-type` | string/number | 否 | 爬取类型（0=增量，1=全量） (默认: 0) |
| `--feature` | string | 否 | 分支名称（master/qa） (默认: master) |
| `--fst-api-url` | string | 否 | FST API 地址 (默认: https://fstapi.sankuai.com) |
| `--fsd-api-url` | string | 否 | FSD API 地址 (默认: https://fsd.sankuai.com) |
| `--holmes-api-url` | string | 否 | Holmes API 地址 (默认: https://holmesapi.sankuai.com) |
| `--pretty` | boolean | 否 | 美化输出格式（人类可读） (默认: false) |
| `--debug` | boolean | 否 | 开启调试模式 (默认: false) |

**说明**：通用项见上文 [fsd autoproject info](#fsd-autoproject-info) 中「使用说明」。本命令会先按名称查询工程得到 `project_id`，再调用 Holmes API 触发爬取；默认 `--parse-type 0`、`--feature master`，可用 `--parse-type 1` 全量、`--feature qa` 换分支。

---

## fsd autoproject case-list

查询 FST 自动化工程的用例列表（支持模糊搜索和分页）。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--project-id` | number | 是 | 自动化测试项目 ID (默认: -) |
| `--case-info` | string | 否 | 用例标题、方法或类名（模糊搜索） (默认: "") |
| `--author` | string | 否 | 用例作者 MIS ID（留空查询全部） (默认: "") |
| `--branch` | string | 否 | 分支名称（master/qa） (默认: master) |
| `--page-no` | number | 否 | 页码 (默认: 1) |
| `--page-size` | number | 否 | 每页数量 (默认: 15) |
| `--fst-api-url` | string | 否 | FST API 地址 (默认: https://fst.sankuai.com) |
| `--fst-web-url` | string | 否 | FST Web 地址 (默认: https://fst.sankuai.com) |
| `--pretty` | boolean | 否 | 美化输出格式（人类可读） (默认: false) |
| `--debug` | boolean | 否 | 开启调试模式 (默认: false) |

**说明**：通用项见上文 [fsd autoproject info](#fsd-autoproject-info) 中「使用说明」。`--case-info` / `--author` / `--branch` / 分页参数可组合，条件为 AND；列表为**不符合规范**用例（type=0）。

---

## 项目状态映射

| 项目状态码 | 状态文本 | 说明 |
|-----------|---------|------|
| 0 | 未知 | 状态未知 |
| 1 | 正常 | 项目正常 |
| 2 | 正常 | 项目正常 |
| 3 | 异常 | 项目异常 |

---

## 项目信息字段

| 字段 | 说明 |
|------|------|
| `status` / `project_id` / `project_name` / `project_git` | 请求状态 / 项目 ID / 项目名称 / Git 仓库地址 |
| `project_status` / `project_status_text` / `build_error` | 项目状态码（0/1/2/3） / 状态文本（未知/正常/异常） / 构建错误信息 |
| `project_score` / `case_score` / `case_count` / `invalid_case_num` | 项目评分 / 用例评分 / 用例总数 / 失效用例数 |
| `linked_test_plan_num` / `linked_pipeline_num` | 关联测试计划数 / 关联流水线数 |
| `project_admins` / `admin_infos[]` | 管理员 MIS 列表（逗号分隔） / 管理员详细信息数组 |
| `admin_infos[].mis` / `name` / `org_name` / `org_path_name` / `avatar_url` | 管理员 MIS ID / 姓名 / 所属组织 / 组织完整路径 / 头像 URL |
| `org_name` / `parse_dir` / `web_url` | 项目所属组织 / 用例解析目录 / 项目详情页 URL |
| `create_time` / `update_time` / `is_favourite` | 创建时间（时间戳） / 更新时间（时间戳） / 是否收藏 |

---

## 爬取类型说明

| 值 | 类型 | 说明 |
|----|------|------|
| 0 | 增量爬取 | 仅爬取自上次爬取以来的新增或修改的用例 |
| 1 | 全量爬取 | 爬取项目中的所有用例，不管是否已经爬取过 |

---

## 用例信息字段

| 字段 | 说明 |
|------|------|
| `status` / `project_id` / `branch` | 请求状态 / 项目 ID / 分支名称（master/qa） |
| `total` / `page_no` / `page_size` / `case_count` | 用例总数 / 当前页码 / 每页数量 / 本页用例数量 |
| `case_list[].case_id` / `case_name` / `case_method` / `case_class` | 用例 ID / 用例名称 / 测试方法名 / 测试类名 |
| `case_list[].case_desc` / `case_author` / `case_submitter` | 用例描述 / 用例作者 MIS ID / 用例提交人 MIS ID |
| `case_list[].invalid_reason` / `case_standard` / `update_time` | 失效原因（对象格式） / 用例评分 / 更新时间 |
| `case_list[].appkey` / `periodic_run_success_rate` / `periodic_run_count` | 关联的 appkey 列表 / 周期执行成功率 / 周期执行次数 |
| `case_list[].average_exec_time` / `case_url` | 平均执行时间（ms） / 用例详情页 URL |

---

## 常见错误码

| 错误码 | 说明 | 解决方案 |
|-------|------|---------|
| `FST_API_ERROR` | FST API 返回错误 | 检查 API 返回的错误信息 |
| `PROJECT_NOT_FOUND` | 项目不存在 | 确认项目名称是否正确（精确匹配）；错误 JSON 可能含 `similar_projects` 提示相似工程名 |
| `NETWORK_ERROR` | 网络请求失败 | 检查网络连接或稍后重试 |
| `UNKNOWN_ERROR` | 未知错误 | 查看详细错误信息或联系管理员 |

---

## 使用示例

### 示例 P1：查询自动化工程信息（JSON）

```bash
fsd autoproject info --name waimai-c-api-case
```

```json
{
  "status": "success",
  "project_id": "2",
  "project_name": "waimai-c-api-case",
  "project_status_text": "正常",
  "case_count": 3607,
  "web_url": "https://fst.sankuai.com/#/FstProjectDetailPage?projectId=2"
}
```

（完整字段见[项目信息字段](#项目信息字段)。）

---

### 示例 C1 / C2：触发爬取（JSON）

```bash
fsd autoproject claw --name waimai-c-api-case
# 全量：fsd autoproject claw --name waimai-c-api-case --parse-type 1
```

```json
{
  "status": "success",
  "project_id": "2",
  "parse_type": 0,
  "parse_type_text": "增量爬取",
  "message": "触发爬取成功"
}
```

全量时 `parse_type` 为 `1`，`parse_type_text` 为「全量爬取」；另有 `feature` 等字段以实际 JSON 为准。

---

### 示例 L1：用例列表（JSON，结构示意）

```bash
fsd autoproject case-list --project-id 2
```

```json
{
  "status": "success",
  "project_id": 2,
  "branch": "master",
  "total": 1944,
  "page_no": 1,
  "page_size": 15,
  "case_count": 15,
  "case_list": [
    {
      "case_id": 54,
      "case_name": "/api/v7/order/update 查券",
      "case_method": "wm_memberTieOnCardCoupon_04",
      "case_class": "com.sankuai....MemberTieOnCardCoupon",
      "case_url": "https://fst.sankuai.com/#/FstCaseDetailPage?caseId=54"
    }
  ]
}
```

（`case_list[]` 另有 `case_desc`、`invalid_reason` 等，见[用例信息字段](#用例信息字段)。）

---

### 示例 L2：按用例名称模糊搜索

```bash
fsd autoproject case-list --project-id 2 --case-info "order"
```

`--case-info` 支持模糊匹配用例标题、方法名或类名（中英文关键字均可）。

---

## 退出码

**0**：成功。**1**：失败（如项目不存在、网络错误、API 错误等）。
