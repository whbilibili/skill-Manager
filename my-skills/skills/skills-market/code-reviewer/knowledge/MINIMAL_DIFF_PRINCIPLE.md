# 最小改动原则与减法审查（团队过度工程反模式库）

> **触发加载**：所有 feature 类 PR 必加载（本文件与 TEAM_STANDARDS.md / CODE_DESIGN.md 同级，是常驻知识）。
>
> **为什么单独建一本**：团队高频出现"改得对但改得多"、"抽象过度"、"为了改而改"的 PR。这类问题不是 bug，但造成代码膨胀、审查成本爆炸、后端契约被隐式改动。本知识库把"减法审查"的条款单独拎出来，和"正确性审查"（SECURITY / ASYNC / TS）做等权对待。

## 速查索引

| # | 规则 | 速查特征 | 级别 |
|---|------|---------|------|
| M1 | 改动必须对齐 PR 意图 | 改动无法对应 commit / PR body 中的任何一条声明目标 | **P1（G13）** |
| M2 | 能删则删 | 存在等价空改动 / 已有兜底 / 既加又删同语义 | **P1（G11）** |
| M3 | 能简则简 | 新增函数 ≥ 20 行但可用一行三元 / 解构 / 已有 util 表达 | **P1（G11）** |
| M4 | DTO 契约一致性 | 接口返回的 DTO 被平铺到 state / props / `defaultValue`，提交时又手动拼回同一个 DTO | **P0（G12）** |
| M5 | 提交入参完整性 | 后端接口定义的字段在提交函数里未传齐（尤其是新需求涉及的新字段） | **P0（G12）** |
| M6 | 空 DTO 禁传 | 构造"全字段 undefined 的对象"直接发给后端（应传 undefined 或判空后不传） | **P0（G12）** |
| M7 | React 意图匹配：`defaultValue` vs `useState` | `defaultValue` 语义是"表单首次渲染的初始值"，禁止放数据列表 / 动态数据 / 需更新的状态 | **P1（G12/React）** |
| M8 | useEffect 目的明确 | 存在 useEffect 但无法一句话说清"触发时机 + 做什么 + 为什么依赖这些项" | **P1（React）** |
| M9 | 解构再复制等于没做 | `{ ...item, a: item.a, b: item.b }`；或 `const a = item.a; const b = item.b; return { a, b }` | **P1（G11）** |
| M10 | 多余布尔包装 | `Boolean(x)` 放进 `if`、三元里；`if (xxx) return true; else return false` 等 | **P1（G11）** |
| M11 | 多余默认参数 | 给永不会走到的分支传 `false` / `undefined`；"兜底已有"的前提下额外加前置判断 | **P1（G11）** |
| M12 | 错误码 / 文案爆炸 | 同一语义拆成多个 ERROR_CODE（`NO_AD_ACCOUNT` vs `NO_SELECTED_AD_ACCOUNT`）；同场景文案 ≥ 3 种分支 | **P1（命名/UX）** |
| M13 | 魔数 / 无名常量 | 代码里直接 `0` / `1` / `-1` 作为业务含义，无常量名 | **P1（命名）** |
| M14 | 为改而改 / 无语义移动 | 只有 `export` 顺序变化 / 名字改了但语义不变 / 文件移动但 import 关系无需求变化 | **P1（G13）** |

---

## 一、减法思维的三个基本动作

每条改动进入审查时，**先做减法再做加法**：

### 动作 1：撤销式阅读（Revert-Reading）

"**如果把这段改动整段撤销，PR 还能满足意图声明里的目标吗？**"

- ✅ 能满足 → 这段改动是冗余，P1 建议撤销（M2 / G11）
- ❌ 不能满足 → 进入动作 2

> 例：把 `rebate-edit/index.tsx` 第 119 行的整块改动撤销，PR 意图仍成立 → 周航实评"整个文件不用改"

### 动作 2：一行替换（One-Liner Challenge）

