# Mobx Store 生命周期规范（跨会话状态残留防护）

> **触发加载**：文件路径含 `store/` / `stores/` / `.store.ts` / `.store.js`；或类名含 `Store`；或出现 `@observable` / `runInAction` / `open(` / `init(` / `reset(` / `dispose(`。

## 速查索引

| # | 规则 | 识别特征 | 级别 |
|---|------|---------|------|
| S1 | Store 打开/初始化时必须**显式重置所有被外部读写的 observable** | `open`/`init`/`show` 方法未调用 `reset()` 也未对所有可变字段赋值 | **P0（G9）** |
| S2 | 条件分支赋值必须**覆盖所有分支** | `if (xxx) { this.a = ... }` 没有 else，或 `if/else if` 链缺少兜底分支 | **P0（G9）** |
| S3 | `queryXxx` / 异步回调里的"延迟赋值"必须有**成功与失败的双路径** | 只在数据校验通过时赋值，校验失败路径静默落空，留残留值 | **P0** |
| S4 | 删除现有 `reset()` / `clear()` / `this.xxx = undefined` 必须有**等价替换** | diff `-` 掉了清理行，函数里没有新的清零语义 | **P0（G10）** |
| S5 | 编辑态 / 查看态 / 新建态的状态入口必须**对称** | 三种态中某一种不走 reset 路径 | P0 |
| S6 | Store 是 **long-lived 单例**时尤其危险 | `@inject` 注入、`useLocalStore` 外部、全局 provider | 触发后上面规则全部升级为 P0 |
| S7 | `dispose()` / `hide()` / `close()` 必须清掉**所有本次交互产生的 observable** | 关闭后残留字段会被下一次 `open` 读到 | P0 |
| S8 | 对 observable 的赋值必须在 `runInAction` 内完成 | `await` 之后直接 `this.xxx = ...` 而不包 `runInAction` | P1 |
| S9 | Store 外部不得直接赋值 observable 属性 | 组件里 `store.xxx = ...` 而不调 `store.setXxx()` / `store.update()` | P1 |

---

## 一、为什么 Store 状态残留是 P0

Store 在很多工程里是 **long-lived 单例**（比如挂在全局 Provider、被 `@inject` 注入到多处）。单例意味着：

- **实例只被构造一次，但 `open()` 会被调用多次**
- 每次 `open` 本质上是"开一个新会话"，但**物理上复用同一个实例**
- 所以任何一个 observable 字段只要在 `open` 时没被显式重写，**就会带着上一次会话的值进入本次会话**

**运行时后果**（直接引用团队 CKA 半年框事故）：
- 用户第一次打开表单 → 选择协议模版 A → `rawSelectedShopAccount = A`
- 关闭表单（`dispose()` 里没清 `rawSelectedShopAccount`）
- 用户第二次打开表单 → 选择协议模版 B → `open()` 只在"新建态"走 `restoreSelectedShopAccount`，"编辑态"不走 → `rawSelectedShopAccount` 仍然是 A
- UI 子表单字段沿用 A 的数据 → 用户看到旧数据，体感上是 "模版切换不生效"

这类 bug 的特点：
- **单人测试极难发现**（因为只有第二次以上打开才复现）
- **只看 diff 片段看不出来**（必须看完整 `open` / `dispose` / 回调对称性）
- **不报错、不抛异常、也不 crash**，属于静默逻辑错误

所以 Store 初始化残留一旦识别到，直接 **P0**，与 XSS / 金额浮点 / 空 catch 同级。

---

## 二、open / init 方法的"五问检查"

对 Store 的 `open` / `init` / `show` 方法（以下统称 `open`），逐一回答：

| # | 问题 | 通过标准 |
|---|------|---------|
| 1 | 本 Store 有哪些会被外部读到的 observable？ | 能列出完整清单（至少 diff 涉及的都要列）|
| 2 | 这次 `open` 里，每个 observable 是否都被**显式写过一次**？ | 有 `reset()` 调用 / 或逐个字段赋值 |
| 3 | 方法里是否存在 `if / else if / switch` 分支？ | 每个分支都要回答清单中所有字段是否被赋值 |
| 4 | 异步回调（`then` / `await` 之后）里赋值的字段，在**回调失败 / 早返回**时是否也被处理？ | 失败路径不能静默落空 |
| 5 | 关掉弹窗 / 切换步骤的 `dispose` / `close` / `hide` 方法是否清掉了本次产生的字段？ | 关闭时 observable 回到初始态 |

**任一问题回答不了 → 按 G9 记 P0 候选，必须 Read 完整 Store 文件二次核实。**

---

## 三、BadCase：Store 条件分支遗漏 else

### ❌ 错误写法（真实事故代码示意）

