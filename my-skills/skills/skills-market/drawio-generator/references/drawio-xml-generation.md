---
ruleType: Model Request
description: 编写或修改 Draw.io 流程图 XML 文件时参考的格式规范，定义了 XML 结构、元素属性和最佳实践
---

# Draw.io 流程图 XML 脚本生成规范

## 规则概述
本文档定义了 Draw.io (.drawio) 流程图文件的 XML 生成规范。Draw.io 使用 mxGraph 格式存储图表数据，了解其结构有助于正确生成和修改流程图文件。

## XML 文件结构

### 1. 根元素结构
```xml
<mxGraphModel dx="818" dy="2432" grid="1" gridSize="10" guides="1" 
              tooltips="1" connect="1" arrows="1" fold="1" page="1" 
              pageScale="1" pageWidth="1169" pageHeight="827" 
              background="#ffffff" math="0" shadow="0">
  <root>
    <mxCell id="0" />
    <mxCell id="1" parent="0" />
    <!-- 所有图形元素放在这里 -->
  </root>
</mxGraphModel>
```

### 2. mxGraphModel 根元素属性

| 属性名 | 类型 | 说明 | 默认值 |
|--------|------|------|--------|
| dx | number | 画布水平偏移 | 818 |
| dy | number | 画布垂直偏移 | 2432 |
| grid | 0/1 | 是否显示网格 | 1 |
| gridSize | number | 网格大小 | 10 |
| guides | 0/1 | 是否显示辅助线 | 1 |
| tooltips | 0/1 | 是否启用提示 | 1 |
| connect | 0/1 | 是否允许连接 | 1 |
| arrows | 0/1 | 是否显示箭头 | 1 |
| fold | 0/1 | 是否允许折叠 | 1 |
| page | 0/1 | 是否显示页面 | 1 |
| pageScale | number | 页面缩放比例 | 1 |
| pageWidth | number | 页面宽度 | 1169 |
| pageHeight | number | 页面高度 | 827 |
| background | color | 背景颜色 | #ffffff |

## XML 注释约束（兼容性关键）

### 1. 注释禁止项

XML 注释内容中**不能包含 `--`**（双连字符），否则整个文件会变成非法 XML，导致 draw.io/学城无法渲染。

- ❌ 错误：`<!-- ---- 1.1 外框 ---- -->`
- ✅ 正确：`<!-- == 1.1 外框 == -->`
- ✅ 正确：`<!-- 1.1 外框 -->`

**特别注意：`-->` 也是禁止出现在注释内容中的**。`-->` 是 XML 注释的结束标记，一旦出现在注释内部，注释会提前结束，剩余内容变为非法 XML。

常见错误场景：用 `-->` 表示流程箭头时：

- ❌ 错误：`<!-- A --> B -->`（注释在第一个 `-->` 处结束，` B -->` 变成非法内容）
- ❌ 错误：`<!-- START --> L1(节点) -->`
- ✅ 正确：`<!-- A -> B -->`（用单箭头）
- ✅ 正确：`<!-- A 流向 B -->`
- ✅ 正确：`<!-- 连线：A 到 B -->`

### 2. 生成建议

- 不要用连续短横线做分隔注释
- 优先使用 `=`、`*` 或普通文本作为注释分隔符
- **注释中描述流程方向时，用 `->` 单箭头，禁止用 `-->`**
- 编码前先执行 `xmllint --noout <file.drawio>` 做语法校验

## 元素定义规范

### 1. 基础元素 (mxCell)

所有图形元素都使用 `<mxCell>` 标签定义：

```xml
<mxCell id="唯一标识" 
        value="显示文本" 
        style="样式字符串" 
        parent="父元素ID" 
        vertex="1">
  <mxGeometry x="x坐标" y="y坐标" width="宽度" height="高度" as="geometry" />
</mxCell>
```

### 2. 元素 ID 命名规范

- 使用数字递增：`id="2"`, `id="3"`, `id="4"`
- 保持 ID 唯一性
- `id="0"` 和 `id="1"` 为系统保留（根节点）

### 3. 坐标系统

- 原点 (0, 0) 在画布左上角
- X 轴向右为正
- Y 轴向下为正
- 所有坐标使用数字，不带单位

## 常用形状样式

### 1. 基础矩形
```xml
style="rounded=0;whiteSpace=wrap;html=1;"
```

### 2. 圆角矩形
```xml
style="rounded=1;whiteSpace=wrap;html=1;arcSize=20;"
```

### 3. 带颜色矩形

**黄色（强调/输入输出）**：
```xml
style="rounded=0;whiteSpace=wrap;html=1;fillColor=#fff2cc;strokeColor=#d6b656;"
```