对每个新增的**函数 / util / helper**，强制问一遍：
- 能不能用 **一行三元** 表达？
- 能不能用 **一个解构 + 直接引用** 表达？
- 能不能直接复用 **已有 util / 类型 / 常量**？

> 例：
> ```ts
> // ❌ 新增了 15 行 helper
> function formatAdAccount(row) {
>   if (row.adAccountDTO) {
>     const id = row.adAccountDTO.adAccountId
>     const name = row.adAccountDTO.adAccountName
>     return `${id}:${name}`
>   }
>   return '-'
> }
>
> // ✅ 一行
> const formatAdAccount = (row) => row.adAccountDTO ? `${row.adAccountDTO.adAccountId}:${row.adAccountDTO.adAccountName}` : '-'
> ```

### 动作 3：既加又删检测（Diff Cancellation）

同一 diff 里查找：
- 有没有"先加一个东西，几行外又删了它"（`+ a` + `- a`）
- 有没有"先判断 x，几行外又兜底了 x"（M11 典型）
- 有没有"解构出字段，再用同名字段拼回去"（M9 典型）

这类改动净效果 = 0，必须删。

---

## 二、DTO 契约审查（G12 的主战场）

### 2.1 平铺 / 拼回反模式

后端接口返回 `adAccountDTO: { adAccountId, adAccountName, adAccountType, ... }`：

```ts
// ❌ 反模式：先平铺，提交时又拼回
const [adAccountId, setId] = useState(data.adAccountDTO?.adAccountId)
const [adAccountName, setName] = useState(data.adAccountDTO?.adAccountName)
// ... 省略 5-10 个 state

// 提交时
submit({
  adAccountDTO: { adAccountId, adAccountName, /* ...又拼回去 */ }
})
```

**为什么是 P0**：
- 增加了"平铺 → 拼回"两处可能 miss 字段的风险（M5 / M6 触发场景）
- 后端接口字段新增时，前端要改两处（取出 + 拼回）
- 字段默认值语义丢失（`undefined` 在平铺过程中可能被误填为 `null` / `''`）

**正解**：
```ts
// ✅ 对象整体持有
const [adAccountDTO, setAdAccountDTO] = useState(data.adAccountDTO)

// 提交时
submit({ adAccountDTO })
```

### 2.2 `defaultValue` 语义误用

```ts
// ❌ defaultValue 里装数据列表
<Form.Item defaultValue={adAccountList}>  // adAccountList 是数组，不是表单初始值
```

`defaultValue` 的语义是"**表单首次渲染的初始受控值**"，应当：
- 装"该字段的初始值"（单值 / 单对象）
- **不**装数据源列表（列表应该用 `useState` / `useMemo` 持有）
- **不**装会更新的动态数据（否则要用 `value` + 外部 state）

### 2.3 空 DTO 直传检查

```ts
// ❌ 哪怕字段全 undefined 也拼一个 DTO 对象发出去
const toSubmit = (item) => ({
  adAccountDTO: {
    adAccountId: item.adAccountId,
    adAccountName: item.adAccountName,
    adAccountType: item.adAccountType,
  },
})

// 后端收到 { adAccountDTO: { adAccountId: undefined, adAccountName: undefined, adAccountType: undefined } }
// 大概率反序列化异常 / 校验失败 / 脏数据入库
```

**正解**：
```ts
// ✅ 判空后决定是否附带 DTO 字段
const toSubmit = (item) => {
  const dto = buildAdAccountDTO(item)  // 内部做完整性校验
  return dto ? { adAccountDTO: dto } : {}
}
```

### 2.4 入参完整性检查（必做）

审查 `toSubmitXxx` / `onSubmit` / `buildPayload` 这类函数时，**把光标移到接口类型定义处 Grep**，逐字段核对：
- 接口定义字段 A/B/C/D/E
- 提交函数字段 A/B/C/D/X（**E 缺失，X 多余**）

