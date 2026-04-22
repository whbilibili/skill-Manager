# TypeScript 规范

## 1) tsconfig（新项目/工具库强制）

### 【强制】至少开启以下配置

- `allowUnreachableCode:false`, `allowUnusedLabels:false`, `exactOptionalPropertyTypes:true`
- `noFallthroughCasesInSwitch:true`, `noImplicitOverride:true`, `noUncheckedIndexedAccess:true`
- `noUnusedLocals:true`, `noUnusedParameters:true`, `isolatedModules:true`, `checkJs:true`
- `forceConsistentCasingInFileNames:true`, `skipLibCheck:true`, `experimentalDecorators:true`
- `strict:true`

### 【存量项目可临时关闭（需 CodeReview 卡控）】

- `strictNullChecks:false`, `exactOptionalPropertyTypes:false`, `noImplicitAny:false`
- `useUnknownInCatchVariables:false`

---

## 2) 类型 / 接口

### 【强制】可选属性不可赋值 `undefined`

除非类型显式包含 `undefined`

### 【强制】禁止隐式 any

### 【强制】重载签名相邻放置

### 【强制】不要仅因某个参数位置类型不同而定义多个重载，优先联合类型

### 【强制】方法签名使用函数类型

如 `func: (arg) => ret`

### 【强制】禁止在泛型与函数返回值之外使用 `void`

### 【强制】禁止冗余并/交类型

如 `any | 'foo'`

### 【强制】禁止不必要的类型断言与不必要的非空断言

### 【强制】禁止对泛型类型进行不必要约束（如 `T extends any`）

### 【强制】禁止不安全的声明合并

interface/class 同名、namespace/enum 重复等。

### 【建议】并集/交集成分按字母顺序排序

### 【强制】类型/接口/枚举 PascalCase

### 【强制】成员分隔符：若成员不与 `]`/`}` 同行，必须以分号结尾

---

## 3) 枚举

### 【强制】枚举成员无重复值

### 【强制】枚举禁止数字/字符串混用

### 【强制】显式初始化每个枚举成员

### 【强制】枚举成员必须是字面量

---

## 4) 字面量 / 字符串插值

### 【强制】避免字符串化出现 `"[object Object]"`

对象需有自定义 `toString` 才允许插值。

### 【强制】模板字符串表达式必须是 `string` 类型

---

## 5) 数组

### 【强制】禁止 `for...in` 遍历数组

### 【建议】`reduce` 使用泛型推导

---

## 6) 变量

### 【强制】禁止未使用变量

### 【强制】不能删除"变量形态"的属性（动态 key 删除）

### 【强制】对初始化为 number/string/boolean 的变量/参数不写显式类型注解

交给推导。

### 【强制】不允许把 any 再分配给变量

新项目/工具库建议强开。

### 【强制】变量命名：camelCase/PascalCase/MACRO_CASE

---

## 7) 对象与空值

### 【强制】通过索引签名引入的属性必须用 `['key']` 访问，禁止点访问

### 【强制】`noUncheckedIndexedAccess`：未声明属性需带 `| undefined` 并做空值校验

### 【强制】严格空值校验

使用可选链/空值合并等。

### 【强制】空对象类型用 `Record<string, unknown>`

### 【强制】禁止连续多个非空断言

### 【强制】可选链表达式后禁止非空断言

### 【强制】禁止在非空断言后直接调用函数

### 【强制】禁止访问 any 类型成员变量

---

## 8) 函数

### 【强制】`call/apply` 严格校验（strictBindCallApply）

### 【强制/建议】函数类型严格校验（strictFunctionTypes）

存量可放宽

### 【强制/建议】必须定义参数与返回值类型，且不得涉及 any

存量可放宽

### 【强制/建议】导出函数/类公共方法必须显式返回类型

存量可放宽

### 【强制】禁止把 void 返回值用于赋值/return

### 【建议】避免未使用入参

### 【强制】禁止向函数传 any 参数 / 调用 any 类型函数 / 返回 any 值

部分条目新项目/工具库建议强开

### 【建议】函数入参尽量用 readonly

### 【强制】默认参数放最后

---

## 9) 类

### 【强制】override 必须显式声明

### 【强制】类属性初始化严格校验

### 【强制/建议】非 public 成员显式 `private/protected`

存量可放宽

### 【强制】禁止 new/constructor 无效使用

### 【建议】构造函数避免参数属性（parameter properties）

### 【建议】返回 this 的方法返回类型写 `this`

---

## 10) 模块

### 【强制/建议】显式导出/导入类型：`export type` / `import type`

### 【强制】禁止使用 namespace（必须结合 declare）

### 【强制】禁止不必要的名称空间限定符

---

## 11) 运算符

### 【强制】判空运算符左侧禁止非空断言

### 【强制】加法两侧类型必须相同且为 bigint/number/string

---

## 12) 异步

### 【强制】任何返回 Promise 的函数/方法必须标注 `Promise<...>` 返回类型

---

## 13) 风格（空格）

### 【强制】类型注解冒号左右空格规范

`foo: string`

### 【强制】代码块左大括号前空一格