**蓝色（功能模块）**：
```xml
style="rounded=0;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;"
```

**绿色（成功/完成）**：
```xml
style="rounded=0;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;"
```

**红色（错误/警告）**：
```xml
style="rounded=0;whiteSpace=wrap;html=1;fillColor=#f8cecc;strokeColor=#b85450;"
```

### 4. 菱形（决策/判断节点）
```xml
style="rhombus;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;"
```

### 5. 椭圆（开始/结束节点）
```xml
style="ellipse;whiteSpace=wrap;html=1;fillColor=#f5f5f5;strokeColor=#666666;fontStyle=1;"
```

### 6. 纯文本标签
```xml
style="text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;"
```

### 7. 分组容器（swimlane）
```xml
style="swimlane;startSize=30;fillColor=#f5f5f5;strokeColor=#666666;fontStyle=1;"
```

### 8. 普通分组框
```xml
style="rounded=0;whiteSpace=wrap;html=1;strokeWidth=2;"
```

## 连接线规范

### 1. 基础连接线
```xml
<mxCell id="连接线ID" 
        style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;" 
        parent="1" 
        source="源元素ID" 
        target="目标元素ID" 
        edge="1">
  <mxGeometry relative="1" as="geometry" />
</mxCell>
```

### 2. 带箭头连接线
```xml
style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=classic;"
```

### 3. 连接线样式属性

| 属性 | 说明 | 可选值 |
|------|------|--------|
| edgeStyle | 边缘样式 | orthogonalEdgeStyle, elbowEdgeStyle, entityRelationEdgeStyle |
| rounded | 是否圆角 | 0, 1 |
| orthogonalLoop | 正交循环 | 0, 1 |
| jettySize | 喷口大小 | auto, 数字 |
| endArrow | 结束箭头 | classic, open, diamond, none |
| startArrow | 开始箭头 | classic, open, diamond, none |

### 4. 连接线标签
```xml
<mxCell id="标签ID" 
        value="标签文本" 
        style="edgeLabel;html=1;align=center;verticalAlign=middle;resizable=0;points=[];" 
        parent="连接线ID" 
        vertex="1" 
        connectable="0">
  <mxGeometry x="偏移量" relative="1" as="geometry">
    <mxPoint as="offset" />
  </mxGeometry>
</mxCell>
```

## 入口/出口点定义

### 1. 入口点配置
```xml
entryX="0"     <!-- 入口X坐标比例 (0-1) -->
entryY="0.5"   <!-- 入口Y坐标比例 (0-1) -->
entryDx="0"    <!-- 入口X偏移 -->
entryDy="0"    <!-- 入口Y偏移 -->
entryPerimeter="0"  <!-- 是否使用周长计算 -->
```

### 2. 出口点配置
```xml
exitX="1"      <!-- 出口X坐标比例 (0-1) -->
exitY="0.5"    <!-- 出口Y坐标比例 (0-1) -->
exitDx="0"     <!-- 出口X偏移 -->
exitDy="0"     <!-- 出口Y偏移 -->
exitPerimeter="0"   <!-- 是否使用周长计算 -->
```

### 3. 常用连接点位置

| 位置 | entryX | entryY | exitX | exitY |
|------|--------|--------|-------|-------|
| 左侧中点 | 0 | 0.5 | - | - |
| 右侧中点 | 1 | 0.5 | - | - |
| 顶部中点 | 0.5 | 0 | - | - |
| 底部中点 | 0.5 | 1 | - | - |
| 左上角 | 0 | 0 | - | - |
| 右下角 | 1 | 1 | - | - |

## 尺寸规范

### 1. 常用元素尺寸

| 元素类型 | 宽度 | 高度 | 说明 |
|----------|------|------|------|
| 标准节点 | 120 | 60 | 流程图基本单位 |
| 大节点 | 160 | 80 | 需要更多文本的节点 |
| 标签 | 自动 | 30 | 使用 autosize=1 |
| 分组容器 | 根据内容 | 根据内容 | 包含子元素 |
| 适配层标签 | 120-140 | 30 | 底部/顶部标签 |

### 2. 间距规范

- 元素间距：至少 20px
- 分组边距：内部元素距边框至少 10px
- 连接线标签偏移：-0.2 到 0.2 之间

## 颜色规范

### 1. 预定义颜色

| 用途 | 填充色 | 边框色 | 说明 |
|------|--------|--------|------|
| 输入/输出 | #fff2cc | #d6b656 | 黄色，表示外部交互 |
| 功能模块 | #dae8fc | #6c8ebf | 蓝色，表示内部处理 |
| 成功/完成 | #d5e8d4 | #82b366 | 绿色，表示正向流程 |
| 错误/警告 | #f8cecc | #b85450 | 红色，表示异常流程 |
| 中性/容器 | #f5f5f5 | #666666 | 灰色，表示分组 |