例：周航评"`platformOperateFeePercent` 这个入参怎么没有呢" = 前端提交函数里遗漏了 `platformOperateFeePercent` 字段。

---

## 三、React 意图匹配清单

对每个 React Hook / 表单字段 / 状态块，强制回答下面三问：

| 组件元素 | 必答 |
|---------|------|
| `useState(initial)` | 这个 state 什么时候会变？由谁触发？初始值为什么是这个？ |
| `useEffect(fn, deps)` | 触发时机？做什么？依赖项为什么是这几个？缺一个会怎样？多一个会怎样？ |
| `<Form.Item defaultValue={x}>` | `x` 是"单次初始值"还是"会变的数据"？是"单值/对象"还是"列表"？ |
| `<Form.Item value={x} onChange>` | 是否应该用 `defaultValue` 替代？是否缺 `onChange`？ |
| `{ ...item, a: item.a }` | `a` 字段是否被其他值覆盖？如果没有 → M9 冗余，直接 `...item` |

**典型漏审**：
- 周航："这好冗余，直接 `...item`" → M9
- 周航："没看懂这个 useEffect 是要干啥" → M8
- 周航："为啥监听 customerList" → M8（依赖项与副作用逻辑不匹配）

---

## 四、文案 / 错误码爆炸审查（M12）

当 diff 里同时出现：
- ≥ 2 个 `ERROR_MESSAGES.XXX` 常量
- 或 ≥ 2 个同场景提示文案分支

必须 Grep 该仓库内同语义常量，判断是否存在"意义接近但独立存在"的错误码。例：
- `ERROR_MESSAGES.NO_AD_ACCOUNT` —— 没有广告账户
- `ERROR_MESSAGES.NO_SELECTED_AD_ACCOUNT` —— 没有选择广告账户

这两者大概率可以合并为一个（触发场景不同但文案语义相近）。合并判断流程：
1. 列出每个错误码的触发场景
2. 对比产品侧是否真的需要区分两种文案
3. 若"用户看到的提示实际是同一句"，建议合并

---

## 五、意图不明改动（M1 / G13）的标准输出

对 N1 不通过的改动，在报告里集中到 **"🔎 意图不明改动清单"** 节，格式：

```
| 文件:行号 | 改动摘要 | 疑问 |
|----------|---------|-----|
| pages/pangu/view/rebate-details/index.tsx:47 | 只调整了 export 顺序 | 本次 PR 意图是"新增 DTO 提交字段"，为什么需要改这里？能否撤销？ |
| pages/pangu/view/rebate-edit/index.tsx:119 | 整个文件大段改动 | 撤销后 PR 意图仍成立，这些改动的必要性是什么？ |
```

这是让 PR 作者必须回答的问题列表，不是 AI 要"判对/判错"的条目。这类条目**不计入 P0/P1 正式 bug 数量**，但必须出现在报告里。

---

## 六、与其他知识文件的关系

| 维度 | 本文件 | 其他文件 |
|------|-------|---------|
| 改的对不对 | —— | SECURITY / ASYNC / TS / REACT_BEST_PRACTICES |
| 改得必要不必要（减法） | ✅ 本文件独占 | —— |
| 改得简洁不简洁（减法） | ✅ 本文件独占 | —— |
| Store 状态生命周期 | 交叉（M4 平铺问题 ↔ STORE_LIFECYCLE §二） | STORE_LIFECYCLE.md |
| 命名 / 魔数 | ✅ M12 / M13 | CODE_DESIGN.md（高层设计） |

**硬规则**：所有 feature PR 的 CR 报告必须同时给出：
- 🔴 正确性问题（G1-G10 / 其他知识文件）
- 🟡 必要性 / 简洁度问题（G11-G13 / 本文件 M1-M14）
- 🔎 意图不明改动清单（N1 产物）

三者齐备，才是一份完整 CR。
