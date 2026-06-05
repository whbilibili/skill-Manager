---
name: mdp-project
description: 使用 mdp CLI 创建美团 MDP 项目脚手架。当用户需要创建 MDP 项目、初始化 MDP 工程、生成 MDP 项目模板时使用。支持通过 appkey 自动推导 groupId 和 artifactId，下载项目压缩包并自动解压、打开项目。

metadata:
  skillhub.creator: "wb_gepengfei"
  skillhub.updater: "wb_gepengfei"
  skillhub.version: "V1"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "20092"
  skillhub.high_sensitive: "false"
---

# MDP Project Creator

通过 `mdp` CLI 工具创建美团 MDP 项目。

## 前提条件

用户环境中需已安装 `mdp-cli`（包含 `mdp` 命令）。可通过以下方式验证：

```bash
mdp --help
```

若命令不存在，自动安装 `mdp-cli`。安装方式：执行：

```bash
pip install mt-mdp-cli -i http://pypi.sankuai.com/simple --trusted-host pypi.sankuai.com
```

## 参数说明

| 参数 | CLI 选项 | 必需 | 默认值 | 说明 |
|------|----------|------|--------|------|
| appkey | `--appkey` / `-a` | 是 | - | 格式：`com.sankuai.{应用名}.{模块名}.{服务名}`，模块名可省略 |
| groupId | `--groupId` / `-g` | 是 | 从 appkey 推导 | 通常取 appkey 去掉最后一段 |
| artifactId | `--artifactId` / `-art` | 是 | 从 appkey 推导 | 通常取 appkey 最后一段 |
| jdkVersion | `--jdkVersion` / `-j` | 否 | `17` | 可选值：`8` 或 `17` |

## 参数推导规则

appkey 格式为 `com.sankuai.{应用名}.{模块名}.{服务名}`（模块名可省略）：

- **有模块名**（4段）：`com.sankuai.app.module.service`
  - groupId = `com.sankuai.app.module`
  - artifactId = `service`

- **无模块名**（3段）：`com.sankuai.app.service`
  - groupId = `com.sankuai.app`
  - artifactId = `service`

## 工作流程

### 第一步：收集参数

必须先获得 `appkey`，然后自动推导 `groupId` 和 `artifactId`，无需用户确认默认值。

若用户未提供 appkey，询问用户提供。其他参数（jdkVersion）使用默认值 `17`，无需询问用户。

### 第二步：执行创建命令

```bash
mdp project \
  --appkey <appkey> \
  --groupId <groupId> \
  --artifactId <artifactId> \
  --jdkVersion <jdkVersion> \
  --output project.zip
```

**注意**：命令在用户当前工作目录执行，`project.zip` 会下载到当前目录。

### 第三步：解压并清理

```bash
# 解压
unzip project.zip

# 删除压缩包
rm project.zip
```

### 第四步：打开项目

使用编辑器命令打开解压后的项目目录（目录名通常为 artifactId）：

```bash
# CatPaw Desk 环境下使用
catpaw <项目目录路径>
```

### 第五步：描述项目结构

简要描述项目结构（目录布局、主要模块），**不要编译或添加任何代码**。

## 错误处理

- 若 `mdp` 命令不存在，提示用户先安装 `mdp-cli`（请联系管理员获取安装包）
- 若下载失败（文件大小异常或为错误响应），告知用户并展示错误信息
- 若解压后目录名与预期不符，用 `ls` 确认实际目录名再打开