### 2. 颜色使用原则

- 同类元素使用相同颜色
- 保持颜色对比度适中
- 遵循语义化颜色含义
- 避免使用过于鲜艳的颜色

## 完整示例

### 示例：简单流程图

```xml
<mxGraphModel dx="818" dy="2432" grid="1" gridSize="10" guides="1" 
              tooltips="1" connect="1" arrows="1" fold="1" page="1" 
              pageScale="1" pageWidth="1169" pageHeight="827" 
              background="#ffffff" math="0" shadow="0">
  <root>
    <mxCell id="0" />
    <mxCell id="1" parent="0" />
    
    <!-- 输入节点 -->
    <mxCell id="2" value="开始" 
            style="rounded=0;whiteSpace=wrap;html=1;fillColor=#fff2cc;strokeColor=#d6b656;" 
            parent="1" vertex="1">
      <mxGeometry x="120" y="120" width="120" height="60" as="geometry" />
    </mxCell>
    
    <!-- 处理节点 -->
    <mxCell id="3" value="处理" 
            style="rounded=0;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" 
            parent="1" vertex="1">
      <mxGeometry x="320" y="120" width="120" height="60" as="geometry" />
    </mxCell>
    
    <!-- 结束节点 -->
    <mxCell id="4" value="结束" 
            style="rounded=0;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;" 
            parent="1" vertex="1">
      <mxGeometry x="520" y="120" width="120" height="60" as="geometry" />
    </mxCell>
    
    <!-- 连接线：开始 -> 处理 -->
    <mxCell id="5" 
            style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;entryX=0;entryY=0.5;entryDx=0;entryDy=0;exitX=1;exitY=0.5;exitDx=0;exitDy=0;" 
            parent="1" source="2" target="3" edge="1">
      <mxGeometry relative="1" as="geometry" />
    </mxCell>
    
    <!-- 连接线：处理 -> 结束 -->
    <mxCell id="6" 
            style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;entryX=0;entryY=0.5;entryDx=0;entryDy=0;exitX=1;exitY=0.5;exitDx=0;exitDy=0;" 
            parent="1" source="3" target="4" edge="1">
      <mxGeometry relative="1" as="geometry" />
    </mxCell>
  </root>
</mxGraphModel>
```

### 示例：分组容器

**重要**：容器内部元素的 `parent` 必须设为容器的 `id`，坐标是相对于容器内部的偏移（非画布绝对坐标）。

```xml
<!-- 外层容器 -->
<mxCell id="10" value="" 
        style="rounded=0;whiteSpace=wrap;html=1;" 
        parent="1" vertex="1">
  <mxGeometry x="320" y="110" width="480" height="400" as="geometry" />
</mxCell>

<!-- 内部元素：parent 必须是容器 id="10"，坐标相对容器左上角 -->
<mxCell id="11" value="模块A" 
        style="rounded=0;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;" 
        parent="10" vertex="1">
  <mxGeometry x="20" y="20" width="120" height="60" as="geometry" />
</mxCell>

<!-- 容器标签（放在容器外，parent="1"，用于显示标题） -->
<mxCell id="12" value="分组名称" 
        style="text;html=1;align=center;verticalAlign=middle;resizable=0;points=[];autosize=1;strokeColor=none;fillColor=none;" 
        parent="1" vertex="1">
  <mxGeometry x="320" y="108" width="70" height="30" as="geometry" />
</mxCell>
```

## 最佳实践

### 1. 布局原则

- **从左到右**：流程从左向右展开
- **从上到下**：层次从上向下递进
- **对齐整齐**：元素坐标取 10 的倍数
- **间距一致**：同类元素保持相同间距

### 2. ID 管理

- 预先规划 ID 分配
- 按"分组-序号"方式管理
- 预留 ID 空间便于扩展
- 连接线 ID 放在元素 ID 之后

### 3. 样式复用

- 定义通用样式模板
- 相同类型元素使用相同样式
- 便于批量修改和维护

### 4. 可读性

- 使用有意义的 value 值
- 添加 XML 注释说明复杂结构
- 保持合理的元素嵌套层级

## 节点重叠检测规范

生成 XML 后，必须对同一 `parent` 下的节点进行重叠检查，避免节点在画布上叠加显示。

### 1. 重叠判定规则

两个节点 A 和 B（同一 parent）发生重叠，当且仅当：