```ts
// store/ad-account.ts
class AdAccountStore {
  @observable rawSelectedShopAccount: ShopAccount | null = null
  @observable initShopAccount: ShopAccount | undefined = undefined
  @observable mtShopIds: number[] = []

  @action
  open({ isEdit, adAccount, mtShopIds, changeAdAccountHandle }: OpenParams) {
    this.mtShopIds = mtShopIds || []
    this.changeAdAccountHandle = changeAdAccountHandle

    if (isEdit) {
      // 编辑态：暂存旧门店数据
      if (adAccount?.adAccountType === AD_ACCOUNT_TYPE.SHOP && adAccount.shopAccounts?.[0]) {
        this.initShopAccount = adAccount.shopAccounts[0]
      }
      // ❌ 没有 else：rawSelectedShopAccount 保留上一次 open 的值
    } else {
      this.restoreSelectedShopAccount(adAccount)
    }
  }

  // 异步查询回调
  @action
  onQueryDone(result: AdAccountDetail) {
    if (this.initShopAccount && result?.shopAccounts) {
      const stillExists = result.shopAccounts.some(s => s.id === this.initShopAccount!.id)
      if (stillExists) {
        this.rawSelectedShopAccount = this.initShopAccount
      }
      // ❌ 没有 else：stillExists=false 时 rawSelectedShopAccount 静默落空，保留上次值
      this.initShopAccount = undefined
    }
  }
}
```

### ✅ 正确写法

```ts
@action
open({ isEdit, adAccount, mtShopIds, changeAdAccountHandle }: OpenParams) {
  // 关键：任何分支进入前，先把"所有本方法会操纵的 observable"重置到初始态
  this.reset()

  this.mtShopIds = mtShopIds || []
  this.changeAdAccountHandle = changeAdAccountHandle

  if (isEdit) {
    if (adAccount?.adAccountType === AD_ACCOUNT_TYPE.SHOP && adAccount.shopAccounts?.[0]) {
      this.initShopAccount = adAccount.shopAccounts[0]
    } else {
      this.initShopAccount = undefined
      this.rawSelectedShopAccount = null
    }
  } else {
    this.restoreSelectedShopAccount(adAccount)
  }
}

@action
private reset() {
  this.rawSelectedShopAccount = null
  this.initShopAccount = undefined
  this.mtShopIds = []
  // ... 列举所有 observable
}

@action
onQueryDone(result: AdAccountDetail) {
  const exists =
    this.initShopAccount &&
    result?.shopAccounts?.some(s => s.id === this.initShopAccount!.id)

  // 不管 exists 是 true 还是 false，rawSelectedShopAccount 都被显式写过一次
  this.rawSelectedShopAccount = exists ? this.initShopAccount! : null
  this.initShopAccount = undefined
}
```

---

## 四、diff 删除行的状态清理语义识别（G10 专用）

以下 **所有以 `-` 打头的删除行**在 Store / Context / 全局单例类文件里都要**单独拎出来判一遍**：

| 删除行模式 | 删除语义 | 是否 P0 |
|-----------|---------|--------|
| `- this.xxx = undefined` / `- this.xxx = null` / `- this.xxx = []` / `- this.xxx = {}` | 清零 observable | 删除后无等价替换 → **P0** |
| `- this.reset()` / `- this.clear()` / `- this.dispose()` | 批量清零 | 同上 → **P0** |
| `- runInAction(() => { this.xxx = ... })` | 在事务里做状态重置 | 同上 → **P0** |
| `- delete this.xxx` | 删除属性 | 同上 → **P0** |
| `- this.$reset()` / Vuex / Pinia 场景 | 清零 | 同上 → **P0** |
| `- // reset ...` 注释 | 仅注释 | P2 |

**判断流程**：
1. 从 diff 里 `grep '^-'` 拿到所有删除行
2. 对每条命中上面模式的行，**Read 整个方法**确认同函数内是否有等价替换
3. 无等价替换 → 直接 P0 候选，引用 G10；**再走第 4 步"五问核验"**确认行号和运行时后果后输出

**AI 容易踩的坑**：
- 只看 `+` 行判断"新加的逻辑正不正确"，忽略 `-` 行的"原来做的事现在谁做"
- 以为 "删了一行空格" 或 "删了一行注释" → 没必要核查。但清理语义类的删除必须逐条过。

---

## 五、Store 外部（组件 / 页面）容易引爆状态残留的调用模式

在组件侧审查时，若发现以下模式，**回到 Store 复查对称性**：

```ts
// ❌ 只有进入时 open，退出没有 dispose
useEffect(() => {
  store.open(params)
  // 没有 return () => store.dispose() !
}, [])

// ❌ 用 open 当 setter 用：切换实体时反复 open 同一个单例
const onChangeTemplate = (tpl) => {
  store.open({ template: tpl })  // 依赖 open 里全字段重写
}

// ❌ 不调 store 方法，直接塞
store.rawSelectedShopAccount = null  // 违反 S9
```

---

## 六、审查模式速记（输出时引用）

| 依据 | 缩写 |
|------|------|
| 本文件 §一 / §二 | `STORE_LIFECYCLE.md §一`、`§二` |
| 条件分支遗漏 else 导致旧状态残留 | `G9 / STORE_LIFECYCLE.md §三` |
| diff 删除清理语句无等价替换 | `G10 / STORE_LIFECYCLE.md §四` |

> **最后一条硬规则**：Store 类文件的 CR 报告中，`📋 上下文分析` 节必须显式写明：
> "✅ 已验证 open/init/reset/dispose 对称性" 或 "⚠️ 发现 X 个字段在 reset 中缺失"。
> 缺这一行 = 本次 Store 审查未执行，必须重做。
