# 团队线上事故案例库

> 每个案例都有真实的线上 COE 记录。CR 时发现相似模式，直接引用对应事故作为佐证。

---

## 案例1：幻影依赖导致页面白屏

**COE**：[#186065](https://coe.mws.sankuai.com/detail/186065) — 2022年3月，MTA后台营销叠加设置功能故障，持续约48小时，影响15000+用户

**代码问题**：
```javascript
import _ from 'lodash'; // ❌ package.json 未显式声明，依赖 some-ui-lib 间接引入
export function formatPrice(price) {
  return _.round(price, 2);
}
```

**触发**：`some-ui-lib` 升级 3.0 后移除了对 lodash 的间接依赖，lodash 不再被安装，20+ 页面白屏。

**修复**：显式在 `package.json` 中声明所有直接使用的包。

**CR 检查点**：代码中 import 的每个包，是否都在 `package.json` `dependencies` 或 `devDependencies` 中**显式声明**？

---

## 案例2：Promise 永远 pending 导致页面卡死

**COE**：[#199127](https://coe.mws.sankuai.com/detail/199127) — 2022年6月，医美预付退款页面部分用户无法打开，持续约8天

**代码问题**：
```javascript
function getLocation() {
  return new Promise((resolve, reject) => {
    KNB.getLocation({
      success(location) {
        if (location.lat) {  // ❌ lat=0 时为 falsy，什么都不做，Promise 永远 pending
          resolve(location);
        }
      }
      // ❌ 没有 fail 回调
    });
  });
}
```

**修复**：
```javascript
function getLocation() {
  return new Promise((resolve, reject) => {
    KNB.getLocation({
      success(location) {
        if (location.lat !== undefined && location.lng !== undefined) {
          resolve(location);
        } else {
          reject(new Error('Invalid location'));
        }
      },
      fail: reject
    });
  });
}
```

**CR 检查点**：Promise 构造函数中，所有条件分支是否都有 resolve 或 reject？success/fail 两个回调是否都处理了？

---

## 案例3：switch-case 缺少 break 导致逻辑穿透

**COE**：[#260045](https://coe.mws.sankuai.com/detail/260045)

**代码问题**：
```javascript
switch (moduleType) {
  case 'address':
    config = getAddressConfig();
    // ❌ 缺少 break，穿透到下一个 case
  case 'payment':
    config = getPaymentConfig(); // 上门地址模块也会执行到这里，配置被覆盖
    break;
}
```

**CR 检查点**：switch 的每个非空 case 是否都有 break 或 return？

---

## 案例4：async 函数忘记 await 导致权限校验失效

**COE**：[#182530](https://coe.mws.sankuai.com/detail/182530) — 约7-10个项目无法正常部署，持续约22小时

**代码问题**：
```javascript
async function myController(ctx) {
  const list = ['123'];
  // ❌ check() 返回 Promise，未 await 直接做 && 判断
  // Promise 对象是 truthy，永远返回 true，权限校验形同虚设
  return ctx.service.groupMessage.check() && list.length > 0;
}
```

**修复**：
```javascript
async function myController(ctx) {
  const list = ['123'];
  const checkResult = await ctx.service.groupMessage.check();
  return checkResult && list.length > 0;
}
```

**CR 检查点**：返回 Promise 的函数调用，是否有 await？禁止直接拿 Promise 对象做条件判断（永远为 truthy）。

---

## 案例5：JSON.parse 未保护导致渲染阻断

**COE**：[#199603](https://coe.mws.sankuai.com/detail/199603) — 2022年6月，IM PC端商品气泡消息不显示，持续约7天

**代码问题**：
```javascript
// ❌ 后端缺少 content 字段时，JSON.parse 报错，后续渲染全部阻断
const data = JSON.parse(message.content);
renderMessage(data);
```

**修复**：
```javascript
let data = null;
try {
  data = JSON.parse(message.content);
} catch (e) {
  console.error('消息解析失败:', e, message);
  data = { type: 'unknown' }; // 兜底，不阻断渲染
}
renderMessage(data);
```

**CR 检查点**：所有 `JSON.parse` 是否有 try-catch？catch 里是否有兜底处理而不是空块？

---

## 案例6：浮点数精度导致退款资损

**COE**：[#240949](https://coe.mws.sankuai.com/detail/240949) — 2023年4月，代金券面值计算错误（16.9元→16.89元），资损¥5万+

**代码问题**：
```javascript
const voucherAmount = 16.9;
const discountedAmount = voucherAmount * 0.9; // ❌ = 15.209999999999999
// 四舍五入后产生错误金额
```

**修复**：
```javascript
// ✅ 整数运算（分为单位）
const voucherAmountCents = 1690;
const discountedCents = Math.floor(voucherAmountCents * 90 / 100); // 1521分
const display = discountedCents / 100; // 15.21元

// ✅ 或用 decimal.js
import Decimal from 'decimal.js';
new Decimal(16.9).mul(0.9).toFixed(2); // "15.21"
```

**CR 检查点**：涉及金额/积分/折扣的计算，是否使用整数（分）或 decimal.js？

---

## 案例7：Vue/React 组件默认值箭头函数写法错误

**COE**：无（规范问题，CR 中频繁出现）

**代码问题**：
```javascript
// ❌ Vue props 默认值
default: () => {}  // 这是函数体，返回 undefined！

// ❌ React 参数默认值
function MyComp({ config = () => {} }) {
  config.theme; // TypeError: Cannot read property 'theme' of undefined
}
```

**修复**：
```javascript
// ✅ Vue：圆括号包裹对象字面量
default: () => ({})

// ✅ React：直接用对象字面量
function MyComp({ config = {} }) {}
```

**CR 检查点**：箭头函数返回对象字面量时，必须用圆括号包裹 `() => ({})`。

---

## 案例N：CKA 半年框切换协议模版后子表单字段不更新（Store 状态残留）

**场景**：2026年，CKA 半年框需求上线后，产品反馈"切换协议模版时，子表单字段信息不更新"。用户需刷新页面或重选账户才能看到正确内容。

**触发路径**（单实例 Store 被复用的经典事故）：
1. 用户第一次打开广告账户表单 → `AdAccountStore.open({ isEdit: true, adAccount: A })`
2. `open` 方法里异步回调给 `rawSelectedShopAccount` 赋值 = A 的门店账户
3. 用户提交后关闭弹窗（`dispose` 未清 `rawSelectedShopAccount`）
4. 用户再次打开表单 → `open({ isEdit: true, adAccount: B })`
5. 本次 `open` 里 `if (isEdit) { /* 只赋值 initShopAccount，没赋值 rawSelectedShopAccount */ }`
6. UI 子表单读到 `rawSelectedShopAccount = A`，显示旧数据

**代码问题**：

```ts
// packages/container/share/share-activity/store/ad-account.ts
class AdAccountStore {
  @observable rawSelectedShopAccount: ShopAccount | null = null
  @observable initShopAccount: ShopAccount | undefined = undefined

  @action
  open({ isEdit, adAccount, mtShopIds, changeAdAccountHandle }: OpenParams) {
    this.mtShopIds = mtShopIds || []
    this.changeAdAccountHandle = changeAdAccountHandle

    if (isEdit) {
      if (adAccount?.adAccountType === AD_ACCOUNT_TYPE.SHOP && adAccount.shopAccounts?.[0]) {
        this.initShopAccount = adAccount.shopAccounts[0]
      }
      // ❌ 没有 else：rawSelectedShopAccount 保留上一次 open 的值
    } else {
      this.restoreSelectedShopAccount(adAccount)
    }
  }

  @action
  onQueryDone(result: AdAccountDetail) {
    if (this.initShopAccount && result?.shopAccounts) {
      const stillExists = result.shopAccounts.some(s => s.id === this.initShopAccount!.id)
      if (stillExists) {
        this.rawSelectedShopAccount = this.initShopAccount
      }
      // ❌ stillExists=false 时静默落空，rawSelectedShopAccount 保留旧值
      this.initShopAccount = undefined
    }
  }
}
```

**本次 diff 中的蛛丝马迹**（CR 没抓住的信号）：
- diff 里**删除了**对 `rawSelectedShopAccount` 的一次重置赋值（G10 典型模式）
- `open` 方法被改写成"条件分支只赋值一部分 observable"（G9 典型模式）
- 但之前的 CR 只看了新增代码的语义是否正确，没有对删除行做"谁接手"的核查，也没有做 `open/dispose` 对称性检查

**修复**：

```ts
@action
open({ isEdit, adAccount, mtShopIds, changeAdAccountHandle }: OpenParams) {
  this.reset()  // 关键：入口先清零所有 observable
  this.mtShopIds = mtShopIds || []
  this.changeAdAccountHandle = changeAdAccountHandle

  if (isEdit) {
    this.initShopAccount =
      adAccount?.adAccountType === AD_ACCOUNT_TYPE.SHOP ? adAccount.shopAccounts?.[0] : undefined
    // rawSelectedShopAccount 由 reset() 归零，等 onQueryDone 覆盖
  } else {
    this.restoreSelectedShopAccount(adAccount)
  }
}

@action
onQueryDone(result: AdAccountDetail) {
  const exists =
    this.initShopAccount && result?.shopAccounts?.some(s => s.id === this.initShopAccount!.id)
  // 不管成立与否，rawSelectedShopAccount 都被显式写过一次
  this.rawSelectedShopAccount = exists ? this.initShopAccount! : null
  this.initShopAccount = undefined
}

@action
private reset() {
  this.rawSelectedShopAccount = null
  this.initShopAccount = undefined
  this.mtShopIds = []
}
```

**CR 检查点（给 skill 的硬规则）**：
1. 路径含 `store/` 或类名含 `Store` 的文件进入 diff → 强制加载 `STORE_LIFECYCLE.md`
2. `open` / `init` / `show` 方法带条件分支时，必须对照"五问检查"（见 STORE_LIFECYCLE §二）
3. diff 中任何含状态清理语义的 `-` 行（`reset()` / `= undefined` / `= null` / `= []`）必须单独判断"谁接手"；无等价替换的 → G10 直接 P0
4. 单实例 / 长生命周期 Store 的 `dispose` / `close` / `hide` 方法必须清掉本次 `open` 写过的所有 observable

---

## 案例N+1：CKA rebate PR 过度工程（28 条人工 CR 评论复盘）

**场景**：2026-04，CKA rebate 需求提交 PR，人工 CR 产出 28 条评论（13 条未解决 / 15 条已解决）。本 PR 的 skill AI CR 几乎没能产出有效意见，暴露"减法审查"盲区。

**本 PR 的问题可归四类**：

| 类别 | 命中评论数 | 代表评论 | 违反规则 |
|------|---------|---------|---------|
| A. 过度工程 / 冗余 | 10 | "22 到 101 行全都不需要"；"整个文件不用改"；"这函数不需要，一行就够"；"直接 `...item`" | **G11 / M2 / M3 / M9** |
| B. 接口 DTO 契约错配 | 6 | "`adAccountDTO` 不需要平铺"；"`platformOperateFeePercent` 入参没有"；"全 undefined DTO 发给后端" | **G12 / M4 / M5 / M6** |
| C. React 意图误用 | 4 | "`defaultValue` 装 `adAccountList`"；"useEffect 要干啥"；"为啥监听 `customerList`" | **M7 / M8** |
| D. 命名 / 魔数 / 文案 | 4 | "魔数 0 是什么"；"`NO_AD_ACCOUNT` vs `NO_SELECTED_AD_ACCOUNT` 区别"；typo `pangul → pangu` | **M12 / M13** |

**最尖锐的一条（人工 reviewer 原话）**：
> "唉，我觉得你是一点不看，纯靠 AI 在这乱写。不梳理原逻辑，不看接口变更，不看 AI 写完的 review，周一必须得仔细梳理清楚，其实整体根本改不了几个地方。"

**本质问题**：PR 作者做了**加法**，没做**减法**。接口改动其实只需要几行，作者写出了几百行。AI 之前的 CR 只看"改的对不对"，没看"该不该改"。

**典型反例 1：DTO 先平铺再拼回（M4）**

```ts
// ❌ 反模式
const [adAccountId, setId] = useState(data.adAccountDTO?.adAccountId)
const [adAccountName, setName] = useState(data.adAccountDTO?.adAccountName)
const [adAccountType, setType] = useState(data.adAccountDTO?.adAccountType)

submit({ adAccountDTO: { adAccountId, adAccountName, adAccountType } })

// ✅ 正解
const [adAccountDTO, setAdAccountDTO] = useState(data.adAccountDTO)
submit({ adAccountDTO })
```

**典型反例 2：helper 函数冗余（M3）**

```ts
// ❌ 写了 15 行 helper
function formatAdAccount(row) {
  if (!row.adAccountDTO) return '-'
  const id = row.adAccountDTO.adAccountId
  const name = row.adAccountDTO.adAccountName
  return `${id}:${name}`
}

// ✅ 一行三元
const formatAdAccount = row =>
  row.adAccountDTO ? `${row.adAccountDTO.adAccountId}:${row.adAccountDTO.adAccountName}` : '-'
```

**典型反例 3：`defaultValue` 装列表（M7）**

```tsx
// ❌ defaultValue 放了 adAccountList（数据列表）
<Form.Item name="accounts" defaultValue={adAccountList} />

// ✅ adAccountList 走 useState，defaultValue 装"单次初始值"
const [adAccountList, setAdAccountList] = useState<AdAccount[]>([])
<Form.Item name="accounts" defaultValue={data.selectedAdAccount} />
```

**典型反例 4：全 undefined DTO 直传（M6）**

```ts
// ❌ 不管字段是否齐全都创建 DTO
const toSubmitDTO = item => ({
  adAccountDTO: {
    adAccountId: item.adAccountId,       // undefined
    adAccountName: item.adAccountName,   // undefined
    adAccountType: item.adAccountType,   // undefined
  }
})

// ✅ 判空后决定是否附带
const toSubmitDTO = item => {
  const dto = buildAdAccountDTO(item)
  return dto ? { adAccountDTO: dto } : {}
}
```

**CR 检查点（给 skill 的硬规则）**：
1. 加载 `MINIMAL_DIFF_PRINCIPLE.md`（feature PR 常驻）
2. 第 0.1 步必须收集 PR 改动意图；commit 为空时主动问作者
3. 第 3.0 步对每个 ≥ 5 行新增块跑必要性五问 N1-N5
4. 报告里必须有 **🔎 必要性审查结论** + **🔎 意图不明改动清单** 两节
5. 文件覆盖矩阵保证所有 diff 文件都被点名，无遗漏

**经验教训**：
- "改的对" ≠ "改的好"
- 代码膨胀本身就是缺陷（维护成本 / 契约漂移 / 审查疲劳）
- AI CR 如果不强制"做减法"，只会鼓励"加法惯性"——本条 case 是明证

---

## 事故统计

| 类型 | COE | 次数 | 典型影响用户数 | 资损 |
|------|-----|------|-------------|------|
| 幻影依赖 | #186065 | 3次 | 15000+ | — |
| Promise pending | #199127 | 5次 | 8000+ | — |
| 忘记 await | #182530 | 4次 | 多项目部署失败 | — |
| JSON.parse 未保护 | #199603 | 2次 | 2000+ | — |
| switch 缺 break | #260045 | 2次 | 3000+ | — |
| 浮点数计算 | #240949 | 1次 | 500+ | ¥5万 |
| Store 状态残留（G9/G10）| CKA 半年框 2026Q2 | 1次 | 全量 CKA 用户 | 产品体感 bug |
| 过度工程/冗余/契约错配（G11-G13）| CKA rebate 2026-04 | 1次 PR | 代码膨胀 + 审查成本 | 28 条人工 CR 评论 |