```
A.x < B.x + B.width  AND  B.x < A.x + A.width
AND
A.y < B.y + B.height AND  B.y < A.y + A.height
```

### 2. 常见重叠场景及修复

**场景一：菱形判断节点与其下游节点 y 坐标过近**

菱形（rhombus）通常有多个出口，其下游节点会放在左/右/下方。若下游节点的 y 坐标落在菱形的 y ~ y+height 范围内，且 x 坐标也有交叉，就会重叠。

修复方法：下游节点的 `y` 值至少为 `菱形.y + 菱形.height + 20`（留 20px 间距）。

**场景二：连续步骤节点 y 坐标递增不足**

```
❌ 错误：
节点A: y=160, height=60  (底部 y=220)
节点B: y=170, height=80  (顶部 y=170) → 与 A 重叠 50px

✅ 正确：
节点A: y=160, height=60  (底部 y=220)
节点B: y=250, height=80  (顶部 y=250) → 间距 30px
```

**场景三：同层多分支节点 x 坐标不足**

左/右分支节点的 x 坐标需确保不与中心节点重叠：
- 左分支：`x + width + 20 <= 中心节点.x`
- 右分支：`x >= 中心节点.x + 中心节点.width + 20`

### 3. swimlane 容器内的坐标

swimlane 容器内的子节点坐标是**相对于容器内部**的，需减去 `startSize`（标题栏高度，通常 30~40px）后才是实际可用区域的起点。

容器内子节点的实际可用高度 = `容器.height - startSize`，子节点的 y 坐标从 0 开始计算（相对于内部）。

## 检查清单

- [ ] 所有 mxCell 元素都有唯一 ID
- [ ] 坐标和尺寸数值正确
- [ ] 连接线的 source 和 target 指向正确的元素 ID
- [ ] 颜色使用符合语义
- [ ] 元素对齐和间距合理（最小间距 20px）
- [ ] **同一 parent 下的节点无重叠**（用重叠判定规则逐一核查）
- [ ] XML 语法正确，标签正确闭合
- [ ] **注释中无 `--` 和 `-->`**（用 `->` 代替箭头）

## 注意事项

1. **坐标精度**：连接线入口/出口坐标使用小数表示比例位置
2. **层级关系**：parent 属性决定元素的层级关系
3. **样式字符串**：样式属性使用分号分隔，格式为 `key=value;`
4. **XML 编码**：特殊字符需要使用 XML 实体编码（如 `<` 编码为 `&lt;`）

## 特殊字符处理

### 中文引号问题

**重要**：value 属性中**禁止使用中文引号**（`""` 和 `''`），这会导致 Draw.io 解析错误（parsererror）。

### 正确的引号处理方式

| 错误写法 | 正确写法 | 说明 |
|----------|----------|------|
| `value="点击"确认""` | `value="点击&quot;确认&quot;"` | 使用 `&quot;` 实体 |
| `value="输入"用户名""` | `value="输入&quot;用户名&quot;"` | 使用 `&quot; 实体 |

### 特殊字符实体编码表

| 字符 | 实体编码 | 示例 |
|------|----------|------|
| `"` | `&quot;` | `value="点击&quot;确认&quot;"` |
| `'` | `&apos;` | `value="用户&apos;s 数据"` |
| `<` | `&lt;` | `value="条件: x &lt; 10"` |
| `>` | `&gt;` | `value="条件: x &gt; 5"` |
| `&` | `&amp;` | `value="A &amp; B"` |
| 换行 | `&#xa;` | `value="第一行&#xa;第二行"` |

### 最佳实践

1. **统一使用英文引号**：在 value 属性中需要显示引号时，使用 `&quot;` 实体
2. **避免中文引号**：中文引号 `""` 在 XML 属性中会导致解析问题
3. **换行符**：使用 `&#xa;` 表示换行，而不是直接换行
4. **预检查**：生成 XML 后检查是否包含中文引号，如有则替换为 `&quot;`

### 错误示例与修正

**错误示例**（会导致 parsererror）：
```xml
<mxCell id="101" value="点击"导出开放平台开票门店"" 
        style="rounded=0;whiteSpace=wrap;html=1;fillColor=#fff2cc;strokeColor=#d6b656;" 
        parent="1" vertex="1">
```

**正确示例**：
```xml
<mxCell id="101" value="点击&#xa;&quot;导出开放平台开票门店&quot;" 
        style="rounded=0;whiteSpace=wrap;html=1;fillColor=#fff2cc;strokeColor=#d6b656;" 
        parent="1" vertex="1">
```

---

*本文档定义了 Draw.io 流程图 XML 的生成规范，用于确保生成的 .drawio 文件结构正确、格式规范。*
